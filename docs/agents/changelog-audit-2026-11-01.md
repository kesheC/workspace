# 六仓 CHANGELOG 一致性审计（2026-11-01）

范围：`projects/{repropack,clidoc,envpulse,gitignore-doctor,jsonl-beaver,apidiff}`。
基线：`git log v0.1.7..HEAD`（这六仓有未推送的本地提交，未用远端做基线）。
只读审计，未改动任何仓库文件。

## 判断标准

1. **一条提交算「已记录」的条件**：CHANGELOG 0.1.8 段里有一句能指向它带来的可观察变化（改了什么、对谁有用）。
2. **纯文档提交**（`docs:` 开头的 README 双语 / 措辞修正）**不要求单独记入 CHANGELOG**——它们不改变工具行为，读者不需要为升级而知道。这类提交在本报告中只列不扣分。
3. **chore(release)** 提交本身产出 CHANGELOG，不参与比对。
4. **一条 CHANGELOG 条目算「多余」的条件**：它声明的变化在 v0.1.7 与 HEAD 之间找不到对应改动，或声明与 v0.1.7 的实际内容相反。
5. 只读 git 对象（`git show v0.1.7:...`）与工作区文件，不看 CI 运行历史。

## 汇总

| 仓库 | 缺失记录 | 多余/无支撑声明 | 标题违规 | 字符集违规 | 顺序问题 |
| --- | --- | --- | --- | --- | --- |
| repropack | 0 | 1 | 0 | 0 | 0 |
| clidoc | 0 | 1 | 0 | 0 | 0 |
| envpulse | **1** | 0 | 0 | 0 | 0 |
| gitignore-doctor | 0 | 1 | 0 | 0 | 0 |
| jsonl-beaver | 0 | 0 | 0 | 0 | 0 |
| apidiff | 0 | 0 | 0 | 0 | 0 |

机械项（六仓全部通过）：版本段顺序 `Unreleased > 0.1.8 > 0.1.7 > ... > 0.1.0` 单调递减；`## [Unreleased]` 段全为空；小标题只出现 `Added / Changed / Fixed / Removed / Quality / Security`；正文除 em dash `—` 外无任何 > U+007E 的字符（无中文标点、无全角符号）。

---

## repropack

**缺失记录：0。** 四条提交都能落到 0.1.8 段：`491ba5a`（重写 workflow 测试）→ 第 1 条「21 cases, up from 6」；`3e504c3` 里 `tests/cli/main.spec.ts` 改用 `TOOL_VERSION` → 第 2 条；`f4d4245`（新增 `tests/package.test.ts`、build 前清 `dist/`）→ 第 3 条；`e857503` 为纯文档提交，按标准 2 不计。

**多余/无支撑声明：1。**
- `CHANGELOG.md:30`「`npm run build` **still** clears `dist/` before compiling」（该条 bullet 起于 `:26`）——`clean` 脚本正是本版新增的：
  运行 `git show v0.1.7:package.json | grep -c '"clean"'` → `0`；当前 `node -p "require('./package.json').scripts"` → `{"clean":"node -e \"require('node:fs').rmSync('dist',{recursive:true,force:true})\"", "build":"npm run clean && tsc -p tsconfig.build.json", ...}`。
  所以「still」应为「now」或「also」。变化本身为真，只是时态错。

**标题/字符集违规：0。** **顺序问题：0。**

**结构瑕疵（不计入上表）**：`CHANGELOG.md:30-31` 与 `:68-69` 的 `## [0.1.7]` / `## [0.1.6]` 前缺空行（`awk 'prev!="" && /^## \[/'` 命中）。其中 0.1.6 那处在 v0.1.7 就已存在，0.1.7 那处是本次新加的。

---

## clidoc

**缺失记录：0。** `41c6cff` → 第 1 条「17 cases」；`4f9f120`（新增 `tests/package.test.ts`）→ 第 2 条；`9c507f5`、`8f4384b` 为纯文档提交，按标准 2 不计。

