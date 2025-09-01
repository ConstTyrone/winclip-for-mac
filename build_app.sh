#!/bin/bash

# ClipMaster 应用构建和安装脚本
# 用法: ./build_app.sh [--install] [--launch]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置
APP_NAME="ClipMaster"
BUNDLE_ID="com.yourcompany.clipmaster"
VERSION="1.0.0"
BUILD_CONFIG="release"
BUILD_DIR=".build/apple/Products/Release"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 解析参数
INSTALL=false
LAUNCH=false
for arg in "$@"; do
    case $arg in
        --install)
            INSTALL=true
            shift
            ;;
        --launch)
            LAUNCH=true
            shift
            ;;
        --help)
            echo "用法: $0 [--install] [--launch]"
            echo "  --install  安装到 /Applications 文件夹"
            echo "  --launch   构建后立即启动应用"
            exit 0
            ;;
    esac
done

echo -e "${GREEN}🔨 开始构建 $APP_NAME...${NC}"

# 清理旧的构建
if [ -d "$APP_DIR" ]; then
    echo "清理旧的应用包..."
    rm -rf "$APP_DIR"
fi

# 构建 Release 版本
echo -e "${YELLOW}正在编译 Release 版本...${NC}"
swift build -c release --arch arm64 --arch x86_64

# 检查构建是否成功
if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo -e "${RED}❌ 构建失败：找不到可执行文件${NC}"
    exit 1
fi

# 创建应用包结构
echo "创建应用包结构..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 复制可执行文件
echo "复制可执行文件..."
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# 设置执行权限
chmod +x "$MACOS_DIR/$APP_NAME"

# 创建 Info.plist
echo "创建 Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>ClipMaster needs to send events to other applications to paste clipboard content.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>ClipMaster需要辅助功能权限来响应全局快捷键Option+V并模拟粘贴操作</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSMainNibFile</key>
    <string>MainMenu</string>
</dict>
</plist>
EOF

# 复制应用图标
echo "复制应用图标..."
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$RESOURCES_DIR/"
    echo "✅ 已使用自定义应用图标"
else
    echo "⚠️ 未找到 AppIcon.icns，使用系统默认图标"
fi

# 代码签名（使用 ad-hoc 签名）
echo "进行代码签名..."
codesign --force --deep --sign - "$APP_DIR"

echo -e "${GREEN}✅ 应用构建成功！${NC}"
echo "应用位置: $(pwd)/$APP_DIR"

# 安装到 Applications 文件夹
if [ "$INSTALL" = true ]; then
    echo -e "${YELLOW}正在安装到 /Applications...${NC}"
    
    # 检查是否已安装
    if [ -d "/Applications/$APP_DIR" ]; then
        # 先终止正在运行的进程
        pkill -f "$APP_NAME" 2>/dev/null || true
        sleep 1
        
        echo "移除旧版本..."
        rm -rf "/Applications/$APP_DIR"
    fi
    
    # 复制新版本
    cp -r "$APP_DIR" /Applications/
    echo -e "${GREEN}✅ 已安装到 /Applications/$APP_DIR${NC}"
fi

# 启动应用
if [ "$LAUNCH" = true ]; then
    echo -e "${YELLOW}正在启动应用...${NC}"
    
    # 先终止旧进程
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 1
    
    if [ "$INSTALL" = true ]; then
        open "/Applications/$APP_DIR"
    else
        open "$APP_DIR"
    fi
    echo -e "${GREEN}✅ 应用已启动${NC}"
fi

echo ""
echo "提示："
echo "  • 首次运行需要在'系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能'中授权"
echo "  • 使用 Option+V 呼出剪贴板历史"
echo "  • 应用会在菜单栏显示图标"

if [ "$INSTALL" = false ]; then
    echo ""
    echo "要安装到 Applications 文件夹，请运行："
    echo "  ./build_app.sh --install"
fi