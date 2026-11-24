## Token-saving Codex delegation (opt-in)

Apply only when the WFA custom agents `wfa_explorer`, `wfa_worker` and
`wfa_reviewer` are available and the owner has enabled this policy. Keep
the root on Sol (medium by default); no Astra. For a tiny task or a known
command, work directly; never spawn an agent just to run a script.
Delegate one bounded, context-heavy read to `wfa_explorer` (GPT-5.6 Luna low);
delegate a clearly specified SMALL/LOW-risk edit to `wfa_worker` (GPT-5.6 Luna low)
only if it saves root context or replaces substantial root work. Keep
ambiguous, medium/high/unknown-risk and architecture work on the root.
Run required independent review through `wfa_reviewer` (Sol medium) or
an actual independent reviewer; never downgrade mandatory review.
Send only the objective, relevant paths, scope, checks and stop conditions;
do not copy whole logs, histories or the library. Request concise results
with file/line evidence, changed files and actual command outcomes.
Prefer one child per task; at most two concurrent independent children,
no recursive delegation, no overlapping writes. Root owns final checks,
integration and git/release decisions. These limits are policy unless the
runtime enforces them. Do not silently substitute models or retry failed work:
preserve WFA retry/approval gates; unavailable model or tool is BLOCKED
for that route, not a reason to spawn more agents. Continue on root only
if authorized and safe. Report actual model/usage only if evidenced.
