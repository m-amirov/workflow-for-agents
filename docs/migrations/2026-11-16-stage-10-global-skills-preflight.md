# Stage 10 — Global Skills Compatibility Audit & Migration Preflight

Статус: `implemented` для read-only preflight и disposable regression fixtures;
`PARTIAL` для полного перехода на единый global Skills source. Установка,
удаление, перезапись, backup и ownership migration в рамках Stage 10 не
выполнялись.

## Источники и границы evidence

- Репозиторий target: `https://github.com/m-amirov/workflow-for-agents`.
- Source SHA, использованный для этого отчёта:
  `8b8b3894b3fc67e3ae5da41e014bb9f9cf65337a`.
- Исторический CEOS source SHA для 15 migrated Skills:
  `c8cc13bd3852409be93097ee823e9cd35e512b73`.
- Инвентаризация выполнена скриптом
  `scripts/global-preflight.ps1`; текущий HOME читался read-only.
- `Current SHA` и `Target SHA` в таблице — SHA-256 `SKILL.md`; fingerprints
  находятся в machine-readable JSON как `CurrentVersion` и `TargetVersion`,
  с областью в `*FingerprintScope` (`manifest-listed`, `skill-md-only` или
  `source-tree`).
- `-All` определяет targets из текущего `docs/SKILL_CATALOG.md`, а не из
  фиксированного числа Skills. На snapshot было 29 `implemented` Skills.

Preflight не читает произвольные файлы за пределами двух Skills roots и
связанных manifest/ownership metadata. Для unmanaged Skill хешируется только
`SKILL.md`; для WFA-managed Skill читаются только файлы, перечисленные его
manifest. Reparse point, symlink, junction и traversal не обходятся.

## Реальный HOME: read-only snapshot

Команды:

```powershell
.\scripts\global-preflight.ps1 -Set ceos-migrated -OutputFormat Json
.\scripts\global-preflight.ps1 -All -OutputFormat Json
```

Наблюдаемый результат:

| Scope | Checked targets | Discovered global Skill dirs | CURRENT | NOT_INSTALLED | Safe install candidates | Migration authorization | Legacy CEOS manifest |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `ceos-migrated` | 15 | 17 | 0 | 15 | 15 | 0 | `ABSENT` |
| `All implemented` | 29 | 17 | 2 | 27 | 27 | 0 | `ABSENT` |

Два существующих WFA-managed Skills — `git-workflow` и
`root-cause-debugging` — имеют валидный WFA manifest и статус `CURRENT`. В
`~/.codex/skills/` обнаружены 15 каталогов/кандидатов без подтверждённого
WFA или CEOS owner, включая `.system`; они остаются
`OWNERSHIP_UNVERIFIED`. Это не утверждение, что migrated set уже установлен.

Текущий WFA manifest: `VALID`, путь
`C:\Users\user\.agents\skills\.workflow-for-agents.manifest.json`.
Legacy manifest `C:\Users\user\.codex\ceos\installation.json` отсутствует.
Pending transaction в snapshot не обнаружен. `AGENTS.md`, hooks, config и
прочие пользовательские настройки preflight не менял.

## Migration table для `ceos-migrated`

Пустой `Current SHA` означает `NOT_INSTALLED`; это не означает, что путь можно
перезаписывать без отдельной проверки перед будущей установкой.

| Skill | Current owner | Current SHA | Target SHA | Status | Required action |
| --- | --- | --- | --- | --- | --- |
| audit | none |  | d1c9f9a4effa3eef70ce0d889d7ec58ac3872871c6e2a67ecb138b5b4353e405 | NOT_INSTALLED | Install after dry-run and approval |
| audit-repair-loop | none |  | 71637335a6d62a7d4fe2c3a7fc55b6c40a1d6c1b931293d6373a7c1a7aad14a6 | NOT_INSTALLED | Install after dry-run and approval |
| ceos-continue | none |  | 1b9d39b2881d50c7e0eadaa2a941c26f72f2a0a682d6248acfdd5eda60e21224 | NOT_INSTALLED | Install after dry-run and approval |
| fix | none |  | 8d87def1806bc4da6db24bead560a539c880d4c0826d1506142ce2669e9b8b4a | NOT_INSTALLED | Install after dry-run and approval |
| incident-analysis | none |  | d9287e795a86d3449601942e3adabc83d57c0a1dd32ecd68e9f4a2067b6e0134 | NOT_INSTALLED | Install after dry-run and approval |
| narrative-continuity-engine | none |  | 2c52108b5005a40e0998631756ab941f294a3aa14f93faf8eb9c80d6516734f6 | NOT_INSTALLED | Install after dry-run and approval |
| narrative-dialogue-editor | none |  | 575fa819254920a582d4c36027571204054acf6886437044d8568cc18b5c0446 | NOT_INSTALLED | Install after dry-run and approval |
| prod-check | none |  | 97beaee8da726627eb9879c000c0c2b6b13810613d8ab28eb0e96790d65b2d77 | NOT_INSTALLED | Install after dry-run and approval |
| production-art | none |  | 23ce75dd88565d2be59865c269a3d689684bf6335c2f12625addd687504949fa | NOT_INSTALLED | Install after dry-run and approval |
| reader-experience-review | none |  | 6ad5a360472e60b16d9dfb680eea7eab86188b8c7c4dc20a8911598a6e8b4a51 | NOT_INSTALLED | Install after dry-run and approval |
| release | none |  | 56931eae29b823a146631c27b86f7d746442687f1684a68587af046b1e1725d4 | NOT_INSTALLED | Install after dry-run and approval |
| romance-narrative | none |  | 6b211307cf5bdb59d9983c083b19026950da96263f859807f759b3dce6f57c1c | NOT_INSTALLED | Install after dry-run and approval |
| verification | none |  | 3b80ffb9b1fcc12b281fefbb72a1feac0fffd270a17395c49cf57c77680a0cf7 | NOT_INSTALLED | Install after dry-run and approval |
| video-production | none |  | 5c3fa6980f4a1b3122c53342f0fa0b1ab13d2a49990361a257cc1055dee8532f | NOT_INSTALLED | Install after dry-run and approval |
| visual-qa | none |  | c9a00af3adee26082d1b285367d35be4907e3281c6bf08f258712ae0651aa4ee | NOT_INSTALLED | Install after dry-run and approval |

