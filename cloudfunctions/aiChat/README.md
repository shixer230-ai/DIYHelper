# aiChat 云函数（AI 分析安全代理）

手机端不再直接调 DeepSeek，而是调这个云函数。云函数里做三件事：

1. 校验登录（未登录拒绝）
2. 每人每天限流（默认 20 次）
3. 用「环境变量」里的 DeepSeek Key 调 AI，把结果返回给 App

**API Key 只存在云函数环境变量里，App 拿不到，也不会打进安装包。**

## 部署步骤（云开发控制台）

1. 打开 [腾讯云开发控制台](https://console.cloud.tencent.com/tcb)，进入环境 `diyhelper-d4g1qnj5l0db7d16e`。
2. 左侧「云函数」→「新建云函数」。
   - 函数名填 `aiChat`（必须和 App 里调用的名字一致）。
   - 运行环境选 **Node.js**（16 或 18 都行）。
3. 把本目录的 `index.js` 和 `package.json` 内容粘到在线编辑器里。
4. 配置环境变量：
   - 键：`DEEPSEEK_API_KEY`
   - 值：你的 DeepSeek 密钥（`sk-...`）
5. 点「保存并部署」。

## 限流用的集合

限流记录写在 `ai_usage` 集合里（每人每天一条）。为了让限流真正生效：

1. 左侧「数据库」→「新建集合」→ 集合名 `ai_usage`。
2. 权限选「无权限」（只有云函数能读写）。

> 这个集合即使没建，云函数也能跑（限流会静默跳过），但建议建上，否则「防滥用」形同虚设。

## 排查

- App 一直提示「需要登录后才能使用 AI 分析」但明明已登录：说明云函数里取用户 ID 的字段没对上。可临时在 `index.js` 的 `exports.main` 开头加一行 `console.log(JSON.stringify(context))`，到「云函数 → 日志」里看 `context` 里实际的字段名，再改 `getUid`。
