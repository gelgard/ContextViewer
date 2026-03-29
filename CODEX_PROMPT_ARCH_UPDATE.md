# Codex Prompt — Architecture Rules Update
## Использование: скопировать блок ниже целиком и передать Codex

---

````
TASK: Architecture rules update — add validation pyramid and anti-loop policy.

PROJECT: ContextViewer-1
CURRENT STAGE: Stage 9 (active)
CURRENT TASK: AI Task 091 (active)

═══════════════════════════════════════════════════════════════
EXECUTION CONSTRAINTS — READ BEFORE ANYTHING ELSE
═══════════════════════════════════════════════════════════════

Environment: offline (no DB, no HTTP server, no network calls).
You are modifying DOCUMENTATION FILES ONLY — no shell scripts, no code.

STOP CONDITIONS (do not retry after these):
1. If a validation command takes > 5 seconds → STOP, report as env_infra skip.
2. If the same command fails twice with identical output → STOP, do not retry.
3. If any command requires psql, curl, python3 -m http.server → SKIP, mark as requires_live_infra.

FORBIDDEN in this session:
- modifying any file in code/
- modifying any file in docs/plans/
- modifying any file in docs/architecture/
- modifying any file in contextJSON/
- modifying any existing ai_tasks/0[0-9][0-9]_*.md
- changing or deleting ANY existing rule, section, or content in the files below
- changing the project stage, task numbering, or plan

ALLOWED: appending new sections to the end of specified files.
All existing content must remain 100% intact.

═══════════════════════════════════════════════════════════════
SCOPE — EXACTLY 4 FILES TO MODIFY, APPEND-ONLY
═══════════════════════════════════════════════════════════════

File 1: AGENTS.md
File 2: project_recovery/05_TESTING_RULES.txt
File 3: project_recovery/11_RESPONSE_FORMAT_RULES.txt
File 4: ai_tasks/000_ai_task_template.md

No other files. No exceptions.

