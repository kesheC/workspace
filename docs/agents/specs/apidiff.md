# apidiff —— 这次改动算 patch 还是 breaking？让机器给你答案

## 痛点
「这次改 API 要不要发 major？」靠人肉 review。OpenAPI / JSON Schema / TS 类型一改，
客户端悄悄挂了才知道。现有工具（oasdiff 等）覆盖不全、报告难读、不能当库用。
开发者要的是：`apidiff old.json new.json` → 明确的 semver 判定 + 可读的破坏性变更清单 + 可进 CI 的退出码。

## 能力范围（v0.1.0）
1. **JSON Schema 比对**：`$schema` 驱动的 draft-07 / 2020-12 子集 —— properties 新增/删除、required 增减、type 收窄/放宽、enum 增删、数值边界（minimum/maximum）收紧、nullable、additionalProperties 变化、$ref 解析（本地文件内 `#/definitions`、`#/$defs`）。
2. **OpenAPI 3.x 比对**：paths × methods 增删、参数（required/in 类型）、requestBody、responses 状态码增删、schema 变更下沉到第 1 条（复用同一套 schema differ）。
3. **环境变量/CLI 契约比对**（加分项）：`--contract env` 比较两个 .env 样本的键集合，判定新增/删除是否破坏（可选，不实现也不扣分）。
4. 输出：
   ```
   verdict: breaking (major)
   ├─ BREAKING  DELETE  paths./users/{id}.delete            API 消费者会 404
   ├─ BREAKING  REQUIRED added: user.email in POST /users 客户端可能不传
   └─ CHANGED   ENUM added "archived" in status            语义放宽，通常安全
   ```
   `--format json` 输出结构化 finding（id/severity/path/message/rule）。
   `--fail-on breaking|deprecation|never` 控制退出码（默认 breaking）。
5. **库 API**（重点）：`import { diffSchemas, diffOpenApi, verdictOf } from 'apidiff'`，纯函数、无 IO、无依赖。
6. **GitHub Action 用法示例**（README 里给 yml 片段）。

## 实现要点
- 判定规则表要显式写成常量表（rule id → severity），README 里列全，方便用户质疑/覆盖。
- JSON Pointer 定位每个 finding；消息要能让人直接看懂（不要只报 "schema changed"）。
- $ref 解析：本地锚点 + 同目录文件；循环 $ref 要能终止（visited 集合）。
- src/schema-diff.ts / src/openapi-diff.ts / src/refs.ts / src/rules.ts / src/report.ts / src/cli.ts；index.ts 导出 API + 完整类型。
- 0 依赖（JSON 自带），解析 YAML 部分不要做（OpenAPI 只吃 JSON，README 里说明用 `yq -o=json` 转换）。

## 测试要求
- 每条判定规则至少一个正例 + 一个反例（required 增/删、type 收窄/放宽、enum、边界、nullable、additionalProperties、嵌套对象、数组 items）
- $ref 解析（含循环引用不死循环）
- OpenAPI 增删 path/method/status code
- verdict 汇总（多 finding 取最严）
- 至少 25 个用例

## README 必须提供
一个真实的 before/after OpenAPI 片段对比输出（贴终端输出），以及「把它接进 CI 的 3 行 yml」。


## 通用要求
- 先读 ../docs/agents/project-playbook.md（相对 workspace 根：docs/agents/project-playbook.md），严格遵守里面的骨架、CI、README、质量闸门、交付报告格式。
- 工作目录：projects/<项目名>/（workspace 根 E:\deepseek_workspace\github）。
- 0 运行时依赖。devDependencies 只允许 typescript / @types/node / vitest。
- 测试离线、确定性、不打网络。至少 15 个用例（正常/边界/错误路径）。
- 完成后必须：npm install 生成 lockfile → npm run build → npm test 全绿 → git init → gh repo create kesheC/<项目名> --public --source=. --remote=origin --push → gh repo edit --add-topic ...
- CI 必须跑绿（gh run list 确认 conclusion=success；CI 慢就 wait 再查，最多等 15 分钟）。
- 交付报告严格按 playbook 第 8 节格式发给 lead。
