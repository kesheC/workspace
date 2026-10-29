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
`projects/*/` 已加入 `.gitignore`：子项目各自是独立仓库，不进本仓库。

## 已出品的项目

五个零运行时依赖的 Node CLI，各自独立建库、四路矩阵 CI（ubuntu/windows × node 20/22）全绿、
v0.1.0 Release 已发。

| 项目 | 说明 | 仓库 |
| --- | --- | --- |
| clidoc | 把真实命令输出写回 README，让文档不会和 CLI 漂移 | [kesheC/clidoc](https://github.com/kesheC/clidoc) |
| envpulse | `.env` 漂移与密钥泄漏体检 | [kesheC/envpulse](https://github.com/kesheC/envpulse) |
| gitignore-doctor | 解释并审计 `.gitignore` 规则：冗余、缺失、已失效 | [kesheC/gitignore-doctor](https://github.com/kesheC/gitignore-doctor) |
| jsonl-beaver | 流式 JSONL / NDJSON 日志分析，GB 级不爆内存 | [kesheC/jsonl-beaver](https://github.com/kesheC/jsonl-beaver) |
| apidiff | 在发布前发现 OpenAPI / JSON Schema / .env 的破坏性变更 | [kesheC/apidiff](https://github.com/kesheC/apidiff) |

## 本机能力边界

- 已配好：`git` 全局身份、`gh` 登录（scopes 含 `repo` / `workflow` / `gist` / `read:org`）
- 能建库、推送、开分支、跑 Actions、发 Pages
- **不能删仓库**：账号缺 `delete_repo` 权限，删库需要手动去网页操作
- 不能部署自有服务器（无 SSH 私钥、无云厂商凭据）
