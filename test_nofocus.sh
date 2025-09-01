#!/bin/bash

echo "🎯 无焦点窗口功能验证"
echo "========================"

# 检查应用运行状态
echo "1. 检查ClipMaster运行状态..."
if pgrep -f "ClipMaster" > /dev/null; then
    echo "✅ ClipMaster正在运行"
else
    echo "❌ ClipMaster未运行"
    exit 1
fi

# 准备测试数据
echo ""
echo "2. 准备测试数据..."
echo "🎯 无焦点测试：这是测试文本1" | pbcopy
sleep 1
echo "✨ 无焦点测试：这是测试文本2" | pbcopy  
sleep 1
echo "🚀 无焦点测试：这是测试文本3" | pbcopy
sleep 1

echo "✅ 已准备3个测试内容"

# 显示当前剪贴板内容
echo ""
echo "3. 当前剪贴板内容："
echo "$(pbpaste)"

# 测试指导
echo ""
echo "4. 🧪 手动测试步骤："
echo "============================="
echo ""
echo "📝 关键测试：验证点击不抢夺焦点"
echo ""
echo "步骤 1️⃣ ："
echo "   - 确保 TextEdit 窗口是活动的"
echo "   - 在 TextEdit 文档中放置光标"
echo "   - 输入一些文字确认光标位置"
echo ""
echo "步骤 2️⃣ ："
echo "   - 按 Option+V 打开 ClipMaster"
echo "   - 观察：ClipMaster 窗口应该出现"
echo "   - 观察：TextEdit 窗口应该仍然保持焦点状态"
echo ""
echo "步骤 3️⃣ ："
echo "   - 单击 ClipMaster 中的任一历史项目"
echo "   - 观察：内容应该直接粘贴到 TextEdit 中"
echo "   - 观察：TextEdit 应该仍然是活动窗口"
echo "   - 观察：不应该看到焦点切换到 ClipMaster"
echo ""
echo "🎯 预期结果："
echo "   ✅ 点击ClipMaster不会使其获得焦点"
echo "   ✅ 内容直接粘贴到原来的光标位置"
echo "   ✅ TextEdit保持活动状态"
echo "   ✅ 无需点击两次"
echo ""
echo "❌ 问题指标："
echo "   - 如果点击后ClipMaster获得焦点"
echo "   - 如果需要点击两次才能粘贴"
echo "   - 如果内容粘贴到错误位置"
echo "   - 如果TextEdit失去焦点"

echo ""
echo "🚀 开始测试！"
echo "请按照上述步骤操作，并观察是否符合预期结果..."