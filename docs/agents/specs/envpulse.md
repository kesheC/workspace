# envpulse —— .env 漂移与泄漏的体检医生

## 痛点
`.env` 是团队协作里最容易腐烂的地方：本地有、CI 没有；`.env.example` 早就不更新；
代码里读了 `process.env.X` 但没人写进模板；某人把真实密钥提交进了 `.env.sample`。
现有 dotenv 系工具只负责「加载」，没人管「一致性」和「泄漏」。

## CLI 设计（命令名 envpulse）
1. `envpulse check [--cwd .]` 综合体检，问题分级：
   - MISSING: 代码里实际读取（扫描 `process.env.X` / `import.meta.env.X` / `os.environ["X"]`）但所有 .env* 模板里没有的变量
   - UNUSED: 模板里有但代码里从没读过的变量
   - DRIFT: 多个 env 文件（.env / .env.example / .env.local / .env.production）之间键集合不一致
   - DUPLICATE: 同一文件里重复定义的键
   - UNSAFE: 值看起来是真密钥（sk_live_、AKIA、ghp_、-----BEGIN、32+ 位高熵）却出现在 `.env.example`/`.env.sample` 这类样例文件里
   - EMPTY: 声明了但值为空
   退出码：有 high 级问题=1。
2. `envpulse diff <a.env> <b.env>` 两文件键值差异（值默认打码，`--reveal` 才显示明文）。
3. `envpulse sync --from .env.example --to .env [--dry-run]` 补齐缺失键（保留已有值、保留注释与顺序、缺失的用模板注释提示）。
4. `envpulse mask < .env` 把 stdin 里的敏感值打码后输出（给截图/贴日志用）。
5. `envpulse init --from-code` 扫描源码里读到的变量，生成 `.env.example` 骨架。

## 实现要点
- .env 解析要正确：`export FOO=bar`、单双引号、值里的 `#`（不该被当注释）、`\n` 转义、多行值、BOM、CRLF。
- 源码扫描：递归遍历，跳过 node_modules/.git/dist/build/venv；语言按扩展名分发（js/ts/jsx/tsx/mjs/cjs→process.env；py→os.environ/getenv；sh→$VAR）。
- 熵/模式检测要有明确规则表，且给 `--no-unsafe` 开关。
- 输出用人类可读的分组报告 + `--json`。
- src/parser.ts / src/scan.ts / src/rules.ts / src/report.ts / src/fix.ts / src/cli.ts；index.ts 导出库 API。

## 测试要求
- 解析器边界：引号、注释、export、CRLF、BOM、空值、重复键
- 敏感值规则命中/不命中
- 扫描器在临时目录里的假仓库上找变量
- sync 的 dry-run 与真实写入（顺序、注释保留）
- 至少 20 个用例

## README 必须提供
用本仓库自己（workspace）做一次 `envpulse check --json` 的真实输出示例（没有 .env 时的表现也要说清楚）。


## 通用要求
- 先读 ../docs/agents/project-playbook.md（相对 workspace 根：docs/agents/project-playbook.md），严格遵守里面的骨架、CI、README、质量闸门、交付报告格式。
- 工作目录：projects/<项目名>/（workspace 根 E:\deepseek_workspace\github）。
- 0 运行时依赖。devDependencies 只允许 typescript / @types/node / vitest。
- 测试离线、确定性、不打网络。至少 15 个用例（正常/边界/错误路径）。
- 完成后必须：npm install 生成 lockfile → npm run build → npm test 全绿 → git init → gh repo create kesheC/<项目名> --public --source=. --remote=origin --push → gh repo edit --add-topic ...
- CI 必须跑绿（gh run list 确认 conclusion=success；CI 慢就 wait 再查，最多等 15 分钟）。
- 交付报告严格按 playbook 第 8 节格式发给 lead。
