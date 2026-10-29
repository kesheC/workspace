# workspace

一站式生成并部署到 GitHub 的工作区。

## 用途

这个仓库是 DSH 的「生成 → 部署」出口：在这里生成的项目，通过本机已登录的 `gh`（账号 `kesheC`）直接建库、推送、跑 Actions，或者发 Pages。

## 目录约定

```
.
├── projects/          各子项目，一个目录一个项目
├── docs/agents/       DSH 插件配置（deck 后端选择等）
└── README.md
```

新项目建议放在 `projects/<name>/`，需要独立版本历史时再单独 `git init` 拆库。

## 本机能力边界

- 已配好：`git` 全局身份、`gh` 登录（scopes 含 `repo` / `workflow` / `gist` / `read:org`）
- 能建库、推送、开分支、跑 Actions、发 Pages
- **不能删仓库**：账号缺 `delete_repo` 权限，删库需要手动去网页操作
- 不能部署自有服务器（无 SSH 私钥、无云厂商凭据）
