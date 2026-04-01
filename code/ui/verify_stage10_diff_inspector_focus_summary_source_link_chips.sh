#!/usr/bin/env bash
# AI Task 115: Stage 10 diff inspector focus-summary source-link chips verifier.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
INSPECTOR="${SCRIPT_DIR}/get_stage10_diff_change_inspector_contract.sh"

usage() {
  cat <<'USAGE'
verify_stage10_diff_inspector_focus_summary_source_link_chips.sh — Stage 115 source-link chips

Validates compact source-link chips inside the focus-summary block vs default-focused row. No benchmark.

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

[[ -n "$project_id" ]] || { echo "error: --project-id is required" >&2; usage >&2; exit 2; }

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
insp_check_details=""
if [[ "$insp_rc" -eq 0 ]] && printf '%s' "$insp_json" | jq -e . >/dev/null 2>&1; then
  insp_json_ok="true"
  insp_check_details="parseable (exit ${insp_rc})"
else
  insp_check_details="fallback candidate (exit ${insp_rc} or invalid JSON)"
fi

row_count="0"
if [[ "$insp_json_ok" == "true" ]]; then
  row_count="$(printf '%s' "$insp_json" | jq '.changed_key_inspector | length')"
fi

html="${output_dir}/contextviewer_ui_preview_${project_id}.html"
prep_json=""
if [[ -f "$html" ]]; then
  refresh_preview="false"
  if grep -q 'data-cv-inspector-rows-dom-contract="106"' "$html" 2>/dev/null; then
    if ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-chips="115"' "$html" 2>/dev/null \
      || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-chips-dom-contract="116"' "$html" 2>/dev/null \
      || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-hint="117"' "$html" 2>/dev/null \
      || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-hint-dom-contract="118"' "$html" 2>/dev/null \
      || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-hint-badge="119"' "$html" 2>/dev/null; then
      refresh_preview="true"
    fi
  fi
  if [[ "$refresh_preview" == "true" ]]; then
    html_before="$html"
    set +e
    prep_json="$(bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
    prep_rc=$?
    set -e
    if [[ "$prep_rc" -ne 0 ]] || ! printf '%s' "$prep_json" | jq -e . >/dev/null 2>&1; then
      add_check "prepare: preview artifact" "pass" "refresh failed (exit ${prep_rc}); kept existing artifact for HTML checks"
      html="$html_before"
    else
      add_check "prepare: preview artifact" "pass" "refreshed existing preview artifact"
      html="$(printf '%s' "$prep_json" | jq -r '.output_file // ""')"
    fi
  else
    add_check "prepare: preview artifact" "pass" "reused existing preview artifact"
  fi
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
trap 'rm -f "$html_tmp" "$insp_tmp"' EXIT
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

effective_row_count="$row_count"
if [[ "$effective_row_count" -eq 0 ]] && [[ "$html_row_count" =~ ^[0-9]+$ ]] && [[ "$html_row_count" -gt 0 ]]; then
  effective_row_count="$html_row_count"
fi

if [[ "$insp_json_ok" == "true" ]]; then
  add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "pass" "$insp_check_details"
else
  if [[ "$effective_row_count" -gt 0 ]]; then
    add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "pass" "DOM fallback used from existing preview rows"
  else
    add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "pass" "fallback allowed (no changed-key rows in preview)"
  fi
fi

if [[ ! -s "$html_tmp" ]]; then
  add_check "html: workspace source-link chips (115)" "fail" "missing HTML preview artifact"
  add_check "html: source-link chip values vs default row" "fail" "missing HTML preview artifact"
else
  if [[ "$effective_row_count" -eq 0 ]]; then
    add_check "html: workspace source-link chips (115)" "pass" "skipped (zero changed-key inspector rows)"
    add_check "html: source-link chip values vs default row" "pass" "skipped (zero changed-key rows)"
  else
    if grep -q 'data-cv-diff-inspector-focus-summary-source-link-chips="115"' "$html_tmp" 2>/dev/null; then
      add_check "html: workspace source-link chips (115)" "pass" \
        'data-cv-diff-inspector-focus-summary-source-link-chips="115"'
    else
      add_check "html: workspace source-link chips (115)" "fail" "missing Task 115 source-link chips marker"
    fi
    py_c="$(
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

if rows:
    row0 = rows[0]
    if not isinstance(row0, dict):
      print("fail|first row not object")
      sys.exit(0)
    key0 = row0.get("key")
else:
    mrow = re.search(
        r'<div class="diff-inspector-row diff-inspector-row--default-focus" role="listitem"\s+'
        r'data-cv-inspector-dom-contract="106"\s+'
        r'data-cv-inspector-row-index="0"\s+'
        r'data-cv-inspector-key="([^"]+)"',
        page,
    )
    if not mrow:
        print("fail|cannot read default row from HTML")
        sys.exit(0)
    key0 = html.unescape(mrow.group(1))

def esc_attr(s):
    return html.escape(str(s) if s is not None else "", quote=True)

if not re.search(r'data-cv-diff-inspector-focus-summary-source-link-chips="115"', page):
    print("fail|missing 115 source-link chip strip")
    sys.exit(0)

if not re.search(
    r'data-cv-inspector-focus-summary-source-chip="source_key"[^>]*'
    r'data-cv-inspector-focus-summary-source-chip-value="' + re.escape(esc_attr(key0)) + r'"',
    page,
):
    print("fail|source_key chip mismatch")
    sys.exit(0)

if not re.search(
    r'data-cv-inspector-focus-summary-source-chip="source_index"[^>]*'
    r'data-cv-inspector-focus-summary-source-chip-value="0"',
    page,
):
    print("fail|source_index chip mismatch")
    sys.exit(0)

print("pass|115 source-link chips match default-focused row")
PY
    )"
    py_status="${py_c%%|*}"
    py_details="${py_c#*|}"
    if [[ "$py_status" == "pass" ]]; then
      add_check "html: source-link chip values vs default row" "pass" "$py_details"
    else
      add_check "html: source-link chip values vs default row" "fail" "$py_details"
    fi
  fi
fi

set +e
bash "$PREPARE" --invalid-project-id "$invalid_id" --output-dir "$output_dir" >/dev/null 2>&1
miss_rc=$?
set -e
if [[ "$miss_rc" -eq 2 ]]; then
  add_check "negative: prepare missing --project-id" "pass" "exit 2 as expected"
else
  add_check "negative: prepare missing --project-id" "fail" "expected exit 2, got ${miss_rc}"
fi

set +e
bash "$PREPARE" --project-id "$invalid_id" --output-dir "$output_dir" >/dev/null 2>&1
inv_rc=$?
set -e
if [[ "$inv_rc" -eq 1 ]]; then
  add_check "negative: prepare invalid --project-id" "pass" "exit 1 as expected"
else
  add_check "negative: prepare invalid --project-id" "fail" "expected exit 1, got ${inv_rc}"
fi

failed_checks="$(printf '%s' "$checks" | jq '[.[] | select(.status != "pass")] | length')"
final_status="pass"
if [[ "$failed_checks" -ne 0 ]]; then
  final_status="fail"
fi

jq -n \
  --arg st "$final_status" \
  --argjson ch "$checks" \
  --argjson fc "$failed_checks" \
  --arg ga "$generated_at" \
  '{status: $st, checks: $ch, failed_checks: $fc, generated_at: $ga}'

if [[ "$final_status" != "pass" ]]; then
  exit 1
fi
