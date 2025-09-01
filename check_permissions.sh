#!/bin/bash

echo "🔐 ClipMaster 权限检查"
echo "===================="

echo ""
echo "📱 打开系统偏好设置检查辅助功能权限:"
echo "系统偏好设置 → 安全性与隐私 → 隐私 → 辅助功能"
echo "确保 ClipMaster 在列表中并已启用"

echo ""
echo "🎯 如果 ClipMaster 不在列表中:"
echo "1. 按 Option+V 尝试触发快捷键"
echo "2. 系统会提示请求权限"
echo "3. 点击'打开系统偏好设置'"
echo "4. 勾选 ClipMaster 旁边的复选框"

# 直接打开系统偏好设置到隐私页面
echo ""
echo "🚀 正在打开系统偏好设置..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"