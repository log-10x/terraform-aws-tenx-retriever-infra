# 10x AWS Retriever Terraform Module

This Terraform module simplifies the deployment of AWS resources for the 10x retriever infrastructure. It deploys four SQS queues that mirror the queues consumed by the run-quarkus server: index, query, sub-query, and stream queues.

## Features

- Deploys four AWS SQS queues for the 10x retriever (index, query, sub-query, and stream).
- Configurable queue settings including visibility timeout, message retention, and message size limits.
- Long polling enabled by default (20 seconds) to match run-quarkus SqsConsumer configuration.
- **Automatic S3-triggered indexing**: Creates S3 buckets and sends S3 event notifications directly to SQS when files are uploaded.
- **CloudWatch Logs**: Optionally creates a CloudWatch Logs log group for query event logging (progress, diagnostics, errors).
- Supports user-defined tags for resource management.

## Prerequisites

- **Terraform**: Version >= 1.0
- **AWS Provider**: Version 6.3.0
- **AWS Credentials**: Configured with appropriate permissions to create SQS queues and S3 buckets.

## Usage

This module is published on Terraform Cloud and can be used directly in your Terraform configuration:

```hcl
module "tenx-retriever-infra" {
  source  = "log-10x/tenx-retriever-infra/aws"
  version = "0.9.0"

  tenx_retriever_index_queue_name    = "my-index-queue"
  tenx_retriever_query_queue_name    = "my-query-queue"
  tenx_retriever_subquery_queue_name = "my-subquery-queue"
  tenx_retriever_stream_queue_name   = "my-stream-queue"
}
```

## Providers

This module requires the AWS provider, configured as follows:

```hcl
provider "aws" {
  region = "us-west-2"  # or your preferred region
}
```

## Inputs

The following input variables are supported:

| Name                                | Description                                                              | Type          | Default             | Required |
|-------------------------------------|--------------------------------------------------------------------------|---------------|---------------------|----------|
| `tenx_retriever_user_supplied_tags`  | Tags to apply to all generated resources                                | `map(string)` | `{}`                | No       |
| `tenx_retriever_index_queue_name`    | Name of the index SQS queue                                             | `string`      | `my-index-queue`    | No       |
| `tenx_retriever_query_queue_name`    | Name of the query SQS queue                                             | `string`      | `my-query-queue`    | No       |
| `tenx_retriever_subquery_queue_name` | Name of the sub-query SQS queue                                         | `string`      | `my-subquery-queue` | No       |
| `tenx_retriever_stream_queue_name`   | Name of the stream SQS queue                                            | `string`      | `my-stream-queue`   | No       |
| `tenx_retriever_visibility_timeout`  | Visibility timeout for all queues in seconds                            | `number`      | `30`                | No       |
| `tenx_retriever_message_retention`   | Number of seconds Amazon SQS retains a message for all queues           | `number`      | `345600` (4 days)   | No       |
| `tenx_retriever_max_message_size`    | Maximum bytes a message can contain before rejection for all queues     | `number`      | `262144` (256 KB)   | No       |
| `tenx_retriever_queue_delay_seconds`       | Time in seconds that delivery of all messages will be delayed           | `number`      | `0`                 | No       |
| `tenx_retriever_queue_receive_wait_time`   | Time for which a ReceiveMessage call will wait (long polling) in seconds | `number`     | `20`                | No       |
| `tenx_retriever_create_index_source_bucket` | Whether to create the S3 bucket for source files to be indexed | `bool` | `true` | No |
| `tenx_retriever_index_source_bucket_name` | Name of the S3 bucket for source files to be indexed | `string` | `my-tenx-index-bucket` | No |
| `tenx_retriever_create_index_results_bucket` | Whether to create the S3 bucket for indexing results | `bool` | `true` | No |
| `tenx_retriever_index_results_bucket_name` | Name of the S3 bucket for indexing results | `string` | `my-tenx-index-bucket` | No |
| `tenx_retriever_index_results_path` | Path within results bucket where indexing results will be stored | `string` | `indexing-results/` | No |
| `tenx_retriever_index_trigger_prefix` | S3 object key prefix filter for triggering indexing | `string` | `app/` | No |
| `tenx_retriever_index_trigger_suffix` | S3 object key suffix filter for triggering indexing | `string` | `.log` | No |
| `tenx_retriever_query_log_group_name` | Name of the CloudWatch Logs log group for query event logging. If empty, no log group is created. | `string` | `""` | No |
| `tenx_retriever_query_log_group_retention` | Number of days to retain query event logs in CloudWatch Logs | `number` | `7` | No |

