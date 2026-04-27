# Existing Buckets Example

This example demonstrates how to use the module with existing S3 buckets instead of creating new ones.

## Use Case

This configuration is ideal when you:
- Already have S3 buckets for logs and results
- Want to add 10x indexing to existing infrastructure
- Need to integrate with existing data pipelines

## What This Creates

- Three SQS queues (newly created)
- S3 event notification on existing source bucket (configured)
- IAM permissions for S3 to send messages to SQS (configured)

**Note**: S3 buckets are NOT created - the module uses your existing buckets.

## Prerequisites

Before running this example, ensure:

1. The S3 buckets already exist:
   - `my-existing-logs-bucket`
   - `my-existing-results-bucket`

2. You have permissions to:
   - Configure S3 bucket notifications
   - Create IAM policies for S3 to SQS messaging

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## How It Works

The module will:
1. Create the three SQS queues
2. Configure S3 event notifications on `my-existing-logs-bucket`
3. Set up IAM permissions for S3 → SQS messaging
4. NOT create or modify the bucket itself (only adds notifications)

## Important Notes

- The module adds S3 event notifications but does NOT modify bucket policies or other bucket settings
- Indexing results will be written to `s3://my-existing-results-bucket/tenx-indexing/`
- Files matching `data/*.log` will trigger indexing

## Testing

Upload a file to test:

```bash
aws s3 cp test.log s3://my-existing-logs-bucket/data/test.log
```

The IndexSqsConsumer will receive the notification and process the file.
