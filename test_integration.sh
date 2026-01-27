#!/bin/bash

# Pet Diary API集成测试脚本

echo ""
echo "🧪 ======================================"
echo "   Pet Diary API 集成测试"
echo "======================================"
echo ""

# 检查Mock Server是否运行
echo "📡 1. 检查Mock Server状态..."
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "   ✅ Mock Server运行正常"
else
    echo "   ❌ Mock Server未运行"
    echo ""
    echo "   💡 请在新终端运行:"
    echo "      cd mock-server && npm start"
    echo ""
    exit 1
fi

# 检查Flutter环境
echo ""
echo "🔧 2. 检查Flutter环境..."
if ! command -v flutter &> /dev/null; then
    echo "   ❌ Flutter未安装"
    exit 1
fi
echo "   ✅ Flutter已安装: $(flutter --version | head -1)"

# 清理缓存
echo ""
echo "🧹 3. 清理Flutter缓存..."
flutter clean > /dev/null 2>&1
echo "   ✅ 缓存已清理"

# 安装依赖
echo ""
echo "📦 4. 安装依赖..."
flutter pub get > /dev/null 2>&1
echo "   ✅ 依赖已安装"

# 检查代码质量
echo ""
echo "🔍 5. 代码质量检查..."
error_count=$(flutter analyze 2>&1 | grep "^error" | wc -l | tr -d ' ')

if [ "$error_count" -eq "0" ]; then
    echo "   ✅ 代码检查通过（0个错误）"
else
    echo "   ⚠️ 发现 $error_count 个错误"
    echo ""
    echo "   详细信息:"
    flutter analyze 2>&1 | grep "^error" | head -5
    echo ""
    echo "   运行以下命令查看完整错误:"
    echo "   flutter analyze"
    echo ""
    exit 1
fi

# 检查Info.plist配置
echo ""
echo "📱 6. 检查iOS HTTP配置..."
if grep -q "NSAppTransportSecurity" ios/Runner/Info.plist; then
    echo "   ✅ Info.plist已配置"
else
    echo "   ❌ Info.plist未配置"
    echo ""
    echo "   💡 请查看: VERIFY_HTTP_CONFIG.md"
    echo ""
    exit 1
fi

# 测试API连接
echo ""
echo "🌐 7. 测试API连接..."
response=$(curl -s http://localhost:3000/api/v1/stats)
if echo "$response" | grep -q "success"; then
    pets=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['pets'])")
    diaries=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['diaries'])")
    echo "   ✅ API响应正常"
    echo "      宠物数: $pets"
    echo "      日记数: $diaries"
else
    echo "   ❌ API响应异常"
    exit 1
fi

# 测试完成
echo ""
echo "✅ ======================================"
echo "   所有检查通过！"
echo "======================================"
echo ""
echo "🚀 准备测试:"
echo "   1. 运行App: flutter run"
echo "   2. 创建宠物档案"
echo "   3. 查看控制台日志"
echo ""
echo "📊 查看Mock Server数据:"
echo "   cat mock-server/db.json | python3 -m json.tool"
echo ""
echo "📝 查看Mock Server日志:"
echo "   tail -f /private/tmp/claude/-Users-00ffff-pet-diary/tasks/b1712af.output"
echo ""
echo "📚 详细文档:"
echo "   API_INTEGRATION_COMPLETE.md"
echo ""
