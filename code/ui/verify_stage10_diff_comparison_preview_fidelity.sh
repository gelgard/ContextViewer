#!/usr/bin/env bash
# AI Task 103: Stage 10 diff comparison preview fidelity (live HTML vs diff contract).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
DIFF_CONTRACT="${SCRIPT_DIR}/../diff/get_diff_viewer_contract_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage10_diff_comparison_preview_fidelity.sh — Stage 103 diff preview scan fidelity

Regenerates preview via prepare_ui_preview_launch.sh, compares HTML markers and counts to
get_diff_viewer_contract_bundle.sh (no benchmark).

Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Requirement mapping (declarative): PG-OV-001, PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002.

Required:
  --project-id <id>   non-negative integer

Optional:
  --output-dir <path>, --invalid-project-id <value>  forwarded to prepare

Missing --project-id: stderr + exit 2.
Invalid --project-id: stdout JSON fail + exit 1.
Prepare / contract failure: reflected in checks; overall fail when any check fails.

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
[[ -f "$DIFF_CONTRACT" && -x "$DIFF_CONTRACT" ]] || { echo "error: missing or not executable: $DIFF_CONTRACT" >&2; exit 1; }

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
  "PG-OV-001 PG-UX-001 PG-EX-001 PG-RT-001 PG-RT-002"

contract_json=""
set +e
contract_json="$("$DIFF_CONTRACT" --project-id "$project_id" 2>/dev/null)"
c_rc=$?
set -e

if [[ "$c_rc" -ne 0 ]] || ! printf '%s' "$contract_json" | jq -e . >/dev/null 2>&1; then
  add_check "contract: get_diff_viewer_contract_bundle stdout JSON" "fail" "exit ${c_rc} or invalid JSON"
else
  add_check "contract: get_diff_viewer_contract_bundle stdout JSON" "pass" "parseable (exit ${c_rc})"
fi

comp="false"
if printf '%s' "$contract_json" | jq -e '.comparison_ready == true' >/dev/null 2>&1; then
  comp="true"
fi

if [[ "$comp" != "true" ]]; then
  add_check "prerequisite: comparison_ready from contract" "fail" "false — preview fidelity gate needs two valid snapshots"
else
  add_check "prerequisite: comparison_ready from contract" "pass" "true"
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

contract_tmp="$(mktemp)"
printf '%s' "$contract_json" >"$contract_tmp"

if [[ "$comp" == "true" ]] && [[ ! -s "$html_tmp" ]]; then
  add_check "html: preview artifact for fidelity" "fail" "missing or empty output after prepare"
fi

if [[ -s "$html_tmp" ]] && [[ "$comp" == "true" ]]; then
  if grep -q 'data-cv-diff-fidelity="103"' "$html_tmp" 2>/dev/null; then
    add_check "html: Task 103 fidelity marker" "pass" 'data-cv-diff-fidelity="103"'
  else
    add_check "html: Task 103 fidelity marker" "fail" "missing fidelity marker"
  fi
  if grep -q 'data-cv-diff-comparison-ready="true"' "$html_tmp" 2>/dev/null; then
    add_check "html: comparison-ready marker" "pass" 'data-cv-diff-comparison-ready="true"'
  else
    add_check "html: comparison-ready marker" "fail" "missing or not true"
  fi
  if grep -q 'diff-compare-summary' "$html_tmp" 2>/dev/null && grep -q 'diff-stat-chips' "$html_tmp" 2>/dev/null; then
    add_check "html: compare summary strip" "pass" "diff-compare-summary + diff-stat-chips"
  else
    add_check "html: compare summary strip" "fail" "missing summary UI"
  fi
  for panel in added removed changed; do
    if grep -q "data-cv-diff-panel=\"${panel}\"" "$html_tmp" 2>/dev/null; then
      add_check "html: key panel (${panel})" "pass" "data-cv-diff-panel present"
    else
      add_check "html: key panel (${panel})" "fail" "missing panel ${panel}"
    fi
  done
  py_ok="$(
    python3 - "$html_tmp" "$contract_tmp" <<'PY'
import json
import re
import sys

html_path, contract_path = sys.argv[1], sys.argv[2]
with open(html_path, encoding="utf-8") as f:
    html = f.read()
with open(contract_path, encoding="utf-8") as f:
    c = json.load(f)

def cnt(key):
    v = c.get("diff_summary") or {}
    x = v.get(key)
    return len(x) if isinstance(x, list) else 0

exp_a, exp_r, exp_g = cnt("added_top_level_keys"), cnt("removed_top_level_keys"), cnt("changed_top_level_keys")
lat = c.get("latest_snapshot") or {}
prev = c.get("previous_snapshot") or {}
exp_lid = lat.get("snapshot_id")
exp_pid = prev.get("snapshot_id")

def m_int(attr):
    m = re.search(rf'{attr}="(\d+)"', html)
    return int(m.group(1)) if m else None

got_a, got_r, got_g = m_int("data-cv-diff-added-count"), m_int("data-cv-diff-removed-count"), m_int("data-cv-diff-changed-count")

def sid(role):
    m = re.search(
        rf'data-cv-diff-role="{role}"\s+data-cv-snapshot-id="([^"]*)"',
        html,
    )
    return m.group(1) if m else None

gl, gp = sid("latest"), sid("previous")

def norm_id(x):
    if x is None or x == "":
        return ""
    s = str(x)
    try:
        return str(int(s))
    except ValueError:
        return s

errors = []
if got_a != exp_a:
    errors.append(f"added_count html={got_a} contract={exp_a}")
if got_r != exp_r:
    errors.append(f"removed_count html={got_r} contract={exp_r}")
if got_g != exp_g:
    errors.append(f"changed_count html={got_g} contract={exp_g}")
if norm_id(gl) != norm_id(exp_lid):
    errors.append(f"latest_id html={gl!r} contract={exp_lid!r}")
if norm_id(gp) != norm_id(exp_pid):
    errors.append(f"previous_id html={gp!r} contract={exp_pid!r}")

print("ok" if not errors else "fail|" + "; ".join(errors))
PY
  )"
  if [[ "$py_ok" == "ok" ]]; then
    add_check "html: counts and snapshot ids match contract" "pass" "added/removed/changed + latest/previous ids"
  else
    add_check "html: counts and snapshot ids match contract" "fail" "${py_ok#fail|}"
  fi
elif [[ "$comp" != "true" ]]; then
  add_check "html: Task 103 fidelity checks" "pass" "not evaluated (comparison_ready false)"
fi

rm -f "$html_tmp" "$contract_tmp"

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
