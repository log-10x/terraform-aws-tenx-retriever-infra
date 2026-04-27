# Production Example

This example demonstrates a production-ready deployment with custom configuration suitable for a production environment.

## What This Creates

- Three SQS queues with production naming:
  - `prod-tenx-index-queue`
  - `prod-tenx-query-queue`
  - `prod-tenx-pipeline-queue`
- Two separate S3 buckets:
  - `prod-logs-bucket` (source files)
  - `prod-index-results-bucket` (indexing results)
- Extended message retention (14 days)
- Custom indexing triggers (`.json` files in `logs/` directory)
- Production tagging for resource management

## Key Differences from Basic Example

1. **Separate Buckets**: Source files and results are kept in separate buckets for better organization
2. **Extended Retention**: Messages retained for 14 days instead of 4
3. **Custom Triggers**: Only indexes `.json` files instead of `.log` files
4. **Production Tags**: Comprehensive tagging for cost tracking and management

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Configuring Your Quarkus Application

```bash
# Export all queue URLs
export TENX_QUARKUS_INDEX_QUEUE_URL=$(terraform output -raw queue_urls | jq -r '.index')
export TENX_QUARKUS_QUERY_QUEUE_URL=$(terraform output -raw queue_urls | jq -r '.query')
export TENX_QUARKUS_PIPELINE_QUEUE_URL=$(terraform output -raw queue_urls | jq -r '.pipeline')
export TENX_QUARKUS_INDEX_WRITE_CONTAINER=$(terraform output -raw index_write_container)
```

## Testing S3 Indexing

Upload a JSON file to trigger automatic indexing:

```bash
aws s3 cp data.json s3://prod-logs-bucket/logs/data.json
```

The IndexSqsConsumer will automatically receive the S3 event notification and index the file.
Results will be written to `s3://prod-index-results-bucket/indexed/`.
