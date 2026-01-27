/// API 配置
///
/// 全局 API 配置管理，支持不同环境的配置切换
class ApiConfig {
  // 私有构造函数，防止实例化
  ApiConfig._();

  /// 当前环境
  static Environment _environment = Environment.development;

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
    // 真机需要使用电脑的局域网 IP
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
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
