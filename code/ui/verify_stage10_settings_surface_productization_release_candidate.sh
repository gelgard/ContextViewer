#!/usr/bin/env bash
# AI Task 126: Stage 10 settings/profile surface productization (release-candidate preview gate).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
SETTINGS_CONTRACT="${SCRIPT_DIR}/../settings/get_settings_profile_contract_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage10_settings_surface_productization_release_candidate.sh — Stage 126 settings surface RC (live HTML)

Regenerates preview via prepare_ui_preview_launch.sh and validates Task 126 productization markers
and settings section shell (no benchmark).

Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Requirement mapping (declarative): PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002.

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
[[ -f "$SETTINGS_CONTRACT" && -x "$SETTINGS_CONTRACT" ]] || { echo "error: missing or not executable: $SETTINGS_CONTRACT" >&2; exit 1; }

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
  "PG-UX-001 PG-EX-001 PG-RT-001 PG-RT-002"

settings_json=""
set +e
settings_json="$("$SETTINGS_CONTRACT" --project-id "$project_id" 2>/dev/null)"
s_rc=$?
set -e

if [[ "$s_rc" -ne 0 ]] || ! printf '%s' "$settings_json" | jq -e . >/dev/null 2>&1; then
  add_check "contract: get_settings_profile_contract_bundle stdout JSON" "fail" "exit ${s_rc} or invalid JSON"
else
  add_check "contract: get_settings_profile_contract_bundle stdout JSON" "pass" "parseable (exit ${s_rc})"
fi

if printf '%s' "$settings_json" | jq -e . >/dev/null 2>&1; then
  if printf '%s' "$settings_json" | jq -e '[.consistency_checks | to_entries | .[].value] | all' >/dev/null 2>&1; then
    add_check "contract: settings consistency_checks" "pass" "all true"
  else
    add_check "contract: settings consistency_checks" "fail" "one or more false"
  fi
else
  add_check "contract: settings consistency_checks" "pass" "skipped (invalid settings JSON)"
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
  if grep -q 'data-section="settings"' "$html_tmp" 2>/dev/null; then
    add_check "html: data-section settings" "pass" 'data-section="settings"'
  else
    add_check "html: data-section settings" "fail" "missing settings section root"
  fi
  if grep -q 'data-cv-settings-surface="087"' "$html_tmp" 2>/dev/null; then
    add_check "html: Task 087 settings surface marker" "pass" 'data-cv-settings-surface="087"'
  else
    add_check "html: Task 087 settings surface marker" "fail" "missing 087 baseline marker"
  fi
  if grep -q 'data-cv-settings-surface-productization="126"' "$html_tmp" 2>/dev/null; then
    add_check "html: Task 126 productization marker" "pass" 'data-cv-settings-surface-productization="126"'
  else
    add_check "html: Task 126 productization marker" "fail" "missing Task 126 marker"
  fi
  if grep -q 'settings-workspace--product-rc' "$html_tmp" 2>/dev/null; then
    add_check "html: product RC workspace class" "pass" "settings-workspace--product-rc"
  else
    add_check "html: product RC workspace class" "fail" "missing settings-workspace--product-rc"
  fi
  if grep -q '<h2>Project &amp; integration</h2>' "$html_tmp" 2>/dev/null; then
    add_check "html: product section title" "pass" "Project & integration h2"
  else
    add_check "html: product section title" "fail" "missing Project & integration heading"
  fi
  if grep -q 'class="settings-workspace' "$html_tmp" 2>/dev/null; then
    add_check "html: settings-workspace root retained" "pass" "settings-workspace class"
  else
    add_check "html: settings-workspace root retained" "fail" "missing settings-workspace"
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
