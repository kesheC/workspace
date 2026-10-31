# repropack —— 把一次失败的运行打包成别人一条命令就能复现的 bundle

## 痛点
「在我这儿能跑」「你贴一下报错」之间的往返是整个开发流程里最贵的一段。
一个 bug 报告通常只包含截图和半截栈，缺少三样决定性的东西：**确切的命令**、**当时的环境指纹**、
**重现所需的那几个文件**。等人把这三样补齐，上下文已经丢了。

同时还有反向风险：为了复现而把整个工作目录打包发出去，等于把 `.env`、token、私有路径一起交出去。

## CLI 设计（命令名 repropack）
1. `repropack capture -- <command...>` 跑一次命令并落盘一个自包含 bundle：
   - 命令 argv（逐字节）、cwd、退出码/信号、开始与结束时间、耗时
   - 环境指纹：Node 版本、平台、架构、CPU 数、package manager 及其 lockfile 摘要
   - git 快照：commit、分支、dirty 状态、staged/unstaged/untracked 列表
   - 文件集合：按 `--scope changed|tracked|all` 选取，再叠加**栈帧闭包**（栈里出现过的文件即便不在 changed 里也要收）
   - 字节预算：单文件 `--max-file-bytes`、整包 `--max-bundle-bytes`，超了按优先级截断并如实记账
2. `repropack replay <bundle-dir>` 把 bundle 还原到临时 workdir 并按原 argv 重跑，
   默认 `shell: false` 保证 argv 可复现；返回退出码，支持 `--ignore-exit-code` 与 `--keep`。
3. `repropack verify <bundle-dir>` 作为**发出前的最后一道闸门**：
   泄漏疑似（密钥模式命中）、完整性不符（sha256 对不上）、缺文件、超限、无可复现命令、绝对路径、home 路径泄漏。
   `--strict` 时 warning 也按不通过处理。
4. `repropack inspect <bundle-dir>` 打印 bundle 摘要（`--json` 给机器读）。
5. `repropack pack` / `unpack` 把 bundle 打成一个归档文件便于传输；打包前必须先过 readBundle 的完整性检查。
6. `repropack report <bundle-dir>` 生成一段可以直接粘进 issue 的 Markdown（含标题、命令、环境、文件清单、脱敏统计、stderr/stdout 尾部）。

## 实现要点
- **脱敏引擎**：规则表覆盖 `.env` 值、URL 里的 userinfo、Authorization 头、常见 token 前缀（`ghp_`/`AKIA`/`sk_live_`/`-----BEGIN`）、高熵串。
  替换样式三种：`placeholder` / `hash` / `length`，并且必须**用偏移量一次性渲染**而不是反复 `replace`——
  否则后面的规则会匹配到前面刚生成的占位符，产生二次污染。
- **hash 稳定性**：`bundleId` 排除时间戳与 `durationMs`，同样的输入两次 capture 必须得到同一个 id。
- **执行层**：`spawn` 一律 `shell: false`，argv 原样传递；输出分别捕获并各自限流。
- **栈解析**：兼容 Node / Python / Go / Java 四种栈格式，`file://` URL 要剥离。
- **积分记账**：截断、跳过、脱敏都进 `RedactionReport` / `SkippedFinding`，report 里如实呈现，不许静默丢弃。
- 目录：`src/capture/ src/redact/ src/bundle/ src/replay/ src/verify/ src/report/ src/archive/ src/export/ src/cli/ src/util/`。

## 测试要求
- 栈帧解析：四种语言格式 + file URL + 运行时路径过滤
- 闭包：从栈帧出发的 import 闭包，含相对路径与 `node:` 内建跳过
- 扫描：changed / tracked / all 三种 scope 在真实 git 仓库（临时目录）里的行为
- 脱敏：每类规则命中与不命中、偏移量渲染不会被二次匹配、hash 稳定性
- 归档：同输入两次 pack 字节相同、`../x` 逃逸必须拒绝且一个文件都不落盘
- report：不泄露 homedir 与 bundle 根、尾部行数准确、`... and N more` 的 N 要对
- 至少 300 个用例（实际 324）

## README 必须提供
一个真实的最小复现示例（从失败命令到 `repropack replay` 跑回同样退出码），
以及 `repropack verify` 拦下一个含泄漏的 bundle 的输出。

## 通用要求
- 先读 ../docs/agents/project-playbook.md（相对 workspace 根：docs/agents/project-playbook.md），严格遵守里面的骨架、CI、README、质量闸门、交付报告格式。
- 工作目录：projects/<项目名>/（workspace 根 E:\deepseek_workspace\github）。
- 0 运行时依赖。devDependencies 只允许 typescript / @types/node / vitest。
- 测试离线、确定性、不打网络。
- 完成后必须：npm install 生成 lockfile → npm run build → npm test 全绿 → git init → gh repo create kesheC/<项目名> --public --source=. --remote=origin --push → gh repo edit --add-topic ...
- CI 必须跑绿（gh run list 确认 conclusion=success；CI 慢就 wait 再查，最多等 15 分钟）。
- 交付报告严格按 playbook 第 8 节格式发给 lead。
