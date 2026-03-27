#!/usr/bin/env bash
# AI Task 011: Stage 3 import pipeline (connector → scanner → download → SHA-256 → DB dedup → import log).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONNECTOR="${SCRIPT_DIR}/github_contextjson_connector.sh"
SCANNER="${SCRIPT_DIR}/contextjson_file_scanner.sh"

usage() {
  cat <<'USAGE'
ContextJSON import pipeline

Runs the GitHub connector, validates filenames with the scanner, downloads each
valid file, computes SHA-256 of the raw body, calls insert_snapshot_dedup(...) per
file, then writes one snapshot_import_logs row via insert_snapshot_import_log(...).

Required environment:
  GITHUB_OWNER       GitHub repository owner
  GITHUB_REPO        Repository name
  PROJECT_ID         Target projects.id (bigint) for snapshots / import log

  PostgreSQL connection:
  - preferred: DATABASE_URL
  - or standard libpq vars, e.g.:
    PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD

Optional environment:
  GITHUB_BRANCH      Branch/ref (default: main)
  GITHUB_TOKEN       Optional API token

Dependencies:
  bash, curl, jq, openssl, psql

Summary (stdout, single JSON object):
  status                  success | partial | failed
  inserted                count of insert_snapshot_dedup → inserted
  duplicate_by_filename   count → duplicate_by_filename
  duplicate_by_hash       count → duplicate_by_hash
  invalid_files           count from scanner invalid_files (filename rule)
  errors                  download / JSON / DB / connector failures

Log status rules:
  failed   — connector or scanner failed, DB unreachable, per-step errors, or log insert failed
  partial  — finished with errors=0 but invalid_files>0 or any duplicates
  success  — errors=0, invalid_files=0, no duplicates

Options:
  -h, --help       Show this help and exit
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
if [[ -n "${1:-}" ]]; then
  echo "error: unknown option: $1" >&2
  usage >&2
  exit 2
fi

for cmd in curl jq openssl psql; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "error: required command not found: $cmd" >&2
    exit 127
  }
done

[[ -x "$CONNECTOR" ]] || { echo "error: connector not executable: $CONNECTOR" >&2; exit 1; }
[[ -x "$SCANNER" ]] || { echo "error: scanner not executable: $SCANNER" >&2; exit 1; }

: "${GITHUB_OWNER:?GITHUB_OWNER is required}"
: "${GITHUB_REPO:?GITHUB_REPO is required}"
: "${PROJECT_ID:?PROJECT_ID is required}"

