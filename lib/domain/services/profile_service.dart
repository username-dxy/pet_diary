import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/pet.dart';
import '../../config/api_config.dart';

/// Profile 同步结果
class ProfileSyncResult {
  final bool success;
  final String message;
  final DateTime? syncedAt;

  ProfileSyncResult({
    required this.success,
    required this.message,
    this.syncedAt,
  });

  /// 错误消息（兼容性 getter）
  String? get errorMessage => success ? null : message;
}

/// Profile 服务抽象接口
abstract class ProfileService {
  /// 同步 Profile 到服务端
  Future<ProfileSyncResult> syncProfile(Pet pet);

  /// 上传头像照片
  Future<String> uploadProfilePhoto(File photo);

  /// 从服务端获取 Profile
  Future<Pet?> fetchProfile(String petId);

  /// 创建 Mock 服务实例
  factory ProfileService.mock() => MockProfileService();

  /// 创建 API 服务实例（使用全局配置）
  factory ProfileService.api({String? baseUrl}) => ApiProfileService(
        baseUrl: baseUrl,
      );
}

/// Mock Profile 服务（用于开发和测试）
class MockProfileService implements ProfileService {
  @override
  Future<ProfileSyncResult> syncProfile(Pet pet) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 1));

    debugPrint('[MockProfileService] 同步 Profile: ${pet.name}');

    // 模拟 90% 成功率
    final random = Random();
    if (random.nextDouble() < 0.9) {
      return ProfileSyncResult(
        success: true,
        message: '同步成功（Mock）',
        syncedAt: DateTime.now(),
      );
    } else {
      throw Exception('网络错误（Mock）');
    }
  }

  @override
  Future<String> uploadProfilePhoto(File photo) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('[MockProfileService] 上传照片: ${photo.path}');

    // 返回本地路径作为模拟 CDN URL
    return photo.path;
  }

  @override
  Future<Pet?> fetchProfile(String petId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    debugPrint('[MockProfileService] 获取 Profile: $petId');

    // 返回 null 表示服务端无数据（首次使用）
    return null;
  }
}

/// API Profile 服务（真实 API 调用）
class ApiProfileService implements ProfileService {
  final String baseUrl;

  /// 构造函数
  ///
  /// [baseUrl] 可选的自定义 API 地址，不传则使用全局配置
  ApiProfileService({String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  @override
  Future<ProfileSyncResult> syncProfile(Pet pet) async {
    debugPrint('[API] 同步宠物档案到服务器...');
    debugPrint('[API] URL: $baseUrl/api/mengyu/pets/profile');
    debugPrint('[API] Pet: ${pet.name}');

    try {
      final headers = await _authHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/mengyu/pets/profile'),
            headers: headers,
            body: jsonEncode(_toProfilePayload(pet)),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      debugPrint('[API] 响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[API] ✅ 同步成功');

        return ProfileSyncResult(
          success: true,
          message: data['message'] ?? '同步成功',
          syncedAt: DateTime.parse(data['data']['syncedAt']),
        );
      } else {
        debugPrint('[API] ❌ 同步失败: ${response.statusCode}');
        return ProfileSyncResult(
          success: false,
          message: '服务器错误: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('[API] ❌ 网络连接失败: $e');
      debugPrint('[API] 💡 提示: 请确保Mock Server正在运行 (npm start)');
      return ProfileSyncResult(
        success: false,
        message: '无法连接到服务器，请检查Mock Server是否运行',
      );
    } on TimeoutException catch (e) {
      debugPrint('[API] ❌ 请求超时: $e');
      return ProfileSyncResult(
        success: false,
        message: '请求超时',
      );
    } catch (e) {
      debugPrint('[API] ❌ 未知错误: $e');
      return ProfileSyncResult(
        success: false,
        message: '同步失败: $e',
      );
    }
  }

  Map<String, dynamic> _toProfilePayload(Pet pet) {
    int type = 0;
    if (pet.species == 'dog') type = 1;
    if (pet.species == 'cat') type = 2;

    int gender = 0;
    if (pet.gender == PetGender.male) {
      gender = 1;
    } else if (pet.gender == PetGender.female) {
      gender = 2;
    }

    return {
      'id': pet.id,
      'name': pet.name,
      'type': type,
      'breed': pet.breed,
      'profilePhotoPath': pet.profilePhotoPath,
      'birthday': pet.birthday?.toIso8601String(),
      'ownerNickname': pet.ownerNickname,
      'gender': gender,
      'personality': pet.personality?.name,
      'createdAt': pet.createdAt.toIso8601String(),
    };
  }

  @override
  Future<String> uploadProfilePhoto(File photo) async {
    debugPrint('[API] 上传头像照片...');
    debugPrint('[API] 文件路径: ${photo.path}');
    debugPrint('[API] URL: $baseUrl/api/mengyu/upload/profile-photo');

    try {
      // 检查文件是否存在
      if (!await photo.exists()) {
        throw Exception('照片文件不存在');
      }

      final fileSize = await photo.length();
      debugPrint('[API] 文件大小: ${fileSize / 1024} KB');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/mengyu/upload/profile-photo'),
      );

      final headers = await _authHeaders();
      request.headers.addAll(headers);

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photo.path,
        ),
      );

      debugPrint('[API] 开始上传...');
      final streamedResponse = await request
          .send()
          .timeout(Duration(seconds: ApiConfig.uploadTimeoutSeconds));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[API] 响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['data']['url'] as String;
        debugPrint('[API] ✅ 上传成功: $url');
        return url;
      } else {
        throw Exception('上传失败: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('[API] ❌ 网络连接失败: $e');
      throw Exception('无法连接到服务器');
    } catch (e) {
      debugPrint('[API] ❌ 上传失败: $e');
      rethrow;
    }
  }

  @override
  Future<Pet?> fetchProfile(String petId) async {
    debugPrint('[API] 获取宠物档案...');
    debugPrint('[API] Pet ID: $petId');
    debugPrint('[API] URL: $baseUrl/api/mengyu/pets/$petId/profile');

    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/mengyu/pets/$petId/profile'),
            headers: headers,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      debugPrint('[API] 响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[API] ✅ 获取成功');
        return Pet.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        debugPrint('[API] ℹ️ 服务端无此档案');
        return null;
      } else {
        throw Exception('获取失败: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('[API] ❌ 网络连接失败: $e');
      throw Exception('网络连接失败');
    } catch (e) {
      debugPrint('[API] ❌ 获取失败: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final headers = <String, String>{};
    final token = await ApiConfig.getToken();
    if (token != null && token.isNotEmpty) {
      headers['token'] = token;
    }
    return headers;
  }
}

/// Profile 服务工厂
class ProfileServiceFactory {
  /// 创建 Profile 服务实例
  ///
  /// [useMock] 是否使用 Mock 服务（默认 false，使用真实 API）
  /// [baseUrl] API 基础 URL（可选，不传则使用全局配置）
  static ProfileService create({
    bool useMock = false,
    String? baseUrl,
  }) {
    if (useMock) {
      return MockProfileService();
    } else {
      return ApiProfileService(baseUrl: baseUrl);
    }
  }
}
