# clidoc —— CLI 文档不再和真实输出漂移

## 痛点
README 里的命令输出示例是手抄的，改一次 CLI 就要手改文档，几个月后全是假的。
现有方案（snapshot testing / asciinema）要么绑死在测试框架里，要么产出不可复制的视频/gif。
开发者的真实需求：**把「真的跑一遍」的输出直接写回 README**。

## 核心设计
两个子命令：`record` 采集，`check` 校验，`render` 写回。

1. `clidoc record <cmd...> [--id <name>] [--cwd <dir>] [--timeout 15]`
   在受控环境跑命令，采集 stdout/stderr/exitCode/耗时，写入 `.clidoc/<id>.json`。
   环境净化：清除 CLICOLOR/FORCE_COLOR/CI 等影响输出的变量；固定 `COLUMNS=80`、`TZ=UTC`、`LANG=C.UTF-8`；默认带 `--no-color` 风格（由使用者传参控制）。
   安全：默认屏蔽绝对路径（把 cwd 替换成 `.`）、时间戳、耗时、内存数值等易变内容 —— 用一组内置 normalizer（可 `--no-normalize` 关闭），保证快照稳定。
2. `clidoc render [--readme README.md] [--check]`
   把 `.clidoc/*.json` 渲染进 README 里的标记块之间：
   ```
   <!-- clidoc:start <id> -->
   ...自动生成...
   <!-- clidoc:end <id> -->
   ```
   `--check` 只比对不写入，不一致则退出码 1（CI 用）。
   渲染格式：`$ <cmd>` 命令行 + ```console 代码块，超长输出自动截断（--max-lines，默认 40）并标注 "... (N more lines)"。
3. `clidoc run <cmd...> [--id <name>] [--readme README.md]` = record + render 一步到位（最常用）。

## 实现要点
- 只用 node:child_process spawn（不用 exec，避免 shell 注入），超时用 AbortController + kill。
- 输出必须确定性：normalizer 链（路径→相对、ISO 时间戳→`<timestamp>`、耗时 ms→`<duration>`、随机 hex→`<id>`）。
- 真实场景支持：`clidoc run -- node dist/cli.js --help` 在 Windows 也能跑（不依赖 shell）。
- 结构化：`.clidoc/*.json` 里存原始输出+规范化输出+命令+退出码+环境指纹，便于 code review 时 diff。
- src/record.ts / src/render.ts / src/markdown.ts / src/normalize.ts / src/store.ts / src/cli.ts；index.ts 导出库 API（runAndCapture / renderBlocks / normalizeOutput）。

## 测试要求
- 用 `node -e "console.log(...)"` 作为被测命令（跨平台稳定）
- normalizer 单测：路径/时间戳/耗时/hex
- markdown 块替换：新增块、更新块、缺失标记报错、重复 id 报错、--check 不一致退出码 1
- 端到端：临时目录写一个 README + record + render + 断言内容

## README 必须提供
一键生成自己 README 示例段落的命令，且 README 里的示例就是 clidoc 自己渲染出来的（自举）。


## 通用要求
- 先读 ../docs/agents/project-playbook.md（相对 workspace 根：docs/agents/project-playbook.md），严格遵守里面的骨架、CI、README、质量闸门、交付报告格式。
- 工作目录：projects/<项目名>/（workspace 根 E:\deepseek_workspace\github）。
- 0 运行时依赖。devDependencies 只允许 typescript / @types/node / vitest。
- 测试离线、确定性、不打网络。至少 15 个用例（正常/边界/错误路径）。
- 完成后必须：npm install 生成 lockfile → npm run build → npm test 全绿 → git init → gh repo create kesheC/<项目名> --public --source=. --remote=origin --push → gh repo edit --add-topic ...
- CI 必须跑绿（gh run list 确认 conclusion=success；CI 慢就 wait 再查，最多等 15 分钟）。
- 交付报告严格按 playbook 第 8 节格式发给 lead。
