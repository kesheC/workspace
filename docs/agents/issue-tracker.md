# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues in **`kesheC/workspace`**.

Two ways to work with them, and they must stay in the same number space:

- **Deck tools** (`deck_issue_*`, `deck_map_*`) — the default in this workspace. Deck talks to the GitHub Issues API for you and keeps kinds, parents and blocking edges consistent.
- **`gh` CLI** — for anything deck doesn't cover (labels, assignees, raw API, bulk queries).

Both hit the same issues. A ticket created with `deck_issue_create` is visible to `gh issue list`, and vice versa.

## Conventions with deck

- **Create a ticket**: `deck_issue_create` with an explicit `kind` — one of `map`, `map-ticket`, `spec`, `spec-ticket`, `bug`, `issue`. A `map-ticket` also needs a `label` (`wayfinder:research` / `wayfinder:prototype` / `wayfinder:grilling` / `wayfinder:task`) and a `parentKey` pointing at a `map`. A `spec-ticket` needs a `parentKey` pointing at a `spec`.
- **Read a ticket**: `deck_issue_get` (pass `blocking=false` to skip the reverse-edge scan when you only need the ticket itself). Use `deck_issue_list` for cheap thin rows filtered by state / label / assignee / query.
- **Whole map**: `deck_map_snapshot` (pass `detail=thin` when the ticket list is long).
- **Change a ticket**: `deck_issue_patch` — comment, labels, assignees, title, body, progress, close. Reopening is human-only.
- **Wire edges between existing tickets**: `deck_map_link` (`parentKey` / `blockedBy`, full replacement lists).
- **Report which ticket you're working on**: `deck_issue_report` — once when you start, once when you close.

Numbers and header markers in the body are written by the tools. Never hand-edit them.

## Conventions with `gh`

Run `gh` inside the clone; it infers the repo from `git remote -v`.

- **Create**: `gh issue create --title "..." --body "..."` (use a heredoc for multi-line bodies).
- **Read**: `gh issue view <number> --comments`, plus `--json` for labels.
- **List**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with `--label` / `--state` filters.
- **Comment**: `gh issue comment <number> --body "..."`.
- **Labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`.
- **Close**: `gh issue close <number> --comment "..."`.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues, using the `gh pr` equivalents:

- **Read a PR**: `gh pr view <number> --comments` and `gh pr diff <number>` for the diff.
- **List external PRs for triage**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments` then keep only `authorAssociation` of `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, or `NONE` (drop `OWNER`/`MEMBER`/`COLLABORATOR`).
- **Comment / label / close**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either: resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue — `deck_issue_create` when it fits one of the kinds, `gh issue create` otherwise.

## When a skill says "fetch the relevant ticket"

`deck_issue_get` (preferred, structured) or `gh issue view <number> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body; child tickets are `wayfinder:<type>` issues parented to it.

- **Map**: `deck_map_plan_create` builds a whole skeleton (map + children + edges) in one call. For a one-off map, `deck_issue_create` with `kind=map`.
- **Child ticket**: `kind=map-ticket` with `label=wayfinder:<type>` and `parentKey=<map>`. Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: deck writes native GitHub issue dependencies. Raw fallback: `gh api --method POST repos/kesheC/workspace/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric database id (`gh api repos/kesheC/workspace/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only, the live gate). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: `deck_map_snapshot` with `frontierOnly=true` — it already drops closed, claimed and still-blocked children and keeps map order. Raw `gh` equivalent: list the map's open children, drop any with an open blocker or an assignee, first in map order wins.
- **Claim**: `deck_issue_report` (the session's first write), or `gh issue edit <n> --add-assignee @me`.
- **Resolve**: `deck_issue_patch` with `comment` + `close=true`, then append a context pointer (gist + link) to the map's Decisions-so-far.
