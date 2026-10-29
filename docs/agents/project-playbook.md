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
  "engines": { "node": ">=20" },
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "dev": "node --experimental-strip-types src/cli.ts"
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

`tsconfig.json`：

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
    "outDir": "dist",
    "rootDir": "src",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"]
}
```

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
├── .github/workflows/ci.yml
├── LICENSE            # MIT，Copyright (c) 2026 kesheC
├── README.md          # 中英双语（见第 6 节）
├── .gitignore
├── package.json / pyproject.toml
├── src/               # 源码；cli 与库分离：index.ts 只导出库 API，cli.ts 只做参数解析
└── tests/ 或 src/**/*.test.ts
```

**库 API 与 CLI 必须解耦**：`index.ts` 不读 `process.argv`、不调 `process.exit`，这样别人能 import 复用。

---

## 4. GitHub Actions CI

Node（`.github/workflows/ci.yml`）：

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
        node: [20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: npm
      - run: npm ci
      - run: npm run build
      - run: npm test
```

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
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python }}
      - run: pip install -e ".[dev]"
      - run: pytest
```

提交 **package-lock.json**（先 `npm install` 生成），CI 用 `npm ci`。

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

推送后必须验证：

```bash
gh run list --repo kesheC/<name> --limit 3
```

CI 跑绿（conclusion: success）才算交付；红了就修，修完再推。

**不要**在 `projects/<name>/` 里嵌套 .git 之后还把它当普通目录提交到 workspace 仓库——每个子项目是独立仓库，workspace 的 `.gitignore` 需要忽略它们（见第 8 节）。

---

## 6. README 规范（中英双语，必须能让陌生人 10 秒看懂）

顺序：

1. 标题 + 一句话价值主张（英文一行，中文一行）
2. badges：CI 状态、npm 版本（如果发布）、license
3. **The problem / 痛点**：3-5 行，讲清楚不做这个工具时人有多难受
4. **Install / 安装**：`npm i -g` 或 `pip install`
5. **Quick start / 60 秒上手**：一条能直接复制的命令 + 真实输出截图（用代码块）
6. **Usage / 用法**：每个子命令一节，含真实输出
7. **How it works / 实现要点**：核心算法 3-6 行
8. **API**（库类项目）：导出函数签名 + 示例
9. **FAQ / 边界**：明确说明不做什么
10. **License**

中英文都要写，英文在前。不要写 "TODO"、"coming soon"。

---

## 7. 质量闸门（自检清单，交付前逐条打勾）

- [ ] `npm run build` 通过，无 TS 报错
- [ ] `npm test` 全绿，测试数 ≥ 15 个用例，且覆盖：正常路径、边界、错误路径
- [ ] `npm pack --dry-run` 里有 dist 和 README
- [ ] 在临时目录 `npm i -g ./` 后，`<name> --help` 和 `<name> --version` 能跑
- [ ] 至少一个**真实世界输入**的端到端演示（比如拿一个 200 行的真实日志/CSV 跑一遍，把输出贴进 README）
- [ ] README 里的每条命令都亲手跑过
- [ ] CI 绿（ubuntu + windows 都过）
- [ ] 仓库已创建、已推送、topics 已设置
- [ ] 交付报告里贴了：仓库 URL、commit SHA、CI 结论、测试输出尾部

---

## 8. 交付报告格式（发给 lead）

```
PROJECT: <name>
REPO: https://github.com/kesheC/<name>
COMMIT: <sha>
CI: success（链接）
TESTS: <通过数>/<总数>
LOC: <src 行数>
WHAT IT DOES: <两句话>
REAL DEMO: <贴一段真实运行输出>
OPEN RISKS: <还有什么没做好>
```
