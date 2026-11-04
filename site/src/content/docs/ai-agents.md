---
title: AI Coding Agents
description: Teach coding agents the CherryPick 4.x API with the cherrypick-di skill.
---

Coding agents often know an older CherryPick API than the one you use: 4.0.0 changed the provider
typedefs and `toProvideAsync`, and the code generator has rules that are easy to miss. The
[`cherrypick-di`](https://github.com/pese-git/cherrypick/tree/master/skills/cherrypick-di) skill
gives an agent an up-to-date, verified description of CherryPick, so the code it writes compiles,
resolves correctly and passes [`cherrypick_lint`](/linting/).

The skill follows the open [Agent Skills](https://agentskills.io) format: a `SKILL.md` file with
short rules plus `references/` files the agent opens only when the task needs them.

## What the skill covers

| File | Topic |
|------|-------|
| `SKILL.md` | When to use it, packages and versions, the ten core rules, a minimal example |
| `references/runtime.md` | Scopes, binding kinds, async, params, named bindings, disposal order, cycle detection, observers, tests |
| `references/codegen.md` | `@module`, `@provide`, `@instance`, `@injectable`, `@inject`, what the generator emits, generator errors |
| `references/flutter.md` | `CherryPickProvider`, a scope per screen or feature, Talker logging |
| `references/pitfalls.md` | Every `cherrypick_lint` rule and other mistakes to look for in review |
| `references/migration-4.md` | Upgrading from 3.x to 4.0.0 |

The agent picks the skill up on its own when a project depends on a `cherrypick*` package or the
task mentions CherryPick, scopes, modules or CherryPick annotations.

## Claude Code

The CherryPick repository is also a Claude Code plugin marketplace. Run in Claude Code:

```text
/plugin marketplace add pese-git/cherrypick
/plugin install cherrypick-di@cherrypick
```

The skill then appears as `cherrypick-di:cherrypick-di`. To get a newer version later, update the
marketplace and the plugin from the `/plugin` menu, or from a terminal:

```bash
claude plugin marketplace update cherrypick
claude plugin update cherrypick-di@cherrypick
```

Without the plugin system, copy the folder instead:

- for one project — to `.claude/skills/cherrypick-di/` in that project (commit it to share it with the team);
- for all your projects — to `~/.claude/skills/cherrypick-di/`.

## Other agents

Any agent that supports Agent Skills can use the same folder. Copy
[`skills/cherrypick-di`](https://github.com/pese-git/cherrypick/tree/master/skills/cherrypick-di)
into the skills directory your agent reads — see your agent's documentation for the location.

Agents without skill support can still use the files: point the agent at `SKILL.md` in your
instructions file (for example `AGENTS.md`) and let it read the references it needs.

## Check that it works

Ask the agent something the skill answers, for example: *“Add a feature scope with an async
database binding and close it correctly.”* A response that uses `toProvideAsync` with
`resolveAsync<T>()` and `await CherryPick.closeScope(...)` comes from the skill; one that uses
`toProvideAsync` with a sync closure or forgets `await` does not.

## Use it together with the linter

The skill helps the agent write correct code; [`cherrypick_lint`](/linting/) checks the result
in the IDE and in `dart analyze`. Enable both — the skill's `references/pitfalls.md` mirrors the
lint rules, so the agent can also explain any warning it sees.
