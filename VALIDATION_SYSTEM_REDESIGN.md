# Системный рефакторинг валидации ContextViewer
## Постоянное решение проблемы медленных тестов и зацикливания Codex

---

## 0. Диагноз — почему система сломана системно

Текущая архитектура валидации построена как **глубокая матрёшка последовательных вызовов без слоёв изоляции**:

```
benchmark (334 ln)
  ↳ hygiene ×3
  ↳ completion_gate_report (613 ln) ×2
       ↳ hygiene
       ↳ diff_verify (186 ln)
       ↳ settings_verify (186 ln)
       ↳ readiness_report (495 ln)
            ↳ delivery (381 ln)
                 ↳ server (225 ln)
                 ↳ bootstrap_preview (2204 ln!)
            ↳ bootstrap_contracts (278 ln)
       ↳ handoff_bundle (382 ln)
       ↳ secondary_gate (429 ln)
            ↳ [те же дочерние снова]
```

**Структурные причины:**

| Проблема | Следствие |
|---|---|
| Нет уровней изоляции (unit / contract / integration) | Любой тест = full-stack вызов |
| child_timeout_s=420 по умолчанию | Worst-case одного прогона = 42+ мин |
| Каждый уровень снова вызывает тех же детей | Дублирование: одна delivery smoke запускается 3–4 раза |
| Тест требует живую DB, HTTP, network | Codex физически не может пройти тест |
| Отсутствует слой визуальной валидации | Для UI задач нет быстрого снимка состояния |
| Acceptance criteria не сегрегированы по среде | Codex пытается выполнить production-integration test |

---

## 1. Новая архитектура: Validation Pyramid

Вся валидация разбивается на **четыре независимых слоя**. Каждый вышестоящий слой вызывает нижние через явный контракт, а не переопределяет их логику.

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 4: VISUAL (screenshot / HTML diff / open-in-browser)  │
│  Кто запускает: пользователь вручную, не Codex               │
│  Время: мгновенно (просмотр) или ~5s (скриншот)             │
├─────────────────────────────────────────────────────────────┤
│  Layer 3: INTEGRATION (live DB + HTTP server + curl)         │
│  Кто запускает: пользователь, CI, не Codex                   │
│  Время: 30–120 секунд                                        │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: CONTRACT (jq + JSON fixtures + script CLI)         │
│  Кто запускает: Codex, CI, пользователь                      │
│  Время: < 10 секунд                                          │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: UNIT (bash -n syntax + --help + --bad-args)        │
│  Кто запускает: Codex автоматически после каждого файла      │
│  Время: < 3 секунды                                          │
└─────────────────────────────────────────────────────────────┘
```

**Правило:** Codex закрывает задачу только по Layer 1 + Layer 2. Layer 3 + Layer 4 — validation evidence, которое предоставляет пользователь.

---

## 2. Слой 1 (Unit) — обязателен для каждой задачи Codex

Минимальный тест, который запускается в изолированной среде за < 3 секунд:

```bash
# Стандартный блок для любого нового .sh-файла
bash -n code/ui/новый_скрипт.sh                          # синтаксис
bash code/ui/новый_скрипт.sh --help | grep -q "Usage"   # help текст
bash code/ui/новый_скрипт.sh 2>/dev/null; [ $? -eq 2 ]  # missing required arg
bash code/ui/новый_скрипт.sh --mode bogus 2>/dev/null; [ $? -eq 2 ]  # invalid mode
bash code/ui/новый_скрипт.sh --port -1 2>/dev/null; [ $? -ne 0 ]     # invalid port
```

**Добавить в AGENTS.md §8 (Execution Rules):**
```markdown
- every new shell script must pass Layer-1 unit gate before Codex marks task complete:
  - bash -n (syntax check)
  - --help exits 0 and prints usage
  - missing required arg exits 2
  - invalid flag value exits 1 or 2
  - Layer-1 gate timeout: 3 seconds per command
