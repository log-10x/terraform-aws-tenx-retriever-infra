variable "tenx_retriever_user_supplied_tags" {
  description = "Tags supplied by the user to populate to all generated resources"
  type        = map(string)
  default     = {}
}

variable "tenx_retriever_index_queue_name" {
  description = "Set the name of the index SQS queue, defaults to 'my-index-queue'"
  type        = string
  default     = "my-index-queue"
}

variable "tenx_retriever_query_queue_name" {
  description = "Set the name of the query SQS queue, defaults to 'my-query-queue'"
  type        = string
  default     = "my-query-queue"
}

variable "tenx_retriever_subquery_queue_name" {
  description = "Set the name of the sub-query SQS queue, defaults to 'my-subquery-queue'"
  type        = string
  default     = "my-subquery-queue"
}

variable "tenx_retriever_stream_queue_name" {
  description = "Set the name of the stream SQS queue, defaults to 'my-stream-queue'"
  type        = string
  default     = "my-stream-queue"
}

variable "tenx_retriever_queue_visibility_timeout" {
  description = "The visibility timeout for all queues in seconds, defaults to 30"
  type        = number
  default     = 30
}

variable "tenx_retriever_queue_message_retention" {
  description = "The number of seconds Amazon SQS retains a message for all queues, defaults to 345600 (4 days)"
  type        = number
  default     = 345600
}

variable "tenx_retriever_queue_max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it for all queues, defaults to 262144 (256 KB)"
  type        = number
  default     = 262144
}

variable "tenx_retriever_queue_delay_seconds" {
  description = "The time in seconds that the delivery of all messages in all queues will be delayed, defaults to 0"
  type        = number
  default     = 0
}

variable "tenx_retriever_queue_receive_wait_time" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (long polling) in seconds for all queues, defaults to 20"
  type        = number
  default     = 20
}

# S3 Indexing Configuration
variable "tenx_retriever_create_index_source_bucket" {
  description = "Whether to create the S3 bucket for source files to be indexed, defaults to true"
  type        = bool
  default     = true
}

variable "tenx_retriever_index_source_bucket_name" {
  description = "Name of the S3 bucket for source files to be indexed, defaults to 'my-tenx-index-bucket'"
  type        = string
  default     = "my-tenx-index-bucket"
}

variable "tenx_retriever_create_index_results_bucket" {
  description = "Whether to create the S3 bucket for indexing results, defaults to true"
  type        = bool
  default     = true
}

variable "tenx_retriever_index_results_bucket_name" {
  description = "Name of the S3 bucket for indexing results, defaults to 'my-tenx-index-bucket'"
  type        = string
  default     = "my-tenx-index-bucket"
}

variable "tenx_retriever_index_results_path" {
  description = "Path within the results bucket where indexing results will be stored, defaults to 'indexing-results/'"
  type        = string
  default     = "indexing-results/"
}

variable "tenx_retriever_index_trigger_prefix" {
  description = "S3 object key prefix filter for triggering indexing (e.g., 'app/'), defaults to 'app/'"
  type        = string
  default     = "app/"
}

variable "tenx_retriever_index_trigger_suffix" {
  description = "S3 object key suffix filter for triggering indexing (e.g., '.log'), defaults to '.log'"
  type        = string
  default     = ".log"
}

# CloudWatch Logs Configuration
variable "tenx_retriever_query_log_group_name" {
  description = "Name of the CloudWatch Logs log group for query event logging. If empty, no log group is created and query event logging is disabled."
  type        = string
  default     = ""
}

variable "tenx_retriever_query_log_group_retention" {
  description = "Number of days to retain query event logs in CloudWatch Logs, defaults to 14"
  type        = number
  default     = 7
}
