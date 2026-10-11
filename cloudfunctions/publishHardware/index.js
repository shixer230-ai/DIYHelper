// 发行新硬件到云端硬件库：仅开发者用，需密钥校验
// 用法：调用时传 { secret, items: [HardwareSpec JSON...] }，按 id 幂等写入 hardware_catalog
// 环境变量 PUBLISH_SECRET 需与请求里的 secret 一致，防止他人乱写硬件

const cloudbase = require('@cloudbase/node-sdk');

const app = cloudbase.init({ env: cloudbase.SYMBOL_CURRENT_ENV });

exports.main = async (event, context) => {
  // 密钥校验
  const secret = process.env.PUBLISH_SECRET;
  if (!secret || !event || event.secret !== secret) {
    return { error: '无权限发布硬件' };
  }

  const items = event.items;
  if (!Array.isArray(items) || items.length === 0) {
    return { error: '没有要发布的硬件' };
  }
  if (items.length > 500) {
    return { error: '一次最多发布 500 条' };
  }

  const db = app.database();
  const col = db.collection('hardware_catalog');
  let ok = 0;
  let fail = 0;
  for (const it of items) {
    const id = it && it.id;
    if (!id) {
      fail++;
      continue;
    }
    try {
      await col.doc(id).set(it);
      ok++;
    } catch (e) {
      fail++;
    }
  }
  return { ok, fail };
};