Для этого snapshot конфликтов `LEGACY_CEOS_MANAGED`, `USER_MODIFIED`,
`UNMANAGED_COLLISION`, `OWNERSHIP_UNVERIFIED`, `INVALID_MANIFEST` или
`UNSAFE_PATH` среди 15 target rows не обнаружено. Это означает только, что
отсутствующие rows можно рассматривать как кандидаты для отдельного будущего
dry-run; это не разрешение на установку.

## Сравнение с собственными Skills

`-All` проверяет весь implemented-каталог. У migrated Skills есть declared
overlaps в metadata, например `audit`/`code-review`,
`release`/`release-verification`, `visual-qa`/`browser-qa` и
narrative/art пары. Preflight выводит их в `FunctionalOverlaps` вместе с
activation description, но не удаляет и не объединяет Skills из-за
функционального пересечения. Совпадение имени и совпадение SHA без trusted
owner остаётся collision/unverified, а не `CURRENT`.

## Backup-backed migration plan (не выполнен)

### Сохранить до любых записей

1. Внешнюю backup-копию `.codex/ceos/installation.json`, если она появится,
   и всех affected Skill directories с исходными байтами.
2. Текущий `.agents/skills/.workflow-for-agents.manifest.json` и полный
   per-file SHA-256 manifest.
3. `AGENTS.md`, hooks, config и остальные user settings; Stage 10 их не
   изменяет и не создаёт для них backup автоматически.

### Будущая последовательность

1. Повторить read-only preflight непосредственно перед записью HOME и
   сохранить JSON report с exact source commit.
2. Для каждой строки подтвердить owner, current SHA, target SHA и отсутствие
   локальных изменений; `INVALID_MANIFEST`/`UNSAFE_PATH` сначала
   восстановить или расследовать.
3. С явным разрешением владельца сделать backup вне live HOME и проверить
   hashes backup до любой записи.
4. Выполнить существующий `install.ps1`/`sync.ps1` в `-DryRun`, проверить
   planned changes и повторно убедиться, что unmanaged/user-modified/legacy
   rows не будут перезаписаны.
5. Только после отдельного разрешения выполнить минимальную установку или
   sync. Автоматического `--force-migrate` и смены owner нет.
6. Сразу повторить preflight и проверить manifest, bytes/SHA, пользовательские
   настройки, pending transaction и rollback evidence.

### Rollback и блокировки

- При сбое существующего transactional sync использовать только его journal и
  `sync.ps1 -Recover` после проверки hashes; preflight recovery не запускает.
- При ошибке ownership transfer восстановить внешний backup и сохранить старый
  owner manifest до нового аудита.
- Миграция блокируется при path traversal, reparse point, invalid/missing
  manifest entry, pending transaction, локальной правке, unmanaged collision,
  неизвестном owner или отсутствии expected source bytes.
- Обязательны отдельные разрешения на backup location, запись в real HOME,
  изменение/удаление CEOS ownership и дальнейшую установку. Stage 10 таких
  разрешений не получает.

## Disposable regression evidence

`scripts/tests/GlobalPreflightSmoke.ps1` создаёт только временные каталоги и
проверяет 16 сценариев: empty/current/partial set, legacy CEOS, разные SHA,
user Skill без manifest, user-modified managed Skill, corrupt/missing/hash/path
manifest, junction, pending transaction, повторяемость и сохранность
`AGENTS.md`/hooks/settings. Проверяется отсутствие изменений файлов и то, что
preflight не создаёт backup, не вызывает install/sync и не снимает pending
lock.

Реальный HOME audit и disposable fixtures — разные gates. Fixture PASS не
подменяет состояние пользовательского ПК.
