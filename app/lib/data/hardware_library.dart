import '../cloud/cloud_sync.dart';
import '../models/hardware_spec.dart';
import '../storage/hardware_catalog_store.dart';
import '../storage/user_spec_store.dart';
import 'hardware_catalog.dart';

/// 合并内置硬件库 + 云端发行的新硬件 + 用户自定义硬件
/// 按 id 去重：云端覆盖内置（同 id 更新），用户自定义优先级最高
Future<List<HardwareSpec>> loadHardwareLibrary() async {
  final cloud = await HardwareCatalogStore().load();
  final userSpecs = await UserSpecStore().loadAll();
  final merged = <String, HardwareSpec>{};
  for (final s in kHardwareCatalog) {
    merged[s.id] = s;
  }
  for (final s in cloud) {
    merged[s.id] = s;
  }
  for (final s in userSpecs) {
    merged[s.id] = s;
  }
  return merged.values.toList();
}

/// 从云端拉取最新硬件库并缓存到本地（尽力而为，失败静默不打断）
Future<void> syncHardwareCatalogFromCloud() async {
  try {
    final cloud = await CloudSync.downloadHardwareCatalog();
    if (cloud.isNotEmpty) {
      await HardwareCatalogStore().save(cloud);
    }
  } catch (_) {
    // 同步失败静默处理，下次再试
  }
}
