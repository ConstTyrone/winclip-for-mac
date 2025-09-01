#!/bin/bash

echo "🧪 ClipMaster 功能测试脚本"
echo "================================="

# 测试1：验证应用是否在运行
echo "1. 检查应用进程..."
if pgrep -f "ClipMaster" > /dev/null; then
    echo "✅ ClipMaster 进程正在运行"
else
    echo "❌ ClipMaster 进程未运行"
fi

# 测试2：复制一些测试内容
echo "2. 复制测试内容到剪贴板..."
echo "测试文本：实时光标检测功能验证" | pbcopy
sleep 1
echo "测试URL：https://github.com/test" | pbcopy
sleep 1
echo "测试代码：console.log('Hello World')" | pbcopy
sleep 1

echo "✅ 已复制3个测试项目到剪贴板"

# 测试3：验证剪贴板内容
echo "3. 验证当前剪贴板内容..."
current_content=$(pbpaste)
echo "当前剪贴板内容：$current_content"

# 测试4：尝试使用快捷键（模拟）
echo "4. 快捷键测试提示..."
echo "请手动测试以下功能："
echo "   - 按 Option+V 呼出 ClipMaster 窗口"
echo "   - 单击任一剪贴板项目进行粘贴"
echo "   - 验证是否粘贴到正确的光标位置"

# 测试5：检查辅助功能权限
echo "5. 检查系统权限..."
if [[ $(sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' 'SELECT allowed FROM access WHERE service="kTCCServiceAccessibility" AND client LIKE "%ClipMaster%";' 2>/dev/null) == "1" ]]; then
    echo "✅ 辅助功能权限已授予"
else
    echo "⚠️  可能需要授予辅助功能权限"
    echo "   请到 系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能"
    echo "   添加 ClipMaster 应用"
fi

echo ""
echo "🎯 焦点检测功能测试指南："
echo "1. 打开一个文本编辑器 (如 TextEdit)"
echo "2. 在文档中放置光标"
echo "3. 按 Option+V 打开 ClipMaster"
echo "4. 单击任一历史项目"
echo "5. 验证内容是否粘贴到 TextEdit 中的光标位置"
echo "6. 测试多屏幕环境下的光标检测准确性"

echo ""
echo "✅ 测试脚本完成！"