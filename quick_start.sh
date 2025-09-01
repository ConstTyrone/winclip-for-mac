#!/bin/bash

# WinClip for Mac - 一键快速开始脚本
# 适合想要快速试用的用户

set -e

echo "🎯 WinClip for Mac - 一键快速开始"
echo "================================"
echo ""
echo "此脚本将："
echo "1. 检查系统环境"
echo "2. 构建应用程序"
echo "3. 直接运行（无需安装）"
echo ""

# 检查系统要求
echo "📋 检查系统环境..."
if [[ $(sw_vers -productVersion | cut -d. -f1) -lt 12 ]]; then
    echo "❌ 错误：需要 macOS 12.0 或更高版本"
    exit 1
fi

if ! command -v swift &> /dev/null; then
    echo "❌ 错误：未找到 Swift 编译器"
    echo "请安装 Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

echo "✅ 系统环境检查通过"
echo ""

# 清理并构建
echo "🔨 构建应用程序..."
rm -rf .build 2>/dev/null || true

swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

echo "✅ 构建完成"
echo ""

# 提示权限要求
echo "🔐 重要提示："
echo "应用需要'辅助功能'权限才能正常工作"
echo "如果系统提示，请前往："
echo "系统偏好设置 → 安全性与隐私 → 辅助功能 → 勾选 ClipMaster"
echo ""

# 询问用户是否继续
echo "按 Enter 键启动应用，或 Ctrl+C 取消"
read

# 直接运行
echo "🚀 启动 WinClip for Mac..."
echo ""
echo "使用说明："
echo "- 按 Option+V 呼出剪贴板历史"
echo "- 单击任意项目直接粘贴"
echo "- 按 Esc 关闭窗口"
echo "- 应用将在菜单栏显示"
echo ""
echo "正在启动..."

swift run ClipMaster