**多余/无支撑声明：1。**
- `CHANGELOG.md:21-23`（bullet 起于 `:21`）「**Three guards the old test did not have.** The release is re-published with `gh release edit --draft=false` ... the `clidoc` bin is smoke tested, and the build clears `dist/` first.」
  其中「build clears dist/」这条**旧测试本来就有**：运行 `git show v0.1.7:tests/workflow.test.ts | sed -n '283,287p'` →
  ```
  expect(manifest.scripts.build).toContain("npm run clean");
  expect(manifest.scripts.clean).toBeDefined();
  const clean = manifest.scripts.clean ?? "";
  expect(clean).toContain("rmSync");
  expect(clean).toContain("dist");
  ```
  v0.1.7 的 `tests/workflow.test.ts` 里 `clean` 命中 5 次，当前文件里 3 次；`draft` 由 0 → 5、`\.bin/` 由 0 → 1。
  所以真正「旧测试没有」的是两条（draft=false、bin smoke），第三条是**原有且仍在**。三个 guard 都真实存在，只是来源叙述不实。

**标题/字符集违规：0。** **顺序问题：0。**
**结构瑕疵**：`CHANGELOG.md:23-24` 缺空行。

---

## envpulse

**缺失记录：1（本报告唯一实质缺失）。**
- `afdd5c6 fix: stop shipping sourcemaps, and make CI check what the tarball holds` **在 0.1.8 段里没有任何对应条目**。
  运行 `grep -in 'sourcemap\|source map' projects/envpulse/CHANGELOG.md` → 零命中；而这条提交是 envpulse 本版**唯一面向用户的产物变化**，且它自己的提交信息写得很清楚：「envpulse was the only one of the six packages still publishing .js.map files ... Those maps point at src/, which the tarball does not contain, so they were 11 dead files and roughly a quarter of the download」。
  证据：`git show v0.1.7:tsconfig.build.json` 的 `compilerOptions` = `{"outDir":"dist","rootDir":"src"}`（**没有** `sourceMap:false`，继承根 tsconfig 的 `sourceMap:true`）；当前 = `{"outDir":"dist","rootDir":"src","sourceMap":false,"declarationMap":false}`。其余五仓的 `tsconfig.build.json` 在 v0.1.7 就已经是 `sourceMap:false`，所以这条只对 envpulse 成立。
  `59189fa`（发版提交）的说明里甚至写了「the README's tarball size claims match what npm pack actually produces now that sourcemaps are gone (25 files, 45 KB packed)」——**发版提交说了，CHANGELOG 没说**。
  0.1.8 段第 2、3 条顺带提到了「package-contents assertion against ... a stray `.js.map`」，但那是新测试的输入样例，读者无法据此知道「本包曾经在发 .js.map、现在少了 11 个文件、下载小了约四分之一」。
  **README 已经写了，只有 CHANGELOG 漏了**：`grep -n 'sourceMap\|sourcemap' projects/envpulse/README.md` → `:52`「no tests, and no `.js.map` files. A sourcemap in a package that publishes no ...」、`:662`（中文段）「不发源码的包里带 sourcemap 只是指向一个读者永远打不开的文件，所以发布构建关掉了它，由 `tsconfig.build.json` 守着，并有 `tests/package.test.ts` 断言」。`grep -c 'package.test' projects/envpulse/CHANGELOG.md` → `0`。同一件事 README 声明了、发版提交声明了、CHANGELOG 没声明。

**多余/无支撑声明：0。** 另外三条都成立：tag gate 确实此前完全缺失（`git show v0.1.7:.github/workflows/release.yml | grep -c 'tag/version gate'` → `0`，其余五仓均为 `1`，与「alone among these packages」一致）；`tests/workflow.test.ts` v0.1.7 不存在 → 现在 21 个 `it(`；draft=false / bin smoke / clean 三项在 v0.1.7 均为 0 命中，确系新增；`grep -c 'pack-meta' .gitignore` → `1`。

**标题/字符集违规：0。** **顺序问题：0。**
**结构瑕疵**：`CHANGELOG.md:26-27` 缺空行。

---

## gitignore-doctor

**缺失记录：0。** `d446e57` → 第 1 条「21 cases, up from 7」（实测 v0.1.7 恰为 7 个 `it(`）；`0779439` → 第 2 条；`ae44685` 纯文档。

