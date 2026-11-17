# Stage 12A — Codex transport diagnostics and global Skills activation

Дата проверки: 2026-11-17. Итоговый статус: `PARTIAL / BLOCKED_EXTERNAL`.

Структурная установка отдельно подтверждена как `INSTALL_VERIFIED`. Реальная
активация шести целевых Skills через HTTPS fallback получила bounded
positive/negative evidence. Полный `COMPLETE` не выставлен: WebSocket 403 не
устранён, а историческое изменение `~/.codex/skills/.system` оставляет
`FULL_NO_TOUCH_GATE = BLOCKED`.

## Source и состояние глобальной установки

- Репозиторий: `workflow-for-agents`, ветка `main`.
- Source SHA: `53f328416998b13970025f4cf3604a32d4745837`.
- GitHub Actions run `43917886110`: `Success` для этого SHA.
- WFA manifest: `VALID`; legacy CEOS manifest: `ABSENT`.
- До Stage 11: 29 implemented, 2 `CURRENT`, 27 отсутствовали.
- После Stage 11 и в финальном Stage 12A preflight: 29 implemented, 29
  `CURRENT`, 0 отсутствуют.
- Повторная установка Skills в Stage 12/12A не выполнялась.
- Финальный preflight: `Ready = true`, `Blocked = false`, `FilesChanged = false`;
  pending install/sync transactions отсутствуют.
- Независимый source/target SHA audit: 29/29, `0` mismatches.
- `git-workflow` и `root-cause-debugging` сохранены без изменения содержимого.

Evidence находится вне репозитория:
`D:\WFA-backups\stage12-20261117-082424`.

## Root cause локального DENY

### Наблюдаемые факты

В Stage 11 trace отказ записан как:

```text
codex_core::tools::router: error=exec_command failed:
CreateProcess { message: "Rejected(...pwsh.exe ... ) rejected: blocked by policy" }
```

Отклонённые дочерние команды не запускались. Первая пыталась прочитать
глобальный `git-workflow/SKILL.md`, вторая — выполнить read-only Git inventory в
disposable fixture. Решение `DENY` принял не PowerShell, не WFA installer и не
внешний `exec_command` вызывающей оболочки, а локальный Codex CLI tool router
до создания процесса `pwsh.exe`.

Проблемный invocation был:

```text
codex exec --ephemeral --ignore-user-config --sandbox read-only --json
```

Он не загружал пользовательский Codex config и оставлял read-only sandbox без
доступа к внешнему относительно workspace каталогу глобальных Skills.
Попытка добавить `-c 'sandbox_permissions=["disk-full-read-access"]'` дала новое
доказательство: CLI 0.167.2 сам сообщил `sandbox_permissions is ignored` как
неизвестную настройку. Это не было разрешением и не обходило policy.

Контрольный запуск без `--ignore-user-config`, но с тем же явным
`--sandbox read-only`, прочитал полный глобальный Skill и выполнил безопасные
Git-команды в disposable repository. Поэтому установленная первопричина
локального DENY — policy stack самого Codex CLI, вызванный способом запуска
eval harness (`--ignore-user-config` + строгий read-only boundary), а не файл
Skill и не WFA-код. Наиболее сильная локальная корреляция — загруженный
пользовательский Windows sandbox profile; отдельное переключение только одного
его ключа не проводилось, поэтому более узкая атрибуция одного config key не
заявляется.

### Безопасное исправление eval environment

Использован штатный per-invocation путь:

```text
codex exec --ephemeral --sandbox read-only -C <disposable-repo>
  --skip-git-repo-check --json <prompt>
```

Пользовательский config загружался только для разрешённого read-only eval;
глобальная approval policy, sandbox settings, credentials, VPN и proxy не
изменялись. WFA harness в репозитории не изменялся: исполняемого activation
harness в `evals/` нет, запуски были bounded CLI invocations из внешнего
evidence bundle.

