import '../models/build_plan.dart';

/// 首次启动预置的 5 套主流配置（2 套中高端 + 3 套中低端）
/// 硬件从内置硬件库挑选，型号字符串须与 kHardwareCatalog 完全一致才能参与分析
/// 价格先留空（0），由用户按实际购买价填写
final List<BuildPlan> kDefaultPlans = [
  BuildPlan(
    id: 'default_1',
    name: '高端 Intel 游戏主机',
    components: {
      'cpu': const PlanComponent(
          category: 'CPU', brand: 'Intel', model: '酷睿 i7-14700K', price: 0, platform: ''),
      'gpu': const PlanComponent(
          category: '显卡', brand: 'NVIDIA', model: 'GeForce RTX 4070 Super', price: 0, platform: ''),
      'motherboard': const PlanComponent(
          category: '主板', brand: '微星', model: 'MAG B760M MORTAR MAX WiFi DDR5', price: 0, platform: ''),
      'ram': const PlanComponent(
          category: '内存', brand: '金士顿', model: 'FURY Beast DDR5-6000 32GB（16G×2）', price: 0, platform: ''),
      'psu': const PlanComponent(
          category: '电源', brand: '海韵', model: '海韵 FOCUS GX-750 金牌全模组', price: 0, platform: ''),
      'case': const PlanComponent(
          category: '机箱', brand: '联力', model: '联力 LANCOOL 216', price: 0, platform: ''),
    },
    storages: [
      const PlanComponent(
          category: '硬盘', brand: '三星', model: '990 PRO 1TB', price: 0, platform: ''),
    ],
  ),
  BuildPlan(
    id: 'default_2',
    name: '高端 AMD 游戏主机',
    components: {
      'cpu': const PlanComponent(
          category: 'CPU', brand: 'AMD', model: '锐龙 7 7800X3D', price: 0, platform: ''),
      'gpu': const PlanComponent(
          category: '显卡', brand: 'AMD', model: 'Radeon RX 7800 XT', price: 0, platform: ''),
      'motherboard': const PlanComponent(
          category: '主板', brand: '微星', model: 'MAG B650M MORTAR WiFi', price: 0, platform: ''),
      'ram': const PlanComponent(
          category: '内存', brand: '芝奇', model: 'Trident Z5 RGB DDR5-6400 32GB（16G×2）', price: 0, platform: ''),
      'psu': const PlanComponent(
          category: '电源', brand: '海盗船', model: '海盗船 RM850x 850W 金牌', price: 0, platform: ''),
      'case': const PlanComponent(
          category: '机箱', brand: '联力', model: '联力 包豪斯 O11 Dynamic', price: 0, platform: ''),
    },
    storages: [
      const PlanComponent(
          category: '硬盘', brand: '西数', model: '黑盘 SN850X 1TB', price: 0, platform: ''),
    ],
  ),
  BuildPlan(
    id: 'default_3',
    name: '中端 Intel 主流主机',
    components: {
      'cpu': const PlanComponent(
          category: 'CPU', brand: 'Intel', model: '酷睿 i5-13400F', price: 0, platform: ''),
      'gpu': const PlanComponent(
          category: '显卡', brand: 'NVIDIA', model: 'GeForce RTX 4060', price: 0, platform: ''),
      'motherboard': const PlanComponent(
          category: '主板', brand: '华硕', model: 'TUF GAMING B760M-PLUS WiFi D4', price: 0, platform: ''),
      'ram': const PlanComponent(
          category: '内存', brand: '金士顿', model: 'FURY DDR4-3200 16GB（8G×2）', price: 0, platform: ''),
      'psu': const PlanComponent(
          category: '电源', brand: '玄武', model: '玄武 650K 金牌', price: 0, platform: ''),
      'case': const PlanComponent(
          category: '机箱', brand: '先马', model: '先马 平头哥M1', price: 0, platform: ''),
    },
    storages: [
      const PlanComponent(
          category: '硬盘', brand: '致态', model: 'TiPlus7100 1TB', price: 0, platform: ''),
    ],
  ),
  BuildPlan(
    id: 'default_4',
    name: '中端 AMD 高性价比主机',
    components: {
      'cpu': const PlanComponent(
          category: 'CPU', brand: 'AMD', model: '锐龙 5 5600', price: 0, platform: ''),
      'gpu': const PlanComponent(
          category: '显卡', brand: 'AMD', model: 'Radeon RX 6650 XT', price: 0, platform: ''),
      'motherboard': const PlanComponent(
          category: '主板', brand: '华硕', model: 'TUF GAMING B550M-PLUS WiFi II', price: 0, platform: ''),
      'ram': const PlanComponent(
          category: '内存', brand: '金百达', model: '银爵 DDR4-3600 32GB（16G×2）', price: 0, platform: ''),
      'psu': const PlanComponent(
          category: '电源', brand: '玄武', model: '玄武 500K 金牌', price: 0, platform: ''),
      'case': const PlanComponent(
          category: '机箱', brand: '九州风神', model: '九州风神 魔方110', price: 0, platform: ''),
    },
    storages: [
      const PlanComponent(
          category: '硬盘', brand: '铠侠', model: 'EXCERIA RC20 1TB', price: 0, platform: ''),
    ],
  ),
  BuildPlan(
    id: 'default_5',
    name: '入门高性价比主机',
    components: {
      'cpu': const PlanComponent(
          category: 'CPU', brand: 'Intel', model: '酷睿 i3-12100F', price: 0, platform: ''),
      'gpu': const PlanComponent(
          category: '显卡', brand: 'AMD', model: 'Radeon RX 6600', price: 0, platform: ''),
      'motherboard': const PlanComponent(
          category: '主板', brand: '华硕', model: 'PRIME B760M-K DDR4', price: 0, platform: ''),
      'ram': const PlanComponent(
          category: '内存', brand: '光威', model: '天策 DDR4-3200 16GB（8G×2）', price: 0, platform: ''),
      'psu': const PlanComponent(
          category: '电源', brand: '玄武', model: '玄武 500K 金牌', price: 0, platform: ''),
      'case': const PlanComponent(
          category: '机箱', brand: '乔思伯', model: '乔思伯 D31 标准版', price: 0, platform: ''),
    },
    storages: [
      const PlanComponent(
          category: '硬盘', brand: '三星', model: '980 PRO 500GB', price: 0, platform: ''),
    ],
  ),
];
