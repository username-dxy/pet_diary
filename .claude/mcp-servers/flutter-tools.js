#!/usr/bin/env node

/**
 * Flutter Tools MCP Server
 * 为 Pet Diary 项目提供 Flutter 开发工具集成
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const path = require('path');
const fs = require('fs').promises;

const execAsync = promisify(exec);

// 简化的 MCP 服务器实现（独立运行，不依赖 SDK）
class FlutterToolsServer {
  constructor() {
    this.projectRoot = process.env.FLUTTER_PROJECT_ROOT || process.cwd();
  }

  // 处理输入请求
  async handleRequest(request) {
    const { method, params } = request;

    switch (method) {
      case 'tools/list':
        return this.listTools();
      case 'tools/call':
        return this.callTool(params.name, params.arguments || {});
      default:
        throw new Error(`Unknown method: ${method}`);
    }
  }

  // 列出可用工具
  listTools() {
    return {
      tools: [
        {
          name: 'flutter_test',
          description: '运行 Flutter 测试',
          inputSchema: {
            type: 'object',
            properties: {
              test_path: {
                type: 'string',
                description: '测试文件路径，默认运行所有测试'
              }
            }
          }
        },
        {
          name: 'flutter_analyze',
          description: '分析 Flutter 代码质量',
          inputSchema: {
            type: 'object',
            properties: {}
          }
        },
        {
          name: 'pub_get',
          description: '获取 Flutter 依赖',
          inputSchema: {
            type: 'object',
            properties: {}
          }
        },
        {
          name: 'dart_format',
          description: '格式化 Dart 代码',
          inputSchema: {
            type: 'object',
            properties: {
              path: {
                type: 'string',
                description: '要格式化的文件或目录路径'
              }
            }
          }
        },
        {
          name: 'check_mvvm',
          description: '检查 MVVM 架构文件结构',
          inputSchema: {
            type: 'object',
            properties: {
              feature: {
                type: 'string',
                description: '功能模块名称（如 home, calendar, diary）'
              }
            },
            required: ['feature']
          }
        }
      ]
    };
  }

  // 调用工具
  async callTool(name, args) {
    try {
      switch (name) {
        case 'flutter_test':
          return await this.runTests(args.test_path);
        case 'flutter_analyze':
          return await this.analyze();
        case 'pub_get':
          return await this.pubGet();
        case 'dart_format':
          return await this.format(args.path);
        case 'check_mvvm':
          return await this.checkMVVM(args.feature);
        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `错误: ${error.message}`
        }],
        isError: true
      };
    }
  }

  // 运行测试
  async runTests(testPath = 'test') {
    const cmd = `cd "${this.projectRoot}" && flutter test ${testPath}`;
    console.error(`[MCP] Running: ${cmd}`);

    try {
      const { stdout, stderr } = await execAsync(cmd, {
        maxBuffer: 10 * 1024 * 1024
      });
      return {
        content: [{
          type: 'text',
          text: `测试结果:\n${stdout || stderr}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `测试失败:\n${error.stderr || error.message}`
        }],
        isError: false // 测试失败不算 MCP 错误
      };
    }
  }

  // 代码分析
  async analyze() {
    const cmd = `cd "${this.projectRoot}" && flutter analyze`;
    console.error(`[MCP] Running: ${cmd}`);

    try {
      const { stdout, stderr } = await execAsync(cmd);
      return {
        content: [{
          type: 'text',
          text: stdout || '代码分析通过'
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `分析结果:\n${error.stderr}`
        }]
      };
    }
  }

  // 获取依赖
  async pubGet() {
    const cmd = `cd "${this.projectRoot}" && flutter pub get`;
    console.error(`[MCP] Running: ${cmd}`);

    try {
      const { stdout } = await execAsync(cmd);
      return {
        content: [{
          type: 'text',
          text: `依赖已更新:\n${stdout}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `获取依赖失败:\n${error.message}`
        }],
        isError: true
      };
    }
  }

  // 格式化代码
  async format(targetPath = '.') {
    const cmd = `cd "${this.projectRoot}" && dart format ${targetPath}`;
    console.error(`[MCP] Running: ${cmd}`);

    try {
      const { stdout } = await execAsync(cmd);
      return {
        content: [{
          type: 'text',
          text: `代码已格式化:\n${stdout}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `格式化失败:\n${error.message}`
        }],
        isError: true
      };
    }
  }

  // 检查 MVVM 架构
  async checkMVVM(feature) {
    const checks = {};
    const expectedFiles = {
      screen: `lib/presentation/screens/${feature}/${feature}_screen.dart`,
      viewmodel: `lib/presentation/screens/${feature}/${feature}_viewmodel.dart`,
      widgets_dir: `lib/presentation/screens/${feature}/widgets`,
      model: `lib/data/models/${feature}.dart`,
      repository: `lib/data/repositories/${feature}_repository.dart`
    };

    for (const [key, relativePath] of Object.entries(expectedFiles)) {
      const fullPath = path.join(this.projectRoot, relativePath);
      try {
        await fs.stat(fullPath);
        checks[key] = '✅ 存在';
      } catch {
        checks[key] = '❌ 缺失';
      }
    }

    const report = Object.entries(checks)
      .map(([key, status]) => `  ${key}: ${status}`)
      .join('\n');

    return {
      content: [{
        type: 'text',
        text: `MVVM 架构检查 (${feature}):\n${report}`
      }]
    };
  }

  // 启动服务器（JSON-RPC over stdio）
  start() {
    console.error('[MCP] Flutter Tools Server starting...');

    let buffer = '';

    process.stdin.on('data', async (chunk) => {
      buffer += chunk.toString();
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        if (!line.trim()) continue;

        try {
          const request = JSON.parse(line);
          console.error(`[MCP] Request: ${request.method}`);

          const response = await this.handleRequest(request);

          const reply = {
            jsonrpc: '2.0',
            id: request.id,
            result: response
          };

          process.stdout.write(JSON.stringify(reply) + '\n');
        } catch (error) {
          console.error(`[MCP] Error: ${error.message}`);

          const errorReply = {
            jsonrpc: '2.0',
            id: null,
            error: {
              code: -32603,
              message: error.message
            }
          };

          process.stdout.write(JSON.stringify(errorReply) + '\n');
        }
      }
    });

    process.stdin.on('end', () => {
      console.error('[MCP] Server shutting down');
      process.exit(0);
    });

    console.error('[MCP] Flutter Tools Server ready');
  }
}

// 主程序
if (require.main === module) {
  const server = new FlutterToolsServer();
  server.start();
}

module.exports = FlutterToolsServer;
