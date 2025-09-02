#!/bin/bash

# ClipMaster 权限修复脚本
# 解决辅助功能权限重复条目问题

echo "🔧 ClipMaster 权限修复工具"
echo "================================"

# 1. 停止所有ClipMaster进程
echo "1️⃣ 停止所有ClipMaster进程..."
killall ClipMaster 2>/dev/null || echo "   没有运行的ClipMaster进程"

# 2. 清理LaunchServices数据库中的重复条目
echo "2️⃣ 清理LaunchServices数据库..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# 3. 删除开发目录中的应用（如果存在）
DEV_APP="/Users/wzy668/Projects/cv_board/winclip-for-mac/ClipMaster.app"
if [ -d "$DEV_APP" ]; then
    echo "3️⃣ 删除开发目录中的旧应用..."
    rm -rf "$DEV_APP"
    echo "   ✅ 已删除: $DEV_APP"
else
    echo "3️⃣ 开发目录中没有找到旧应用"
fi

# 4. 重新注册Applications目录中的应用
MAIN_APP="/Applications/ClipMaster.app"
if [ -d "$MAIN_APP" ]; then
    echo "4️⃣ 重新注册主应用..."
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister "$MAIN_APP"
    echo "   ✅ 已重新注册: $MAIN_APP"
else
    echo "❌ 错误: 在Applications目录中没有找到ClipMaster.app"
    exit 1
fi

# 5. 重建LaunchServices数据库
echo "5️⃣ 重建LaunchServices数据库..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# 6. 尝试清理TCC权限数据库 (需要用户手动操作)
echo "6️⃣ 清理权限设置..."
echo ""
echo "⚠️  请手动执行以下步骤："
echo "   1. 打开 系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能"
echo "   2. 如果看到多个ClipMaster条目，全部删除（点击 - 号）"
echo "   3. 点击 + 号，选择 /Applications/ClipMaster.app"
echo "   4. 确保只有一个ClipMaster条目且已勾选"

# 7. 验证修复结果
echo ""
echo "7️⃣ 验证修复结果..."
CLIP_COUNT=$(/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep -c "com.clipmaster.app")
echo "   LaunchServices中的ClipMaster条目数量: $CLIP_COUNT"

if [ "$CLIP_COUNT" -eq 1 ]; then
    echo "   ✅ 修复成功！只有一个ClipMaster条目"
else
    echo "   ⚠️  仍有 $CLIP_COUNT 个条目，可能需要重启系统"
fi

echo ""
echo "🎯 下一步操作："
echo "   1. 重新启动ClipMaster应用"
echo "   2. 按照上述步骤手动设置辅助功能权限"
echo "   3. 如果问题仍然存在，请重启macOS"

echo ""
echo "修复脚本执行完成！"