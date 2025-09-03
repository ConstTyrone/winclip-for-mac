#!/bin/bash

# ClipMaster - 一键运行脚本
# 自动检查环境、构建、安装并启动应用

set -e

echo "🎯 ClipMaster - 一键安装运行"
echo "================================="
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
rm -rf .build ClipMaster.app 2>/dev/null || true

swift build -c release --arch arm64 --arch x86_64

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

# 创建应用包
echo "📦 创建应用包..."
APP_NAME="ClipMaster"
BUILD_DIR=".build/apple/Products/Release"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# 复制可执行文件
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"
chmod +x "$MACOS_DIR/$APP_NAME"

# 创建 Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClipMaster</string>
    <key>CFBundleIdentifier</key>
    <string>com.clipmaster.app</string>
    <key>CFBundleName</key>
    <string>ClipMaster</string>
    <key>CFBundleDisplayName</key>
    <string>ClipMaster</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>ClipMaster需要辅助功能权限来响应全局快捷键Option+V并模拟粘贴操作</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# 复制图标
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/"
fi

# 代码签名
echo "🔐 代码签名..."
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || echo "⚠️ 代码签名跳过（需要开发者证书）"

# 安装到 Applications
echo "📂 安装到应用程序文件夹..."
if [ -d "/Applications/$APP_DIR" ]; then
    echo "⚠️ 检测到已安装版本，正在替换..."
    pkill -f "ClipMaster" 2>/dev/null || true
    rm -rf "/Applications/$APP_DIR"
fi

cp -r "$APP_DIR" "/Applications/"

if [ $? -eq 0 ]; then
    echo "✅ 安装成功！"
    echo ""
    
    # 启动应用
    echo "🚀 启动 ClipMaster..."
    open "/Applications/$APP_DIR"
    
    echo ""
    echo "🎉 ClipMaster 已安装并启动！"
    echo ""
    echo "📝 下一步："
    echo "1. 应用已在菜单栏显示"
    echo "2. 系统会提示需要'辅助功能'权限"
    echo ""
    echo "🔐 重要：权限设置说明"
    echo "由于应用使用自签名，请按以下步骤设置权限："
    echo "• 打开：系统偏好设置 → 安全性与隐私 → 辅助功能"
    echo "• 点击左下角🔒解锁，输入密码"
    echo "• 点击 ➕ 号手动添加 ClipMaster（推荐）"
    echo "• 不要使用开关键，直接手动添加更稳定"
    echo ""
    echo "4. 按 Option+V 开始使用！"
    echo ""
    echo "💡 使用说明："
    echo "  • Option+V 呼出剪贴板历史"
    echo "  • 单击任意项目直接粘贴"
    echo "  • Esc 关闭窗口"
else
    echo "❌ 安装失败"
    echo "💡 请手动将 $APP_DIR 拖到应用程序文件夹"
    exit 1
fi