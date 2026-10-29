# jsonl-beaver —— 几个 G 的 JSONL 日志不用再写一次性的 jq

## 痛点
线上日志 / 事件流都是 NDJSON（JSONL），动辄几个 G。用 `jq` 要么写出天书，要么得先 `grep` 再猜；
用 Python 得现写脚本；用 spreadsheets 直接爆内存。开发者真正想要的是：**流式、内存有界、随手过滤和聚合**。

## CLI 设计（命令名 jlb）
1. `jlb stat <file|->` 流式统计：行数、合法/非法行数、字段出现率（top 30）、每字段类型分布、行长度分布（p50/p95/max）、嵌套深度最大值。只读一遍、内存 O(字段数)。
2. `jlb head <file> [-n 10] [--pretty]` 流式取前 n 条（不整文件读入）。
3. `jlb filter <file> --where "level=error and dur>500" [--limit N] [--pretty]` 简单表达式 DSL：`=` `!=` `>` `<=` `includes`、`and`/`or`、括号、(可选) `--where-file`。`-` 表示 stdin，与管道天然配合。
4. `jlb agg <file> --by user --count` / `--sum dur` / `--avg dur` / `--p95 dur`，`--top 20`，`--where` 可与 agg 组合。
5. `jlb to-csv <file> --fields a,b,c` 导出 CSV；`jlb to-jsonl --fields ...` 重塑字段。
6. 全局参数：`--skip-invalid`（坏行跳过并计数到 stderr）、`--json`（机器可读结果）、`--progress`（stderr 每 100 万行打点）。

## 实现要点
- 用 `node:readline` + `createReadStream` 流式处理，**绝不 `JSON.parse` 整个文件**；内存有界（--by 基数大时用近似/HLL 或明示限制）。
- 字段路径支持点号嵌套 `a.b.c` 与数组索引 `items[0].id`。
- 表达式解析：手写递归下降 parser → AST → 编译成闭包（避免每行重新 parse）。
- 大文件测试：生成 200MB 临时 JSONL 的测试标 @slow，默认用 50k 行；断言峰值内存不随文件线性增长（用 process.memoryUsage 粗断）。
- 错误处理：非法 JSON 行给出行号与摘录；文件不存在/目录/编码错误给清晰提示。
- src/stream.ts / src/expr.ts / src/agg.ts / src/format.ts / src/cli.ts；index.ts 导出库 API。

## 测试要求
- 表达式优先级、括号、字符串比较、数字比较、嵌套字段
- 聚合正确性（count/sum/avg/p95 与手算对照）
- CSV 转义（逗号、引号、换行）
- 坏行处理、stdin 管道、空文件
- 至少 20 个用例

## README 必须提供
用一份真实形态的 nginx/应用日志样例跑 `jlb stat` 与 `jlb filter --where "status>=500"` 的真实输出，并给出「1GB 文件耗时约 X 秒」的实测数字（本机实测，写清楚机器条件）。


## 通用要求
- 先读 ../docs/agents/project-playbook.md（相对 workspace 根：docs/agents/project-playbook.md），严格遵守里面的骨架、CI、README、质量闸门、交付报告格式。
- 工作目录：projects/<项目名>/（workspace 根 E:\deepseek_workspace\github）。
- 0 运行时依赖。devDependencies 只允许 typescript / @types/node / vitest。
- 测试离线、确定性、不打网络。至少 15 个用例（正常/边界/错误路径）。
- 完成后必须：npm install 生成 lockfile → npm run build → npm test 全绿 → git init → gh repo create kesheC/<项目名> --public --source=. --remote=origin --push → gh repo edit --add-topic ...
- CI 必须跑绿（gh run list 确认 conclusion=success；CI 慢就 wait 再查，最多等 15 分钟）。
- 交付报告严格按 playbook 第 8 节格式发给 lead。
