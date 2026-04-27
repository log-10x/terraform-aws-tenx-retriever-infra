# Basic Example

This example demonstrates the simplest way to deploy the 10x retriever infrastructure with default settings.

## What This Creates

- Three SQS queues with default names:
  - `my-index-queue` (for IndexSqsConsumer)
  - `my-query-queue` (for QuerySqsConsumer)
  - `my-pipeline-queue` (for PipelineSqsConsumer)
- One S3 bucket for both source files and indexing results: `my-tenx-index-bucket`
- S3 event notification that triggers indexing on `.log` files in the `app/` prefix

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Configuring Your Quarkus Application

After applying, use the output values to configure your run-quarkus application:

```bash
export TENX_QUARKUS_INDEX_QUEUE_URL=$(terraform output -raw index_queue_url)
export TENX_QUARKUS_QUERY_QUEUE_URL=$(terraform output -raw query_queue_url)
export TENX_QUARKUS_PIPELINE_QUEUE_URL=$(terraform output -raw pipeline_queue_url)
export TENX_QUARKUS_INDEX_WRITE_CONTAINER=$(terraform output -raw index_write_container)
```

## Testing S3 Indexing

Upload a log file to trigger automatic indexing:

```bash
aws s3 cp myfile.log s3://my-tenx-index-bucket/app/myfile.log
```

The IndexSqsConsumer will automatically receive an S3 event notification and process the file.
