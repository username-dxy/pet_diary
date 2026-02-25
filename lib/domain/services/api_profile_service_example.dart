/// 这是连接本地Mock Server的完整示例
/// 文件位置: lib/domain/services/api_profile_service_example.dart
///
/// 使用方法:
/// 1. 启动Mock Server: cd mock-server && npm start
/// 2. 在ProfileViewModel中切换到此服务:
///    _profileService = ApiProfileServiceExample()

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../data/models/pet.dart';
import '../../config/api_config.dart';
import 'profile_service.dart';

class ApiProfileServiceExample implements ProfileService {
  // 本地服务器地址
  // iOS模拟器: localhost
  // Android模拟器: 10.0.2.2
  final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';

  @override
  Future<ProfileSyncResult> syncProfile(Pet pet) async {
    debugPrint('[API] 同步宠物档案到服务器...');
    debugPrint('[API] URL: $baseUrl/api/mengyu/pets/profile');

    try {
      final headers = await _authHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/mengyu/pets/profile'),
            headers: headers,
            body: jsonEncode(_toProfilePayload(pet)),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('[API] 响应状态码: ${response.statusCode}');
      debugPrint('[API] 响应内容: ${response.body}');

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
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[API] 响应状态码: ${response.statusCode}');
      debugPrint('[API] 响应内容: ${response.body}');

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
          .timeout(const Duration(seconds: 10));

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
      return null; // 离线时返回null
    } catch (e) {
      debugPrint('[API] ❌ 获取失败: $e');
      return null;
    }
  }

  /// 测试服务器连接
  Future<bool> testConnection() async {
    debugPrint('[API] 测试服务器连接...');
    debugPrint('[API] URL: $baseUrl');

    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('[API] ✅ 服务器连接正常');
        return true;
      } else {
        debugPrint('[API] ⚠️ 服务器响应异常: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[API] ❌ 无法连接服务器: $e');
      debugPrint('[API] 💡 请检查:');
      debugPrint('[API]    1. Mock Server是否运行: npm start');
      debugPrint('[API]    2. 端口是否正确: 3000');
      debugPrint('[API]    3. iOS Info.plist是否允许HTTP');
      return false;
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
}

/// 使用示例:
///
/// ```dart
/// // 在ProfileViewModel中
/// ProfileViewModel({
///   ProfileService? profileService,
/// }) : _profileService = profileService ?? ApiProfileServiceExample();
///
/// // 测试连接
/// final apiService = ApiProfileServiceExample();
/// final isConnected = await apiService.testConnection();
/// if (isConnected) {
///   print('✅ 可以使用API服务');
/// } else {
///   print('❌ 使用Mock服务');
/// }
/// ```
