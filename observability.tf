# CloudWatch metric filters that translate the retriever's standard log output
# into queryable CloudWatch metrics. Patterns parse log lines the engine
# already emits — no engine changes required to use these.
#
# Three groups of metrics are produced:
#
#   - Crash detection: StackOverflowError occurrences.
#   - Per-stage progress + failures: counters for each pipeline stage (scan,
#     stream worker, results writer) plus the failure modes (workers skipped
#     due to processing-time limits, pipeline launch errors).
#   - Bloom filter efficiency: scanned vs matched object counts, used to
#     derive the bloom false-positive ratio via metric math on the consumer
#     side.
#
# Alarms and dashboards are intentionally NOT created here — they're
# environment-specific (alarm thresholds, SNS action ARNs, Grafana
# workspace, etc.). Consumers reference the canonical metric names via the
# `observability_metric_names` output and build their own alarms/dashboards
# on top.
#
# Toggle the entire block with `tenx_retriever_enable_observability_metrics`
# (default true). Filter resource names default to a sanitized form of the
# log group name; override via `tenx_retriever_metric_filter_name_prefix` to
# preserve existing names across module upgrades.

# ==============================================================================
# Crash detection
# ==============================================================================

# Any StackOverflowError indicates a recursion bug; consumers typically alarm
# on >0 in a 1-minute window.
resource "aws_cloudwatch_log_metric_filter" "stack_overflow" {
  count          = local.observability_enabled ? 1 : 0
  name           = "${local.metric_filter_name_prefix}-stack-overflow"
  log_group_name = var.tenx_retriever_query_log_group_name
  pattern        = "\"StackOverflowError\""

  metric_transformation {
    name          = "StackOverflowCount"
    namespace     = var.tenx_retriever_metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# ==============================================================================
# Per-stage pipeline progress + failures
# ==============================================================================
# Pipeline shape: scan → stream-worker → results writer. Each stage emits a
# "<stage> complete:" log line; counters surface throughput and "skipped" /
# "could not launch pipeline" surface failure modes.

# "scan complete: scanned=N, matched=M, skippedDuplicate=D, …"
resource "aws_cloudwatch_log_metric_filter" "scan_complete" {
  count          = local.observability_enabled ? 1 : 0
  name           = "${local.metric_filter_name_prefix}-scan-complete"
  log_group_name = var.tenx_retriever_query_log_group_name
  pattern        = "\"scan complete:\""

  metric_transformation {
    name          = "ScanCompleteCount"
    namespace     = var.tenx_retriever_metric_namespace
    value         = "1"
    default_value = "0"
  }
}

# "stream worker complete: fetched N bytes"
resource "aws_cloudwatch_log_metric_filter" "stream_worker_complete" {
  count          = local.observability_enabled ? 1 : 0
  name           = "${local.metric_filter_name_prefix}-stream-worker-complete"
  log_group_name = var.tenx_retriever_query_log_group_name
  pattern        = "\"stream worker complete:\""

  metric_transformation {
    name          = "StreamWorkerCompleteCount"
    namespace     = var.tenx_retriever_metric_namespace
    value         = "1"
    default_value = "0"
  }
}

# "stream worker skipped: processing time limit exceeded (…)"
# A non-zero rate indicates queries are exceeding the configured
# `processingTimeLimit`. Consumers typically alarm on a sustained surge
# (e.g., >5 in 5m).
resource "aws_cloudwatch_log_metric_filter" "stream_worker_skipped" {
  count          = local.observability_enabled ? 1 : 0
  name           = "${local.metric_filter_name_prefix}-stream-worker-skipped"
  log_group_name = var.tenx_retriever_query_log_group_name
  pattern        = "\"stream worker skipped:\""

  metric_transformation {
    name          = "StreamWorkerSkippedCount"
    namespace     = var.tenx_retriever_metric_namespace
    value         = "1"
    default_value = "0"
  }
}

# "results writer complete: N events written, D dropped, … N bytes"
resource "aws_cloudwatch_log_metric_filter" "results_writer_complete" {
  count          = local.observability_enabled ? 1 : 0
  name           = "${local.metric_filter_name_prefix}-results-writer-complete"
  log_group_name = var.tenx_retriever_query_log_group_name
  pattern        = "\"results writer complete:\""

  metric_transformation {
    name          = "ResultsWriterCompleteCount"
    namespace     = var.tenx_retriever_metric_namespace
    value         = "1"
    default_value = "0"
  }
}

# "could not launch pipeline" — pipeline configuration or override mismatch.
# Consumers typically alarm on >0 in 5m.
resource "aws_cloudwatch_log_metric_filter" "launch_failed" {
  count          = local.observability_enabled ? 1 : 0
  name           = "${local.metric_filter_name_prefix}-launch-failed"
  log_group_name = var.tenx_retriever_query_log_group_name
  pattern        = "\"could not launch pipeline\""

  metric_transformation {
    name          = "LaunchFailedCount"
    namespace     = var.tenx_retriever_metric_namespace
    value         = "1"
    default_value = "0"
  }
}

# ==============================================================================
# Bloom filter efficiency (matched / scanned)
# ==============================================================================
# CloudWatch metric filters can't divide — SCANNED and MATCHED counts are
# emitted as separate metrics, and the consumer's dashboard/alarm computes
# the ratio via metric math (e.g. `(m_matched / m_scanned) * 100`).
# Patterns extract numeric fields from the structured JSON payload the
# engine emits alongside the plain-text "scan complete:" line.

resource "aws_cloudwatch_log_metric_filter" "bloom_blobs_scanned" {
  count          = local.observability_enabled ? 1 : 0
  name           = "${local.metric_filter_name_prefix}-bloom-blobs-scanned"
  log_group_name = var.tenx_retriever_query_log_group_name
  pattern        = "{ $.message = \"scan complete*\" && $.fields.scanned = * }"

  metric_transformation {
    name          = "BloomBlobsScanned"
    namespace     = var.tenx_retriever_metric_namespace
    value         = "$.fields.scanned"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "bloom_blobs_matched" {
  count          = local.observability_enabled ? 1 : 0
  name           = "${local.metric_filter_name_prefix}-bloom-blobs-matched"
  log_group_name = var.tenx_retriever_query_log_group_name
  pattern        = "{ $.message = \"scan complete*\" && $.fields.matched = * }"

  metric_transformation {
    name          = "BloomBlobsMatched"
    namespace     = var.tenx_retriever_metric_namespace
    value         = "$.fields.matched"
    default_value = "0"
  }
}