## Outputs

The module provides the following outputs for application configuration:

| Name                        | Description                                                      | Used For |
|-----------------------------|------------------------------------------------------------------|----------|
| `index_queue_url`           | Full URL of the index SQS queue                                  | `TENX_QUARKUS_INDEX_QUEUE_URL` |
| `query_queue_url`           | Full URL of the query SQS queue                                  | `TENX_QUARKUS_QUERY_QUEUE_URL` |
| `subquery_queue_url`        | Full URL of the sub-query SQS queue                              | `TENX_QUARKUS_SUBQUERY_QUEUE_URL` |
| `stream_queue_url`          | Full URL of the stream SQS queue                                 | `TENX_QUARKUS_STREAM_QUEUE_URL` |
| `index_source_bucket_name`  | Name of the S3 bucket for source files to be indexed            | Reference/Documentation |
| `index_results_bucket_name` | Name of the S3 bucket for indexing results                       | Reference/Documentation |
| `index_write_container`     | Full path for indexing results (bucket + path)                   | `tenx.quarkus.index.write.container` |
| `query_log_group_name`      | Name of the CloudWatch Logs log group for query events (empty if disabled) | `TENX_QUERY_LOG_GROUP` |
| `query_log_group_arn`       | ARN of the CloudWatch Logs log group for query events (empty if disabled) | IAM policy configuration |

## Example Configuration

Below is an example of how to use this module with custom settings:

```hcl
module "tenx-retriever-infra" {
  source  = "log-10x/tenx-retriever-infra/aws"
  version = "0.9.0"

  # Queue Configuration
  tenx_retriever_index_queue_name    = "my-custom-index-queue"
  tenx_retriever_query_queue_name    = "my-custom-query-queue"
  tenx_retriever_subquery_queue_name = "my-custom-subquery-queue"
  tenx_retriever_stream_queue_name   = "my-custom-stream-queue"

  tenx_retriever_queue_visibility_timeout = 60
  tenx_retriever_queue_message_retention  = 604800  # 7 days
  tenx_retriever_queue_receive_wait_time  = 20      # Long polling (default)

  # S3 Indexing Configuration
  tenx_retriever_index_source_bucket_name   = "my-logs-bucket"
  tenx_retriever_index_results_bucket_name  = "my-index-results-bucket"
  tenx_retriever_index_results_path         = "processed/"
  tenx_retriever_index_trigger_prefix       = "logs/"
  tenx_retriever_index_trigger_suffix       = ".log"

  # CloudWatch Logs for query event logging (optional)
  tenx_retriever_query_log_group_name      = "/tenx/prod/retriever/query"
  tenx_retriever_query_log_group_retention = 30

  tenx_retriever_user_supplied_tags = {
    Environment = "Production"
    Project     = "DataStreaming"
  }
}
```

## Module Details

- **SQS Queues**: Creates four standard SQS queues that mirror the queues consumed by run-quarkus:
  - **Index Queue**: Processes index/indexing requests via `IndexSqsConsumer`
  - **Query Queue**: Processes query requests via `QuerySqsConsumer`
  - **Sub-Query Queue**: Processes sub-query (scan) requests dispatched by query coordinators
  - **Stream Queue**: Processes stream requests that fetch and transform matching events