**多余/无支撑声明：1。**
- `CHANGELOG.md:20-23`（bullet 起于 `:20`）「**Rewriting the tests lost three guards; all three are back.** ... **both** bins (`gid` and `gitignore-doctor`) are smoke tested ... and `npm run build` still clears `dist/`」。v0.1.7 的测试里 `draft` 命中 2 次、`\.bin/` 命中 2 次，标题就有一条 `it("checks both bin names, because each alias can break on its own"`——**both bins 与 draft=false 旧测试已有**。真正新增的只有 clean（v0.1.7 命中 0）。「lost three guards」这一中间状态无法用 git 证明（`tests/workflow.test.ts` 在 v0.1.7..HEAD 之间只有一个提交），而「三条都是新补回来的」与 v0.1.7 的实际内容相矛盾。

**标题/字符集违规：0。** **顺序问题：0。**
**结构瑕疵**：`CHANGELOG.md:23-24` 缺空行。

---

## jsonl-beaver

ok —— 缺失 0 / 多余 0 / 标题 0 / 字符集 0 / 顺序 0。
`6c02eaf` → 第 1 条「21 cases, up from 13」（v0.1.7 实测 13 个 `it(`）；`c216ad1` → 第 2 条（draft/bin/clean 在 v0.1.7 均为 0 命中，三项确系新增，「lost and back」叙述可成立）。

**说明**：审计开始时该仓工作区有 ` M README.md` 与 `?? .tmp-readme-audit.mjs`；审计结束前另一个 agent 把 README 改动提交为 `49f99cf docs: mirror the Chinese sections against the English ones` 并清掉临时文件，工作区现已干净。该提交是纯文档提交，按标准 2 不影响缺失/多余判定。

**结构瑕疵**：`CHANGELOG.md:23-24` 缺空行。

---

## apidiff

ok —— 缺失 0 / 多余 0 / 标题 0 / 字符集 0 / 顺序 0。
`3b9f4e8`（新建 `tests/workflow.test.ts`）→ 第 1 条「21 cases」；`be5be74` → 第 2 条（v0.1.7 的 `tests/workflow.test.ts` 不存在，三项均为新增）；`af0d4d1`、`d0713d7` 为纯文档提交。

**结构瑕疵**：`CHANGELOG.md:23-24` 缺空行。

---

## 六仓共有的结构问题（不计入各仓上表）

1. **新版本段前缺空行**：六个 CHANGELOG 的 `## [0.1.7]` 前都紧贴上一段的最后一条列表项（repropack 另有 0.1.6 处），Markdown 渲染仍能正确分段，但不符合文件内既有风格。
2. **链接引用未同步**：六个文件末尾的 `[Unreleased]` 仍指向 `compare/v0.1.6...HEAD`，且**都没有** `[0.1.7]` / `[0.1.8]` 的定义（`grep -c '^\[0\.1\.8\]:'` 六仓均为 `0`）。所以 `## [0.1.8]`、`## [0.1.7]` 渲染成字面文本而非链接。这是沿用自 0.1.7 的既有模式，不是本次新增。
3. **版本/Tag 状态一致**：六仓 `package.json` 均为 `0.1.8`，tag `v0.1.1`..`v0.1.8` 齐全，`git describe` 分别为 repropack `v0.1.8-1-ge857503` / clidoc `v0.1.8-2-g8f4384b` / envpulse `v0.1.8-1-ga75aa28` / gitignore-doctor `v0.1.8-1-gae44685` / jsonl-beaver `v0.1.8-1-g49f99cf` / apidiff `v0.1.8-2-gd0713d7`。tag 之后的提交全是 `docs:`，没有未发布的代码变更混在 tag 后面。
4. **小标题分类**：六个 0.1.8 段落全部只用 `### Added`，包括 envpulse 的 tag gate（「had no tag/version gate at all」本质是修 bug）。允许集合不禁止这么做，但 `### Fixed` 会更准确。

## 建议的最小修复（不在本次任务范围内）

1. envpulse：补一条 0.1.8 记录，说明不再发布 `.js.map`（11 个文件、约四分之一体积），并把 CI 的包内容断言写进去。
2. clidoc / gitignore-doctor / repropack：把「old test did not have」「lost three guards」「still clears dist/」三处措辞改成与实际 v0.1.7 内容相符的说法。
3. 六仓：版本段前补空行、把 `[Unreleased]` 的比较基线改到 `v0.1.8`、补 `[0.1.7]` / `[0.1.8]` 链接定义。
