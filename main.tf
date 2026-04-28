locals {
  tags = merge(var.tenx_retriever_user_supplied_tags, {
    terraform-module         = "tenx-retriever-infra"
    terraform-module-version = "v0.9.3"
    managed-by               = "tenx-terraform"
  })

  # Determine if source and results buckets are the same
  buckets_are_same = var.tenx_retriever_index_source_bucket_name == var.tenx_retriever_index_results_bucket_name

  # Construct the indexWriteContainer path (bucket + path)
  index_write_container = "${var.tenx_retriever_index_results_bucket_name}/${var.tenx_retriever_index_results_path}"

  # Observability metric-filter name prefix. Default: sanitized log group
  # name (leading slash stripped, remaining slashes → hyphens). Override
  # via tenx_retriever_metric_filter_name_prefix to maintain naming
  # continuity across module upgrades.
  metric_filter_name_prefix = (
    var.tenx_retriever_metric_filter_name_prefix != ""
    ? var.tenx_retriever_metric_filter_name_prefix
    : replace(trimprefix(var.tenx_retriever_query_log_group_name, "/"), "/", "-")
  )

  # Observability is wireable when a log group is configured AND the user
  # has not opted out. Used as the count guard on every metric filter.
  observability_enabled = var.tenx_retriever_query_log_group_name != "" && var.tenx_retriever_enable_observability_metrics
}

# Data sources used to construct the log group ARN when the consumer brings
# their own log group (i.e. tenx_retriever_create_query_log_group = false).
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "tenx_index_queue" {
  name = var.tenx_retriever_index_queue_name

  visibility_timeout_seconds = var.tenx_retriever_queue_visibility_timeout
  message_retention_seconds  = var.tenx_retriever_queue_message_retention
  max_message_size           = var.tenx_retriever_queue_max_message_size
  delay_seconds              = var.tenx_retriever_queue_delay_seconds
  receive_wait_time_seconds  = var.tenx_retriever_queue_receive_wait_time

  tags = local.tags
}

resource "aws_sqs_queue" "tenx_query_queue" {
  name = var.tenx_retriever_query_queue_name

  visibility_timeout_seconds = var.tenx_retriever_queue_visibility_timeout
  message_retention_seconds  = var.tenx_retriever_queue_message_retention
  max_message_size           = var.tenx_retriever_queue_max_message_size
  delay_seconds              = var.tenx_retriever_queue_delay_seconds
  receive_wait_time_seconds  = var.tenx_retriever_queue_receive_wait_time

  tags = local.tags
}

resource "aws_sqs_queue" "tenx_subquery_queue" {
  name = var.tenx_retriever_subquery_queue_name

  visibility_timeout_seconds = var.tenx_retriever_queue_visibility_timeout
  message_retention_seconds  = var.tenx_retriever_queue_message_retention
  max_message_size           = var.tenx_retriever_queue_max_message_size
  delay_seconds              = var.tenx_retriever_queue_delay_seconds
  receive_wait_time_seconds  = var.tenx_retriever_queue_receive_wait_time

  tags = local.tags
}

resource "aws_sqs_queue" "tenx_stream_queue" {
  name = var.tenx_retriever_stream_queue_name

  visibility_timeout_seconds = var.tenx_retriever_queue_visibility_timeout
  message_retention_seconds  = var.tenx_retriever_queue_message_retention
  max_message_size           = var.tenx_retriever_queue_max_message_size
  delay_seconds              = var.tenx_retriever_queue_delay_seconds
  receive_wait_time_seconds  = var.tenx_retriever_queue_receive_wait_time

  tags = local.tags
}

# S3 Buckets for Indexing
resource "aws_s3_bucket" "index_source" {
  count  = var.tenx_retriever_create_index_source_bucket ? 1 : 0
  bucket = var.tenx_retriever_index_source_bucket_name

  tags = local.tags
}

resource "aws_s3_bucket" "index_results" {
  count  = var.tenx_retriever_create_index_results_bucket && !local.buckets_are_same ? 1 : 0
  bucket = var.tenx_retriever_index_results_bucket_name

  tags = local.tags
}

# SQS Queue Policy to allow S3 to send messages
resource "aws_sqs_queue_policy" "index_queue_s3_policy" {
  queue_url = aws_sqs_queue.tenx_index_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.tenx_index_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::${var.tenx_retriever_index_source_bucket_name}"
          }
        }
      }
    ]
  })
}

# S3 Bucket Notification to send events directly to SQS
# Always created - the S3→SQS trigger is core to retriever operation
# regardless of whether we create the bucket or user brings their own
resource "aws_s3_bucket_notification" "index_trigger" {
  bucket = var.tenx_retriever_index_source_bucket_name

  queue {
    queue_arn     = aws_sqs_queue.tenx_index_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.tenx_retriever_index_trigger_prefix
    filter_suffix = var.tenx_retriever_index_trigger_suffix
  }

  depends_on = [aws_sqs_queue_policy.index_queue_s3_policy]
}

# CloudWatch Logs for Query Event Logging
# Only created when a log group name is provided
resource "aws_cloudwatch_log_group" "query_log_group" {
  count             = var.tenx_retriever_query_log_group_name != "" && var.tenx_retriever_create_query_log_group ? 1 : 0
  name              = var.tenx_retriever_query_log_group_name
  retention_in_days = var.tenx_retriever_query_log_group_retention

  tags = local.tags
}