═══════════════════════════════════════════════════════════════
FILE 1 — AGENTS.md
Append after the closing line of section ## 8.1 CONTEXT RESTORE POLICY
(after the "Blocked response format:" block, before ## 9.)
═══════════════════════════════════════════════════════════════

Insert the following three new sections between ##8.1 and ##9:

---

## 8.2 VALIDATION LAYER POLICY (permanent)

All validation is organized into four independent layers. Each layer has a designated executor. No layer substitutes for another. No layer can be skipped by its designated executor.

Layer 1 — Unit (executor: Codex agent, mandatory):
- scope: bash syntax check, --help exit 0, missing required arg exit 2, invalid flag value exit 1 or 2
- timeout: 3 seconds per command (hard ceiling)
- environment: fully offline — no DB, no HTTP, no network
- gate: Codex must pass Layer 1 before marking any task as complete

Layer 2 — Contract (executor: Codex agent, mandatory):
- scope: JSON shape validation, jq parsing, fixture-based contract checks, STAGE9_HYGIENE_SKIP=1 mock-mode outputs
- timeout: 10 seconds total for all Layer 2 commands combined
- environment: fully offline — fixtures from code/test_fixtures/*.json, no live infrastructure
- gate: Codex must pass Layer 2 before marking any task as complete
- required env: STAGE9_HYGIENE_SKIP=1 for any script that calls hygiene preflight

Layer 3 — Integration (executor: user or CI, mandatory for task closure):
- scope: live DB (psql/Neon), HTTP server startup, curl to localhost, full orchestration gate
- timeout default: STAGE9_GATE_TIMEOUT_S=60 for single verifier; STAGE9_GATE_TIMEOUT_S=120 for benchmark
- timeout STAGE9_GATE_TIMEOUT_S=420 is reserved for explicit CI diagnostics only; never the default
- gate: user provides Layer 3 output as "What to send back for validation"

Layer 4 — Visual (executor: user, mandatory for every task touching HTML preview):
- scope: HTML section marker presence (grep, no browser), render_profile attribute check, manual browser open
- timeout: 5 seconds for HTML grep checks; browser open is instant
- tool: bash grep on HTML file + open file in browser (no Playwright required for Layer 4)
- gate: user confirms section checklist or provides screenshot as visual evidence

Child-script deduplication rule (permanent):
- a child script invoked by a lower-level gate must NOT be re-invoked by a higher-level gate in the same validation cycle
- the higher-level gate must consume the child gate's JSON output, not re-execute it
- duplicate child invocations within one validation cycle are a defect, not a safety measure


---

## 8.3 INTEGRATION TIMEOUT PROFILES (permanent)

STAGE9_GATE_TIMEOUT_S preset values — use the lowest sufficient profile:

  30  — DB contract check only (no server startup, no HTTP)
  60  — single verifier with server startup included (default for Manual Test blocks)
  120 — full benchmark with two sequential legs (fast + full)
  420 — legacy full-stack CI diagnostics only; explicitly labelled when used; never the default

When authoring Manual Test blocks in AI task responses:
- always export STAGE9_GATE_TIMEOUT_S before the first integration command
- default export value: 60
- benchmark evidence: 120
- never omit the export — unset timeout inherits the script default of 420


---

## 8.4 ANTI-LOOP EXECUTION POLICY (permanent)

Codex agent must follow these rules unconditionally to prevent infinite retry cycles:

IDENTICAL FAILURE RULE:
- if the same command produces the same error output on two consecutive runs → STOP
- do not retry without a code change that addresses the specific failure
- classify and report: {blocked: true, cause: "<unit_syntax|contract_shape|env_infra|timeout>", command: "<cmd>", output: "<first 200 chars>"}

TIMEOUT STOP RULE:
- Layer 1 commands: stop if > 3 seconds
- Layer 2 commands: stop if total > 10 seconds
- if a command exceeds its ceiling → classify as env_infra or timeout, mark check as "fail: timeout>{N}s", continue to next check

INFRA DEPENDENCY RULE:
- if a command requires psql, curl, HTTP server startup, or any live network call → do not run it
- mark as: "skipped: requires_live_infra — delegate to Layer 3 (user)"
- this is not a failure; it is correct routing

SCOPE BOUNDARY RULE:
- Codex modifies only files listed in the AI task's "Files to Create / Update" section
- if a Layer 1/2 check fails because a file outside scope has an issue → report it, do not fix it
- fixing out-of-scope files to make tests pass is a scope violation


---


═══════════════════════════════════════════════════════════════
FILE 2 — project_recovery/05_TESTING_RULES.txt
Append to the END of the file (after the last existing line)
═══════════════════════════════════════════════════════════════

Append exactly the following block:

- validation pyramid is mandatory (see AGENTS.md §8.2):
  - Layer 1 Unit: Codex, offline, bash syntax + CLI flags, < 3s per command
  - Layer 2 Contract: Codex, offline, jq fixtures + STAGE9_HYGIENE_SKIP=1, < 10s total
  - Layer 3 Integration: user/CI, live DB + HTTP, STAGE9_GATE_TIMEOUT_S=60 default
  - Layer 4 Visual: user, HTML grep + browser open, < 5s grep + instant browser
- codex acceptance gate = Layer 1 + Layer 2 only (offline, no live infrastructure)
- integration gate = Layer 3, executor = user, output sent back as validation evidence
- visual gate = Layer 4, executor = user, HTML section markers + manual browser confirm
- child script deduplication: no script may be invoked more than once per validation cycle; higher-level gates consume child output, not re-execute
- timeout profiles: 30s (DB only), 60s (with server, default), 120s (benchmark), 420s (CI explicit only)
- anti-loop rule: identical failure × 2 = stop and classify, never retry without a code change addressing the failure
- STAGE9_GATE_TIMEOUT_S must be explicitly exported before every Manual Test integration block; default export value = 60


═══════════════════════════════════════════════════════════════
FILE 3 — project_recovery/11_RESPONSE_FORMAT_RULES.txt
Append to the END of the file (after the last existing line)
═══════════════════════════════════════════════════════════════

Append exactly the following block:

Visual Validation Rule (Layer 4, mandatory for every UI task):
- every AI task that creates or modifies HTML preview content must include a dedicated Visual Validation block in Manual Test
- Visual Validation block must contain two sub-steps:

  Sub-step A — HTML structure check (Codex-safe, < 5 seconds, no browser):
    grep -q 'render_profile="<expected>"' <output_dir>/index.html
    grep -q 'data-section="<section>"' <output_dir>/index.html  [repeat for each expected section]

  Sub-step B — Manual browser open (user, instant):
    open <output_dir>/index.html
    OR: python3 -m http.server <port> --directory <output_dir> & ; open http://localhost:<port>

- Visual evidence to send back: screenshot OR confirmed checklist of visible sections
- Visual validation is a separate evidence block; it does not replace Layer 3 integration evidence
- Playwright is optional for Layer 4; HTML grep + browser open is sufficient and always preferred
- Visual Validation block must appear as the last sub-section of Manual Test, clearly labelled "### Visual (Layer 4)"

Codex Acceptance Gate block (mandatory in every AI task response):
- every AI task response must include an explicit "Codex Acceptance Gate" block
- this block contains only Layer 1 + Layer 2 commands
- each command must include an expected exit code or expected output
- the block must be labelled "### Codex Acceptance Gate (offline, Layer 1+2)"
- commands in this block must not require live DB, HTTP server, or network
- maximum 7 commands per gate block; each must complete in < 10 seconds


═══════════════════════════════════════════════════════════════
FILE 4 — ai_tasks/000_ai_task_template.md
Replace the entire file content with the expanded template below.
(The existing template is a stub — this is its full expansion.
All original placeholder fields are preserved exactly.)
═══════════════════════════════════════════════════════════════

Replace the full file content with:

# AI Task XXX — {{TASK_NAME}}

## Stage
{{STAGE}}

## Substage
{{SUBSTAGE}}

## Goal
{{GOAL}}

## Why This Matters
{{WHY_THIS_TASK_EXISTS}}

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- {{REQ_ID_1}}

## Files to Create / Update
Create:
- {{FILE_TO_CREATE_1}}

Update:
- {{FILE_TO_UPDATE_1}}

## Requirements
- {{REQUIREMENT_1}}

## Acceptance Criteria
- {{CRITERIA_1}}
- {{CRITERIA_2}}
- {{CRITERIA_3}}

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration: < 10 seconds total. No DB. No HTTP. No network.
Required env: STAGE9_HYGIENE_SKIP=1 (for any script with hygiene preflight)

```bash
# Layer 1 — Unit (syntax + CLI contract)
bash -n {{PRIMARY_SCRIPT}}
bash {{PRIMARY_SCRIPT}} --help 2>&1 | grep -q "{{HELP_KEYWORD}}"
bash {{PRIMARY_SCRIPT}} 2>/dev/null; [ $? -eq 2 ]
bash {{PRIMARY_SCRIPT}} --mode bogus 2>/dev/null; [ $? -ne 0 ]

# Layer 2 — Contract (JSON shape, offline fixtures)
# STAGE9_HYGIENE_SKIP=1 bash {{PRIMARY_SCRIPT}} | jq -e '.status'
# jq -e '{{SHAPE_CHECK}}' code/test_fixtures/{{FIXTURE_FILE}}
```
Expected: all commands exit 0 or expected non-zero as noted above.

### Integration Gate (Layer 3)
Executor: user. Duration: ~60 seconds. Requires live DB + running stack.

```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

# Step 1: port cleanup
lsof -t -i:8787 | xargs kill 2>/dev/null || true

# Step 2: {{INTEGRATION_STEP_DESCRIPTION}}
{{INTEGRATION_COMMAND}}
```
Expected: {{INTEGRATION_EXPECTED_OUTPUT}}

### Visual (Layer 4)
Executor: user. Applies only when task touches HTML preview.

```bash
# A. HTML structure check (< 5 seconds, no browser)
grep -q 'render_profile="{{EXPECTED_RENDER_PROFILE}}"' /tmp/contextviewer_ui_preview/index.html
grep -q 'data-section="overview"' /tmp/contextviewer_ui_preview/index.html
grep -q 'data-section="{{EXPECTED_SECTION}}"' /tmp/contextviewer_ui_preview/index.html

# B. Open in browser
open /tmp/contextviewer_ui_preview/index.html
```
Send back: screenshot OR confirm:
- [ ] render_profile = "{{EXPECTED_RENDER_PROFILE}}"
- [ ] {{EXPECTED_SECTION}} section is visible
- [ ] No layout breakage visible

## What to send back for validation
- Layer 1+2: Codex gate output (pass/fail per command)
- Layer 3: JSON output of {{PRIMARY_INTEGRATION_SCRIPT}} (status field + blockers array)
- Layer 4 (if UI task): screenshot or confirmed checklist


═══════════════════════════════════════════════════════════════
VALIDATION — Codex self-check after all edits (offline, < 30s total)
═══════════════════════════════════════════════════════════════

Run these commands in order. Report pass/fail for each.

```bash
# 1. AGENTS.md contains new sections (< 1s)
grep -q "8.2 VALIDATION LAYER POLICY" AGENTS.md
grep -q "8.3 INTEGRATION TIMEOUT PROFILES" AGENTS.md
grep -q "8.4 ANTI-LOOP EXECUTION POLICY" AGENTS.md

# 2. Existing AGENTS.md sections are intact (< 1s)
grep -q "8.1 CONTEXT RESTORE POLICY" AGENTS.md
grep -q "FAST RESTORE" AGENTS.md
grep -q "MISSION" AGENTS.md
grep -q "SOURCE PRIORITY" AGENTS.md

# 3. Testing rules updated (< 1s)
grep -q "validation pyramid is mandatory" project_recovery/05_TESTING_RULES.txt
grep -q "anti-loop rule" project_recovery/05_TESTING_RULES.txt

# 4. Original testing rules intact (< 1s)
grep -q "fast smoke mode is mandatory" project_recovery/05_TESTING_RULES.txt
grep -q "validation profile lock is mandatory" project_recovery/05_TESTING_RULES.txt

# 5. Response format rules updated (< 1s)
grep -q "Visual Validation Rule" project_recovery/11_RESPONSE_FORMAT_RULES.txt
grep -q "Codex Acceptance Gate block" project_recovery/11_RESPONSE_FORMAT_RULES.txt

# 6. Original response format rules intact (< 1s)
grep -q "Fast smoke execution policy" project_recovery/11_RESPONSE_FORMAT_RULES.txt
grep -q "Anti-hang test-instruction policy" project_recovery/11_RESPONSE_FORMAT_RULES.txt

# 7. Task template updated (< 1s)
grep -q "Codex Acceptance Gate" ai_tasks/000_ai_task_template.md
grep -q "Layer 1" ai_tasks/000_ai_task_template.md
grep -q "Visual (Layer 4)" ai_tasks/000_ai_task_template.md

# 8. Task template original placeholders intact (< 1s)
grep -q "TASK_NAME" ai_tasks/000_ai_task_template.md
grep -q "Files to Create / Update" ai_tasks/000_ai_task_template.md
grep -q "Acceptance Criteria" ai_tasks/000_ai_task_template.md

# 9. No code files were modified (< 1s)
git diff --name-only | grep -v "^AGENTS.md$" | grep -v "^project_recovery/" | grep -v "^ai_tasks/000" | grep "^code/" && echo "VIOLATION: code file modified" || echo "scope clean"

# 10. No plan files were modified (< 1s)
git diff --name-only | grep "^docs/" && echo "VIOLATION: docs file modified" || echo "docs clean"
```

All 10 checks must pass. Report format:
{
  "check_1_new_sections": "pass|fail",
  "check_2_existing_intact": "pass|fail",
  "check_3_testing_updated": "pass|fail",
  "check_4_testing_intact": "pass|fail",
  "check_5_response_updated": "pass|fail",
  "check_6_response_intact": "pass|fail",
  "check_7_template_updated": "pass|fail",
  "check_8_template_intact": "pass|fail",
  "check_9_no_code_modified": "pass|fail",
  "check_10_no_docs_modified": "pass|fail",
  "overall": "pass|fail"
}

If overall = pass: commit with message:
  "arch: add validation pyramid, anti-loop policy, and visual validation layer to OS rules"

If any check = fail: report the failed check, do not commit, do not retry other files.

═══════════════════════════════════════════════════════════════
WHAT TO SEND BACK
═══════════════════════════════════════════════════════════════

Send back:
1. The JSON check report above (all 10 checks with pass/fail)
2. The git diff --stat output (should show exactly 4 files changed)
3. The commit hash
````
