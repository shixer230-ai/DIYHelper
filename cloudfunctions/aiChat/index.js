// 云函数：AI 分析（安全代理）
//
// 作用：
//   1) 校验调用者已登录（未登录直接拒绝）——防滥用第一步；
//   2) 按「用户 + 日期」记每日调用次数做限流；
//   3) 用云端「环境变量」里的 DeepSeek Key 调用 AI，把结果返回给 App。
//
// 关键点：API Key 只存在这个云函数的环境变量里，App 里永远拿不到，也不会被打包进安装包。

const cloudbase = require('@cloudbase/node-sdk');
const https = require('https');

const app = cloudbase.init({ env: cloudbase.SYMBOL_CURRENT_ENV });

// 固定分析规则 + 输出格式（分点罗列）。与 App 内一致，改这里即可统一生效。
const SYSTEM_PROMPT = `你是一名资深 DIY 装机专家。请根据用户提供的整机配置做分析，务必遵守：
1. 最近内存和存储芯片价格上涨幅度较大，这方面金额偏高是正常现象，不要因此批评用户。
2. 一定不要评价「性价比」，只说说在哪些方面性价比较高即可。
3. 不要锐评用户的选择，给用户良好体验，只提出合理建议。
4. 如果配置里用了垃圾佬（二手/老旧高性价比）型号，侧重性价比分析；否则侧重稳定性分析。
5. 严格按以下固定格式输出（约 512 tokens），不要输出任何多余内容，每个板块下用「- 」分点罗列（每点单独一行，不要写成一整段）：
此方案的亮点是:
    - （要点1）
    - （要点2）

方案侧重:
    - （如单机游戏 3A、网游、内容创作、服务器主机等哪一方面）

注意:
    - （此方案的局限性；若没有则写「方案完备」）
    - （注意主板供电、兼容性等方面）

其它事项:
    - （超频潜力、稳定性等）`;

// 可靠性分析的固定规则 + 输出格式（分点罗列）。App 传 mode='reliability' 时用这份。
const RELIABILITY_SYSTEM_PROMPT = `你是一名资深 DIY 装机硬件检测专家。请根据用户提供的整机配置做「可靠性分析」，评估这套配置的稳定性与耐用风险，务必遵守：
1. 功耗稳定性：评估整机功耗是否合理、电源（若有标注）功率是否足够、有无供电或散热隐患。
2. 硬件稳定性：
   - 识别「魔改 CPU」（笔记本 CPU 改台式、寨板、工程样品 ES 版等）及其潜在风险（无官方保修、温度/兼容性问题等）。
   - 判断显卡是否可能经历过「矿潮」（矿卡）：结合型号、年份、显存类型，判断翻新/矿卡风险，并给出选购建议。
   - 评估二手、洋垃圾、杂牌、翻新硬件的稳定性风险；注意语气客观，不要贬低「洋垃圾」——它们性价比高是事实，只客观说明风险即可。
3. 严格按以下固定格式输出（约 512 tokens），不要输出任何多余内容，每个板块下用「- 」分点罗列（每点单独一行，不要写成一整段）：
功耗稳定性:
    - （要点）

硬件稳定性:
    - （要点）

潜在风险:
    - （要点）

购买建议:
    - （要点）`;

// 每人每天 AI 分析次数上限（防滥用）。
const DAILY_LIMIT = 20;

// 用户消息最大长度（合规）。
const MAX_PROMPT_LEN = 4000;

