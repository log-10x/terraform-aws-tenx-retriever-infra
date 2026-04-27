# Production Example - Custom Configuration
# This example shows a production-ready configuration with:
# - Custom queue names
# - Separate buckets for source and results
# - Extended message retention
# - Production tags

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
  region = "us-east-1"
}

module "tenx_retriever_infra" {
  source  = "log-10x/tenx-retriever-infra/aws"
  version = "~> 0.1"

  # Custom queue names
  tenx_retriever_index_queue_name    = "prod-tenx-index-queue"
  tenx_retriever_query_queue_name    = "prod-tenx-query-queue"
  tenx_retriever_subquery_queue_name = "prod-tenx-subquery-queue"
  tenx_retriever_stream_queue_name   = "prod-tenx-stream-queue"

  # Queue configuration for production
  tenx_retriever_queue_visibility_timeout = 60      # 1 minute
  tenx_retriever_queue_message_retention  = 1209600 # 14 days
  tenx_retriever_queue_receive_wait_time  = 20      # Long polling

  # S3 configuration - separate buckets for source and results
  tenx_retriever_index_source_bucket_name  = "prod-logs-bucket"
  tenx_retriever_index_results_bucket_name = "prod-index-results-bucket"
  tenx_retriever_index_results_path        = "indexed/"

  # Trigger indexing only for JSON logs in the logs/ directory
  tenx_retriever_index_trigger_prefix = "logs/"
  tenx_retriever_index_trigger_suffix = ".json"

  # CloudWatch Logs for query event logging
  tenx_retriever_query_log_group_name      = "/tenx/prod/retriever/query"
  tenx_retriever_query_log_group_retention = 14

  # Production tags
  tenx_retriever_user_supplied_tags = {
    Environment = "production"
    Project     = "10x-retriever"
    ManagedBy   = "terraform"
    Team        = "data-engineering"
    CostCenter  = "engineering"
  }
}

# Outputs for application configuration
output "queue_urls" {
  description = "All queue URLs for Quarkus configuration"
  value = {
    index    = module.tenx_retriever_infra.index_queue_url
    query    = module.tenx_retriever_infra.query_queue_url
    subquery = module.tenx_retriever_infra.subquery_queue_url
    stream   = module.tenx_retriever_infra.stream_queue_url
  }
}

output "index_write_container" {
  description = "Index write container for Quarkus configuration"
  value       = module.tenx_retriever_infra.index_write_container
}

output "bucket_names" {
  description = "S3 bucket names"
  value = {
    source  = module.tenx_retriever_infra.index_source_bucket_name
    results = module.tenx_retriever_infra.index_results_bucket_name
  }
}

output "query_log_group" {
  description = "CloudWatch Logs log group for query events"
  value = {
    name = module.tenx_retriever_infra.query_log_group_name
    arn  = module.tenx_retriever_infra.query_log_group_arn
  }
}
