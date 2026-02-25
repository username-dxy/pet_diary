import 'package:shared_preferences/shared_preferences.dart';

/// API 配置
///
/// 全局 API 配置管理，支持不同环境的配置切换
class ApiConfig {
  // 私有构造函数，防止实例化
  ApiConfig._();

  /// Token 存储 key
  static const String _tokenKey = 'api_token';

  /// 当前环境
  static Environment _environment = Environment.development;

  /// 内存中缓存的 token
  static String? _cachedToken;

  /// 获取当前环境
  static Environment get environment => _environment;

  /// 设置环境（在 main.dart 中调用）
  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// 获取 API Base URL
  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return _developmentUrl;
      case Environment.staging:
        return _stagingUrl;
      case Environment.production:
        return _productionUrl;
    }
  }

  /// 开发环境 URL（本地 Mock Server）
  static String get _developmentUrl {
    // iOS 模拟器使用 localhost
    // Android 模拟器使用 10.0.2.2
    // 真机需要使用电脑的局域网 IP（需与 mock-server 的 HOST 一致）192.168.3.129
    // 热点：172.20.10.6 
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://192.168.3.129:3000',
    );
  }

  /// 预发布环境 URL
  static String get _stagingUrl {
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://staging-api.petdiary.com',
    );
  }

  /// 生产环境 URL
  static String get _productionUrl {
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.petdiary.com',
    );
  }

  /// API 超时时间（秒）
  static int get timeoutSeconds {
    return const int.fromEnvironment('API_TIMEOUT', defaultValue: 10);
  }

  /// 上传超时时间（秒）
  static int get uploadTimeoutSeconds {
    return const int.fromEnvironment('UPLOAD_TIMEOUT', defaultValue: 30);
  }

  /// 是否启用调试日志
  static bool get enableDebugLog {
    return _environment == Environment.development;
  }

  /// 获取 token（优先从内存缓存读取）
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  /// 保存 token
  static Future<void> setToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// 清除 token
  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// 是否已有 token
  static Future<bool> get hasToken async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

/// 环境枚举
enum Environment {
  /// 开发环境（本地 Mock Server）
  development,

  /// 预发布环境
  staging,

  /// 生产环境
  production,
}