// 从 context 里尽力取出当前登录用户的稳定 ID。
//
// 注意：新版 @cloudbase/node-sdk 里，用户身份不再塞在 context.userInfo，
// 而是要通过 app.auth().getUserInfo() 拿（返回 { uid, openId, customUserId }）。
// 下面优先用官方 API，再兜底从 context 里翻常见字段。
function getUid(context) {
  // 方式一：官方 API（账号密码登录的用户在这里是 uid）。
  try {
    const info = app.auth().getUserInfo();
    const v = info && (info.uid || info.customUserId || info.openId);
    if (v) return String(v).trim();
  } catch (e) {
    // 个别运行时可能没有该方法，忽略，走兜底。
  }

  // 方式二：兜底从 context.userInfo / context 里翻常见字段。
  const c = context || {};
  const ui = c.userInfo || c.user || {};
  const candidates = [
    ui.uid, c.uid, ui._id, c._id,
    ui.customUserId, ui.custom_user_id, c.customUserId, c.custom_user_id,
    ui.unionId, ui.unionid, c.unionId, c.unionid,
    ui.openId, ui.openid, c.openId, c.openid,
    c.OPENID, c.UIN, c.TENCENTCLOUD_UIN,
  ];
  for (const v of candidates) {
    if (v != null && String(v).trim() !== '') return String(v).trim();
  }
  return '';
}

// 用 https 调 DeepSeek（不依赖第三方包，兼容各 Node 运行时）。
function callDeepSeek(apiKey, prompt, systemPrompt) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      model: 'deepseek-chat',
      stream: false,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: prompt },
      ],
    });
    const req = https.request(
      {
        hostname: 'api.deepseek.com',
        path: '/chat/completions',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${apiKey}`,
          'Content-Length': Buffer.byteLength(body),
        },
        timeout: 60000,
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          let json = null;
          try { json = JSON.parse(data); } catch (e) {}
          if (res.statusCode !== 200) {
            const msg = (json && json.error && json.error.message) || `HTTP ${res.statusCode}`;
            reject(new Error(msg));
            return;
          }
          const content = json && json.choices && json.choices[0] &&
            json.choices[0].message && json.choices[0].message.content;
          if (!content) { reject(new Error('AI 未返回内容，请重试')); return; }
          resolve(content);
        });
      }
    );
    req.on('timeout', () => { req.destroy(new Error('调用 AI 超时，请重试')); });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

exports.main = async (event, context) => {
  // 排查用：打印取到的 uid 和 context 字段名，方便定位「未登录」问题（确认无误后可删）。
  console.log('[aiChat] uid =', getUid(context), '| context keys =', Object.keys(context || {}));

  // 1) 登录校验。
  const uid = getUid(context);
  if (!uid) {
    return { error: '需要登录后才能使用 AI 分析' };
  }

  // 2) 输入合规。
  const prompt = event && (event.prompt || (event.data && event.data.prompt));
  if (typeof prompt !== 'string' || prompt.trim().length === 0) {
    return { error: '方案内容为空，无法分析' };
  }
  if (prompt.length > MAX_PROMPT_LEN) {
    return { error: '方案内容过长，无法分析' };
  }

  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) {
    return { error: '未配置 AI 接口 Key（请在云函数环境变量里填 DEEPSEEK_API_KEY）' };
  }

  // 3) 限流：按「用户 + 日期」记每日次数（尽力而为，失败不阻断）。
  try {
    const db = app.database();
    // 用 UTC+8（北京时间）的日期，符合国内用户的「每日」习惯。
    const date = new Date(Date.now() + 8 * 3600 * 1000).toISOString().slice(0, 10);
    const docId = `${uid}_${date}`;
    const usage = await db.collection('ai_usage').doc(docId).get();
    const row = usage && usage.data && usage.data[0];
    const count = (row && row.count) || 0;
    if (count >= DAILY_LIMIT) {
      return { error: `今日 AI 分析次数已用完（每天 ${DAILY_LIMIT} 次）` };
    }
    await db.collection('ai_usage').doc(docId).set({ count: count + 1, uid, date });
  } catch (e) {
    // 限流记录失败不阻断（例如 ai_usage 集合还没建），避免数据库异常挡住正常用户。
  }

  // 4) 调 DeepSeek 并返回。
  try {
    // 按 mode 选择提示词：reliability 走可靠性分析，否则默认常规分析。
    const mode = event && event.mode;
    const systemPrompt =
      mode === 'reliability' ? RELIABILITY_SYSTEM_PROMPT : SYSTEM_PROMPT;
    const content = await callDeepSeek(apiKey, prompt, systemPrompt);
    return { content };
  } catch (e) {
    return { error: e && e.message ? e.message : String(e) };
  }
};
