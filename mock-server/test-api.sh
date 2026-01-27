#!/bin/bash

# Pet Diary Mock Server API 测试脚本

BASE_URL="http://localhost:3000"

echo "🧪 ====================================="
echo "   Pet Diary API 测试"
echo "====================================="
echo ""

# 检查服务器是否运行
echo "📡 1. 检查服务器状态..."
response=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL)
if [ $response -eq 200 ]; then
    echo "   ✅ 服务器运行正常"
else
    echo "   ❌ 服务器未运行 (请先运行 npm start)"
    exit 1
fi
echo ""

# 测试获取统计信息
echo "📊 2. 获取统计信息..."
curl -s $BASE_URL/api/v1/stats | python3 -m json.tool
echo ""

# 测试创建宠物档案
echo "📝 3. 测试创建宠物档案..."
curl -s -X POST $BASE_URL/api/v1/pets/profile \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test_pet_001",
    "name": "测试小猫",
    "species": "cat",
    "breed": "橘猫",
    "ownerNickname": "测试主人",
    "birthday": "2020-05-01T00:00:00.000Z",
    "gender": "male",
    "personality": "playful",
    "createdAt": "2024-01-26T10:00:00.000Z"
  }' | python3 -m json.tool
echo ""

# 测试获取宠物档案
echo "🔍 4. 测试获取宠物档案..."
curl -s $BASE_URL/api/v1/pets/test_pet_001/profile | python3 -m json.tool
echo ""

# 测试创建日记
echo "📔 5. 测试创建日记..."
curl -s -X POST $BASE_URL/api/v1/diaries \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test_diary_001",
    "petId": "test_pet_001",
    "date": "2024-01-26T00:00:00.000Z",
    "content": "今天测试小猫很开心，在阳光下打滚。",
    "isLocked": false,
    "createdAt": "2024-01-26T10:00:00.000Z"
  }' | python3 -m json.tool
echo ""

# 测试获取日记列表
echo "📚 6. 测试获取日记列表..."
curl -s "$BASE_URL/api/v1/diaries?petId=test_pet_001&limit=10" | python3 -m json.tool
echo ""

# 再次获取统计信息
echo "📊 7. 查看更新后的统计信息..."
curl -s $BASE_URL/api/v1/stats | python3 -m json.tool
echo ""

echo "✅ ====================================="
echo "   所有测试完成！"
echo "====================================="
echo ""
echo "💡 提示:"
echo "   - 查看数据: cat db.json"
echo "   - 清空数据: rm db.json && echo '{}' > db.json"
echo "   - 查看上传文件: ls -lh uploads/"
echo ""
