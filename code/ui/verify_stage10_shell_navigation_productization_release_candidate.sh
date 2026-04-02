#!/usr/bin/env bash
# AI Task 127: Stage 10 shell and navigation productization (release-candidate preview gate).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
BOOTSTRAP="${SCRIPT_DIR}/get_ui_bootstrap_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage10_shell_navigation_productization_release_candidate.sh — Stage 127 shell/navigation RC (live HTML)

Regenerates preview via prepare_ui_preview_launch.sh and validates Task 127 shell productization markers
and section roots (no benchmark).

Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Requirement mapping (declarative): PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002, PG-OV-001.

Required:
  --project-id <id>   non-negative integer

Optional:
  --output-dir <path>, --invalid-project-id <value>  forwarded to prepare

Missing --project-id: stderr + exit 2.
Invalid --project-id: stdout JSON fail + exit 1.

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project-id)
      [[ -n "${2:-}" ]] || { echo "error: --project-id requires a value" >&2; exit 2; }
      project_id="$2"; shift 2 ;;
    --output-dir)
      [[ -n "${2:-}" ]] || { echo "error: --output-dir requires a value" >&2; exit 2; }
      output_dir="$2"; shift 2 ;;
    --invalid-project-id)
      [[ -n "${2:-}" ]] || { echo "error: --invalid-project-id requires a value" >&2; exit 2; }
      invalid_id="$2"; shift 2 ;;
    *)
      echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$project_id" ]] && { echo "error: --project-id is required" >&2; usage >&2; exit 2; }

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
[[ -f "$PREPARE" && -x "$PREPARE" ]] || { echo "error: missing or not executable: $PREPARE" >&2; exit 1; }
[[ -f "$BOOTSTRAP" && -x "$BOOTSTRAP" ]] || { echo "error: missing or not executable: $BOOTSTRAP" >&2; exit 1; }

checks='[]'
add_check() {
  local n="$1" s="$2" d="$3"
  checks="$(jq -n --argjson c "$checks" --arg n "$n" --arg st "$s" --arg det "$d" \
    '$c + [{name: $n, status: $st, details: $det}]')"
}

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  jq -n --arg ga "$generated_at" '{
    status: "fail",
    checks: [{name: "project_id", status: "fail", details: "must be non-negative integer"}],
    failed_checks: 1,
    generated_at: $ga
  }'
  exit 1
fi

add_check "traceability: product goal IDs (declarative)" "pass" \
  "PG-UX-001 PG-EX-001 PG-RT-001 PG-RT-002 PG-OV-001"

boot_json=""
set +e
boot_json="$(bash "$BOOTSTRAP" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>/dev/null)"
b_rc=$?
set -e

if [[ "$b_rc" -ne 0 ]] || ! printf '%s' "$boot_json" | jq -e . >/dev/null 2>&1; then
  add_check "contract: get_ui_bootstrap_bundle stdout JSON" "fail" "exit ${b_rc} or invalid JSON"
else
  add_check "contract: get_ui_bootstrap_bundle stdout JSON" "pass" "parseable (exit ${b_rc})"
fi

if printf '%s' "$boot_json" | jq -e . >/dev/null 2>&1; then
  if printf '%s' "$boot_json" | jq -e '.consistency_checks | type == "object"' >/dev/null 2>&1 \
    && printf '%s' "$boot_json" | jq -e '[.consistency_checks | to_entries | .[].value] | all' >/dev/null 2>&1; then
    add_check "contract: bootstrap consistency_checks" "pass" "all true"
  else
    add_check "contract: bootstrap consistency_checks" "fail" "missing or not all true"
  fi
else
  add_check "contract: bootstrap consistency_checks" "pass" "skipped (invalid bootstrap JSON)"
fi

prep_json=""
set +e
prep_json="$(bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
p_rc=$?
set -e

if [[ "$p_rc" -ne 0 ]] || ! printf '%s' "$prep_json" | jq -e . >/dev/null 2>&1; then
  add_check "prepare: prepare_ui_preview_launch stdout JSON" "fail" "exit ${p_rc} or invalid JSON"
  html=""
