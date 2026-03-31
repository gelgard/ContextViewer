#!/usr/bin/env bash
# AI Task 107: Stage 10 diff change inspector default-focus verifier.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
INSPECTOR="${SCRIPT_DIR}/get_stage10_diff_change_inspector_contract.sh"

usage() {
  cat <<'USAGE'
verify_stage10_diff_change_inspector_default_focus.sh — Stage 107 inspector default-focus

Validates deterministic first-row focus on live HTML from prepare / existing artifact (no benchmark).

Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Declarative requirement mapping: PG-AR-001, PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002.

Required:
  --project-id <id>   non-negative integer

Optional:
  --output-dir <path>, --invalid-project-id <value>

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
[[ -f "$INSPECTOR" && -x "$INSPECTOR" ]] || { echo "error: missing or not executable: $INSPECTOR" >&2; exit 1; }

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
  "PG-AR-001 PG-UX-001 PG-EX-001 PG-RT-001 PG-RT-002"

insp_json=""
set +e
insp_json="$(bash "$INSPECTOR" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
insp_rc=$?
set -e

insp_json_ok="false"
if [[ "$insp_rc" -eq 0 ]] && printf '%s' "$insp_json" | jq -e . >/dev/null 2>&1; then
  insp_json_ok="true"
  add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "pass" "parseable (exit ${insp_rc})"
else
  add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "fail" "exit ${insp_rc} or invalid JSON"
fi

ch_count="0"
if [[ "$insp_json_ok" == "true" ]]; then
  ch_count="$(printf '%s' "$insp_json" | jq '.changed_key_inspector | length')"
fi

html="${output_dir}/contextviewer_ui_preview_${project_id}.html"
prep_json=""

if [[ -f "$html" ]]; then
  add_check "prepare: preview artifact" "pass" "reused existing preview artifact"
else
  set +e
  prep_json="$(bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
  prep_rc=$?
  set -e
  if [[ "$prep_rc" -ne 0 ]] || ! printf '%s' "$prep_json" | jq -e . >/dev/null 2>&1; then
    add_check "prepare: preview artifact" "fail" "exit ${prep_rc} or invalid JSON"
    html=""
  else
    add_check "prepare: preview artifact" "pass" "exit ${prep_rc}"
    html="$(printf '%s' "$prep_json" | jq -r '.output_file // ""')"
  fi
fi

html_tmp="$(mktemp)"
insp_tmp="$(mktemp)"
[[ -n "$html" && -f "$html" ]] && cat "$html" >"$html_tmp"
printf '%s' "$insp_json" >"$insp_tmp"

html_row_count="$(
  python3 - "$html_tmp" <<'PY'
import re
import sys
path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        page = f.read()
except FileNotFoundError:
    print(0)
    sys.exit(0)
print(len(re.findall(r'data-cv-inspector-row-index="(\d+)"', page)))
PY
)"

if [[ ! -s "$html_tmp" ]]; then
  add_check "html: workspace default-focus marker (107)" "fail" "missing HTML preview artifact"
  add_check "html: rows container default-focus mode (107)" "fail" "missing HTML preview artifact"
  add_check "html: focused row + key vs contract" "fail" "missing HTML preview artifact"
else
  effective_row_count="$ch_count"
  if [[ "$effective_row_count" -eq 0 ]] && [[ "$html_row_count" =~ ^[0-9]+$ ]] && [[ "$html_row_count" -gt 0 ]]; then
    effective_row_count="$html_row_count"
  fi
  if [[ "$effective_row_count" -eq 0 ]]; then
    add_check "html: workspace default-focus marker (107)" "pass" "skipped (zero changed keys in inspector contract)"
    add_check "html: rows container default-focus mode (107)" "pass" "skipped (zero changed keys)"
    add_check "html: focused row + key vs contract" "pass" "skipped (zero changed keys)"
  else
    if grep -q 'data-cv-diff-inspector-default-focus="107"' "$html_tmp" 2>/dev/null; then
      add_check "html: workspace default-focus marker (107)" "pass" 'data-cv-diff-inspector-default-focus="107"'
    else
      add_check "html: workspace default-focus marker (107)" "fail" "missing workspace Task 107 marker"
    fi
    if grep -q 'data-cv-inspector-default-focus-mode="107"' "$html_tmp" 2>/dev/null \
      && grep -q 'data-cv-inspector-default-focus-index="0"' "$html_tmp" 2>/dev/null; then
      add_check "html: rows container default-focus mode (107)" "pass" "mode + index=0 on rows list"
    else
      add_check "html: rows container default-focus mode (107)" "fail" "missing mode/index on inspector rows"
    fi
    py_f="$(
      python3 - "$html_tmp" "$insp_tmp" <<'PY'
import html
import json
import re
import sys

html_path, insp_path = sys.argv[1], sys.argv[2]
with open(html_path, encoding="utf-8") as f:
    page = f.read()
with open(insp_path, encoding="utf-8") as f:
    raw = f.read()
try:
    insp = json.loads(raw)
except json.JSONDecodeError:
    insp = {}
rows = insp.get("changed_key_inspector") or []
if not isinstance(rows, list):
    rows = []

row_keys = re.findall(r'data-cv-inspector-key="([^"]+)"', page)
if not row_keys:
    print("fail|missing changed-key inspector rows in HTML")
    sys.exit(0)

if rows:
    row0 = rows[0]
    if not isinstance(row0, dict):
        print("fail|first row not object")
        sys.exit(0)
    k0 = row0.get("key")
else:
    k0 = html.unescape(row_keys[0])

def esc_attr(s):
    return html.escape(str(s) if s is not None else "", quote=True)

exp_k = esc_attr(str(k0))
mc = re.search(
    r'data-cv-inspector-default-focus-key="' + re.escape(exp_k) + r'"',
    page,
)
if not mc:
    print("fail|container or row default-focus-key does not match first contract key")
    sys.exit(0)
if page.count('data-cv-inspector-default-focus-key="' + exp_k + '"') < 1:
    print("fail|expected at least one default-focus-key attr for first key")
    sys.exit(0)
true_ct = len(re.findall(r'data-cv-inspector-default-focus="true"', page))
if true_ct != 1:
    print(f"fail|expected exactly one data-cv-inspector-default-focus=true, got {true_ct}")
    sys.exit(0)
pat0 = (
    r'<div class="diff-inspector-row diff-inspector-row--default-focus" role="listitem"\s+'
    r'data-cv-inspector-dom-contract="106"\s+'
    r'data-cv-inspector-row-index="0"\s+'
    r'data-cv-inspector-key="' + re.escape(exp_k) + r'"'
)
if not re.search(pat0, page):
    print("fail|default-focus row missing class or index 0 key mismatch")
    sys.exit(0)
if not re.search(r'class="diff-inspector-focus-badge mono">Default focus</p>', page):
    print("fail|missing visible default-focus badge")
    sys.exit(0)
print("ok")
PY
    )"
    if [[ "$py_f" == "ok" ]]; then
      add_check "html: focused row + key vs contract" "pass" "first changed_key_inspector row is default-focused"
    else
      add_check "html: focused row + key vs contract" "fail" "${py_f#fail|}"
    fi
  fi
fi

rm -f "$html_tmp" "$insp_tmp"

run_neg() {
  local name="$1" exp="$2"; shift 2
  local r
  set +e
  "$@" >/dev/null 2>&1
  r=$?
  set -e
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