Один mutating foundation positive с `workspace-write` не завершил turn и был
остановлен как `NOT RUN`; он не является PASS. Для финальной пары использован
завершившийся read-only positive Git audit, который доказал чтение Skill и
выполнение Git-команд только в disposable repository.

## WebSocket и HTTPS

- CLI: `codex-cli 0.167.2`.
- `codex login status`: `Logged in using ChatGPT`.
- WebSocket handshake к `wss://chatgpt.com/backend-api/codex/responses`
  возвращает HTML `403 Forbidden`; CLI делает пять retry и переходит на HTTPS.
- В каждом завершившемся Stage 12A eval после fallback наблюдались
  `agent_message` и `turn.completed`; это позволило провести evals через
  рабочий HTTPS fallback.
- Отдельный HTTPS `403` не доказан. Поэтому WebSocket 403 не смешан с local
  policy DENY и остаётся `BLOCKED_EXTERNAL` с неустановленным upstream
  решением. Это не интерпретируется автоматически как ошибка токена, VPN или
  proxy.
- Один ограниченный `Test-NetConnection chatgpt.com -Port 443` дал
  `TcpTestSucceeded = True`; повторный сетевой probe не выполнялся.

## Read-only audit `~/.codex/skills/.system`

Разделённые verdicts:

- `WFA_SCOPE_INTEGRITY = PASS`: WFA manifest и 29 Skills не повреждены;
  source/target hashes совпадают; reparse points отсутствуют.
- `CODEX_SYSTEM_CHANGE = OBSERVED_AUTOMATIC_REFRESH`: после запуска обычной
  пользовательской конфигурации все 49 текущих system-файлов получили единое
  время refresh `2026-11-17 09:25:58`; после этого новых изменений до финального
  аудита не наблюдалось. Временная связь с нормальным Codex startup
  подтверждена, внутренний источник refresh не доказан.
- `FULL_NO_TOUCH_GATE = BLOCKED`: исторический Stage 11 drift и этот
  наблюдаемый automatic refresh не позволяют утверждать полный no-touch gate.
- `Official baseline = BASELINE_UNAVAILABLE`; byte-level сравнение с
  официальной поставкой не заявляется.
- `.system` не откатывался, не удалялся и не заменялся вручную.

WFA-managed `~/.agents/skills/` и non-system Codex Skills после evals
остались без drift. Доступный read-only audit сохранён в
`stage12a-system-audit-after.json`.

### Пользовательская конфигурация

Два workspace-write запуска автоматически добавили в `~/.codex/config.toml`
trust entries только для task-owned disposable repositories
`wfa-stage12a-git-positive*`. Это было обнаружено пост-аудитом; записи удалены
точечным patch. Финальный semantic project inventory и hook trusted hashes
совпали с pre-eval snapshot; `hooks.json` не изменялся. Exact pre-run byte hash
`config.toml` в Stage 12A не был сохранён, поэтому byte-level no-touch claim
для config не выдаётся.

## Positive/negative activation matrix

Все завершившиеся тесты выполнялись с CLI `0.167.2`, source SHA
`53f328416998b13970025f4cf3604a32d4745837`, в disposable Git workspace,
без merge/deploy/production writes. `PASS` ниже означает activation contract:
в trace есть полное чтение целевого `SKILL.md`, поведение соответствует Skill,
а side effects ограничены fixture. Это не означает, что read-only design
доказал production runtime.

