# Codex token-saving mode

Status: implemented configuration and advisory policy; runtime activation and
token savings NOT VERIFIED. No Astra profile or fallback. Sol is the root
recommendation; existing root configuration is not changed.

| Profile | Model | Effort | Use |
| --- | --- | --- | --- |
| Root | gpt-5.6-sol | medium | Planning, complex work, integration |
| wfa_explorer | gpt-5.6-luna | low | Bounded read with context savings |
| wfa_worker | gpt-5.6-luna | low | SMALL/LOW-risk scoped change |
| wfa_reviewer | gpt-5.6-sol | medium | Independent review when required |

Definitions are in the repository's `.codex/agents/`. The model IDs and
native format follow https://developers.openai.com/codex/subagents and
https://developers.openai.com/api/docs/models . Actual client/account
availability must be checked. The default lightweight model is GPT-5.6 Luna
(`gpt-5.6-luna`), observed in the owner's ChatGPT-authenticated Codex model
picker on 2026-11-24. The previous GPT-6 Luna ID was rejected by that runtime.
API model availability is not proof of Codex account support. Check both
lightweight and reviewer routes with the actual account before delegation;
do not treat a static test or a picker entry as a successful invocation. Lower model price is not lower token count:
subagents repeat context and have their own tool/LLM work. Avoid fan-out.

## Native versus Web routes

For the owner's Codex model catalog (2026-11-24), select native GPT-5.6 Sol
(without the "(Web)" suffix) for the root and reviewer. The native
GPT-5.6 Luna profiles remain unchanged. The GPT-6.2 Sol (Web) and GPT-6
Sol (Web) entries belong to the separate, unofficial
[Codex ChatGPT Web adapter](https://github.com/miuuyy/codex-chatgpt-web);
their display names do not establish native model availability.

Only Instant Web entries may be considered under the owner's constraint.
They are optional, manually selected routes for bounded, non-sensitive
standalone text work, not mandatory engineering agents or automatic
fallbacks. Do not enable the adapter, alter its settings, or route private
project context through it as part of WFA installation. Local tool access
and cross-backend delegation depend on actual adapter mode and verified
harness capability. No Web profile is installed or auto-selected by WFA.
Astra and non-Instant Web models are excluded. Keep mandatory code review,
local edits, tests, and release gates on verified native routes. Record
BLOCKED if a required native route is unavailable. Never use Web as an
implicit substitute.

## Activation

For WFA itself, open the trusted repository in Codex with native GPT-5.6 Sol medium, and
explicitly enable the token-saving policy for the task. For other projects,
copy the three named TOML files to `.codex/agents/` (project scope) or
`~/.codex/agents/` (user scope), then incorporate
[the instruction fragment](AGENTS.token-saving.md) into the applicable
existing AGENTS.md after reviewing it. Do not replace existing instructions.
The fragment's reference to owner opt-in is satisfied only by explicit
activation; simply copying TOML files does not activate the policy.

PowerShell, from a WFA checkout, for user scope (change destination for project):

~~~powershell
$src = Join-Path (Get-Location) '.codex/agents'
$dst = Join-Path $HOME '.codex/agents'
$names = @('wfa_explorer.toml','wfa_worker.toml','wfa_reviewer.toml')
foreach ($name in $names) {
    if (Test-Path -LiteralPath (Join-Path $dst $name)) {
        throw "Collision: $name; inspect manually before installing"
    }
    Get-FileHash -LiteralPath (Join-Path $src $name) -Algorithm SHA256
}
# Stop here for dry-run. Run the following only after reviewing the paths.
New-Item -ItemType Directory -Path $dst -Force | Out-Null
foreach ($name in $names) {
    [System.IO.File]::Copy((Join-Path $src $name), (Join-Path $dst $name), $false)
}
~~~

This is a manual copy, not a transactional installer or WFA Skill sync.
If a copy fails, inspect any files already copied; never overwrite a collision.
Check directory junctions/symlinks and other custom agents with the same
`name` before activation. To deactivate remove only the added instruction
fragment; remove copied TOML files only after checking hashes and ownership.
Restart Codex after configuration changes. Do not change existing global
config or override root permissions. Optionally set
`agents.max_concurrent_threads_per_session = 2` inside the existing
`[agents]` table if supported by the installed client; do not duplicate it.
For older clients check the documented legacy alias. No recursion and
write scopes are prompt policy, not sandbox guarantees.

## Advisory probe

~~~powershell
python scripts/task_routing.py --type CHANGE --size SMALL --risk LOW --docs-impact LOCAL --token-work BOUNDED_WRITE
~~~

Use BOUNDED_READ/BOUNDED_WRITE only when transferring a small task contract
replaces substantial root context or work; otherwise use TINY or COMPLEX.
COMMAND means a known tool operation; native verification and review gates
still apply. This probe never invokes Codex. Unassessed/high risk or required
architecture stays ROOT. The root must use an independent reviewer when
required even if it costs additional tokens. Never auto-escalate or reset
retry limits. Missing model/tool: report BLOCKED for that route; no hidden
fallback.

## Acceptance and measurement

1. Check client version, model availability, and the three custom names.
2. In a disposable project, exercise a tiny direct edit (no child), a
   bounded read and write (Luna), and a required review (Sol).
3. Verify actual child model/thread evidence, scope, command outcomes and
   independent review; record UNKNOWN if model metadata is unavailable.
4. Compare equivalent tasks in clean worktrees with identical acceptance
   checks and root settings: direct Sol baseline vs opt-in delegation.
   Record root and all child input, cached input, output and reasoning
   tokens as available; avoid double-counting reasoning in output. Compare
   total input+output, retries, elapsed time and correctness. Record unknown
   fields, not invented numbers. Keep delegation only where measured benefit
   exceeds overhead without reducing quality. Do not publish private logs.
5. No global rollout or savings claim until actual activation and measurement.

Static unit tests exercise routing and TOML profiles; they do not run Codex.
