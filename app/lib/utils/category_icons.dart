import 'package:flutter/material.dart';

/// 根据品类返回一个图标。
IconData categoryIcon(String category) {
  switch (category) {
    case 'CPU':
      return Icons.memory;
    case '主板':
      return Icons.developer_board;
    case '显卡':
      return Icons.videogame_asset;
    case '内存':
      return Icons.storage;
    case '硬盘':
      return Icons.sd_storage;
    case '电源':
      return Icons.power;
    case '机箱':
      return Icons.dns;
    case '整机方案':
      return Icons.computer;
    default:
      return Icons.devices_other;
  }
}
