import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

/// API连接测试页面
///
/// 提供可视化的API测试界面，用户可以手动触发测试
class ApiTestPage extends StatefulWidget {
  const ApiTestPage({Key? key}) : super(key: key);

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  String _result = '点击按钮开始测试...';
  bool _isLoading = false;
  static const String _testToken = 'test-token';

  final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';

  /// 测试连接
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = '正在连接...';
    });

    final buffer = StringBuffer();

    try {
      // 测试1: 基础连接
      buffer.writeln('📡 测试1: 检查服务器状态');
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        buffer.writeln('✅ 服务器响应正常');
        buffer.writeln('   版本: ${data['version']}');
        buffer.writeln('   消息: ${data['message']}');
      } else {
        buffer.writeln('⚠️ 响应异常: ${response.statusCode}');
      }

      // 测试2: 获取统计信息
      buffer.writeln('\n📊 测试2: 获取统计信息');
      final statsResponse = await http
          .get(
            Uri.parse('$baseUrl/api/chongyu/stats'),
            headers: const {'token': _testToken},
          )
          .timeout(const Duration(seconds: 5));

      if (statsResponse.statusCode == 200) {
        final stats = jsonDecode(statsResponse.body);
        buffer.writeln('✅ 获取成功');
        buffer.writeln('   宠物: ${stats['data']['pets']}');
        buffer.writeln('   照片: ${stats['data']['photos']}');
        buffer.writeln('   日记: ${stats['data']['diaries']}');
        buffer.writeln('   运行时间: ${stats['data']['uptime'].toStringAsFixed(1)}秒');
      }

      buffer.writeln('\n🎉 所有测试通过！');

      setState(() {
        _result = buffer.toString();
      });
    } on SocketException catch (e) {
      setState(() {
        _result = '❌ 连接失败\n\n'
            '错误: 无法连接到服务器\n'
            '详情: ${e.message}\n\n'
            '💡 解决方法:\n'
            '1. 检查Mock Server是否运行:\n'
            '   cd mock-server && npm start\n\n'
            '2. 检查端口3000是否被占用:\n'
            '   lsof -i :3000\n\n'
            '3. Android需使用10.0.2.2而非localhost';
      });
    } on TimeoutException {
      setState(() {
        _result = '❌ 请求超时\n\n'
            '服务器响应超时（>5秒）\n\n'
            '💡 检查:\n'
            '1. 网络连接\n'
            '2. 服务器是否卡死\n'
            '3. 重启Mock Server';
      });
    } catch (e) {
      setState(() {
        _result = '❌ 未知错误\n\n'
            '错误: $e\n\n'
            '💡 检查:\n'
            '1. Info.plist是否配置NSAppTransportSecurity\n'
            '2. http依赖是否安装\n'
            '3. 运行flutter clean';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试POST请求
  Future<void> _testPost() async {
    setState(() {
      _isLoading = true;
      _result = '正在测试POST请求...';
    });

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/chongyu/pets/profile'),
            headers: {
              'Content-Type': 'application/json',
              'token': _testToken,
            },
            body: jsonEncode({
              'id': 'test_ui_${DateTime.now().millisecondsSinceEpoch}',
              'name': 'UI测试猫',
              'species': 'cat',
              'breed': '测试品种',
              'ownerNickname': 'UI测试主人',
              'birthday': '2020-05-01T00:00:00.000Z',
              'gender': 'male',
              'personality': 'playful',
              'createdAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _result = '✅ POST请求成功！\n\n'
              'Pet ID: ${result['data']['petId']}\n'
              '同步时间: ${result['data']['syncedAt']}\n'
              '消息: ${result['message']}\n\n'
              '💡 查看服务器数据:\n'
              'cat mock-server/db.json';
        });
      } else {
        setState(() {
          _result = '❌ POST请求失败\n\n状态码: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ POST请求失败\n\n错误: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 查看服务器统计
  Future<void> _viewStats() async {
    setState(() {
      _isLoading = true;
      _result = '正在获取统计信息...';
    });

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/chongyu/stats'),
            headers: const {'token': _testToken},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data['data'];

        setState(() {
          _result = '📊 服务器统计信息\n\n'
              '数据统计:\n'
              '  宠物: ${stats['pets']}\n'
              '  照片: ${stats['photos']}\n'
              '  日记: ${stats['diaries']}\n'
              '  用户: ${stats['users']}\n\n'
              '系统信息:\n'
              '  运行时间: ${stats['uptime'].toStringAsFixed(1)}秒\n'
              '  内存使用: ${(stats['memory']['heapUsed'] / 1024 / 1024).toStringAsFixed(1)} MB\n'
              '  内存总量: ${(stats['memory']['heapTotal'] / 1024 / 1024).toStringAsFixed(1)} MB';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ 获取失败\n\n错误: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        title: const Text('API连接测试'),
        backgroundColor: const Color(0xFFFFF8DC),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL显示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD2B48C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '测试服务器',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    baseUrl,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 测试按钮组
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: const Icon(Icons.link),
                    label: const Text('测试连接'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testPost,
                    icon: const Icon(Icons.send),
                    label: const Text('POST请求'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _viewStats,
                icon: const Icon(Icons.bar_chart),
                label: const Text('查看统计'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 结果显示
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD2B48C)),
                ),
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF8B4513),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '测试中...',
                              style: TextStyle(
                                color: Color(0xFF8B4513),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _result,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '确保Mock Server正在运行:\ncd mock-server && npm start',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
