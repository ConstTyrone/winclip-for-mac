import SwiftUI
import AppKit

// 主窗口视图
struct MainWindowView: View {
    @EnvironmentObject var manager: ClipboardManager
    @State private var selectedItem: ClipboardItem?
    @State private var hoveredItem: ClipboardItem?
    @State private var showPreview = false
    
    // 获取当前快捷键显示字符串
    private var currentShortcutString: String {
        let modifiers = UserDefaults.standard.string(forKey: "globalShortcutModifiers") ?? "option"
        let key = UserDefaults.standard.string(forKey: "globalShortcutKey") ?? "v"
        
        var parts: [String] = []
        
        if modifiers.contains("command") { parts.append("⌘") }
        if modifiers.contains("option") { parts.append("⌥") }
        if modifiers.contains("control") { parts.append("⌃") }
        if modifiers.contains("shift") { parts.append("⇧") }
        
        parts.append(key.uppercased())
        
        return parts.joined(separator: "+")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("ClipMaster")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 快捷提示
                Text(currentShortcutString)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            // 搜索框已删除 - 解决焦点冲突问题
            
            // 核心功能提示
            HStack {
                Label("单击直接粘贴到光标位置", systemImage: "arrow.right.circle.fill")
                Spacer()
                Label("按 \(currentShortcutString) 快速呼出", systemImage: "keyboard")
            }
            .font(.caption)
            .foregroundColor(.accentColor)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            
            // 分类标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryTag(title: "全部", icon: nil, isSelected: manager.selectedCategory == "all") {
                        manager.selectedCategory = "all"
                    }
                    CategoryTag(title: "文本", icon: "📝", isSelected: manager.selectedCategory == "text") {
                        manager.selectedCategory = "text"
                    }
                    CategoryTag(title: "链接", icon: "🔗", isSelected: manager.selectedCategory == "link") {
                        manager.selectedCategory = "link"
                    }
                    CategoryTag(title: "图片", icon: "🖼️", isSelected: manager.selectedCategory == "image") {
                        manager.selectedCategory = "image"
                    }
                    CategoryTag(title: "代码", icon: "💻", isSelected: manager.selectedCategory == "code") {
                        manager.selectedCategory = "code"
                    }
                    CategoryTag(title: "文件", icon: "📁", isSelected: manager.selectedCategory == "file") {
                        manager.selectedCategory = "file"
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // 剪贴板列表
            if manager.filteredItems.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("暂无剪贴板历史")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("复制任何内容开始使用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(manager.filteredItems) { item in
                                ClipboardItemRow(
                                    item: item,
                                    isSelected: selectedItem?.id == item.id,
                                    isHovered: hoveredItem?.id == item.id
                                )
                                .onHover { isHovered in
                                    if isHovered {
                                        hoveredItem = item
                                    } else if hoveredItem?.id == item.id {
                                        hoveredItem = nil
                                    }
                                }
                                .onTapGesture {
                                    selectAndPaste(item)
                                }
                                .contextMenu {
                                    contextMenu(for: item)
                                }
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Divider()
            
            // 状态栏
            HStack {
                Text("💡 **单击直接粘贴到光标位置** | 按分类筛选")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("共 \(manager.items.count) 条历史")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 600, height: 500)
        .background(VisualEffectView())
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    // 单击剪贴板项目直接粘贴 - 立即消失
    private func selectAndPaste(_ item: ClipboardItem) {
        selectedItem = item
        print("🎯 单击粘贴: \(item.preview)")
        
        // 立即隐藏窗口 - 使用HotkeyManager的窗口实例
        HotkeyManager.shared.hideClipboardWindow()
        
        // 直接粘贴到用户按Option+V时记录的目标应用
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.manager.pasteItem(item)
        }
        
        print("✅ 窗口已隐藏，开始粘贴")
    }
    
    // 不再需要复杂的光标检测 - 无焦点窗口直接保持原有焦点
    
    // 显示粘贴确认
    private func showPasteConfirmation() {
        // 这里可以显示一个简单的通知或动画
        print("✅ 已粘贴到光标位置")
    }
    
    // 上下文菜单
    @ViewBuilder
    private func contextMenu(for item: ClipboardItem) -> some View {
        Button {
            manager.pasteItem(item)
        } label: {
            Label("粘贴", systemImage: "doc.on.clipboard")
        }
        
        Button {
            item.copyToPasteboard()
        } label: {
            Label("复制", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        Button {
            manager.togglePin(item)
        } label: {
            Label(item.isPinned ? "取消固定" : "固定", 
                  systemImage: item.isPinned ? "pin.slash" : "pin")
        }
        
        Divider()
        
        Button {
            manager.deleteItem(item)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
    
    // 设置键盘快捷键
    private func setupKeyboardShortcuts() {
        // 这里可以添加窗口内的键盘快捷键处理
    }
}

// 分类标签组件
struct CategoryTag: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Text(icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// 视觉效果背景
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}