/// 快速测试API连接
///
/// 使用方法:
/// 1. 确保Mock Server正在运行: cd mock-server && npm start
/// 2. 在main.dart中调用此函数: await testApiConnection();
/// 3. 查看控制台输出

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<void> testApiConnection() async {
  debugPrint('');
  debugPrint('🧪 ========== API连接测试 ==========');

  // 根据平台选择URL
  final baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';

  debugPrint('📍 测试URL: $baseUrl');
  debugPrint('📱 平台: ${Platform.operatingSystem}');

  try {
    // 测试1: 检查服务器是否运行
    debugPrint('');
    debugPrint('📡 测试1: 检查服务器状态...');
    final response = await http
        .get(Uri.parse(baseUrl))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      debugPrint('✅ 服务器响应正常');
      final data = jsonDecode(response.body);
      debugPrint('   版本: ${data['version']}');
      debugPrint('   消息: ${data['message']}');
    } else {
      debugPrint('⚠️ 服务器响应异常: ${response.statusCode}');
    }

    // 测试2: 获取统计信息
    debugPrint('');
    debugPrint('📊 测试2: 获取统计信息...');
    final statsResponse = await http
        .get(
          Uri.parse('$baseUrl/api/chongyu/stats'),
          headers: const {'token': 'test-token'},
        )
        .timeout(const Duration(seconds: 5));

    if (statsResponse.statusCode == 200) {
      final stats = jsonDecode(statsResponse.body);
      debugPrint('✅ 获取统计信息成功');
      debugPrint('   宠物数: ${stats['data']['pets']}');
      debugPrint('   照片数: ${stats['data']['photos']}');
      debugPrint('   日记数: ${stats['data']['diaries']}');
      debugPrint('   运行时间: ${stats['data']['uptime']} 秒');
    }

    // 测试3: 测试POST请求（创建宠物档案）
    debugPrint('');
    debugPrint('📝 测试3: 测试POST请求...');
    final postResponse = await http
        .post(
          Uri.parse('$baseUrl/api/chongyu/pets/profile'),
          headers: {
            'Content-Type': 'application/json',
            'token': 'test-token',
          },
          body: jsonEncode({
            'id': 'test_flutter_${DateTime.now().millisecondsSinceEpoch}',
            'name': 'Flutter测试猫',
            'species': 'cat',
            'breed': '测试品种',
            'ownerNickname': 'Flutter主人',
            'birthday': '2020-05-01T00:00:00.000Z',
            'gender': 'male',
            'personality': 'playful',
            'createdAt': DateTime.now().toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (postResponse.statusCode == 200) {
      final result = jsonDecode(postResponse.body);
      debugPrint('✅ POST请求成功');
      debugPrint('   Pet ID: ${result['data']['petId']}');
      debugPrint('   同步时间: ${result['data']['syncedAt']}');
    }

    debugPrint('');
    debugPrint('🎉 ========== 所有测试通过！==========');
    debugPrint('💡 提示: API服务已正常工作，可以开始使用');
    debugPrint('');

  } on SocketException catch (e) {
    debugPrint('');
    debugPrint('❌ ========== 连接失败 ==========');
    debugPrint('错误: 无法连接到服务器');
    debugPrint('详情: $e');
    debugPrint('');
    debugPrint('💡 解决方法:');
    debugPrint('1. 检查Mock Server是否运行:');
    debugPrint('   cd mock-server && npm start');
    debugPrint('2. 检查端口3000是否被占用:');
    debugPrint('   lsof -i :3000');
    debugPrint('3. 如果是Android，确保使用10.0.2.2而非localhost');
    debugPrint('==============================');
    debugPrint('');

  } on TimeoutException catch (e) {
    debugPrint('');
    debugPrint('❌ ========== 请求超时 ==========');
    debugPrint('错误: 服务器响应超时');
    debugPrint('详情: $e');
    debugPrint('');
    debugPrint('💡 解决方法:');
    debugPrint('1. 检查网络连接');
    debugPrint('2. 重启Mock Server');
    debugPrint('3. 增加超时时间');
    debugPrint('==============================');
    debugPrint('');

  } catch (e) {
    debugPrint('');
    debugPrint('❌ ========== 未知错误 ==========');
    debugPrint('错误: $e');
    debugPrint('');
    debugPrint('💡 解决方法:');
    debugPrint('1. 检查Info.plist是否配置NSAppTransportSecurity');
    debugPrint('2. 查看完整错误堆栈');
    debugPrint('3. 重新运行flutter clean && flutter run');
    debugPrint('==============================');
    debugPrint('');
  }
}
