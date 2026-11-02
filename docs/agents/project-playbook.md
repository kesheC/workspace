# 项目生产手册（Agent 必读）

本手册规定本工作区里「从零做一个项目 → 推上 GitHub」的标准流程与质量标准。
**项目质量优先于数量**。任何一条验收项不通过，就不算完成。

---

## 0. 铁律

1. **不引入运行时第三方依赖**，除非能一句话说清为什么必须（默认 0 依赖，Node 只用 stdlib + `node:` 前缀）。
2. **测试必须离线可跑**：不访问网络、不依赖用户主目录里的真实文件、不依赖本机时区/locale 的默认值。
3. **自己先跑通再交付**：`npm ci && npm run build && npm test` 三条命令都必须退出码 0，并且把真实输出贴进交付报告。
4. **绝不伪造**：不写假的 badge、不写假的功能清单、README 里出现的每个命令都必须真的能跑。
5. **Windows 优先**：路径处理用 `node:path`，不写死 `/tmp`、不假设 shell 是 bash。
6. 提交信息用英文 Conventional Commits（`feat:` / `fix:` / `test:` / `docs:` / `chore:`）。

---

## 1. Node 项目骨架

`package.json`（按需改 name/description/bin）：

```json
{
  "name": "<name>",
  "version": "0.1.0",
  "description": "<一句话英文描述>",
  "type": "module",
  "bin": { "<name>": "./dist/cli.js" },
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": { "types": "./dist/index.d.ts", "import": "./dist/index.js" }
  },
  "files": ["dist", "README.md", "LICENSE"],
  "engines": { "node": ">=20.11" },
  "scripts": {
    "clean": "node -e \"require('node:fs').rmSync('dist',{recursive:true,force:true})\"",
    "build": "npm run clean && tsc -p tsconfig.build.json",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "dev": "npm run build && node dist/cli.js",
    "prepack": "npm run build"
  },
  "keywords": ["..."],
  "license": "MIT",
  "devDependencies": {
    "@types/node": "^22.10.2",
    "typescript": "^5.7.2",
    "vitest": "^2.1.8"
  }
}
```

`dev` 不能写 `node --experimental-strip-types src/cli.ts`：本骨架的源码一律用 `.js` 后缀导入同级模块（`moduleResolution: NodeNext` 要求），而类型剥离加载器不会把 `./errors.js` 映射回 `./errors.ts`，脚本会以 `ERR_MODULE_NOT_FOUND` 立即退出 1。先 build 再跑 dist，构建不到两秒。

`engines` 的下限要等于 CI 矩阵里最小的那个 Node 小版本（`>=20.11` 而不是 `>=20`），否则「我们支持的版本」和「我们测过的版本」就是两句不同的话。

`tsconfig.json`（给编辑器和 `npm run typecheck` 用，**必须把 tests 也纳入**）：

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2023"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "declaration": true,
    "sourceMap": true,
    "noEmit": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src", "tests"]
}
```

`tsconfig.build.json`（只给发版用，只编译 src）：

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noEmit": false,
    "outDir": "dist",
    "rootDir": "src",
    "sourceMap": false,
    "declarationMap": false
  },
  "include": ["src"]
}
```

两层分开的理由：`include: ["src"]` 的单一 tsconfig 会让 `npm run typecheck` 永远不打开测试文件，于是测试里的类型错误一路绿到 CI；反过来把 `rootDir` 留在 tsconfig.json 又会让 tests 触发 TS6059。所以 `noEmit` 那层收 src+tests、发版那层收 src 并自带 `rootDir`。`sourceMap` 在发版层关掉：`files` 只发 `dist/`，`.js.map` 指向的 `../src/*.ts` 不在包里，等于让下载体积翻倍换一堆死链接。

v0.1.0 必须自带一份**真实可用的 tarball 检查**：`npm pack --dry-run` 输出里 `dist/` 和 `README.md` 都在。

---

## 2. Python 项目骨架

`pyproject.toml`（hatchling，0 运行时依赖）：

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "<name>"
version = "0.1.0"
description = "<一句话英文描述>"
readme = "README.md"
requires-python = ">=3.10"
license = { text = "MIT" }
dependencies = []

[project.scripts]
<name> = "<pkg>.cli:main"

