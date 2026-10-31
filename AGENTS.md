# workspace

一站式「生成 → 部署到 GitHub」的工作空间。整个目录是一个仓库，远端为
[`kesheC/workspace`](https://github.com/kesheC/workspace)。

## 目录约定

```
.
├── docs/agents/          # 本仓库的 agent 配置与决策记录
├── projects/<name>/      # 每个独立项目一个子目录，自带构建与测试
└── README.md
```

新项目放 `projects/<name>/`，在本仓库内即自成一体，不需要单独建库；
需要单独发版或单独授权时，再把它拆成独立仓库。

## 环境

- Windows + Git Bash；GitHub 走 HTTPS（`gh` 已登录 `kesheC`）。
- 网络到 `github.com` 不稳时必须加兜底：
  `git -c "http.curloptResolve=github.com:443:140.82.113.3" push`。
- 本机无 SSH 私钥、无云服务凭据：能建库 / push / Actions CI / Pages，
  不能部署自有服务器。

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in `kesheC/workspace`, driven by deck tools
(`deck_issue_*`, `deck_map_*`) with `gh` for everything else. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`,
`ready-for-human`, `wontfix`) plus the four `wayfinder:*` labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: if a root `GLOSSARY.md` and `docs/adr/` exist, they are shared by all
`projects/*` rather than duplicated per project. Neither file exists yet; `docs/agents/domain.md`
says to proceed silently in that case, so do not create them just to fill the layout.
