/// API 错误信息
class ApiError {
  final String message;
  final int code;

  const ApiError({required this.message, required this.code});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] as String? ?? '',
      code: json['code'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}

/// 通用 API 响应模型
///
/// 匹配服务端标准响应格式: `{ success, data, error }`
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  /// 从 JSON 解析响应
  ///
  /// [fromJsonT] 用于将 `data` 字段转换为泛型 T
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 创建成功响应
  factory ApiResponse.success(T data) {
    return ApiResponse<T>(success: true, data: data);
  }

  /// 创建失败响应
  factory ApiResponse.failure(String message, int code) {
    return ApiResponse<T>(
      success: false,
      error: ApiError(message: message, code: code),
    );
  }

  /// 错误信息（便捷获取）
  String get errorMessage => error?.message ?? '未知错误';
}