[project.optional-dependencies]
dev = ["pytest>=8", "ruff>=0.6"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"

[tool.ruff]
line-length = 100
target-version = "py310"
```

---

## 3. 目录结构（所有项目统一）

```
<name>/
├── .github/
│   ├── ISSUE_TEMPLATE/{bug_report.yml,config.yml,feature_request.yml}
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/{ci.yml,release.yml}
├── LICENSE            # MIT，Copyright (c) 2026 kesheC
├── README.md          # 中英双语（见第 6 节）
├── CHANGELOG.md       # Keep a Changelog + SemVer（见第 6 节）
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── .gitattributes     # package-lock.json 标 text eol=lf（别再写 -diff）
├── .gitignore
├── package.json / pyproject.toml
├── tsconfig.json      # 编辑器 + typecheck，含 src 与 tests
├── tsconfig.build.json# 只编 src，自带 rootDir
├── src/               # 源码；cli 与库分离：index.ts 只导出库 API，cli.ts 只做参数解析
└── tests/
```

**库 API 与 CLI 必须解耦**：`index.ts` 不读 `process.argv`、不调 `process.exit`，这样别人能 import 复用。

`.gitattributes` 里要给锁文件写的是 `package-lock.json text eol=lf`，**不是** `text eol=lf -diff`：`-diff` 不是「也顺便当文本看」，它是 `diff` 属性取值为 unset，意思是「这个文件不要给 diff」。带上它，`git diff` 只回一句 `Binary files differ`，锁文件的版本漂移就永远看不见了 —— 正好是这句话本来想避免的后果。

最小复现（三行就够）：提交一份 `package-lock.json`，改一个字符，再分别在没有属性 / `-diff` / 只有 `text eol=lf` 三种情况下看 `git diff --stat`：前两种是 `1 insertion(+), 1 deletion(-)` 与 `Bin 13 -> 13 bytes`，第三种才是 `1 insertion(+), 1 deletion(-)`；加了 `-diff` 的那份要 `git diff --text` 才能把正文逼出来 —— 注意 `git diff --text --stat` 仍然打印 `Bin`，`--stat` 不认这个开关，得拆成两条命令。`git check-attr -a -- package-lock.json` 会老实告诉你 `diff: unset`。**`-diff` 的用途是「明确不想要 diff」**（二进制产物、快照文件），不是「让 diff 好看」。

社区文件的四个入口各司其职，缺一个 GitHub 的 community profile 就不是 100%：`CONTRIBUTING.md` 写给要动代码的人，`CODE_OF_CONDUCT.md` 写给要吵架的人，`SECURITY.md` 写给要报漏洞的人（**不能走公开 issue**），issue/PR 模板写给要报问题的人。安全联系入口必须同时出现在 `SECURITY.md` 与 `.github/ISSUE_TEMPLATE/config.yml` 的 `contact_links` 里，否则 issue 选择页没有一条通往「不能公开说」的路。

---

## 4. GitHub Actions CI

Node（`.github/workflows/ci.yml`）：

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    name: ${{ matrix.os }} / node ${{ matrix.node }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
        # engines.node is >=20.11, so 20 is the floor we promise; 24 is
        # the current active LTS. Every version we claim to support runs here.
        node: [20, 22, 24]

    steps:
      - uses: actions/checkout@v5

      - name: Set up Node ${{ matrix.node }}
        uses: actions/setup-node@v5
        with:
          node-version: ${{ matrix.node }}
          cache: npm

      - name: Install
        run: npm ci

      # build only joins src; this also typechecks the test files.
      - name: Typecheck
        run: npm run typecheck

      - name: Build
        run: npm run build

      - name: Test
        run: npm test

      # The tarball is what users install, so the tarball is what CI runs.
      - name: Smoke test the packed tarball
        shell: bash
        run: |
          set -euo pipefail
          npm pack
          TARBALL=$(ls <name>-*.tgz | head -n 1)
          npm pack --dry-run --json > pack-meta.json
          node -e "
          const fs = require('fs');
          const files = JSON.parse(fs.readFileSync('pack-meta.json', 'utf8'))[0].files.map((f) => f.path);
          if (!files.includes('dist/index.js')) { console.error('dist/index.js is missing'); process.exit(1); }
          if (!files.includes('dist/index.d.ts')) { console.error('the types do not ship'); process.exit(1); }
          for (const bad of ['tests/', 'src/', 'node_modules/']) {
            if (files.some((p) => p.startsWith(bad))) { console.error('the tarball leaks ' + bad); process.exit(1); }
          }
          console.log('package contents ok: ' + files.length + ' entries');
          "
          SMOKE=$(mktemp -d)
          cd "$SMOKE"
          npm init -y > /dev/null
          npm install "$GITHUB_WORKSPACE/$TARBALL"
          expected=$(node -p "require('./node_modules/<name>/package.json').version")
          actual=$(./node_modules/.bin/<name> --version)
          [ "$actual" = "$expected" ] || { echo "version mismatch" >&2; exit 1; }
```

三处口径写死的原因：矩阵必须覆盖 `engines.node` 承诺的每一个主版本，`20` 是下限、`24` 是当前 active LTS，中间不能断；`actions/checkout@v5` / `actions/setup-node@v5` 是 Node 24 能跑起来的最低大版本；`Typecheck` 必须独立成步，因为 `npm run build` 只编 src，测试文件的类型错误只有 `tsc --noEmit` 会看。

`npm pack --dry-run` 那段要在 `cd` 去临时目录**之前**跑：`npm pack` 打的是当前目录的包，cd 之后再打会去检查那个空的包，永远通过。装到临时目录再跑 `--version`，是为了让 `node` 把 `<name>` 解析到 `node_modules/<name>`（真正发布的产物）而不是检出目录里的源码。

Python：

```yaml
name: CI
on:
  push: { branches: [main] }
  pull_request:
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
        python: ["3.10", "3.12"]
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python }}
      - run: pip install -e ".[dev]"
      - run: pytest
```

提交 **package-lock.json**（先 `npm install --package-lock-only` 生成，不发 node_modules），CI 用 `npm ci`。版本 bump 之后要重新生成它：锁文件的 `version` 与 `packages[""]` 里的 `engines.node` 会停在旧值，而 `npm ci` 不会因此失败，于是没有人会注意到。

### 发布链路（`.github/workflows/release.yml`）

Tag-driven：`on: push: tags: v*`，`permissions: contents: write`，固定 node 24（发版只跑一次，不需要矩阵）。步骤顺序是 Pack → Smoke test the tarball → Publish release assets，每步各带一条不可省略的注释级理由：

1. **资产双名**：打包出 `<name>-<ver>.tgz`，同时 `cp` 成稳定名 `<name>.tgz`。README 链的是 `releases/latest/download/<name>.tgz`，读者不需要知道版本号；版本名留着，旧链接才继续解析得通。
2. **sha256 必须重新生成，不能 `cp`**：校验文件名在它自己的内容里（`sha256sum x.tgz > x.tgz.sha256` 写出的是 `x.tgz  <hash>`），`cp` 出来的稳定名校验文件会指向版本名，`sha256sum -c` 当场失败。
3. **tag/version 闸门在任何 `gh` 调用之前**：`tag/version mismatch: tag says X, package.json says Y` 然后 exit 1。发版是 tag 驱动的，tag 是唯一说明「这次是哪个版本」的东西；对不上就会把 0.1.6 的资产挂到 v0.1.7 的标题下。
4. **Release body 从 CHANGELOG 抽 `## [<tag>]` 段**，抽不到就 `CHANGELOG.md has no section for <tag>` 失败。落在 release 页上的读者应该看到改了什么，不需要再跳一次；没有写法的 tag 是一个没人能评估的发布。
5. **`gh release edit --draft=false` 每次显式跑一遍**：tag 被删掉重推时 GitHub 会把 release 变回 draft，这条让任务两种状态都幂等；对已发布的 release 是 no-op。
6. **Publish 之后回读资产名**，逐个断言稳定名与它的校验文件都在。上传命令成功不代表资产在那——`--clobber` 与 tag 复用会让漏传和覆盖看起来一样。

Smoke test 步骤要**把稳定名装进另一个空目录**：同一个 name+version 已经满足时 npm 不会去读新文件，装在版本名旁边等于什么都没测。

---

## 5. 建库并推送（在本机已登录 kesheC 的前提下）

在 `projects/<name>/` 里：

```bash
git init -b main
git add -A
git commit -m "feat: initial implementation"
gh repo create kesheC/<name> --public --source=. --remote=origin --push \
  --description "<一句话英文描述>"
# 若 push 卡住，用兜底：
# git -c "http.curloptResolve=github.com:443:140.82.113.3" push -u origin main
gh repo edit kesheC/<name> --add-topic cli,typescript,developer-tools
```

**推送成功的判据是远端 sha，不是命令退出码**：

```bash
local_sha=$(git rev-parse HEAD)
remote_sha=$(gh api repos/kesheC/<name>/git/ref/heads/main --jq .object.sha)
[ "$local_sha" = "$remote_sha" ] && echo OK || echo MISMATCH
```

`git rev-list --count origin/main..HEAD` 在这里会**恒显示有积压**：走 GitHub Data API 推上去的提交不会更新本地的追踪引用，于是「已推送」和「还没推」看起来一模一样。只有远端 sha 相等才算成功。

推送后必须验证：

```bash
gh run list --repo kesheC/<name> --limit 3
gh run view <run-id> --repo kesheC/<name> --json jobs \
  --jq '.jobs[] | .name + " = " + .conclusion'
```

CI 跑绿（conclusion: success）才算交付；红了就修，修完再推。**要按 job 逐个核对**，`in_progress` 的 run 会被 `gh run list` 显示成空 conclusion，误读成「没问题」。

**不要**在 `projects/<name>/` 里嵌套 .git 之后还把它当普通目录提交到 workspace 仓库——每个子项目是独立仓库，workspace 的 `.gitignore` 需要忽略它们（见第 8 节）。提交前先 `git rev-parse --show-toplevel` 确认自己在哪个仓库里：在没有 .git 的子目录里 `git add` 会命中父仓库，把整个子项目塞进 workspace。

---

## 6. README 规范（中英双语，必须能让陌生人 10 秒看懂）

顺序：

1. 标题 + 一句话价值主张（英文一行，中文一行）
2. badges：CI 状态、Release、license、runtime deps、最低 Node 版本（每条都要对得上仓库里真实存在的工作流名与字段）
3. **The problem / 痛点**：3-5 行，讲清楚不做这个工具时人有多难受
4. **Install / 安装**：`npm i -g` 或 `pip install`，并给出**三种**都验过的方式（全局装 tarball、`npx`、`devDependency`），因为读者所在的环境各不相同
5. **Quick start / 60 秒上手**：一条能直接复制的命令 + **真实**输出代码块
6. **Usage / 用法**：每个子命令一节，含真实输出
7. **How it works / 实现要点**：核心算法 3-6 行
8. **API**（库类项目）：导出函数签名 + 示例
9. **FAQ / 边界**：明确说明不做什么
10. **Security and changes**：SECURITY.md 与 CHANGELOG.md 的相对链接，末尾一句指向 CONTRIBUTING.md
11. **License**

中英文都要写，英文在前。不要写 "TODO"、"coming soon"。

### 真实转录的四条硬规则

1. **块必须自包含**。读者从仓库根开始，脚下的目录大概率不是你以为的那个。凡是要在 `demo/`、某个 fixture、某个临时目录里跑的命令，命令行里就要有 `cd`，或者块前先给造夹具的命令。
2. **块必须幂等**。`mkdir -p` 而不是 `mkdir`；第一行先 `rm -rf <scratch>` 再建，否则第二次跟着敲会撞上上一次留下的快照/文件，输出就变了。
3. **省略要写出来**。用 `…` 或一句「其余 N 行省略」，并把 N 说准。**不要**在 JSON 里塞字面 `...`：那会让整段不再是合法 JSON，读者复制去 `jq` 就崩。
4. **流分离要说明**。stdout 给机器、stderr 给人是这些工具的常见结构（`pack` 的进度走 stderr、`filter` 的汇总走 stderr、`--json` 的正文走 stdout）。块里要么 `2>/dev/null` 掉噪声，要么在散文里说清哪一行来自哪个流。

### 不要写会腐烂的数字

「57 条规则」「13 条归一化规则」「3 high, 4 medium, 2 low」「~2,400 lines」「45 KB packed」这类手写数字是最先过期的东西，而且没有任何 CI 会替你发现。两种正确做法：

- **让它从代码派生并被测试钉住**：`expect(readme).toContain(`${REDACTION_RULES.length} rules`)`，或跑一遍 `demo/make-fixture.mjs` 再断言 README 里那七个数字。反向验证两次：改 README 要红，改生成器也要红。
- **改写成结构承诺**：不写「45 KB packed / 25 files」，写「tarball 只有 `dist/`、`README.md` 和 `LICENSE`，`src/`、测试或 sourcemap 混进去 CI 就红」。结构由 CI 每次断言，任何体积下都成立。

### 关于「CI 会检查这个」的句子

写「CI re-runs that transcript and fails when the quoted output no longer matches」之前，去 `ci.yml` 里搜一遍那一步在不在。这类承诺是全文档最容易腐烂的一类：读起来像事实，实际是愿望。四仓实测下来只有两个仓库真有转录步骤，其余四个的 README 与 CONTRIBUTING 都在说一件没发生的事。

---

## 7. 质量闸门（自检清单，交付前逐条打勾）

### 构建与测试

- [ ] `npm run typecheck` 通过（这一层必须含 tests，见第 1 节）
- [ ] `npm run build` 通过，无 TS 报错
- [ ] `npm test` 全绿，测试数 ≥ 15 个用例，且覆盖：正常路径、边界、错误路径
- [ ] `npm run dev` 能启动并打印 `--version`（写不出可用 dev 脚本就删掉它，别留一个退出 1 的死脚本）
- [ ] 在**干净导出**里也能过：`git archive` 到临时目录 → `npm ci` → `build` → `test`（仓库里躺着的未跟踪文件会掩盖缺陷）

### 打包与安装

- [ ] `npm pack --dry-run` 里有 dist 和 README，且没有 `tests/`、`src/`、`node_modules/`、`.js.map`
- [ ] 在临时目录 `npm i -g ./` 后，`<name> --help` 和 `<name> --version` 能跑
- [ ] 用**发布的 tarball** 再验一次（`npm install --prefix <dir> ./<name>-<ver>.tgz`），而不是只验检出目录
- [ ] `package-lock.json` 的 `version` 与 `engines.node` 跟 `package.json` 一致

### 文档与真实输出

- [ ] README 里的每条命令都亲手跑过，且命令**自包含**（不依赖作者机器上的某个目录、某个未提交的文件）
- [ ] README 里的每段输出都是从真实运行里复制出来的，省略处显式声明（`…` 或一句「其余 N 行省略」）
- [ ] README 里手写的数字（规则条数、测试数、行数、包体积）都有测试钉住，或者干脆不写数字、改写成结构承诺
- [ ] 交互式演示块给的是**前置条件**（造夹具的命令），而不是「假设你已经在某个目录里」
- [ ] README 里提到 CI 会做什么，就去 `ci.yml` 里确认那一步真的存在

### 交付面

- [ ] `engines.node` 的下限 = CI 矩阵里最小的 Node 版本
- [ ] CI 绿（ubuntu + windows 都过），矩阵覆盖 `engines.node` 承诺的每个主版本
- [ ] 仓库已创建、已推送、topics 已设置
- [ ] 仓库 URL、commit SHA、CI 结论、测试输出尾部都贴进交付报告
- [ ] 至少一个**真实世界输入**的端到端演示（比如拿一个 200 行的真实日志/CSV 跑一遍，把输出贴进 README）

---

## 8. 交付报告格式（发给 lead）

```
PROJECT: <name>
REPO: https://github.com/kesheC/<name>
COMMIT: <sha>（且 remote sha 与它相等）
CI: success（链接，六个 job 逐个贴 name = conclusion）
RELEASE: vX.Y.Z（资产数、tarball 字节数、sha256 前 8 位）
TESTS: <通过数>/<总数>
LOC: <src 行数>
WHAT IT DOES: <两句话>
REAL DEMO: <贴一段真实运行输出>
GATES: typecheck=0 build=0 test=0 dev=0 pack-install=0
OPEN RISKS: <还有什么没做好>
```

报告里每个数字都要能追到一条命令。「六个 job 全 success」要贴 job 名与 conclusion，「已推送」要贴远端 sha，「Release 有资产」要贴资产文件名与字节数——这三处是最容易嘴上说完成、实际只差一步的地方。

失败与没做的部分同样要写。`OPEN RISKS` 空着通常意味着没查，而不是没问题。