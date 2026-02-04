import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'api_response.dart';

/// HTTP 客户端封装
///
/// 提供 GET / POST / 文件上传方法，自动附加 token 和 baseUrl
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// 发起 GET 请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    required T Function(dynamic json) fromJson,
  }) async {
    final uri = _buildUri(path, queryParams);
    _log('GET $uri');

    try {
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.failure('网络连接失败', -1);
    } on http.ClientException catch (e) {
      return ApiResponse.failure('请求失败: ${e.message}', -1);
    } catch (e) {
      if (e is TimeoutException || e.toString().contains('TimeoutException')) {
        return ApiResponse.failure('请求超时', -2);
      }
      return ApiResponse.failure('请求异常: $e', -1);
    }
  }

  /// 发起 POST 请求（JSON body）
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) fromJson,
  }) async {
    final uri = _buildUri(path);
    _log('POST $uri');

    try {
      final headers = await _headers();
      headers['Content-Type'] = 'application/json';

      final response = await _client
          .post(uri, headers: headers, body: json.encode(body ?? {}))
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.failure('网络连接失败', -1);
    } on http.ClientException catch (e) {
      return ApiResponse.failure('请求失败: ${e.message}', -1);
    } catch (e) {
      if (e is TimeoutException || e.toString().contains('TimeoutException')) {
        return ApiResponse.failure('请求超时', -2);
      }
      return ApiResponse.failure('请求异常: $e', -1);
    }
  }

  /// 上传文件
  ///
  /// [files] 为字段名到文件路径列表的映射
  /// [fields] 为附加的表单字段
  Future<ApiResponse<T>> uploadFiles<T>(
    String path, {
    required Map<String, List<String>> files,
    Map<String, String>? fields,
    required T Function(dynamic json) fromJson,
  }) async {
    final uri = _buildUri(path);
    _log('🌐 UPLOAD $uri');

    try {
      final request = http.MultipartRequest('POST', uri);
      final headers = await _headers();
      request.headers.addAll(headers);

      // 添加文件
      int fileCount = 0;
      for (final entry in files.entries) {
        for (final filePath in entry.value) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, filePath),
          );
          fileCount++;
        }
      }
      _log('   文件数: $fileCount');

      // 添加表单字段
      if (fields != null) {
        request.fields.addAll(fields);
        _log('   字段数: ${fields.length}');
        if (fields.containsKey('petId_0')) {
          _log('   petId: ${fields['petId_0']}');
        }
        if (fields.containsKey('date_0')) {
          _log('   date: ${fields['date_0']}');
        }
      }

      _log('   超时: ${ApiConfig.uploadTimeoutSeconds}s');
      final streamedResponse = await request
          .send()
          .timeout(Duration(seconds: ApiConfig.uploadTimeoutSeconds));

      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, fromJson);
    } on SocketException catch (e) {
      _log('❌ 网络连接失败: $e');
      return ApiResponse.failure('网络连接失败', -1);
    } catch (e) {
      if (e is TimeoutException || e.toString().contains('TimeoutException')) {
        _log('⏱️ 上传超时');
        return ApiResponse.failure('上传超时', -2);
      }
      _log('❌ 上传异常: $e');
      return ApiResponse.failure('上传异常: $e', -1);
    }
  }

  /// 构建完整 URI
  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final base = ApiConfig.baseUrl;
    final uri = Uri.parse('$base$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  /// 构建请求头（自动附加 token）
  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{};
    final token = await ApiConfig.getToken();
    if (token != null && token.isNotEmpty) {
      headers['token'] = token;
    }
    return headers;
  }

  /// 处理响应
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json) fromJson,
  ) {
    final bodyPreview = response.body.length > 200
        ? '${response.body.substring(0, 200)}...'
        : response.body;
    _log('📥 Response [${response.statusCode}]');
    _log('   Body: $bodyPreview');

    if (response.statusCode == 401) {
      _log('❌ 401 未授权');
      return ApiResponse.failure('未授权，请重新登录', 401);
    }

    if (response.statusCode >= 400) {
      _log('❌ HTTP ${response.statusCode} 错误');
    }

    try {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(jsonData, fromJson);

      if (apiResponse.success) {
        _log('✅ API 调用成功');
      } else {
        _log('❌ API 返回失败: ${apiResponse.errorMessage}');
      }

      return apiResponse;
    } catch (e) {
      _log('❌ JSON 解析失败: $e');
      return ApiResponse.failure('数据解析失败: $e', -3);
    }
  }

  /// 调试日志
  void _log(String message) {
    if (ApiConfig.enableDebugLog) {
      // ignore: avoid_print
      print('[ApiClient] $message');
    }
  }

  /// 关闭客户端
  void dispose() {
    _client.close();
  }
}
