# workspace

一站式生成并部署到 GitHub 的工作区。

## 用途

这个仓库是 DSH 的「生成 → 部署」出口：在这里生成的项目，通过本机已登录的 `gh`（账号 `kesheC`）直接建库、推送、跑 Actions，或者发 Pages。

## 目录约定

```
.
├── projects/          各子项目，一个目录一个项目（各自是独立 git 仓库，不进本库）
├── docs/agents/       agent 配置、决策记录与各项目的 spec
├── LICENSE            MIT
└── README.md
```

新项目放在 `projects/<name>/`，需要独立版本历史时再单独 `git init` 拆库。
`projects/*/` 已加入 `.gitignore`：子项目各自是独立仓库，不进本仓库。

## 已出品的项目

六个零运行时依赖的 Node CLI，各自独立建库、四路矩阵 CI（ubuntu / windows × node 20 / 22）全绿，
每次打 tag 由 release workflow 构建 tarball、在干净目录里安装并运行它，再上传到 Release。

| 项目 | 说明 | 仓库 |
| --- | --- | --- |
| repropack | 把一次失败的运行打包成自包含、脱敏、别人一条命令就能复现的 bundle | [kesheC/repropack](https://github.com/kesheC/repropack) |
| clidoc | 把真实命令输出写回 README，让文档不会和 CLI 漂移 | [kesheC/clidoc](https://github.com/kesheC/clidoc) |
| envpulse | `.env` 漂移与密钥泄漏体检 | [kesheC/envpulse](https://github.com/kesheC/envpulse) |
| gitignore-doctor | 解释并审计 `.gitignore` 规则：哪一行让这个路径被忽略 | [kesheC/gitignore-doctor](https://github.com/kesheC/gitignore-doctor) |
| jsonl-beaver | 流式 JSONL / NDJSON 日志分析，GB 级不爆内存 | [kesheC/jsonl-beaver](https://github.com/kesheC/jsonl-beaver) |
| apidiff | 在发布前发现 OpenAPI / JSON Schema / .env 的破坏性变更 | [kesheC/apidiff](https://github.com/kesheC/apidiff) |

### 安装方式说明

这六个包**都没有发布到 npm registry**（`clidoc` 与 `repropack` 这两个名字在 npm 上属于别人的无关包）。
每个 Release 都附带一个可以直接安装的 tarball，资产名固定、不带版本号，所以这条命令在哪个版本都能用：

```console
$ npm install -g https://github.com/kesheC/<name>/releases/latest/download/<name>.tgz
```

> `npm install -g git+https://github.com/...` 装不起来：checkout 里没有构建产物，而全局安装
> 会跳过 `devDependencies`，没有 `tsc` 可以编译。这也是本仓库统一改用 tarball 的原因。

## 本机能力边界

- 已配好：`git` 全局身份、`gh` 登录（scopes 含 `repo` / `workflow` / `gist` / `read:org`）
- 能建库、推送、开分支、跑 Actions、发 Pages
- **不能发 npm**：`npm whoami` 返回 `ENEEDAUTH`，没有发布凭据；所以 README 里不出现 npm 安装命令
- **不能删仓库**：账号缺 `delete_repo` 权限，删库需要手动去网页操作
- 不能部署自有服务器（无 SSH 私钥、无云厂商凭据）

## 文档

- [`AGENTS.md`](AGENTS.md)：目录约定、环境、agent 技能与 issue tracker 规则
- [`docs/agents/`](docs/agents/)：issue tracker / triage labels / domain 三份配置，外加每个项目的 spec