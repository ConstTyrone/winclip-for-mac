#!/bin/bash

# WinClip for Mac - 自动安装脚本
# 构建并安装应用到 Applications 文件夹

set -e  # 遇到错误时退出

echo "🚀 开始构建和安装 WinClip for Mac..."
echo "=================================="

# 检查系统要求
echo "📋 检查系统要求..."
if [[ $(sw_vers -productVersion | cut -d. -f1) -lt 12 ]]; then
    echo "❌ 错误：需要 macOS 12.0 或更高版本"
    exit 1
fi

# 检查是否存在 Swift
if ! command -v swift &> /dev/null; then
    echo "❌ 错误：未找到 Swift 编译器"
    echo "请安装 Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# 清理之前的构建
echo "🧹 清理构建缓存..."
rm -rf .build 2>/dev/null || true
rm -rf ClipMaster.app 2>/dev/null || true

# 构建应用
echo "🔨 构建应用（Release 模式）..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

# 运行构建脚本生成应用包
echo "📦 生成应用程序包..."
if [ -f "build_app.sh" ]; then
    ./build_app.sh
else
    echo "❌ 未找到 build_app.sh 脚本"
    exit 1
fi

# 检查应用包是否生成成功
if [ ! -d "ClipMaster.app" ]; then
    echo "❌ 应用程序包生成失败"
    exit 1
fi

# 复制到 Applications 文件夹
echo "📂 安装到 Applications 文件夹..."
if [ -d "/Applications/ClipMaster.app" ]; then
    echo "⚠️  检测到已安装的版本，正在替换..."
    rm -rf "/Applications/ClipMaster.app"
fi

cp -r "ClipMaster.app" "/Applications/"

if [ $? -eq 0 ]; then
    echo "✅ 安装成功！"
    echo ""
    echo "🎉 WinClip for Mac 已安装到 /Applications/ClipMaster.app"
    echo ""
    echo "📝 下一步操作："
    echo "1. 从启动台或应用程序文件夹启动 ClipMaster"
    echo "2. 系统会提示授予'辅助功能'权限"
    echo "3. 前往 系统偏好设置 → 安全性与隐私 → 隐私 → 辅助功能"
    echo "4. 勾选 ClipMaster 以启用全局快捷键"
    echo "5. 按 Option+V 开始使用！"
    echo ""
    echo "🚀 要立即启动应用，请运行："
    echo "   open /Applications/ClipMaster.app"
    echo ""
    echo "💡 遇到问题？运行 ./check_permissions.sh 检查系统权限"
else
    echo "❌ 安装失败：无法复制到 Applications 文件夹"
    echo "💡 请检查是否有足够的权限，或尝试手动复制："
    echo "   cp -r ClipMaster.app /Applications/"
    exit 1
fi