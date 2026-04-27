# Basic Example - Minimal Configuration
# This example shows the simplest way to use the tenx-retriever-infra module
# with default settings for all three queues and S3 indexing.

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

module "tenx_retriever_infra" {
  source  = "log-10x/tenx-retriever-infra/aws"
  version = "~> 0.1"

  # Use default queue names (my-index-queue, my-query-queue, my-subquery-queue, my-stream-queue)
  # Use default S3 bucket configuration (creates my-tenx-index-bucket)

  # CloudWatch Logs for query event logging
  tenx_retriever_query_log_group_name      = "/tenx/my-retriever/query"
  tenx_retriever_query_log_group_retention = 1

  tenx_retriever_user_supplied_tags = {
    Environment = "development"
    Project     = "10x-retriever"
  }
}

# Outputs for Quarkus application configuration
output "index_queue_url" {
  description = "Use this for TENX_QUARKUS_INDEX_QUEUE_URL"
  value       = module.tenx_retriever_infra.index_queue_url
}

output "query_queue_url" {
  description = "Use this for TENX_QUARKUS_QUERY_QUEUE_URL"
  value       = module.tenx_retriever_infra.query_queue_url
}

output "subquery_queue_url" {
  description = "Use this for TENX_QUARKUS_SUBQUERY_QUEUE_URL"
  value       = module.tenx_retriever_infra.subquery_queue_url
}

output "stream_queue_url" {
  description = "Use this for TENX_QUARKUS_STREAM_QUEUE_URL"
  value       = module.tenx_retriever_infra.stream_queue_url
}

output "index_write_container" {
  description = "Use this for TENX_QUARKUS_INDEX_WRITE_CONTAINER"
  value       = module.tenx_retriever_infra.index_write_container
}
