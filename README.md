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

九个零运行时依赖的 Node CLI，各自独立建库、六路矩阵 CI（ubuntu / windows × node 20 / 22 / 24）全绿，
每次打 tag 由 release workflow 构建 tarball、在干净目录里安装并运行它，再上传到 Release。

| 项目 | 说明 | 仓库 |
| --- | --- | --- |
| repropack | 把一次失败的运行打包成自包含、脱敏、别人一条命令就能复现的 bundle | [kesheC/repropack](https://github.com/kesheC/repropack) |
| clidoc | 把真实命令输出写回 README，让文档不会和 CLI 漂移 | [kesheC/clidoc](https://github.com/kesheC/clidoc) |
| envpulse | `.env` 漂移与密钥泄漏体检 | [kesheC/envpulse](https://github.com/kesheC/envpulse) |
| gitignore-doctor | 解释并审计 `.gitignore` 规则：哪一行让这个路径被忽略 | [kesheC/gitignore-doctor](https://github.com/kesheC/gitignore-doctor) |
| jsonl-beaver | 流式 JSONL / NDJSON 日志分析，GB 级不爆内存 | [kesheC/jsonl-beaver](https://github.com/kesheC/jsonl-beaver) |
| apidiff | 在发布前发现 OpenAPI / JSON Schema / .env 的破坏性变更 | [kesheC/apidiff](https://github.com/kesheC/apidiff) |
| releaseforge | 把 Conventional Commits 变成一次 release：计划 bump、跑发布闸门、冻结 CHANGELOG、打 tag、出 tarball | [kesheC/releaseforge](https://github.com/kesheC/releaseforge) |
| httptape | HTTP 录制 / 回放测试库：把真实请求录成 tape 文件，测试里离线回放 | [kesheC/httptape](https://github.com/kesheC/httptape) |
| hooktap | 本地 webhook 检查器：捕获请求的原始字节、按 GitHub 方式验 HMAC 签名、原样重放 | [kesheC/hooktap](https://github.com/kesheC/hooktap) |

### 安装方式说明

这九个包**都没有发布到 npm registry**（`clidoc` 与 `repropack` 这两个名字已被别人的项目占用，其余七个名字都还空着）。
每个 Release 都附带一个可以直接安装的 tarball，资产名固定、不带版本号，所以这条命令在哪个版本都能用：

```console
$ npm install -g https://github.com/kesheC/<name>/releases/latest/download/<name>.tgz
```

> `npm install -g git+https://github.com/...` 装不起来：checkout 里没有构建产物，而全局安装
> 会跳过 `devDependencies`，没有 `tsc` 可以编译。这也是本仓库统一改用 tarball 的原因。

每个 tarball 里只有 `dist/`、`README.md` 和 `LICENSE`：没有 `src/`、没有测试、没有 `.js.map`。
不发源码的包里带 sourcemap 只是指向一个读者永远打不开的文件，所以九个包的发布构建都关掉了它，
并由各自的 `tests/package.test.ts` 与 CI 的打包检查同时守着。

### 发版记录

| 版本 | 日期 | 内容 |
| --- | --- | --- |
| [releaseforge v0.1.0](https://github.com/kesheC/releaseforge/releases/tag/v0.1.0) · [httptape v0.1.0](https://github.com/kesheC/httptape/releases/tag/v0.1.0) · [hooktap v0.1.0](https://github.com/kesheC/hooktap/releases/tag/v0.1.0) | 2026-11-05 | 三个新项目首版：`releaseforge`（发布链自动化 CLI，五道发布闸门 + Conventional Commits bump 计划 + CHANGELOG 冻结）、`httptape`（HTTP 录制/回放测试库，tape 格式带 formatVersion、strict 模式未匹配即失败）、`hooktap`（本地 webhook 捕获/验签/重放，原始字节保真、x-hub-signature-256 常时比较）。三者沿用六仓的生产手册：零运行时依赖、六格矩阵 CI + coverage 闸门 + npm audit 闸门、README 双语 + 真实转录（vtf3 逐块复验 34/34、15/15、10/10）、tag 驱动 Release 双名资产 + sha256 清单、干净目录安装验证 `--version` |
| [releaseforge v0.1.1](https://github.com/kesheC/releaseforge/releases/tag/v0.1.1) · [httptape v0.1.1](https://github.com/kesheC/httptape/releases/tag/v0.1.1) · [hooktap v0.1.1](https://github.com/kesheC/hooktap/releases/tag/v0.1.1) | 2026-11-05 | 三新仓全面审计后的修复版：`releaseforge` 修掉 `npm pack` 目标路径未加引号（含空格路径失败）、`freeze --dry-run` 实际会写 CHANGELOG 的虚假承诺、首发版本生成 `vX...vX` 自比死链、非 git 目录裸栈（现在退出 2）、tag 已存在时只说失败不给出路（现在提示 `git tag -d`）、UTC 日期在东八区晚间写昨天、未知命令 usage 误打 stdout；`httptape` 修掉 bin 缺 shebang（Unix 全局安装直接不可执行）、录制对响应断开永不 resolve、无超时永久挂起、played 指纹按原始路径串分叉、tape 落盘非原子；`hooktap` 修掉大小写不同的签名头被静默漏检、捕获落盘非原子且吞错、带请求体的 GET/HEAD 重放声明 content-length 却不发体、空闲超时冒充硬时限、非 UTF-8 载荷经 utf8 往返失真、EADDRINUSE 裸栈、413 请求体上限；三仓同时补齐 README 转录守卫的诚实声明与 vitest 注释指向 |
| [hooktap v0.1.2](https://github.com/kesheC/hooktap/releases/tag/v0.1.2) | 2026-11-05 | v0.1.1 装包复验抓到的漏网缺陷：hooktap 的 `dist/cli.js` 仍缺 shebang（审计轮只修了 httptape 同款），从 Release 资产安装后执行 `hooktap` 被 bash 当 shell 脚本跑，`import: command not found`；现在 bin 带 `#!/usr/bin/env node`，守卫测试断言 shebang 必须在源码第一行，从 Release 资产装包后 `hooktap --version` 实测通过 |
| [releaseforge v0.1.2](https://github.com/kesheC/releaseforge/releases/tag/v0.1.2) · [httptape v0.1.2](https://github.com/kesheC/httptape/releases/tag/v0.1.2) · [hooktap v0.1.3](https://github.com/kesheC/hooktap/releases/tag/v0.1.3) | 2026-11-05 | 第四轮全面审计（每仓再派独立审计员探针实测）后的修复版：`releaseforge` 修掉 origin 带 token 时凭据泄进 stderr 警告（现在只打剥凭据后的 URL）、CLI 打轻量标签而 README 教 `--follow-tags` 导致标签永远到不了远端、Release 静默不跑（现在打附注标签 + 文档改两步推送）、`~~~` 与 ``` ``` ``` 互不闭合的围栏状态机、双 `[Unreleased]` 直接拒绝、release.yml 提取 notes 不感知代码围栏会截断、`@scope/thing` 包的陈旧 tarball 清理拼错路径、跨行版本常量声明漏检导致守卫假绿；`httptape` 修掉头名含凭据语义（`x-api-key`、`session-token`…）不脱敏、URL userinfo 入库前不剥除、错误消息带查询串、Buffer 请求体经 utf8 失真、tape 的 `status` 不校验整数范围、磁带落盘不自校验、stub 命中时不回放真实交互；`hooktap` 修掉存储 `raw` 为 `null` 时验签把字符串 "null" 拿去哈希、`captures:[null]` 裸 TypeError、未知旗标/旗标吞值/缺值静默忽略、`replayCapture` 同步抛违背 Promise 契约、IPv6 host 打印非法 URL、README 的 "same path" 声明与实现不符、`realpathSync` 入口守卫（v0.1.3 独立发版）。装包复验：三个 tarball 经 asset-id 端点下载、sha256 与远端 SHA256SUMS 逐字一致、`--version` 全对 |
| [v0.1.7](https://github.com/kesheC/repropack/releases/tag/v0.1.7) | 2026-11-01 | 六个包统一发版：修正 README 里与实际不符的输出、补齐发布链路的闸门、发布构建停发 sourcemap、`files` 收紧为 `dist` + `README` + `LICENSE` |
| [v0.1.8](https://github.com/kesheC/repropack/releases/tag/v0.1.8) | 2026-11-01 | 发布与 CI 闸门改成「把闸门自己的 shell body 抽出来真跑」而不是断言 YAML 里有某个字符串；补回重写时丢掉的三条守卫（先 `--draft=false` 发布再上传、每个 bin 都冒烟测、build 先清 `dist`）；envpulse 补上它一直没有的 tag/version 闸门；repropack 的 `--version` 断言改为比对 `TOOL_VERSION`，版本号不再变成测试失败 |
| [v0.1.9](https://github.com/kesheC/repropack/releases/tag/v0.1.9) | 2026-11-01 | 六仓 README 补中文：十二节（clidoc/envpulse/jsonl-beaver 为段内镜像）全部有中文对照；clidoc / envpulse / jsonl-beaver 修掉「命令不读的选项被静默忽略」，越界 flag 现在 exit 2 并指出真正读它的命令；apidiff 的 FAQ 不再声称 `diffSchemas` 会拒绝数组根（它返回一条 `schema.replaced`，只有 CLI 的 `assertSchemaRoot` 会拒）；0.1.8 里对 v0.1.7 守卫的口径逐仓校正 |
| [v0.1.10](https://github.com/kesheC/repropack/releases/tag/v0.1.10) | 2026-11-01 | 六个 CLI 的参数解析器统一口径：`--flag=value` 在六仓全部可用（clidoc / apidiff / gitignore-doctor 原本直接报 unknown），布尔开关被传值时一律 exit 2 而不是静默忽略；`--` 终止符补齐到 gid 与 apidiff，以 `-` 开头的文件名终于能被指名；repropack 把「缺值」与「不认识这个选项」拆成两条消息（原先 `capture --out` 会回答 `unknown option '--out'; did you mean '--out'?`），`did you mean` 也不再把破折号计入编辑距离、不再建议用户刚打的那个词；clidoc 拒绝 `render` / `list` 上的位置参数；envpulse 无参运行改为 exit 2；jsonl-beaver 命令名拼错时先报命令名而不是缺文件；gitignore-doctor 的 `--cwd` 把「路径不存在」「不是目录」「不是 git 仓库」三种情况分开 |
| [v0.1.11](https://github.com/kesheC/repropack/releases/tag/v0.1.11) | 2026-11-01 | 六个 CLI 的「谁的回答算数」统一口径：拼错的选项不再被 `--help` 挡住（repropack / gid / jlb 原本打帮助并 exit 0），`--version` 一律只在顶层生效、子命令上 exit 2 并指出正确写法，以破折号开头的第一个词按「拼错的选项」报而不是「未知命令」；拿到 `--json` 的调用方在失败时也能拿到文档——`{"error":{"message":...,"exitCode":n}}` 写 stdout，退出码就是真实用的那个（repropack / envpulse / jlb / gid 四处补齐，apidiff 本来就有）；gitignore-doctor 把 V8 编译不了的正则变成 `INVALID` 发现项而不是整行 pattern 吐回 stderr 的 exit 1，规则文本一律缩写；apidiff 的单个 `-` 是路径不是坏选项 |
| [v0.1.12](https://github.com/kesheC/repropack/releases/tag/v0.1.12) | 2026-11-02 | 管道下游先走不再算失败：五个 CLI 原先没有 stdout 的 `error` 监听器，把 `<cli> ...` 的输出接进 `head -1` 时下一次写入触发 EPIPE，Node 当作 unhandled error 打栈并 exit 1，跑完的活看起来像挂了。现在 stdout 上的 EPIPE 读作「读者已经拿到想要的」并 exit 0，stderr 上的 EPIPE 吞掉继续跑（它只是进度与警告），其它流错误照旧抛出。jsonl-beaver 早在 v0.1.10 就有这层守卫，这轮把它补到其余五个；每个仓新增 `tests/pipe.test.ts` 两个用例（spawn 后立刻 `stdout.destroy()`，不靠时序运气），其中一个断言真实错误码仍是 2 而不是被伪装成 0 |
| [v0.1.13](https://github.com/kesheC/repropack/releases/tag/v0.1.13) | 2026-11-02 | 六仓 README 里每一段 `$` 转录都改成能在一台干净机器上照着敲出来的形态，并用脚本逐块真跑比对（repropack 20、clidoc 55、envpulse 27、gitignore-doctor 26、jsonl-beaver 33 块）：缺前置命令的补前置（`cd demo`、`node demo/make-fixture.mjs`）、依赖别处文件的补 `printf` 造夹具、输出带机器绝对路径的用 `sed` 脱敏、把渲染器专有的 `[exit code: N]` 尾行换成 `; echo "exit $?"`、`time` 的 wall-clock 移出转录、`TIMEFORMAT` 换成合法的 `%R`。同时修掉 CHANGELOG 从 0.1.2 起就写错的一行——Quality 说矩阵是 Node 20 and 22，实际一直跑 20 / 22 / 24（0.1.0 与 0.1.1 保留原样，那时确实只有 20 和 22）；这些段正是 GitHub Release notes 的来源，历史 Release 也一并纠正。jsonl-beaver 从 0.1.11 直接到 0.1.13，它没有 0.1.12：那轮修的封闭管道该仓 0.1.11 就已具备 |
| [v0.1.14](https://github.com/kesheC/repropack/releases/tag/v0.1.14) | 2026-11-02 | 六仓补上 GitHub 社区档案缺的三件文件（`CONTRIBUTING.md` 写死代码真正依赖的约束与三道本机闸门、`CODE_OF_CONDUCT.md` 用 Contributor Covenant 2.1 且举报指向私密 advisory 通道、`.github/PULL_REQUEST_TEMPLATE.md` 要求贴命令与输出），社区档案完整度从 57% 到 100%；重新生成 `package-lock.json`（它停在 0.1.0、engines 写 `>=20`、repropack 的 bin 记成 `dist/cli.js`），CI 从不细看所以一直没暴露；bug 模板不再要 0.1.1 那个九个版本前的例子（安装字段改用 `releases/latest/download/`），channel picker 补上通往私密安全报告的 `contact_links`； **clidoc 与 jsonl-beaver 的 `npm run typecheck` 从来没打开过测试文件**（tsconfig 的 include 只有 `src`），CONTRIBUTING 写着「tests included」，现在 include 加上 `tests`、clidoc 的 `rootDir` 移到 `tsconfig.build.json`，两仓探针都能让 typecheck 变红；repropack 的 setup 块改成 `dist/cli/index.js`，四仓 CONTRIBUTING 里那句「CI 会重跑 README 转录」改成实情（只有 clidoc 与 apidiff 有该步骤） |
| [v0.1.15](https://github.com/kesheC/repropack/releases/tag/v0.1.15) | 2026-11-02 | 六个包的 README 里手写的数字全部挂上守卫：脱敏规则数 / 归一化链长 / 严重度分布 / demo 夹具行数与规则数 / `check` 汇总 / agg 表，都由测试从代码里的表或生成器重新算出来比对，改规则或改夹具而不改文档会直接红；`CONTRIBUTING.md` 改成点名 CI 真正重跑哪些块、哪些靠手验；envpulse 把已经过期两版的 tarball 体积声明换成「发出去只有 `dist/`、`README.md`、`LICENSE`」这种由 CI 每次断言的结构承诺 |
| [v0.1.16](https://github.com/kesheC/envpulse/releases/tag/v0.1.16) | 2026-11-02 | envpulse 与 apidiff 各补一节文档、并让它们真的进到 tarball 里：envpulse 增加「在 monorepo 里」章节，讲清在 workspace 根跑 `check` 会把找到的每一份 env 文件互相比较——两个各自都对的包也会报 1 high / 2 medium，随后给出逐包检查都干净的真实输出，以及在本 workspace 根跑 `check --json --cwd .` 的带日期结果（6 份 env、388 个源文件、41/15/2、58 条 finding、exit 1，全部是跨包误配而非工具缺陷）；apidiff 增加「当成 GitHub Action」章节，把整段 step 抄全，包括 `actions/checkout` 单分支浅取之后必须显式写的 `+refs/heads/main:refs/remotes/origin/main` refspec，以及「契约文件是本分支新增」时必须走的 else 分支（否则空基线被读成 `error: invalid JSON` 退出 2）。`tests/action.test.ts` 用真实 `origin`、按 runner 的方式单分支检出、在 `bash -e` 下跑那段正文，三种情形分别断言 |
| [v0.1.17](https://github.com/kesheC/repropack/releases/tag/v0.1.17) | 2026-11-02 | 六仓的 `npm run dev` 全部启动不了，本版修掉并顺带把 workspace 的生产手册改成能照着抄的样子。`dev` 原本是 `node --experimental-strip-types src/cli.ts`，而这些仓库的源码一律用 `.js` 后缀导入同级模块（`moduleResolution: NodeNext` 编译产物才能解析），类型剥离加载器不会把 `./errors.js` 映射回 `./errors.ts`，脚本在打印第一行之前就以 `ERR_MODULE_NOT_FOUND` 退出 1；没有测试也没有工作流调用它，所以六仓一起坏了很久没人发现。现在改成先 build 再跑 dist，六仓 `dev --version` 全部 rc=0 并打出正确版本。`docs/agents/project-playbook.md` 同步重写：Node 骨架的 `dev`、`engines`（`>=20` → `>=20.11`，下限必须等于矩阵最小版本）、tsconfig（拆成 `noEmit` 覆盖 src+tests 与只编 src 的 build 层，这正是 0.1.14 那轮发现的「typecheck 从不打开测试文件」的根因）、CI 矩阵与 actions 版本、发布链路六条不可省略的理由（资产双名、校验和不能 cp、tag/version 闸门在任何 gh 调用之前……）、推送以远端 sha 为准、README 转录四条硬规则与「手写数字最先腐烂」；质量闸门从 9 条扩到 4 组 20 条 |
| [v0.1.18](https://github.com/kesheC/repropack/releases/tag/v0.1.18) | 2026-11-02 | repropack 与 clidoc 各修一处「只读一次才成立」的转录。repropack 的快速开始第二块 `capture --out ./bundle` 在同一个目录里重跑时会复用已存在的 `./bundle` 而不是重建，第二遍输出从 `files 4 (1.3 KB)` 漂到 `files 5 (4.2 KB)`、`packed 10 file(s)` 漂到 `packed 11`；clidoc 的 tag 闸门示例断言 `test -f RELEASE_NOTES.md` 打印 `not written`，而同一页下面那个「tag 匹配」的示例会在 `gh` 拒绝假 token 之前就把 `RELEASE_NOTES.md` 写出来，从上往下读一遍成立、在同一个 shell 里读第二遍不成立。两块现在都先清掉自己的产物（`rm -rf ./bundle demo.repropack` 与 `rm -f RELEASE_NOTES.md`），vtf3 连跑两遍都是 24/24 与 56/56 全 MATCH |
| [v0.1.19](https://github.com/kesheC/repropack/releases/tag/v0.1.19) | 2026-11-02 | 六仓再修一处六个人一起犯的错：`tsconfig.json` 都不写 `noEmit`。`npm run typecheck` 带 `--noEmit` 所以闸门一直是绿的，可编辑器与随手敲 `npx tsc` 的人只读配置文件，于是一次全量编译就把 `.js`、`.d.ts`、`.js.map` 落在每个 `.ts` 旁边（实测 repropack 186 个、apidiff 90 个、envpulse 72 个、gitignore-doctor 69 个、clidoc 与 jsonl-beaver 各 63 个未跟踪文件，下一次 `git add .` 就会把它们扫进提交），拦在中间只有包内容测试。现在 `noEmit` 落在基础层，编译输出变成 build 层必须显式索取的东西；这一改立刻暴露出 envpulse 的 build 配置继承了新的 `noEmit`、退出 0 却什么都不产出（同样只有包测试能发现）。两个开关连同 build 层的 `rootDir` 与 `include: ["src"]` 现在都由 `tests/package.test.ts` 断言。clidoc 的 build 配置原本用 `exclude` 而不是 `include`，于是继承了基础层的 `tests`：`tests/` 下任何一个普通 `.ts`（helper，不是测试）都会进来，在 `rootDir` 上报 TS6059 把发布构建弄红，现在只编 `src/` |
| [v0.1.20](https://github.com/kesheC/repropack/releases/tag/v0.1.20) | 2026-11-02 | 一处供应链、一处 git 属性、一句数错的承诺。`npm audit` 在六个仓库都报 `3 moderate, 1 high, 2 critical`，六个 advisory 全部从 `vitest 2.1.9` 进来（`tinypool` 的原型污染 gadget 两条 critical、`@vitest/mocker` 的路径穿越与手动 mock 注入、`vite`/`esbuild` 的开发服务器转发）；包本身零运行时依赖，所以这不是用户面的洞，但贡献者敲 `npm test` 时全跑在上面，现在 `vitest` 是 `^4.1.12`、树里 0 漏洞。这次升级顺带把 `vite 8` 的 `engines` 地板（`^20.19.0 或 >=22.12.0`）暴露出来，比六仓声明给用户的 `>=20.11` 高一个小版本——两个承诺不是一回事，地板保持 20.11 不动，改在 `CONTRIBUTING.md` 里说清「用这个包」与「改这个包」分别需要什么。第二处：`.gitattributes` 里的 `package-lock.json text eol=lf -diff` 读起来像「也当文本看」，实际是 `diff` 属性取值为 unset，即**不要 diff 这个文件**；于是每次依赖变更都渲染成 `Binary files differ`，一行都读不到，而这偏偏是审依赖时唯一要读的文件。受控实验（一次性仓库、同一份 lock、三种属性）确认只有 `-diff` 会变 Bin，`--text` 能逼出正文但 `--text --stat` 仍打 Bin，`git check-attr` 会说 `diff: unset`；现在属性是 `text eol=lf`，`tests/package.test.ts` 直接问 git（`-diff`、`diff=false`、`binary` 三种写法终点相同，读文件判断不了）。第三处：六份 `CONTRIBUTING.md` 都写「CI 跑的那三条命令」，而 CI 从 audit 步骤落地那天起跑四条，照列表做的贡献者恰好会跳过唯一读整条供应链的那步；标题去掉数字、列表补上 `npm audit --audit-level=high`，并由 `tests/workflow.test.ts` 把四个名字同时对着两个文件走一遍 |
| [v0.1.21](https://github.com/kesheC/repropack/releases/tag/v0.1.21) | 2026-11-02 | dependabot 开通后第一次自动开 PR，六个仓库各来两个，正好当成一次免费的兼容性实验： actions 那个（`checkout` v5.1.0→v7.0.1、`setup-node` v5.0.0→v7.1.0）六仓 6/6 全绿， 于是把 `uses:` 指向它提议的两个 commit（`3d3c42e5…` / `949feb24…`），可读版本留在 sha 旁边； npm 那个在 node 20 列红，查明是 TypeScript 7 不再自动引入 `@types/node`（`tsconfig.json` 现在显式写上） 加 `vitest 5` 的 `engines` 要求 `^22.12` 而包承诺 20.11 —— 拒掉这两个大版本（只拒 major，minor/patch 照来， **安全更新不受 `ignore` 过滤**），并在 `dependabot.yml` 里写明理由。 顺带修掉 `package-lock.json` 那条守卫的判据：它原本用 `git --version` 判断 git 可用， 而 `git archive` 导出的副本里 git 装着、属性查询却 exit 128，测试会为一件与属性无关的事变红； 现在问 git 这个目录是不是它自己的工作树（且必须就是这一个，嵌套在别的仓库里的副本会替那个仓库回答） |
| [v0.1.22](https://github.com/kesheC/repropack/releases/tag/v0.1.22) | 2026-11-02 | 六仓第一次真正量自己的覆盖率，并把 TypeScript 升到 7。`@vitest/coverage-v8` 进 devDependencies，`npm run coverage` 跑同一套测试但按阈值失败——不是打印一张没人看的表：阈值写在 `vitest.config.ts` 的 `coverage.thresholds`（80 语句 / 70 分支 / 85 函数 / 80 行），故意略低于当前实测，跌破时要补测试而不是删断言。这份报告第一次就把一个陷阱量了出来：报告里的 `exclude` 必须排掉 `dist/**`，否则测试 import 的构建产物与 source map 回源的源码会被算成两个模块，同一份代码量两遍——repropack 上读到 46.75%，真值是 89.66%，正好腰斩。CI 只在一条腿跑 coverage（Linux / Node 24），因为它是唯一要再跑一遍全量 suite 的闸门，六格都跑只是把成本翻倍，而固定同一条腿前后两次的数字才可比。阈值只被 `vitest run --coverage` 读取，所以 `tests/workflow.test.ts` 同时钉住三件事：四个键都在配置文件里、CI 里真有一格在跑它、那一步带 `if:`——否则四个数字会变成一份没人执行的策略却看着像在执行。TypeScript 从 5.9.3 到 7.0.2：当初在 dependabot 里拒掉这个 major 的理由是它不再自动引入 `@types/node`，这轮实测发现修法只是基础 tsconfig 里一行 `types: ["node"]`，于是 typescript 移出 `ignore`（`vitest` 与 `@types/node` 仍在，注释里写明各自在等什么条件），源码一行没改 |
| [v0.1.23](https://github.com/kesheC/repropack/releases/tag/v0.1.23) | 2026-11-02 | dependabot 的 `ignore` 名单只写了一半，而 npm 把它们当一个决定。`@vitest/coverage-v8` 的 `peerDependencies` 是**精确版本** `vitest: "4.1.12"`，两个包只能成对发版：名单拦住了 `vitest` 和 `@types/node`，却漏了 coverage-v8，于是 coverage-v8 进树第二天 dependabot 就单独给它开 PR，把 4.1.12 提到 5.0.5——这个组合装不上，npm 直接在 pin 死的 peer 上 `ERESOLVE`，六个仓库六格 CI 全红，而本地无论怎么修都救不回来。现在两半一起 ignore，每行写明解除条件（vitest 5 的 `engines` 地板降到本包承诺的 20.11、或本包地板抬到 `^22.12`，两条同时满足才解除），免得这条 ignore 活得比理由长。规矩不靠记性：`tests/workflow.test.ts` 新增一段，把 `package.json`、`package-lock.json`、`dependabot.yml` 并排读——凡是「声明了的依赖 pin 了另一个同样声明了的依赖的精确版本 peer」，两个要么都 ignore 要么都不 ignore；此外每个被 ignore 的名字必须仍在本仓的 devDependencies 里（防止名单替一个已经不存在的包挡路）。删掉条目会红并指名道姓是哪个包、哪个版本；加一条 `left-pad` 会红并说 `dependabot ignores left-pad but nothing declares it`。反向验证做过：删掉新条目复现了真实的 ERESOLVE，加回来即恢复全绿 |

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
- [`docs/agents/project-playbook.md`](docs/agents/project-playbook.md)：九个项目共用的生产手册（骨架、CI、发布链路、README 规范、质量闸门、交付报告）
- [`CONTRIBUTING.md`](CONTRIBUTING.md)：一处改动该提到哪个仓库；`projects/*/` 在这里是被忽略的独立 checkout
- [`SECURITY.md`](SECURITY.md) / [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)：报告渠道（私密 advisory，不是公开 issue）
- [`scripts/github-posture.sh`](scripts/github-posture.sh)：一行一仓打印 version / topics / 社区档案 / secret scanning / push protection / 私密报告 / 最新 CI / 最新 release，有一列不达标就退出 1