# Existing Buckets Example
# This example shows how to use the module with existing S3 buckets
# instead of creating new ones.

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Reference existing S3 buckets
data "aws_s3_bucket" "existing_source" {
  bucket = "my-existing-logs-bucket"
}

data "aws_s3_bucket" "existing_results" {
  bucket = "my-existing-results-bucket"
}

module "tenx_retriever_infra" {
  source  = "log-10x/tenx-retriever-infra/aws"
  version = "~> 0.1"

  # Queue configuration
  tenx_retriever_index_queue_name    = "my-index-queue"
  tenx_retriever_query_queue_name    = "my-query-queue"
  tenx_retriever_subquery_queue_name = "my-subquery-queue"
  tenx_retriever_stream_queue_name   = "my-stream-queue"

  # Use existing S3 buckets - do NOT create new ones
  tenx_retriever_create_index_source_bucket  = false
  tenx_retriever_create_index_results_bucket = false

  tenx_retriever_index_source_bucket_name  = data.aws_s3_bucket.existing_source.id
  tenx_retriever_index_results_bucket_name = data.aws_s3_bucket.existing_results.id
  tenx_retriever_index_results_path        = "tenx-indexing/"

  # Custom trigger configuration
  tenx_retriever_index_trigger_prefix = "data/"
  tenx_retriever_index_trigger_suffix = ".log"

  # CloudWatch Logs for query event logging
  tenx_retriever_query_log_group_name      = "/tenx/my-retriever/query"
  tenx_retriever_query_log_group_retention = 1

  tenx_retriever_user_supplied_tags = {
    Environment = "staging"
    Project     = "10x-retriever"
  }
}

# Outputs
output "index_queue_url" {
  description = "Index queue URL"
  value       = module.tenx_retriever_infra.index_queue_url
}

output "query_queue_url" {
  description = "Query queue URL"
  value       = module.tenx_retriever_infra.query_queue_url
}

output "subquery_queue_url" {
  description = "Sub-query queue URL"
  value       = module.tenx_retriever_infra.subquery_queue_url
}

output "stream_queue_url" {
  description = "Stream queue URL"
  value       = module.tenx_retriever_infra.stream_queue_url
}

output "index_write_container" {
  description = "Index write container"
  value       = module.tenx_retriever_infra.index_write_container
}
