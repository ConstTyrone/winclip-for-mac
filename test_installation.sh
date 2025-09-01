#!/bin/bash

echo "🧪 ClipMaster 安装测试"
echo "====================="

# 检查应用是否存在
if [ -d "/Applications/ClipMaster.app" ]; then
    echo "✅ 应用包存在"
else
    echo "❌ 应用包不存在"
    exit 1
fi

# 检查进程是否运行
if pgrep -f "ClipMaster" > /dev/null; then
    echo "✅ 应用进程运行中 (PID: $(pgrep -f "ClipMaster"))"
else
    echo "❌ 应用进程未运行"
fi

# 检查菜单栏图标
echo ""
echo "🔍 检查菜单栏状态..."
echo "请检查菜单栏右上角是否显示了自定义的剪贴板图标"
echo "（应该是蓝色圆角矩形剪贴板样式，而不是系统默认图标）"

# 检查快捷键设置
echo ""
echo "⌨️  检查快捷键设置..."
echo "默认快捷键应该为: Option+V"

# 提供手动测试指引
echo ""
echo "📋 手动测试步骤:"
echo "1. 复制一些文本到剪贴板"
echo "2. 按 Option+V 快捷键"
echo "3. 应该弹出剪贴板历史窗口"
echo "4. 单击任意项目应该直接粘贴到当前光标位置"
echo "5. 点击窗口外部应该关闭窗口"

echo ""
echo "⚙️ 设置测试:"
echo "1. 右键点击菜单栏图标"
echo "2. 选择'偏好设置...'"
echo "3. 尝试录制新的快捷键"
echo "4. 检查录制是否正常工作"

echo ""
echo "🎯 如果发现问题，请反馈:"
echo "- 菜单栏图标是否为自定义样式？"
echo "- Option+V 是否能打开剪贴板？"
echo "- 快捷键录制是否正常？"
