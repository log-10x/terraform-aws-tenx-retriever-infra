# CloudWatch metric filters that translate the retriever JVM's standard log
# output into queryable CloudWatch metrics. All patterns parse log lines the
# engine ALREADY emits — no engine changes required.
#
# Three observability themes covered:
#   - O14: crash detection (StackOverflowError)
#   - O11: per-stage pipeline progress + failure modes (scan/worker/results/
#          launch_failed)
#   - O12: bloom filter false-positive rate (matched/scanned ratio)
#
# Alarms + dashboards are intentionally NOT in this module — they're env-
# specific (alarm thresholds, SNS action ARNs, Grafana workspace, etc.).
# Consumers reference the metric names via the `observability_metric_names`
# output and build their own alarms/dashboards on top.
#
# Toggle with `tenx_retriever_enable_observability_metrics` (default true).
# Filter names default to a sanitized form of the log group name; override
# via `tenx_retriever_metric_filter_name_prefix` to maintain naming continuity.

# ==============================================================================
# O14 — Crash detection
# ==============================================================================
# Any single StackOverflowError is a ten-alarm fire (recursion bug surface
# in string handling). Consumers should alarm on >0 in 1m.

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
# O11 — Per-stage pipeline progress + failures
# ==============================================================================
# scan → stream-worker → results writer. Each stage emits a "<stage>
# complete:" log line. Counters surface throughput; "skipped" + "could not
# launch pipeline" surface failure modes.

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
# Sustained non-zero rate = deadline starvation regression OR scan phase
# eating more budget than `processingTimeLimit` allows. Consumers should
# alarm on a sustained surge (e.g., >5 in 5m).
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

# "could not launch pipeline" — required-overrides mismatch or config error
# (e.g., queryFilters list/override plumbing, case-folding of
# groupFlushTimeout). Consumers should alarm on >0 in 5m.
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
# O12 — Bloom false-positive rate (matched / scanned ratio)
# ==============================================================================
# CloudWatch can't divide in metric filters — emit SCANNED and MATCHED as
# separate metrics; consumer dashboards/alarms compute the ratio via metric
# math (e.g. `(m_matched / m_scanned) * 100`). Pulls numeric fields from the
# structured JSON payload the engine emits alongside the plain "scan
# complete:" line — see indexAccessor.logQueryEvent in IndexQueryWriter.java.

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
