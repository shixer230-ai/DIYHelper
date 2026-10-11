// 捐赠验证云函数：校验登录 + 用爱发电订单号查单 + 自动开通 donator
// 环境变量：AFDIAN_USER_ID、AFDIAN_TOKEN（爱发电「创作者管理 → 开发者设置」里获取）
// 用法：App 端调 callFunction('verifyDonation', { orderNo }) 即可，uid 从登录态取

const cloudbase = require('@cloudbase/node-sdk');
const https = require('https');
const crypto = require('crypto');

const app = cloudbase.init({ env: cloudbase.SYMBOL_CURRENT_ENV });

// 取当前登录用户 uid；只用官方 API，不读 context 里的运行身份字段（防公网绕过登录）
function getUid() {
  try {
    const info = app.auth().getUserInfo();
    const v = info && (info.uid || info.customUserId || info.openId);
    return v ? String(v).trim() : '';
  } catch (e) {
    return '';
  }
}

// 调爱发电订单查询 API（按订单号查单）
// 签名：md5(token + 'params' + paramsJson + 'ts' + ts + 'user_id' + userId)
function queryAfdianOrder(userId, token, orderNo) {
  return new Promise((resolve, reject) => {
    const params = JSON.stringify({ out_trade_no: orderNo });
    const ts = Math.floor(Date.now() / 1000);
    const sign = crypto
      .createHash('md5')
      .update(`${token}params${params}ts${ts}user_id${userId}`)
      .digest('hex');
    const body = JSON.stringify({ user_id: userId, params, ts, sign });
    const req = https.request(
      {
        hostname: 'afdian.com',
        path: '/api/open/query-order',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
        timeout: 15000,
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          let json = null;
          try { json = JSON.parse(data); } catch (e) {}
          if (res.statusCode !== 200) {
            reject(new Error(`爱发电接口异常 HTTP ${res.statusCode}`));
            return;
          }
          resolve(json);
        });
      }
    );
    req.on('timeout', () => { req.destroy(new Error('查询订单超时，请重试')); });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

exports.main = async (event, context) => {
  const uid = getUid();
  if (!uid) {
    return { error: '需要登录后才能开通 donator' };
  }

  const orderNo = event && (event.orderNo || (event.data && event.data.orderNo));
  if (typeof orderNo !== 'string' || orderNo.trim().length === 0) {
    return { error: '请填写爱发电订单号' };
  }
  const no = orderNo.trim();

  const userId = process.env.AFDIAN_USER_ID;
  const token = process.env.AFDIAN_TOKEN;
  if (!userId || !token) {
    return { error: '未配置爱发电接口（请在云函数环境变量里填 AFDIAN_USER_ID 和 AFDIAN_TOKEN）' };
  }

  const db = app.database();

  // 防重复：同一个订单号只能给一个账号开通
  try {
    const used = await db.collection('donations').doc(no).get();
    const row = used && used.data && used.data[0];
    if (row) {
      if (row.uid === uid) return { ok: true, already: true };
      return { error: '这个订单号已被其他账号使用' };
    }
  } catch (e) {
    // 查询失败不阻断，继续查爱发电
  }

  // 查爱发电订单，确认已付款
  let json = null;
  try {
    json = await queryAfdianOrder(userId, token, no);
  } catch (e) {
    return { error: e && e.message ? e.message : '查询订单失败，请重试' };
  }

  // 爱发电业务错误码（ec 非 200 通常是签名/凭证没配对，把真实原因透出来方便排查）
  const ec = json && json.ec;
  if (ec !== 200) {
    const em = (json && json.em) || '';
    return { error: em ? `爱发电返回错误：${em}` : `爱发电返回错误码 ${ec}` };
  }

  const list = json && json.data && json.data.list;
  const order = Array.isArray(list) && list.length > 0 ? list[0] : null;
  if (!order) {
    return { error: '没查到这笔订单，请确认订单号正确' };
  }
  if (Number(order.status) !== 2) {
    return { error: '这笔订单还没支付成功' };
  }
  const amount = parseFloat(order.total_amount);
  if (!(amount > 0)) {
    return { error: '这笔订单金额为 0，无法开通' };
  }

  // 开通：先记订单号防重复，再写 donators
  try {
    await db.collection('donations').doc(no).set({ uid, orderNo: no, time: Date.now() });
    await db.collection('donators').doc(uid).set({ uid, enabled: true });
    return { ok: true };
  } catch (e) {
    return { error: '开通失败，请重试' };
  }
};