```

---

## 3. Слой 2 (Contract) — JSON-fixture validation

### 3.1. Создать `code/test_fixtures/`

Каталог статичных JSON-эталонов, которые представляют **канонические выходные данные** каждого верификатора:

```
code/test_fixtures/
  hygiene_ok.json
  hygiene_port_blocked.json
  diff_verify_pass.json
  diff_verify_fail_no_data.json
  settings_verify_pass.json
  readiness_ready.json
  readiness_not_ready.json
  completion_report_ready.json
  completion_report_not_ready.json
  benchmark_pass.json
  benchmark_env_blocked.json
```

**Что это даёт:** Codex может валидировать jq-парсинг, blocker classification, JSON shape — без DB, без HTTP, без ожиданий.

### 3.2. Стандартный Contract Test Block (< 10 секунд):

```bash
# Проверка JSON shape без инфраструктуры
jq -e '.status' code/test_fixtures/completion_report_ready.json
jq -e '.status == "ready_for_stage_transition"' code/test_fixtures/completion_report_ready.json
jq -e '.transition_readiness.closure_evidence_complete == true' code/test_fixtures/completion_report_ready.json
jq -e '.fast_seconds < .full_seconds' code/test_fixtures/benchmark_pass.json

# Проверка что скрипты корректно разбирают эти fixture
bash code/ui/verify_stage9_completion_gate.sh --project-id 1 \
  --invalid-project-id abc STAGE9_HYGIENE_SKIP=1 2>/dev/null | jq -e '.checks | length > 0'
