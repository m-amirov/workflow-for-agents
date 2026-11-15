---
name: browser-automation
description: >-
  Use when implementing, changing, or diagnosing stateful browser automation with
  submit/retry/navigation/reload recovery, task leases, durable fences, or an
  external side effect. Do not use for read-only research, visual browser QA,
  theoretical Playwright questions, CSS work, or refactors without browser state.
---

# Safe Stateful Browser Automation

Use this Skill when a browser operation can cause an external side effect and a retry could duplicate it. It complements [browser-qa](../../testing/browser-qa/SKILL.md): browser-qa checks UI behavior; this Skill protects identity, durable state and the meaning of completion.

## Safety boundary

Default to fake pages, deterministic time and temporary durable stores. Do not start a live submission, connect to a user production session, read credentials, or copy real task/customer data. A real external action requires explicit authorization and a project-defined receipt contract.

## Lifecycle

1. **Define the contract.** Record task identity, page and frame identity, permitted side effect, durable-state location, cancellation conditions and an independent receipt. If any is undefined, stop before implementation.
2. **Check the lease immediately before the effect.** Confirm task/page/frame still match, the lease has not expired or been cancelled, and no unresolved reservation already exists for that identity. Treat a stale callback as blocked.
3. **Reserve durably before acting.** Atomically persist one reservation for the exact identity. If persistence or locking fails, do not perform the side effect.
4. **Perform once.** Serialize concurrent attempts and issue at most one effect for that reservation. A restart observes the reservation; it does not retry it.
5. **Preserve unknown outcomes.** Timeout, navigation, reload, network error, crash or ambiguous DOM after the effect means `UNKNOWN`, not failure. Do not blindly retry.
6. **Require independent receipt.** Clear the fence only after the contract's identity-bound receipt. A local `clicked` log, no Playwright exception, handler `ok: true`, an unexplained missing button or arbitrary DOM change is not a receipt.
7. **Report separate states.** State local execution, receipt confirmation, unknown outcome and external-platform acceptance independently. Never collapse them into one PASS.

Read [references/lifecycle-and-evidence.md](references/lifecycle-and-evidence.md) when designing state transitions, failure tests or source-bound evidence.

## Verification

Use sanitized offline fixtures. Cover stale identity, durable-write failure, restart after reservation, timeout, mismatched/missing receipt and concurrent attempts. Add a positive receipt transition and a negative no-retry assertion. Use `root-cause-debugging` for an observed failure and `regression-testing` to preserve its reproduction.

## Completion gate

Before calling the automation safe, show the contract, test results and the outstanding status of each external confirmation. If platform acceptance was not observed, report it as `NOT RUN`, `UNKNOWN` or `BLOCKED` rather than PASS.