- **S3 Automatic Indexing**: When files matching the configured prefix/suffix are uploaded to the source bucket:
  1. S3 sends an event notification directly to the index SQS queue
  2. `IndexSqsConsumer` in run-quarkus receives the S3 event notification
  3. The consumer parses the S3 event and converts it to an `IndexRequest`
  4. Indexing proceeds with the extracted bucket/object information
- **Direct S3 → SQS Integration**: No Lambda required - S3 sends events directly to SQS with proper IAM permissions
- **CloudWatch Logs**: Optionally creates a CloudWatch Logs log group for query event logging. When configured, query coordinators and stream workers write progress, diagnostic, and error events to this log group. Each query creates log streams named `{queryID}/{workerID}`.
- **Bucket Management**: Optionally creates S3 buckets for source files and indexing results, or uses existing buckets
- **Tags**: User-supplied tags are merged with default tags (`terraform-module`, `terraform-module-version`, `managed-by`) for resource identification.
- **Configurable Parameters**: Supports customization of queue behavior including visibility timeout, message retention, and long polling settings.
- **Long Polling**: Defaults to 20 seconds to match the run-quarkus SqsConsumer configuration for efficient message retrieval.

## Notes

- Queue names default to match the LocalStack development setup: `my-index-queue`, `my-query-queue`, `my-subquery-queue`, `my-stream-queue`.
- All four queues share the same configuration parameters (visibility timeout, retention, etc.) by design.
- The queue URLs should be configured in the run-quarkus application using environment variables:
  - `TENX_QUARKUS_INDEX_QUEUE_URL`
  - `TENX_QUARKUS_QUERY_QUEUE_URL`
  - `TENX_QUARKUS_SUBQUERY_QUEUE_URL`
  - `TENX_QUARKUS_STREAM_QUEUE_URL`

### S3 Indexing Workflow

When a file is uploaded to the source bucket (e.g., `s3://my-tenx-index-bucket/app/myfile.log`):

1. S3 sends an event notification directly to the index SQS queue
2. The S3 event notification contains:
   ```json
   {
     "Records": [{
       "eventName": "ObjectCreated:Put",
       "s3": {
         "bucket": {"name": "my-tenx-index-bucket"},
         "object": {"key": "app/myfile.log"}
       }
     }]
   }
   ```
3. `IndexSqsConsumer` in run-quarkus receives the S3 event
4. The consumer parses the event and creates an `IndexRequest`:
   - `indexObjectStorageName`: "AWS" (hardcoded)
   - `indexReadContainer`: Extracted from S3 event bucket name
   - `indexReadObject`: Extracted from S3 event object key
   - `indexWriteContainer`: From config property `tenx.quarkus.index.write.container`, or defaults to `{source-bucket}/tenx-index`
5. Indexing proceeds and results are written to the configured write container path

**Quarkus Configuration:**
Set the `tenx.quarkus.index.write.container` property to specify where indexing results should be written. If not set, results will be written to `{source-bucket}/tenx-index`.

### Bucket Configuration Options

- **Same bucket for source and results**: Set both bucket names to the same value (default behavior)
- **Separate buckets**: Provide different names for source and results buckets
- **Use existing buckets**: Set `tenx_retriever_create_index_source_bucket` or `tenx_retriever_create_index_results_bucket` to `false`

- For additional details, refer to the module's page on the [Terraform Cloud Registry](https://registry.terraform.io/).

## License

This repository is licensed under the [Apache License 2.0](LICENSE).

### Important: Log10x Product License Required

This repository contains infrastructure tooling for Log10x Retriever. While the Terraform module
itself is open source, **using Log10x requires a commercial license**.

| Component | License |
|-----------|---------|
| This repository (Terraform module) | Apache 2.0 (open source) |
| Log10x engine and runtime | Commercial license required |

**What this means:**
- You can freely use, modify, and distribute this Terraform module
- The Log10x software that consumes this infrastructure requires a paid subscription
- A valid Log10x API key is required to run the deployed software

**Get Started:**
- [Log10x Pricing](https://log10x.com/pricing)
- [Documentation](https://doc.log10x.com)
- [Contact Sales](mailto:sales@log10x.com)
