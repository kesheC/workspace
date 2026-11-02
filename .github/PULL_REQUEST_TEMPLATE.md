## Why

<!-- The problem this solves, in a sentence or two. Link the issue if there is one. -->

## What changed

<!-- Bullet the actual changes. "Refactor" and "cleanup" are not changes. -->

## Evidence

<!--
The commands you ran and what they printed. This repository has no build of its own: the evidence
is that the project you touched still passes its own gates, and that the docs you edited still
match what the tools print.
-->

```console
$ cd projects/<name> && npm run typecheck && npm run build && npm test
```

## Checklist

- [ ] If a `projects/<name>/` tree changed, its own `typecheck`, `build` and `test` all pass.
- [ ] If a README transcript changed, the command was re-run and the quoted output pasted verbatim.
- [ ] If a number changed, it is derived from code or a generator rather than typed by hand.
- [ ] `docs/agents/project-playbook.md` still describes what the six repositories actually do.
- [ ] No `projects/*/` file is staged here: each project is its own repository.
