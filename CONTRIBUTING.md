# Contributing to workspace

Thanks for taking the time to look at this. This repository is not a software project: it is the
index and the working notes for six CLI tools that each live in their own repository.

```
workspace/
├── docs/agents/          # playbook, specs, issue-tracker and triage conventions
├── projects/<name>/      # a checkout of one of the six tools (git-ignored here)
├── scripts/              # one-off checks that read the GitHub API
└── README.md            # the index: what each tool is, and every release so far
```

## Where a change belongs

| You want to change… | Open the PR in… |
| ------------------- | --------------- |
| a tool's behaviour, tests, docs or README | that tool's own repository |
| `docs/agents/project-playbook.md`, `docs/agents/specs/*` | here |
| the root `README.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` | here |
| `scripts/` — the checks that query the GitHub API | here |

`projects/*/` is git-ignored on purpose. Each subdirectory is its own git checkout; staging one
here would commit a nested repository. If `git status` ever shows a path under `projects/`, that is
a mistake — unstage it and commit it in the project's own repository instead.

## Before you start

- **A shipped tool is broken?** Open the issue in that tool's repository. Six separate trackers keep
  the numbers meaningful; a bug filed here has to be copied by hand and loses its history.
- **A security problem?** Do not open a public issue. See [`SECURITY.md`](SECURITY.md) — it says
  which repository to use and what each one promises.
- **A large change to the playbook or a spec?** Open an issue first. The playbook is what six
  repositories were measured against; changing a rule silently makes earlier compliance claims
  unverifiable.

## Setting up

There is no build and no test suite at this level. What you need is `gh`, `git` and Node:

```console
$ gh auth status
$ node --version      # 20.11 or newer
```

If you are editing a project's code as well, clone that project separately — `projects/<name>/` is
where a working copy usually sits, but it is not tracked here.

## The checks that exist

Nothing runs on push here, so a doc change is verified by running the thing the doc describes:

```console
$ bash scripts/github-posture.sh
```

That one prints a line per repository — version, topics, community health, secret scanning, push
protection, private vulnerability reporting, the newest CI run, the newest release — and exits
non-zero if any of them says a thing the repository does not actually do. It is the closest thing
this repository has to a gate.

When you edit something under `docs/agents/`, the check is a `bash` block in that file: copy any
command out of it and run it. A playbook that teaches a command which fails on this machine is a
bug in the playbook, and the only way to notice is to run it.

## House rules

- **The six tool repositories are the source of truth.** When the playbook and a tool disagree, the
  tool wins and the playbook gets fixed.
- **No hand-typed numbers.** A count in the docs is either derived from the code that produces it,
  or it is a structural claim ("only `dist/`, `README.md` and `LICENSE` ship") that stays true at
  any size. A number nobody re-derives is a number that is already wrong.
- **Quote real output.** A transcript in the docs is a command someone ran, with the output pasted
  back. If you elide part of it, say so in the surrounding prose.
- **Say which gate checks what.** "CI runs this" is a claim about a workflow file. Open the workflow
  file before writing it.

## Commits and pull requests

Commit subjects take a prefix: `fix:`, `feat:`, `docs:`, `test:`, `chore:`. The body explains the
*why* — what was wrong, and what would still be wrong under the obvious alternative. Fill in the PR
template; the Evidence section is the one that matters.

## Licence

Contributions are accepted under the MIT licence in [`LICENSE`](LICENSE).