# Auto-load local env file for DATABASE_URL if it exists and var is unset.
if [[ -z "${DATABASE_URL:-}" && -f "${PROJECT_ROOT}/.env.local" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "${PROJECT_ROOT}/.env.local"
  set +a
fi

# Use DATABASE_URL when present; otherwise rely on libpq environment defaults.
PSQL_CMD=(psql)
if [[ -n "${DATABASE_URL:-}" ]]; then
  PSQL_CMD+=("$DATABASE_URL")
fi

inserted=0
duplicate_by_filename=0
duplicate_by_hash=0
invalid_files=0
errors=0
fatal=0
scanner_json='{"valid_files":[],"invalid_files":[]}'

IMPORT_TMPDIR=''
IMPORT_CONNECTOR_ERR=''
IMPORT_SUMMARY_DONE=0
IMPORT_FINAL_STATUS='failed'

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

import_summarize() {
  [[ "$IMPORT_SUMMARY_DONE" -eq 1 ]] && return 0
  IMPORT_SUMMARY_DONE=1

  local dup_total=$((duplicate_by_filename + duplicate_by_hash))
  local log_status
  local summary_status

  if [[ "$fatal" -ne 0 ]] || [[ "$errors" -gt 0 ]]; then
    log_status='failed'
    summary_status='failed'
  elif [[ "$invalid_files" -gt 0 ]] || [[ "$dup_total" -gt 0 ]]; then
    log_status='partial'
    summary_status='partial'
  else
    log_status='success'
    summary_status='success'
  fi

  local msg
  printf -v msg \
    'pipeline status=%s inserted=%s dup_name=%s dup_hash=%s invalid_files=%s errors=%s fatal=%s' \
    "$log_status" "$inserted" "$duplicate_by_filename" "$duplicate_by_hash" \
    "$invalid_files" "$errors" "$fatal"

  local m_delim
  m_delim="logmsg_$(openssl rand -hex 16)_"

  set +e
  "${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 -q -t -A <<SQL >/dev/null
SELECT insert_snapshot_import_log(
  ${PROJECT_ID}::bigint,
  '$(sql_escape "$log_status")',
  \$${m_delim}\$${msg}\$${m_delim}\$
);
SQL
  local log_rc=$?
  set -e
  if [[ "$log_rc" -ne 0 ]]; then
    summary_status='failed'
    errors=$((errors + 1))
  fi

  IMPORT_FINAL_STATUS="$summary_status"

  jq -n \
    --arg st "$summary_status" \
    --argjson ins "$inserted" \
    --argjson df "$duplicate_by_filename" \
    --argjson dh "$duplicate_by_hash" \
    --argjson inv "$invalid_files" \
    --argjson err "$errors" \
    '{status: $st, inserted: $ins, duplicate_by_filename: $df, duplicate_by_hash: $dh, invalid_files: $inv, errors: $err}'
}

import_on_exit() {
  trap - EXIT
  local ec=$?
  rm -rf "${IMPORT_TMPDIR:-}"
  rm -f "${IMPORT_CONNECTOR_ERR:-}"
  import_summarize || true
  if [[ "$IMPORT_FINAL_STATUS" == "failed" ]]; then
    exit 1
  fi
  exit "$ec"
}

trap 'import_on_exit' EXIT

"${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 -q -t -A -c "SELECT 1;" >/dev/null 2>&1 || {
  echo "error: psql connection check failed" >&2
  fatal=1
  false
  exit 1
}

IMPORT_CONNECTOR_ERR="$(mktemp)"

set +e
connector_out="$("$CONNECTOR" 2>"$IMPORT_CONNECTOR_ERR")"
conn_rc=$?
set -e
if [[ "$conn_rc" -ne 0 ]]; then
  echo "error: github_contextjson_connector.sh failed (exit $conn_rc)" >&2
  cat "$IMPORT_CONNECTOR_ERR" >&2 || true
  fatal=1
  false
  exit 1
fi
rm -f "$IMPORT_CONNECTOR_ERR"
IMPORT_CONNECTOR_ERR=''

set +e
scanner_json="$(printf '%s\n' "$connector_out" | "$SCANNER" 2>&1)"
scan_rc=$?
set -e
if [[ "$scan_rc" -ne 0 ]]; then
  echo "error: contextjson_file_scanner.sh failed (exit $scan_rc): $scanner_json" >&2
  fatal=1
  false
  exit 1
fi

invalid_files="$(jq -r '.invalid_files | length' <<<"$scanner_json")"

IMPORT_TMPDIR="$(mktemp -d)"

CONTEXTJSON_OK_JQ='
  (type == "object")
  and has("project") and has("system") and has("progress") and has("roadmap") and has("changes_since_previous")
  and (.project | type == "object")
  and (.system | type == "object")
  and (.progress | type == "object")
  and (.roadmap | type == "array")
  and (.changes_since_previous | type == "array")
'

while IFS= read -r row; do
  name="$(jq -r '.name // empty' <<<"$row")"
  # Scanner valid_files omit download_url; resolve from connector listing by name.
  dl_url="$(jq -r --arg n "$name" 'map(select(.name == $n)) | first | .download_url // empty' <<<"$connector_out")"

  if [[ -z "$dl_url" || "$dl_url" == "null" ]]; then
    errors=$((errors + 1))
    continue
  fi

  fpath="${IMPORT_TMPDIR}/dl.json"
  set +e
  curl -fsS -L --max-redirs 5 -o "$fpath" "$dl_url"
  cr=$?
  set -e
  if [[ "$cr" -ne 0 ]]; then
    errors=$((errors + 1))
    continue
  fi

  if ! jq empty "$fpath" >/dev/null 2>&1; then
    errors=$((errors + 1))
    continue
  fi

  hash_hex="$(openssl dgst -sha256 -r "$fpath" | awk '{print $1}')"

  if jq -e "$CONTEXTJSON_OK_JQ" "$fpath" >/dev/null 2>&1; then
    is_valid_sql=true
  else
    is_valid_sql=false
  fi

  delim="j_$(openssl rand -hex 16)_"
  compact="$(jq -c . "$fpath")"

  set +e
  dedup_out="$(
    "${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 -q -t -A -F '|' <<SQL 2>/dev/null
SELECT outcome, snapshot_id FROM insert_snapshot_dedup(
  ${PROJECT_ID}::bigint,
  '$(sql_escape "$name")'::text,
  '$(sql_escape "$hash_hex")'::text,
  \$${delim}\$${compact}\$${delim}\$::jsonb,
  ${is_valid_sql}::boolean
);
SQL
  )"
  pr=$?
  set -e

  if [[ "$pr" -ne 0 ]]; then
    errors=$((errors + 1))
    continue
  fi

  outcome="$(printf '%s\n' "$dedup_out" | head -n1 | cut -d'|' -f1 | tr -d ' \t\r\n')"
  case "$outcome" in
    inserted)
      inserted=$((inserted + 1))
      ;;
    duplicate_by_filename)
      duplicate_by_filename=$((duplicate_by_filename + 1))
      ;;
    duplicate_by_hash)
      duplicate_by_hash=$((duplicate_by_hash + 1))
      ;;
    *)
      errors=$((errors + 1))
      ;;
  esac
done < <(jq -c '.valid_files[]' <<<"$scanner_json")

exit 0
