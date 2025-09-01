#!/bin/bash

# ClipMaster 调试脚本
# 用于诊断设置窗口问题

echo "🔍 ClipMaster 调试模式"
echo "========================"
echo ""

# 清理旧进程
echo "清理旧进程..."
pkill -f ClipMaster 2>/dev/null || true
sleep 1

# 构建调试版本
echo "构建调试版本..."
swift build -c debug

echo ""
echo "启动应用（查看控制台输出）..."
echo "================================="
echo ""

# 直接运行调试版本，输出到控制台
./.build/debug/ClipMaster