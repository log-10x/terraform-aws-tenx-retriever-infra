# SQS Queue URLs - used by application configuration
output "index_queue_url" {
  description = "The URL of the index SQS queue (for tenx.quarkus.index.queue.url)"
  value       = aws_sqs_queue.tenx_index_queue.url
}

output "query_queue_url" {
  description = "The URL of the query SQS queue (for tenx.quarkus.query.queue.url)"
  value       = aws_sqs_queue.tenx_query_queue.url
}

output "subquery_queue_url" {
  description = "The URL of the sub-query SQS queue (for tenx.quarkus.subquery.queue.url)"
  value       = aws_sqs_queue.tenx_subquery_queue.url
}

output "stream_queue_url" {
  description = "The URL of the stream SQS queue (for tenx.quarkus.stream.queue.url)"
  value       = aws_sqs_queue.tenx_stream_queue.url
}

# S3 Bucket Names - used for application configuration and reference
output "index_source_bucket_name" {
  description = "The name of the S3 bucket for source files to be indexed"
  value       = var.tenx_retriever_index_source_bucket_name
}

output "index_results_bucket_name" {
  description = "The name of the S3 bucket for indexing results"
  value       = var.tenx_retriever_index_results_bucket_name
}

output "index_write_container" {
  description = "The full path for indexing results (bucket + path) - used for tenx.quarkus.index.write.container"
  value       = local.index_write_container
}

# CloudWatch Logs - used for query event logging
output "query_log_group_name" {
  description = "The name of the CloudWatch Logs log group for query event logging (empty if disabled)"
  value       = var.tenx_retriever_query_log_group_name
}

output "query_log_group_arn" {
  description = "The ARN of the CloudWatch Logs log group for query event logging (empty if disabled)"
  value       = length(aws_cloudwatch_log_group.query_log_group) > 0 ? aws_cloudwatch_log_group.query_log_group[0].arn : ""
}