else
  add_check "prepare: prepare_ui_preview_launch stdout JSON" "pass" "parseable (exit ${p_rc})"
  html="$(printf '%s' "$prep_json" | jq -r '.output_file // ""')"
fi

if [[ -n "$html" && -f "$html" ]]; then
  add_check "prepare: output_file exists" "pass" "$html"
else
  add_check "prepare: output_file exists" "fail" "missing path"
fi

html_tmp="$(mktemp)"
if [[ -n "$html" && -f "$html" ]]; then
  cat "$html" >"$html_tmp"
fi

if [[ ! -s "$html_tmp" ]]; then
  add_check "html: preview artifact" "fail" "missing or empty after prepare"
else
  add_check "html: preview artifact" "pass" "non-empty"
  if grep -q 'data-cv-preview-shell="080"' "$html_tmp" 2>/dev/null; then
    add_check "html: Task 080 shell marker retained" "pass" 'data-cv-preview-shell="080"'
  else
    add_check "html: Task 080 shell marker retained" "fail" "missing 080 shell marker"
  fi
  if grep -q 'data-cv-shell-navigation-productization="127"' "$html_tmp" 2>/dev/null; then
    add_check "html: Task 127 shell productization marker" "pass" 'data-cv-shell-navigation-productization="127"'
  else
    add_check "html: Task 127 shell productization marker" "fail" "missing Task 127 marker"
  fi
  if grep -q 'cv-app-shell--product-rc' "$html_tmp" 2>/dev/null; then
    add_check "html: product RC shell class" "pass" "cv-app-shell--product-rc"
  else
    add_check "html: product RC shell class" "fail" "missing cv-app-shell--product-rc"
  fi
  if grep -q 'id="cv-main-workspace"' "$html_tmp" 2>/dev/null \
    && grep -q 'class="workspace-nav"' "$html_tmp" 2>/dev/null; then
    add_check "html: main workspace + nav retained" "pass" "cv-main-workspace + workspace-nav"
  else
    add_check "html: main workspace + nav retained" "fail" "missing main or nav"
  fi
  sec_ok="true"
  for sec in overview visualization history diff settings; do
    if ! grep -q "data-section=\"${sec}\"" "$html_tmp" 2>/dev/null; then
      sec_ok="false"
      break
    fi
  done
  if [[ "$sec_ok" == "true" ]]; then
    add_check "html: all data-section roots" "pass" "overview visualization history diff settings"
  else
    add_check "html: all data-section roots" "fail" "missing one or more data-section markers"
  fi
  id_ok="true"
  for sid in cv-section-overview cv-section-visualization cv-section-history cv-section-diff cv-section-settings; do
    if ! grep -q "id=\"${sid}\"" "$html_tmp" 2>/dev/null; then
      id_ok="false"
      break
    fi
  done
  if [[ "$id_ok" == "true" ]]; then
    add_check "html: section ids retained" "pass" "all cv-section-* ids present"
  else
    add_check "html: section ids retained" "fail" "missing section id"
  fi
  if grep -q 'id="ui-bootstrap-payload"' "$html_tmp" 2>/dev/null; then
    add_check "html: embedded payload retained" "pass" 'ui-bootstrap-payload'
  else
    add_check "html: embedded payload retained" "fail" "missing payload script"
  fi
fi

rm -f "$html_tmp"

run_neg() {
  local name="$1" exp="$2"; shift 2
  local r
  local errf
  errf="$(mktemp)"
  set +e
  "$@" >/dev/null 2>"$errf"
  r=$?
  set -e
  rm -f "$errf"
  if [[ "$r" -eq "$exp" ]]; then
    add_check "$name" "pass" "exit ${exp} as expected"
  else
    add_check "$name" "fail" "expected exit ${exp}, got ${r}"
  fi
}

run_neg "negative: prepare missing --project-id" 2 bash "$PREPARE" --output-dir "$output_dir"
run_neg "negative: prepare invalid --project-id" 1 bash "$PREPARE" --project-id "$invalid_id" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n --arg st "$overall" --argjson chk "$checks" --argjson fc "$failed_checks" --arg ga "$generated_at" \
  '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
