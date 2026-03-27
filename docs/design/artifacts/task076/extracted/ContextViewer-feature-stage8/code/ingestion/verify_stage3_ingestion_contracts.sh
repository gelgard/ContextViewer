#!/usr/bin/env bash
# AI Task 014: Stage 3 ingestion contract smoke suite (JSON report to stdout).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECTOR="${SCRIPT_DIR}/github_contextjson_connector.sh"
SCANNER="${SCRIPT_DIR}/contextjson_file_scanner.sh"
PIPELINE="${SCRIPT_DIR}/import_contextjson_pipeline.sh"
REFRESH="${SCRIPT_DIR}/refresh_contextjson_ingestion.sh"
IMPORT_STATUS="${SCRIPT_DIR}/get_project_import_status.sh"

usage() {
  cat <<'USAGE'
verify_stage3_ingestion_contracts.sh — Stage 3 ingestion JSON contract smoke tests

Runs contract checks against ingestion scripts and prints exactly one JSON object:
  status        pass | fail (fail if any check fails)
  checks        array of { name, status, details }
  failed_checks integer count of failed checks
  generated_at  UTC ISO-8601

Required for full pass (GitHub + DB checks):
  GITHUB_OWNER, GITHUB_REPO
  PROJECT_ID   (bigint, existing projects.id)
  PostgreSQL: DATABASE_URL or PGHOST + PGDATABASE (+ PGUSER / PGPORT as needed)

Optional:
  GITHUB_BRANCH, GITHUB_TOKEN
  Same .env.local loading rules as other ingestion scripts where applicable.

This script performs real network and DB calls when prerequisites are set; it does
not start daemons or change architecture.

Usage:
  verify_stage3_ingestion_contracts.sh
  verify_stage3_ingestion_contracts.sh --help
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
if [[ -n "${1:-}" ]]; then
  echo "error: unknown argument: $1 (use --help)" >&2
  exit 2
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

for s in "$CONNECTOR" "$SCANNER" "$PIPELINE" "$REFRESH" "$IMPORT_STATUS"; do
  [[ -x "$s" ]] || {
    echo "error: not executable: $s" >&2
    exit 1
  }
done

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
checks='[]'

add_check() {
  local n="$1" s="$2" d="$3"
  checks="$(jq -n \
    --argjson c "$checks" \
    --arg n "$n" \
    --arg st "$s" \
    --arg det "$d" \
    '$c + [{name: $n, status: $st, details: $det}]')"
}

# --- connector output contract ---
connector_out=""
connector_rc=1
if [[ -z "${GITHUB_OWNER:-}" || -z "${GITHUB_REPO:-}" ]]; then
  add_check "connector output contract" "fail" "GITHUB_OWNER and GITHUB_REPO must be set for live connector validation"
else
  conn_err="$(mktemp)"
  set +e
  connector_out="$("$CONNECTOR" 2>"$conn_err")"
  connector_rc=$?
  set -e
  if [[ "$connector_rc" -ne 0 ]]; then
    err_body=""
    [[ -f "$conn_err" ]] && err_body="$(cat "$conn_err")"
    rm -f "$conn_err"
    add_check "connector output contract" "fail" "connector exited ${connector_rc}: ${err_body:-no stderr captured}"
  else
    rm -f "$conn_err"
    if ! echo "$connector_out" | jq -e '
        type == "array"
        and all(
          .[];
          type == "object"
          and (.name | type == "string")
          and (.path | type == "string")
          and (.size | type == "number")
          and (.sha | type == "string")
          and (.download_url == null or (.download_url | type == "string"))
        )
      ' >/dev/null 2>&1; then
      add_check "connector output contract" "fail" "stdout is not a JSON array of objects with name, path, size, sha, download_url"
    else
      n="$(echo "$connector_out" | jq 'length')"
      add_check "connector output contract" "pass" "GitHub listing parsed; ${n} json file(s) in contract shape"
    fi
  fi
fi

# --- scanner output contract ---
if [[ "$connector_rc" -ne 0 || -z "$connector_out" ]]; then
  add_check "scanner output contract" "fail" "skipped: connector did not return output (run with valid GITHUB_OWNER/GITHUB_REPO)"
else
  scan_err="$(mktemp)"
  set +e
  scanner_out="$(printf '%s\n' "$connector_out" | "$SCANNER" 2>"$scan_err")"
  scanner_rc=$?
  set -e
  if [[ "$scanner_rc" -ne 0 ]]; then
    se="$(cat "$scan_err" 2>/dev/null || true)"
    rm -f "$scan_err"
    add_check "scanner output contract" "fail" "scanner exited ${scanner_rc}: ${se:0:500}"
  elif ! echo "$scanner_out" | jq -e '
        type == "object"
        and (.valid_files | type == "array")
        and (.invalid_files | type == "array")
        and (.latest_valid_file == null or (.latest_valid_file | type == "object"))
        and (
          (.valid_files | length) == 0
          or all(
            .valid_files[];
            (.name | type == "string")
            and (.path == null or (.path | type == "string"))
            and (.sha | type == "string")
            and (.size | type == "number")
            and (.timestamp | type == "string")
          )
        )
      ' >/dev/null 2>&1; then
    rm -f "$scan_err"
    add_check "scanner output contract" "fail" "stdout does not match scanner contract (valid_files, invalid_files, latest_valid_file)"
  else
    rm -f "$scan_err"
    add_check "scanner output contract" "pass" "scanner output validates against expected schema (chained from connector)"
  fi
fi

db_ready=1
if [[ -z "${PROJECT_ID:-}" ]]; then
  db_ready=0
elif ! command -v psql >/dev/null 2>&1; then
  db_ready=0
else
  set +e
  if [[ -n "${DATABASE_URL:-}" ]]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -t -A -c "SELECT 1" >/dev/null 2>&1
  else
    psql -v ON_ERROR_STOP=1 -q -t -A -c "SELECT 1" >/dev/null 2>&1
  fi
  psql_rc=$?
  set -e
  [[ "$psql_rc" -eq 0 ]] || db_ready=0
fi

# --- pipeline summary contract ---
if [[ "$db_ready" -ne 1 || -z "${GITHUB_OWNER:-}" || -z "${GITHUB_REPO:-}" ]]; then
  add_check "pipeline summary contract" "fail" "needs PROJECT_ID, working psql, GITHUB_OWNER, GITHUB_REPO (see --help)"
else
  pl_err="$(mktemp)"
  set +e
  pipeline_out="$("$PIPELINE" 2>"$pl_err")"
  pipeline_rc=$?
  set -e
  pl_e="$(cat "$pl_err" 2>/dev/null || true)"
  rm -f "$pl_err"
  if ! echo "$pipeline_out" | jq -e . >/dev/null 2>&1; then
    add_check "pipeline summary contract" "fail" "pipeline exited ${pipeline_rc} or stdout is not JSON. stderr: ${pl_e:0:300} stdout: ${pipeline_out:0:200}"
  elif ! echo "$pipeline_out" | jq -e '
        type == "object"
        and (.status | type == "string" and IN("success", "partial", "failed"))
        and (.inserted | type == "number")
        and (.duplicate_by_filename | type == "number")
        and (.duplicate_by_hash | type == "number")
        and (.invalid_files | type == "number")
        and (.errors | type == "number")
      ' >/dev/null 2>&1; then
    add_check "pipeline summary contract" "fail" "pipeline JSON missing required keys or wrong types"
  else
    add_check "pipeline summary contract" "pass" "pipeline summary keys validated (status=$(echo "$pipeline_out" | jq -r .status))"
  fi
fi

# --- refresh wrapper contract ---
if [[ "$db_ready" -ne 1 || -z "${GITHUB_OWNER:-}" || -z "${GITHUB_REPO:-}" ]]; then
  add_check "refresh wrapper contract" "fail" "needs PROJECT_ID, working psql, GITHUB_OWNER, GITHUB_REPO (see --help)"
else
  rf_err="$(mktemp)"
  set +e
  refresh_out="$("$REFRESH" manual_refresh 2>"$rf_err")"
  refresh_rc=$?
  set -e
  rf_e="$(cat "$rf_err" 2>/dev/null || true)"
  rm -f "$rf_err"
  if ! echo "$refresh_out" | jq -e . >/dev/null 2>&1; then
    add_check "refresh wrapper contract" "fail" "refresh exited ${refresh_rc} or stdout is not JSON. stderr: ${rf_e:0:300} stdout: ${refresh_out:0:200}"
  elif ! echo "$refresh_out" | jq -e '
        type == "object"
        and (.trigger_source == "manual_refresh")
        and (.pipeline | type == "object")
        and (.started_at | type == "string")
        and (.finished_at | type == "string")
        and (.pipeline.status | type == "string" and IN("success", "partial", "failed"))
        and (.pipeline.inserted | type == "number")
        and (.pipeline.duplicate_by_filename | type == "number")
        and (.pipeline.duplicate_by_hash | type == "number")
        and (.pipeline.invalid_files | type == "number")
        and (.pipeline.errors | type == "number")
      ' >/dev/null 2>&1; then
    add_check "refresh wrapper contract" "fail" "refresh JSON missing trigger_source/pipeline/timestamps or nested pipeline contract"
  else
    add_check "refresh wrapper contract" "pass" "refresh wrapper and nested pipeline JSON validated"
  fi
fi

# --- import status contract ---
if [[ "$db_ready" -ne 1 ]]; then
  add_check "import status contract" "fail" "needs PROJECT_ID and working psql connection (see --help)"
else
  st_err="$(mktemp)"
  set +e
  status_out="$("$IMPORT_STATUS" "$PROJECT_ID" 2>"$st_err")"
  status_rc=$?
  set -e
  st_e="$(cat "$st_err" 2>/dev/null || true)"
  rm -f "$st_err"
  if [[ "$status_rc" -ne 0 ]]; then
    add_check "import status contract" "fail" "get_project_import_status exited ${status_rc}: ${st_e:0:300} ${status_out:0:200}"
  elif ! echo "$status_out" | jq -e '
        type == "object"
        and (.project_id | type == "number")
        and (.integration_status | type == "string"
          and IN("never_imported", "imported", "import_failed_or_partial"))
        and (.latest_import_log == null or (.latest_import_log | type == "object"))
        and (.snapshot_count | type == "number")
        and (.latest_snapshot_timestamp == null or (.latest_snapshot_timestamp | type == "string"))
      ' >/dev/null 2>&1; then
    add_check "import status contract" "fail" "import status JSON missing required keys or wrong types"
  else
    add_check "import status contract" "pass" "import status keys validated (integration_status=$(echo "$status_out" | jq -r .integration_status))"
  fi
fi

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n \
  --arg st "$overall" \
  --argjson checks "$checks" \
  --argjson fc "$failed_checks" \
  --arg ga "$generated_at" \
  '{status: $st, checks: $checks, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
