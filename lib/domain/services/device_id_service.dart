import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 设备级稳定 ID
///
/// 同一设备始终返回同一 ID，首次调用时生成并持久化。
/// 后续迁移到用户体系后，可用 userId 替换。
class DeviceIdService {
  static const String _key = 'device_id';

  /// 内存缓存
  static String? _cached;

  /// 获取设备 ID（懒加载：首次生成，后续复用）
  static Future<String> getId() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }
}
