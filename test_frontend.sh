#!/bin/bash

echo "🎯 ClipMaster 前端焦点检测验证"
echo "======================================"

# 步骤1：打开多个测试应用
echo "1. 设置测试环境..."
echo "   打开多个应用进行测试..."

# 打开TextEdit
osascript -e 'tell application "TextEdit" to activate'
osascript -e 'tell application "TextEdit" to make new document'
sleep 2

# 打开Terminal
osascript -e 'tell application "Terminal" to activate'
sleep 1

# 打开Safari
osascript -e 'tell application "Safari" to activate'
sleep 1

echo "✅ 已打开测试应用：TextEdit, Terminal, Safari"

# 步骤2：复制测试内容
echo ""
echo "2. 准备测试数据..."

echo "✨ 第一条：纯文本测试" | pbcopy
sleep 1
echo "🔗 第二条：https://example.com/test-url" | pbcopy  
sleep 1
echo "💻 第三条：const result = await fetch('/api/test');" | pbcopy
sleep 1
echo "📝 第四条：多行文本测试
第二行内容
第三行内容" | pbcopy
sleep 1

echo "✅ 已准备4个不同类型的测试内容"

# 步骤3：测试指导
echo ""
echo "3. 手动测试步骤："
echo "   ===================="
echo ""
echo "   🎯 焦点恢复测试："
echo "   1️⃣  点击 TextEdit 窗口，在文档中放置光标"
echo "   2️⃣  按 Option+V 打开 ClipMaster"
echo "   3️⃣  单击任一历史项目"
echo "   4️⃣  验证：内容应该粘贴到 TextEdit 中光标位置"
echo ""
echo "   🖥️  多屏幕测试（如果有）："
echo "   1️⃣  将 TextEdit 移动到副屏"
echo "   2️⃣  在副屏的 TextEdit 中放置光标"
echo "   3️⃣  在主屏按 Option+V"
echo "   4️⃣  单击历史项目"
echo "   5️⃣  验证：内容应该粘贴到副屏 TextEdit 中"
echo ""
echo "   🔄 切换应用测试："
echo "   1️⃣  在 TextEdit 中放置光标"
echo "   2️⃣  切换到 Terminal"
echo "   3️⃣  按 Option+V（光标仍在 TextEdit 中）"
echo "   4️⃣  单击历史项目"
echo "   5️⃣  验证：应该回到 TextEdit 并粘贴"

# 步骤4：检查关键功能
echo ""
echo "4. 验证核心改进："
echo "   ✅ 已移除搜索框（解决焦点冲突）"
echo "   ✅ 使用后台应用模式（.accessory）"
echo "   ✅ 实现LimitedFocusWindow（平衡焦点控制）"  
echo "   ✅ 新增实时光标检测（detectCursorTargetApp）"
echo "   ✅ 使用CGWindowListCopyWindowInfo（精确检测）"

# 步骤5：问题检查列表
echo ""
echo "5. 问题检查列表："
echo "   ❓ Option+V 快捷键是否响应？"
echo "   ❓ 单击是否直接粘贴（无需二次点击）？"
echo "   ❓ 是否粘贴到正确的光标位置？"
echo "   ❓ 多屏幕环境下检测是否准确？"
echo "   ❓ 切换应用后焦点恢复是否正确？"

# 步骤6：期望的日志输出
echo ""
echo "6. 期望的控制台日志："
echo "   🎯 检测到光标目标应用: TextEdit"
echo "   ✅ 激活目标应用: TextEdit"
echo "   ✅ 已模拟粘贴操作 (plainText)"
echo "   ✅ 剪贴板窗口已隐藏"

echo ""
echo "🚀 开始测试！请按照上述步骤进行验证..."
echo "   如果遇到问题，请查看控制台输出获取详细信息"