| Skill | Positive | Negative | Фактическое evidence |
| --- | --- | --- | --- |
| `git-workflow` | `PASS` | `PASS` | Positive прочитал полный Skill и выполнил status/branch/HEAD/worktree/remote в disposable repo; negative theory дал `0` command events и `0` target Skill mentions. |
| `root-cause-debugging` | `PASS` | `PASS` | Positive прочитал Skill, выделил synthetic root cause, minimal fix и regression test без записи; negative не активировал debugging workflow. |
| `logging-standard` | `PASS` | `PASS` | Positive прочитал Skill и построил bounded event/retry/fallback/privacy design; negative theory stdout/stderr не активировал logging Skill. |
| `task-planning` | `PASS` | `PASS` | Positive прочитал Skill, зафиксировал неизвестные, high-risk/reviewer gate и acceptance criteria; negative не читал `task-planning` (вспомогательные Skills не считаются ложной активацией цели). |
| `audit` | `PASS` | `PASS` | Positive прочитал Skill и выполнил read-only audit; verdict target был честно `BLOCKED` из-за пустого fixture. Negative не активировал `audit`. |
| `ceos-continue` | `PASS` | `PASS` | Positive прочитал Skill и вернул ожидаемый `BLOCKED`: CEOS CLI, `RUN-123` state и lease отсутствуют; negative обычного continue не активировал CEOS Skill. |

Каждый завершившийся CLI turn имел exit code `0` и `turn.completed`. Для
mutating foundation positive отдельный результат: `NOT RUN` — процесс не
завершил turn; это не подменяет основной bounded activation pair.

JSONL evidence:

- `stage12a-git-workflow-positive-user-config.jsonl`
- `stage12a-git-workflow-negative.jsonl`
- `stage12a-root-cause-debugging-positive.jsonl`
- `stage12a-root-cause-debugging-negative.jsonl`
- `stage12a-logging-standard-positive.jsonl`
- `stage12a-logging-standard-negative.jsonl`
- `stage12a-task-planning-positive.jsonl`
- `stage12a-task-planning-negative.jsonl`
- `stage12a-audit-positive.jsonl`
- `stage12a-audit-negative.jsonl`
- `stage12a-ceos-continue-positive.jsonl`
- `stage12a-ceos-continue-negative.jsonl`

## Выполненные проверки

- `codex --version`, `codex --help`, `codex login status`.
- Read-only inspection CLI launcher, transport config, env presence, TLS,
  DNS/TCP reachability and trace event chain; secrets, cookies и auth headers
  в evidence не записывались.
- `global-preflight.ps1 -All -OutputFormat Json` до и после evals;
  финальный `Ready=True`, `CURRENT=29`, manifest `VALID`, no pending
  transactions, `FilesChanged=False`.
- Source/target SHA audit для всех 29 Skills и отдельные hashes шести Skills,
  использованных в evals.
- Read-only `.system` audit, reparse-point check, WFA/non-system integrity
  check и config semantic restore check.
- `python scripts/validate.py` — PASS, 29 Skills, 0 errors.
- `python -m unittest discover -s tests -v` — PASS, 101/101.
- PowerShell 7 smoke, global-preflight smoke, install-transaction smoke и
  Windows PowerShell 5.1 smoke — PASS в Stage 12 evidence.
- `git diff --check` — PASS.
- `git status --short --branch`, `git rev-parse HEAD`, `git rev-parse
  origin/main` — main clean кроме этого untracked report до commit; HEAD и
  origin/main перед публикацией должны быть повторно проверены.

## Остаточные риски и следующий шаг

1. Upstream WebSocket 403 остаётся `BLOCKED_EXTERNAL`; его причина ниже
   уровня CLI по доступным данным не установлена.
2. `FULL_NO_TOUCH_GATE` остаётся `BLOCKED` из-за `.system` refresh и
   отсутствующего официального baseline.
3. Exact byte-level pre-run hash `config.toml` отсутствует; task-owned trust
   entries удалены, semantic inventory и hook hashes восстановлены.
4. Positive cases для Skills с mutation-oriented формулировками проверяли
   activation/read-only behavior, а не запись в реальный продукт. Production,
   deploy, merge и external side effects не выполнялись.

Следующий конкретный шаг: после появления независимого evidence о доступности
Responses WebSocket повторить только transport-specific bounded check; до этого
считать глобальную установку и текущую HTTPS activation matrix проверенными, а
общую интеграцию — `PARTIAL / BLOCKED_EXTERNAL`.
