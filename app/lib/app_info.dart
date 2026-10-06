// 应用级信息：版本号、更新日志、版权署名。
// 版本号与署名在此统一维护，避免多处写死导致不一致。

/// 当前对外版本号（显示在「我的」页）。
const String kAppVersion = '1.0.1';

/// 版本更新日志，最新的排在最前。
class VersionLogEntry {
  const VersionLogEntry(this.version, this.items);

  final String version;
  final List<String> items;
}

const List<VersionLogEntry> kVersionLog = [
  VersionLogEntry('1.0.1', [
    '一键导出配置单（「我的」页，走系统分享面板）',
    '清单自定义硬件同步到硬件库「我的添加」，并支持写性能分',
    '扩充硬件库：锐龙 3000 系、Intel 12 代、玄武/海韵等电源（标注功率）',
  ]),
  VersionLogEntry('1.0.0 Beta', [
    '整机方案：多方案管理、一键保存到清单、性价比排行',
    '硬件库：Tab 分栏、品牌分组搜索、我的添加',
    '个性化：主题色、自定义背景、深浅色、昵称',
    '底部导航背景模糊 + 分类页圆角胶囊高亮',
  ]),
];

/// 设计与创作署名（防止盗用）。
const String kCredit = 'CreativeDesign ZkeRurQwQ · 蓝色大肥鱼Accomplish';