```

### 3.3. Новое правило в AI Task Template:

```markdown
## Contract Validation (Layer 2, Codex-safe)
Duration: < 10 seconds total
Environment: offline (no DB, no HTTP)
Required env: STAGE9_HYGIENE_SKIP=1
Fixtures: code/test_fixtures/*.json

[конкретные jq команды по fixture]
```

---

## 4. Слой 3 (Integration) — сжатые тесты для пользователя

**Проблема текущего Layer 3:** 420-секундный timeout на каждый дочерний процесс — избыточно. Реальная production latency DB-запросов = 1–5 секунд. HTTP-сервер стартует за < 2 секунды.

### 4.1. Новые timeout-пресеты:

```bash
# Заменить STAGE9_GATE_TIMEOUT_S=420 на профили:
export STAGE9_GATE_TIMEOUT_S=30   # routine integration (db query + curl)
export STAGE9_GATE_TIMEOUT_S=60   # server startup included
export STAGE9_GATE_TIMEOUT_S=120  # full benchmark with two legs
# 420 — только для explicit debug/CI mode
```

**Добавить в AGENTS.md §8.3:**
```markdown
## 8.3 INTEGRATION TIMEOUT PROFILES

STAGE9_GATE_TIMEOUT_S preset values:
- 30  — DB contract check (no server startup)
- 60  — single verifier with server startup
- 120 — full benchmark (two modes, sequential)
- 420 — legacy full, CI-only, never default

Default for Manual Test blocks: 60
Default for benchmark evidence: 120
Default for Codex Layer-1/2: not applicable (offline)
```

### 4.2. Убрать дублирование дочерних вызовов

**Текущая проблема:** `verify_stage9_secondary_flows_readiness_gate.sh` уже вызывает diff_verify + settings_verify + readiness + delivery + handoff. Затем `get_stage9_completion_gate_report.sh` вызывает ВСЁ ЭТО СНОВА плюс secondary_gate сверху.

**Правило с этого момента:**
```markdown
Orchestration rule (add to AGENTS.md §8):
- top-level gate MUST NOT re-invoke child scripts that are already
  invoked by a lower-level gate in the same validation chain
- instead: pass the child gate's JSON output as a parameter or read
  it from a temp file (single execution per validation cycle)
- duplicate child invocations in one cycle are a defect, not a safety measure
```

### 4.3. Стандартный Integration Test Block для Manual Test:

```bash
# ===== INTEGRATION TEST (пользователь, ~60 секунд) =====
# Предусловие: проверить что порт свободен
lsof -i :8787 | grep LISTEN && kill $(lsof -t -i:8787) || true

# Шаг 1: Hygiene (< 5s)
bash code/ui/ensure_stage9_validation_runtime_hygiene.sh --port 8787 | jq -e '.status == "ok"'

# Шаг 2: Contract smokes (< 15s)
STAGE9_GATE_TIMEOUT_S=15 bash code/diff/verify_stage9_diff_viewer_contracts.sh \
  --project-id $PROJECT_ID | jq -e '.status == "pass"'

# Шаг 3: Completion gate fast (< 30s)
STAGE9_GATE_TIMEOUT_S=30 bash code/ui/get_stage9_completion_gate_report.sh \
  --mode fast --project-id $PROJECT_ID | jq '{status, failed:.transition_readiness.blockers|length}'

# Шаг 4: Benchmark (< 120s)
STAGE9_GATE_TIMEOUT_S=120 bash code/ui/run_stage9_validation_runtime_benchmark.sh \
  --project-id $PROJECT_ID --fast-port 8787 --full-port 8788
```

Итого для пользователя: **4 команды, ~2 минуты**, вместо одного benchmark-монстра на 40+ минут.

---

## 5. Слой 4 (Visual) — новый постоянный слой

Для проекта ContextViewer, который **генерирует HTML-preview**, визуальная валидация должна быть частью системы, а не опциональным шагом.

### 5.1. Visual checkpoint script (создать один раз)

Создать `code/ui/capture_visual_checkpoint.sh`:

```bash
#!/usr/bin/env bash
# Сохраняет снимок текущего состояния preview для визуальной валидации.
# Выводы: HTML diff, screenshot-placeholder, HTML structural markers.
# Не требует браузера. Работает на основе HTML-файла.
# Usage: bash code/ui/capture_visual_checkpoint.sh --output-dir /tmp/cv_preview --task-id 091

# 1. Проверить наличие HTML-файла в output-dir
# 2. Извлечь render_profile из data-cv-* атрибутов
# 3. Извлечь все section markers (data-section, data-surface, data-cv-*)
# 4. Проверить наличие ожидаемых HTML-блоков
# 5. Вывести JSON с visual_snapshot: {render_profile, sections[], markers[], file_size_bytes}
# 6. Опционально: сохранить HTML snapshot в /tmp/cv_snapshots/task_<id>_<timestamp>.html
```

**Что это даёт:**
- Codex может проверить HTML-структуру без браузера
- Пользователь получает явный список section markers для ручной проверки
- Каждая задача оставляет артефакт `task_<id>_<timestamp>.html` для сравнения

### 5.2. Стандартный Visual Test Block (добавить к каждой UI задаче):

```markdown
## Visual Validation (Layer 4)

### Codex-safe HTML structure check (< 5s, no browser):
```bash
# Проверить render_profile в HTML
grep -q 'render_profile="<expected_profile>"' /tmp/contextviewer_ui_preview/index.html

# Проверить section markers
grep -q 'data-section="overview"' /tmp/contextviewer_ui_preview/index.html
grep -q 'data-section="visualization"' /tmp/contextviewer_ui_preview/index.html
grep -q 'data-section="history"' /tmp/contextviewer_ui_preview/index.html
grep -q 'data-section="diff-viewer"' /tmp/contextviewer_ui_preview/index.html
grep -q 'data-section="settings"' /tmp/contextviewer_ui_preview/index.html

# Visual snapshot JSON
bash code/ui/capture_visual_checkpoint.sh --output-dir /tmp/contextviewer_ui_preview --task-id <N>
```

### User manual visual check (open browser):
```bash
open /tmp/contextviewer_ui_preview/index.html
# ИЛИ
python3 -m http.server 8787 --directory /tmp/contextviewer_ui_preview &
open http://localhost:8787
```

**What to send back:** screenshot или confirm:
- [ ] Шапка и навигация отображаются
- [ ] Раздел Overview видим с данными
- [ ] Diff Viewer раздел видим (empty state ИЛИ comparison)
- [ ] Settings раздел видим
- [ ] render_profile в title или в HTML-коменте соответствует задаче
```

### 5.3. Добавить в AGENTS.md §11 (Response Format Rules):

```markdown
## Visual Validation Rule (mandatory for UI tasks):

For every task that modifies or creates HTML preview content:
1. Codex-safe HTML structure check (bash grep on HTML file, no browser, < 5s):
   - render_profile attribute match
   - all expected section markers present
2. Visual snapshot capture (capture_visual_checkpoint.sh, < 5s):
   - JSON output with sections, markers, file_size
3. User manual browser check (open file locally):
   - explicit list of what to confirm visually
   - what to send back as evidence (screenshot or checklist)

Visual validation is a separate evidence block from contract/integration evidence.
It must appear as a distinct section in Manual Test instructions.
```

---

## 6. Реструктуризация промтов для Codex

### 6.1. Новый шаблон AI Task (обязательные секции)

Добавить в `ai_tasks/000_ai_task_template.md`:

```markdown
## Validation Profile
- Layer 1 (Unit, Codex): syntax + CLI flags — < 3s each
- Layer 2 (Contract, Codex): jq fixtures + skip-flags — < 10s total
- Layer 3 (Integration, User): live DB + HTTP — < 60s total, STAGE9_GATE_TIMEOUT_S=60
- Layer 4 (Visual, User): HTML markers + browser — < 5s check + manual review

## Codex Acceptance Gate (Layers 1+2 only)
[exact commands, max 5, each < 10s, no live DB, no HTTP server]

## Manual Test — Integration (Layer 3)
STAGE9_GATE_TIMEOUT_S=<30|60|120>
[exact commands with timeout export]

## Manual Test — Visual (Layer 4)
[grep checks on HTML + open browser instructions + what to send back]
```

### 6.2. Cursor Prompt Anti-Loop Block (добавить в начало каждого Cursor prompt)

```markdown
## EXECUTION CONSTRAINTS (read first)
Environment: Codex (offline, no DB, no HTTP)
Timeout per command: 10s max
Stop condition: if a command takes > 10s or fails identically twice → STOP, report error, do not retry

Forbidden in this session:
- psql / DB connections
- curl to localhost or external URLs
- python3 -m http.server startup
- any command requiring STAGE9_GATE_TIMEOUT_S > 30

Allowed:
- bash -n (syntax)
- bash script --help
- bash script --bad-arg 2>/dev/null; echo $?
- jq < code/test_fixtures/*.json
- STAGE9_HYGIENE_SKIP=1 bash script
- grep / awk / sed on local files
```

### 6.3. Anti-Loop Rule (постоянное правило в AGENTS.md §8)

```markdown
## 8.4 ANTI-LOOP EXECUTION POLICY

Codex agent must follow these rules to prevent infinite retry cycles:

1. IDENTICAL FAILURE RULE:
   If the same command fails with the same error output twice in a row:
   → STOP. Do not retry.
   → Classify failure: unit_syntax | contract_shape | env_infra | timeout
   → Output: {blocked: true, cause: "<class>", command: "<cmd>", output: "<first 200 chars>"}

2. TIMEOUT STOP RULE:
   If any command exceeds 10 seconds (Codex context):
   → STOP. Do not wait.
   → Classify as: env_infra or timeout
   → Mark check as "fail" with details "timeout>10s, classified as env_infra"
   → Continue with next check

3. INFRA DEPENDENCY RULE:
   If a command requires psql, curl, HTTP server startup, or live network:
   → Do not run it.
   → Mark as "skipped: requires_live_infra"
   → Note: "manual integration test required"

4. SCOPE BOUNDARY RULE:
   Codex modifies ONLY files listed in "Files to Create / Update".
   Codex does NOT modify files to make tests pass unless the file is in scope.
   If a test fails because a file outside scope is wrong → report it, do not fix it.
```

---

## 7. Реструктуризация Manual Test секций

**Текущая проблема:** Manual Test = один монолитный блок из 5–10 команд, все требуют live DB, всё занимает 10–20 минут.

**Новый стандарт — три явных подблока:**

```markdown
## Manual Test (exact commands)

### A. Unit Gate (Codex ran this — confirm matches)
```bash
# Все эти команды Codex уже выполнил. Вы можете проверить или пропустить.
bash -n code/ui/<file>.sh
STAGE9_HYGIENE_SKIP=1 bash code/ui/<file>.sh | jq -e '.status'
```
Expected: exit 0, valid JSON

### B. Integration Gate (вы запускаете, ~60 секунд)
```bash
export PROJECT_ID=<ваш id>
export STAGE9_GATE_TIMEOUT_S=60

# 1. Port cleanup
lsof -t -i:8787 | xargs kill 2>/dev/null || true

# 2. Hygiene check
bash code/ui/ensure_stage9_validation_runtime_hygiene.sh --port 8787 | jq .status

# 3. Primary check
bash code/ui/get_stage9_completion_gate_report.sh \
  --mode fast --project-id $PROJECT_ID --port 8787 | jq '{status, blockers:.transition_readiness.blockers}'
```
Expected: status="ready_for_stage_transition", blockers=[]

### C. Visual Gate (вы смотрите, ~1 минута)
```bash
open /tmp/contextviewer_ui_preview/index.html
```
Send back: screenshot + confirm checkboxes:
- [ ] render_profile = "<expected>"
- [ ] Overview section visible
- [ ] Diff Viewer section visible
- [ ] Settings section visible
```

---

## 8. Изменения в архитектурных файлах — что именно добавить

### 8.1. AGENTS.md — новые постоянные разделы

Добавить секцию **§8.2 VALIDATION LAYER POLICY** (после существующего §8):

```markdown
## 8.2 VALIDATION LAYER POLICY (permanent)

Four validation layers. Each layer is independent. Higher layers do not replace lower ones.

Layer 1 — Unit (Codex, mandatory):
  scope: syntax, CLI contract, flag validation
  timeout: 3s per command
  env: offline, no DB, no HTTP
  gate: must pass before Codex marks task complete

Layer 2 — Contract (Codex, mandatory):
  scope: JSON shape, jq parsing, fixture-based contract checks
  timeout: 10s total
  env: offline, no DB, no HTTP
  fixtures: code/test_fixtures/*.json
  gate: must pass before Codex marks task complete
  required env flag: STAGE9_HYGIENE_SKIP=1

Layer 3 — Integration (User/CI, mandatory for closure):
  scope: live DB, HTTP server, curl, full orchestration
  timeout: STAGE9_GATE_TIMEOUT_S=60 (default), max 120 for benchmark
  never 420 unless explicitly forced for CI diagnostics
  gate: user provides output as "What to send back for validation"

Layer 4 — Visual (User, mandatory for UI tasks):
  scope: HTML markers, browser render, render_profile, section visibility
  tool: capture_visual_checkpoint.sh (HTML grep, < 5s) + manual browser open
  gate: user provides screenshot or confirmed checklist
  note: Layer-4 is independent of Layer-3 — can pass even if integration is degraded

No layer can be substituted for another.
No layer can be skipped for its designated executor.
```

### 8.2. project_recovery/05_TESTING_RULES.txt — добавить:

```
- validation pyramid is mandatory: unit → contract → integration → visual
- codex acceptance gate = layer 1 + layer 2 only (offline, no infra)
- integration gate = layer 3, executor = user, timeout = STAGE9_GATE_TIMEOUT_S=60 default
- visual gate = layer 4, executor = user, HTML marker check + manual browser open
- child script deduplication: no script may be called more than once per validation cycle
- timeout profile: 30s (db-only), 60s (with server), 120s (benchmark), 420s (CI/explicit only)
- anti-loop: identical failure × 2 = stop + classify, never retry without code change
```

### 8.3. Создать `code/test_fixtures/` — отдельная AI задача

Выделить это в **AI Task 092** с четкими offline acceptance criteria:

```markdown
## AI Task 092 — Test Fixtures Layer (Offline Contract Validation)

Goal: создать code/test_fixtures/ с эталонными JSON для каждого Stage 9 верификатора.

Files to Create:
- code/test_fixtures/README.md
- code/test_fixtures/hygiene_ok.json
- code/test_fixtures/completion_report_ready.json
- code/test_fixtures/completion_report_not_ready.json
- code/test_fixtures/benchmark_pass.json
- code/test_fixtures/benchmark_env_blocked.json

Codex Acceptance Gate (Layer 1+2, < 15 seconds total):
  jq -e '.status == "ok"' code/test_fixtures/hygiene_ok.json
  jq -e '.status == "ready_for_stage_transition"' code/test_fixtures/completion_report_ready.json
  jq -e '.transition_readiness.closure_evidence_complete == true' code/test_fixtures/completion_report_ready.json
  jq -e '.fast_seconds | type == "number"' code/test_fixtures/benchmark_pass.json
  jq -e '.blocker_class == "env_network"' code/test_fixtures/benchmark_env_blocked.json

No integration tests required for this task.
```

---

## 9. Visual Validation Script — `capture_visual_checkpoint.sh`

Создать отдельной AI задачей (093):

```markdown
## AI Task 093 — Visual Checkpoint Capture Script

Goal: создать code/ui/capture_visual_checkpoint.sh для offline HTML-валидации preview.

Requirements:
- читает HTML из --output-dir
- извлекает render_profile из data-cv-* / meta тегов / HTML комментов
- проверяет наличие data-section="overview|visualization|history|diff-viewer|settings"
- выводит JSON: {render_profile, sections_found[], missing_sections[], markers_count, file_size_bytes, status}
- status: "pass" если все expected sections найдены, "fail" если нет
- принимает --expected-sections для Codex-override нужного набора

Codex Acceptance Gate (Layer 1+2):
  bash -n code/ui/capture_visual_checkpoint.sh
  bash code/ui/capture_visual_checkpoint.sh --help | grep -q "render_profile"
  bash code/ui/capture_visual_checkpoint.sh 2>/dev/null; [ $? -eq 2 ]  # missing --output-dir
  echo '<div data-section="overview"></div>' > /tmp/test_cv.html
  bash code/ui/capture_visual_checkpoint.sh --output-dir /tmp --html-file /tmp/test_cv.html \
    --expected-sections overview | jq -e '.sections_found | contains(["overview"])'
  rm /tmp/test_cv.html
```

---

## 10. Сводная таблица изменений

| Что | Где | Тип | Приоритет |
|---|---|---|---|
| §8.2 Validation Layer Policy | AGENTS.md | Постоянное правило | Немедленно |
| §8.3 Integration Timeout Profiles | AGENTS.md | Постоянное правило | Немедленно |
| §8.4 Anti-Loop Execution Policy | AGENTS.md | Постоянное правило | Немедленно |
| Validation pyramid rule | 05_TESTING_RULES.txt | Постоянное правило | Немедленно |
| Layer 4 Visual rule | 11_RESPONSE_FORMAT_RULES.txt | Постоянное правило | Немедленно |
| Codex validation profile секция | AI Task template (000) | Шаблон | Немедленно |
| Child deduplication rule | AGENTS.md §8 | Постоянное правило | Немедленно |
| code/test_fixtures/ | AI Task 092 | Новый код | Следующая задача |
| capture_visual_checkpoint.sh | AI Task 093 | Новый код | После 092 |
| STAGE9_GATE_TIMEOUT_S defaults (30/60/120) | Все gate-скрипты | Рефактор | Параллельно 092 |
| Cursor Prompt EXECUTION CONSTRAINTS block | Шаблон промта | Шаблон | Немедленно |

---

## 11. Промты для немедленного использования

### Промт для Codex — закрыть текущий тупик (Task 091):

```
Context: AI Task 091 in project ContextViewer-1, Stage 9.
Scripts ensure_stage9_validation_runtime_hygiene.sh and run_stage9_validation_runtime_benchmark.sh
already exist in code/ui/.

EXECUTION CONSTRAINTS:
- Offline environment: no DB, no HTTP, no network
- Max timeout: 10 seconds per command
- If a command takes > 10s: STOP and classify as env_infra skip

Your task: verify Task 091 is complete by running Layer 1 + Layer 2 checks only.

Layer 1 checks (run all, report pass/fail):
  bash -n code/ui/ensure_stage9_validation_runtime_hygiene.sh
  bash -n code/ui/run_stage9_validation_runtime_benchmark.sh
  bash code/ui/ensure_stage9_validation_runtime_hygiene.sh --help 2>&1 | grep -qi "clean"
  bash code/ui/run_stage9_validation_runtime_benchmark.sh --help 2>&1 | grep -qi "benchmark"
  bash code/ui/run_stage9_validation_runtime_benchmark.sh 2>/dev/null; echo "exit:$?"
  bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id abc 2>/dev/null; echo "exit:$?"
  bash code/ui/ensure_stage9_validation_runtime_hygiene.sh --port -1 2>/dev/null; echo "exit:$?"

Layer 2 checks (STAGE9_HYGIENE_SKIP=1, no network):
  STAGE9_HYGIENE_SKIP=1 bash code/ui/ensure_stage9_validation_runtime_hygiene.sh \
    --port 9999 | jq -e '.status == "ok"'

If all Layer 1+2 checks pass → mark Task 091 Codex gate PASS.
Report: {layer1_passed: N, layer2_passed: N, skipped_infra: ["benchmark live run"]}

Do NOT run: actual benchmark with real project-id, psql, curl, HTTP server.
```

### Промт для Codex — создать test fixtures (Task 092):

```
Context: AI Task 092, project ContextViewer-1.
Create code/test_fixtures/ directory with static JSON fixture files.
Each file represents a canonical output of one Stage 9 verifier script.

Files to create (derive schema from existing scripts):
1. code/test_fixtures/README.md — list of fixtures and their purpose
2. code/test_fixtures/hygiene_ok.json
   Schema: {status:"ok", generated_at:"...", ports_checked:[8787], cleaned_processes:[],
            port_listeners:[], foreign_listeners:[], checks:[{name:"hygiene_ok",status:"pass"}]}
3. code/test_fixtures/completion_report_ready.json
   Schema: derive from get_stage9_completion_gate_report.sh output shape (lines 510-606)
   status must be "ready_for_stage_transition", all consistency_checks true
4. code/test_fixtures/completion_report_not_ready.json
   status: "not_ready", one blocker in transition_readiness.blockers
5. code/test_fixtures/benchmark_pass.json
   Schema: {status:"pass", project_id:1, fast_seconds:2.1, full_seconds:8.4,
            speedup_ratio:4.0, checks:[...], failed_checks:0, blocker_class:null}
6. code/test_fixtures/benchmark_env_blocked.json
   status:"fail", blocker_class:"env_network"

Codex Acceptance Gate (offline, < 15 seconds):
  jq -e '.status == "ok"' code/test_fixtures/hygiene_ok.json
  jq -e '.status == "ready_for_stage_transition"' code/test_fixtures/completion_report_ready.json
  jq -e '.transition_readiness.closure_evidence_complete == true' code/test_fixtures/completion_report_ready.json
  jq -e '.status == "not_ready"' code/test_fixtures/completion_report_not_ready.json
  jq -e '.fast_seconds < .full_seconds' code/test_fixtures/benchmark_pass.json
  jq -e '.blocker_class == "env_network"' code/test_fixtures/benchmark_env_blocked.json

No integration tests. No network. No DB.
```
