# Security Policy

## Supported versions

This repository ships no code of its own. The security posture that matters belongs to each
`projects/<name>/` repository, and each of those carries its own `SECURITY.md`.

| Component | Where the policy lives |
| --------- | ---------------------- |
| repropack | <https://github.com/kesheC/repropack/blob/main/SECURITY.md> |
| clidoc | <https://github.com/kesheC/clidoc/blob/main/SECURITY.md> |
| envpulse | <https://github.com/kesheC/envpulse/blob/main/SECURITY.md> |
| gitignore-doctor | <https://github.com/kesheC/gitignore-doctor/blob/main/SECURITY.md> |
| jsonl-beaver | <https://github.com/kesheC/jsonl-beaver/blob/main/SECURITY.md> |
| apidiff | <https://github.com/kesheC/apidiff/blob/main/SECURITY.md> |

## Reporting a vulnerability

Please **do not open a public issue** for a security problem.

- **A shipped tool** (repropack, clidoc, envpulse, gitignore-doctor, jsonl-beaver, apidiff): use that
  repository's private advisory channel — `https://github.com/kesheC/<name>/security/advisories/new`.
  Its `SECURITY.md` says what that project promises to hide or ignore, which is what a report should
  be measured against.
- **This repository** (the docs, the playbook, the specs — anything under `docs/agents/`): use
  <https://github.com/kesheC/workspace/security/advisories/new>.

If a private channel is unavailable, open a minimal issue that says only *"security report — please
contact me"* and wait for a maintainer to reach out. Do not include reproduction details, payloads,
or secrets in the issue itself.

### What to include

- Which project and which version (`<tool> --version`).
- The smallest input that shows the problem.
- What you expected versus what happened.
- Whether the issue lets an attacker read data, execute code, or only crash the process.

### What to expect

These are small projects maintained on a best-effort basis. You should get an acknowledgement
within about two weeks. A fix or a written "won't fix" with reasoning follows once the report is
reproduced.

## Scope

In scope for this repository:

- Guidance in `docs/agents/` that would lead someone to publish a secret, or to trust a gate that
  does not actually gate anything.
- Instructions that produce a different result than they claim, where the difference is a security
  one.

Out of scope:

- Anything about a shipped tool that has its own repository and its own `SECURITY.md` (report it there).
- Findings that need an already-compromised machine or a modified local build.
- Issues in Node.js or in GitHub itself rather than in these files.
