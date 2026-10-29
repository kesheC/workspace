# gitignore-doctor —— 让 .gitignore 不再是黑盒

## 痛点
开发者不知道某条忽略规则到底为什么生效：规则来自哪个 .gitignore？哪一行？为什么 `!important` 没起作用？
更危险的是：本该被忽略的文件被提交进了仓库（.env、日志、构建产物），或者本该跟踪的文件被悄悄忽略了。
现有工具只能「生成」.gitignore，没有一个能「解释 + 体检」。

## CLI 设计（命令名 gid，也可用 gitignore-doctor）
1. `gid explain <path> [--cwd .]`  解释一个路径是否被忽略、被哪条规则的哪一行命中、经过哪些文件层级。
   输出示例：
   ```
   path:  dist/bundle.js
   status: ignored
   rule:  .gitignore:4  "dist/"          (directory-only match on ancestor "dist")
   chain: .gitignore#4 -> matched
   note:  被 git 跟踪时需要 `git rm -r --cached dist`
   ```
   支持 --json 输出结构化结果（字段：path, ignored, source, line, pattern, reason, whitelistedBy?）。
2. `gid check [--cwd .] [--strict]` 仓库体检，输出问题清单：
   - LEAK: 已被 git 跟踪但命中忽略规则的文件（`git ls-files` 与规则求交），按危险度排序（.env / *.pem / *.key / *.log 优先）
   - MISSING: 未跟踪、未被忽略、但看起来绝对不该进库的文件（.env、*.log、node_modules/、.DS_Store、dist/），建议补规则
   - DEAD: 匹配 0 个文件的规则（死规则）
   - CONFLICT: 被后续规则完全覆盖的规则
   退出码：有问题=1，干净=0（用于 pre-commit / CI）。
3. `gid list [--why] [--cwd .]` 列出所有生效规则：来源文件、行号、模式、命中文件数；--why 时附上 `git check-ignore -v` 风格的解释。
4. `gid init [--detect] [--cwd .]` 按目录特征检测技术栈（node/python/go/rust/java/macos/windows/jetbrains/vscode），生成一份带分组的 .gitignore。检测依据要写清楚（package.json→node, pyproject.toml/setup.py→python …）。

## 实现要点
- 必须自己实现 gitignore 匹配语义（**不允许**调用 `git check-ignore` 作为主实现，只能作为可选对照/测试断言）：
  - 行首 `#` 注释、行尾空格（转义例外）、`\!` `\#` 转义
  - `/` 结尾 = 仅目录；模式含 `/` = 相对 .gitignore 所在目录锚定；不含 `/` = 任意层级匹配
  - `*` 不跨 `/`；`**` 语义（`**/` 前缀、`/**` 后缀、`/**/` 中间）；`?`；`[a-z]` 字符类
  - 取反 `!`；**最后匹配的规则获胜**（不是第一个）
  - 多层级 .gitignore 从仓库根到目标目录依次应用；父目录被排除后子目录规则不再生效（git 的 "cannot re-include" 语义）
  - 全局规则：默认不读 core.excludesFile，但支持 --global 显式开启
- 目录结构：src/rules.ts（解析）、src/matcher.ts（匹配）、src/resolve.ts（多层级合成 + explain）、src/check.ts（体检）、src/init.ts（栈检测）、src/cli.ts；src/index.ts 导出纯函数 API（parseIgnoreFile / matchPath / explainPath / checkRepo）。
- 所有文件 IO 用 node:fs/promises；路径用 node:path；Windows 路径分隔符要归一化后再匹配。

## 测试要求
- 直接用 gitignore 官方规范里的边界用例（写死在测试里）
- 用临时目录构造多层 .gitignore 场景
- explainPath 的 reason/source/line 断言
- `gid check` 对一个含 .env 且被跟踪的临时仓库给出 LEAK（测试里用 `git init` + `git add -f` 构造，若环境无 git 则跳过该用例）

## README 必须展示
一个真实仓库（就用本仓库 E:\deepseek_workspace\github 的 .gitignore 拷贝一份到临时目录）的 `gid explain node_modules/foo` 与 `gid check` 真实输出。


## 通用要求
- 先读 ../docs/agents/project-playbook.md（相对 workspace 根：docs/agents/project-playbook.md），严格遵守里面的骨架、CI、README、质量闸门、交付报告格式。
- 工作目录：projects/<项目名>/（workspace 根 E:\deepseek_workspace\github）。
- 0 运行时依赖。devDependencies 只允许 typescript / @types/node / vitest。
- 测试离线、确定性、不打网络。至少 15 个用例（正常/边界/错误路径）。
- 完成后必须：npm install 生成 lockfile → npm run build → npm test 全绿 → git init → gh repo create kesheC/<项目名> --public --source=. --remote=origin --push → gh repo edit --add-topic ...
- CI 必须跑绿（gh run list 确认 conclusion=success；CI 慢就 wait 再查，最多等 15 分钟）。
- 交付报告严格按 playbook 第 8 节格式发给 lead。
