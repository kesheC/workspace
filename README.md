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

六个零运行时依赖的 Node CLI，各自独立建库、六路矩阵 CI（ubuntu / windows × node 20 / 22 / 24）全绿，
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

这六个包**都没有发布到 npm registry**（`clidoc` 与 `repropack` 这两个名字已被别人的项目占用，其余四个名字仍然空着）。
每个 Release 都附带一个可以直接安装的 tarball，资产名固定、不带版本号，所以这条命令在哪个版本都能用：

```console
$ npm install -g https://github.com/kesheC/<name>/releases/latest/download/<name>.tgz
```

> `npm install -g git+https://github.com/...` 装不起来：checkout 里没有构建产物，而全局安装
> 会跳过 `devDependencies`，没有 `tsc` 可以编译。这也是本仓库统一改用 tarball 的原因。

每个 tarball 里只有 `dist/`、`README.md` 和 `LICENSE`：没有 `src/`、没有测试、没有 `.js.map`。
不发源码的包里带 sourcemap 只是指向一个读者永远打不开的文件，所以六个包的发布构建都关掉了它，
并由各自的 `tests/package.test.ts` 与 CI 的打包检查同时守着。

### 发版记录

| 版本 | 日期 | 内容 |
| --- | --- | --- |
| [v0.1.7](https://github.com/kesheC/repropack/releases/tag/v0.1.7) | 2026-11-01 | 六个包统一发版：修正 README 里与实际不符的输出、补齐发布链路的闸门、发布构建停发 sourcemap、`files` 收紧为 `dist` + `README` + `LICENSE` |
| [v0.1.8](https://github.com/kesheC/repropack/releases/tag/v0.1.8) | 2026-11-01 | 发布与 CI 闸门改成「把闸门自己的 shell body 抽出来真跑」而不是断言 YAML 里有某个字符串；补回重写时丢掉的三条守卫（先 `--draft=false` 发布再上传、每个 bin 都冒烟测、build 先清 `dist`）；envpulse 补上它一直没有的 tag/version 闸门；repropack 的 `--version` 断言改为比对 `TOOL_VERSION`，版本号不再变成测试失败 |
| [v0.1.9](https://github.com/kesheC/repropack/releases/tag/v0.1.9) | 2026-11-01 | 六仓 README 补中文：十二节（clidoc/envpulse/jsonl-beaver 为段内镜像）全部有中文对照；clidoc / envpulse / jsonl-beaver 修掉「命令不读的选项被静默忽略」，越界 flag 现在 exit 2 并指出真正读它的命令；apidiff 的 FAQ 不再声称 `diffSchemas` 会拒绝数组根（它返回一条 `schema.replaced`，只有 CLI 的 `assertSchemaRoot` 会拒）；0.1.8 里对 v0.1.7 守卫的口径逐仓校正 |
| [v0.1.10](https://github.com/kesheC/repropack/releases/tag/v0.1.10) | 2026-11-01 | 六个 CLI 的参数解析器统一口径：`--flag=value` 在六仓全部可用（clidoc / apidiff / gitignore-doctor 原本直接报 unknown），布尔开关被传值时一律 exit 2 而不是静默忽略；`--` 终止符补齐到 gid 与 apidiff，以 `-` 开头的文件名终于能被指名；repropack 把「缺值」与「不认识这个选项」拆成两条消息（原先 `capture --out` 会回答 `unknown option '--out'; did you mean '--out'?`），`did you mean` 也不再把破折号计入编辑距离、不再建议用户刚打的那个词；clidoc 拒绝 `render` / `list` 上的位置参数；envpulse 无参运行改为 exit 2；jsonl-beaver 命令名拼错时先报命令名而不是缺文件；gitignore-doctor 的 `--cwd` 把「路径不存在」「不是目录」「不是 git 仓库」三种情况分开 |
| [v0.1.11](https://github.com/kesheC/repropack/releases/tag/v0.1.11) | 2026-11-01 | 六个 CLI 的「谁的回答算数」统一口径：拼错的选项不再被 `--help` 挡住（repropack / gid / jlb 原本打帮助并 exit 0），`--version` 一律只在顶层生效、子命令上 exit 2 并指出正确写法，以破折号开头的第一个词按「拼错的选项」报而不是「未知命令」；拿到 `--json` 的调用方在失败时也能拿到文档——`{"error":{"message":...,"exitCode":n}}` 写 stdout，退出码就是真实用的那个（repropack / envpulse / jlb / gid 四处补齐，apidiff 本来就有）；gitignore-doctor 把 V8 编译不了的正则变成 `INVALID` 发现项而不是整行 pattern 吐回 stderr 的 exit 1，规则文本一律缩写；apidiff 的单个 `-` 是路径不是坏选项 |

每个 tag 由各自的 release workflow 构建 tarball、在干净目录里装一遍、核对 `--version`、再连同
`.sha256` 一起上传；资产同时发布固定名（`<name>.tgz`，可长期引用）与版本名（`<name>-<ver>.tgz`）两套。

## 本机能力边界

- 已配好：`git` 全局身份、`gh` 登录（scopes 含 `repo` / `workflow` / `gist` / `read:org`）
- 能建库、推送、开分支、跑 Actions、发 Pages
- **不能发 npm**：`npm whoami` 返回 `ENEEDAUTH`，没有发布凭据；所以 README 里不出现 npm 安装命令
- **不能删仓库**：账号缺 `delete_repo` 权限，删库需要手动去网页操作
- 不能部署自有服务器（无 SSH 私钥、无云厂商凭据）

## 文档

- [`AGENTS.md`](AGENTS.md)：目录约定、环境、agent 技能与 issue tracker 规则
- [`docs/agents/`](docs/agents/)：issue tracker / triage labels / domain 三份配置，外加每个项目的 spec