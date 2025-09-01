import SwiftUI
import AppKit

// 无焦点窗口 - 单击即可操作
class NoFocusWindow: NSWindow {
    override var canBecomeKey: Bool {
        return false  // 不获得键盘焦点，避免双击问题
    }
    
    override var canBecomeMain: Bool {
        return false  // 不成为主窗口
    }
    
    override var acceptsFirstResponder: Bool {
        return false  // 不接受第一响应者状态
    }
}

// 剪贴板窗口控制器
class ClipboardWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var hostingController: NSHostingController<AnyView>?
    private var clickOutsideMonitor: Any?  // 全局点击监听器
    
    override init() {
        super.init()
        setupWindow()
    }
    
    private func setupWindow() {
        // 创建SwiftUI视图
        let contentView = MainWindowView()
            .environmentObject(ClipboardManager.shared)
        
        hostingController = NSHostingController(rootView: AnyView(contentView))
        
        // 创建无焦点窗口 - 单击即可操作
        window = NoFocusWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        guard let window = window else { return }
        
        // 简化窗口配置 - 专注于功能而非焦点控制
        window.title = "ClipMaster"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.contentViewController = hostingController
        window.level = .floating  // 保持在其他窗口之上
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        
        // 设置窗口初始隐藏
        window.alphaValue = 0.0
    }
    
    // 显示窗口
    func showWindow() {
        guard let window = window else { return }
        
        // 不在这里记录应用，而是在粘贴时实时检测
        
        // 计算窗口位置（鼠标位置附近或屏幕中央）
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        
        var windowOrigin = NSPoint(
            x: mouseLocation.x - 300,  // 窗口宽度的一半
            y: mouseLocation.y - 100   // 向上偏移
        )
        
        // 确保窗口在屏幕内
        let windowSize = window.frame.size
        if windowOrigin.x < 0 { windowOrigin.x = 20 }
        if windowOrigin.x + windowSize.width > screenFrame.width {
            windowOrigin.x = screenFrame.width - windowSize.width - 20
        }
        if windowOrigin.y < 0 { windowOrigin.y = 20 }
        if windowOrigin.y + windowSize.height > screenFrame.height {
            windowOrigin.y = screenFrame.height - windowSize.height - 20
        }
        
        window.setFrameOrigin(windowOrigin)
        
        // 正常显示窗口 - 用户意图处理在粘贴时执行
        window.orderFront(nil)
        
        // 淡入动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        }
        
        // 设置管理器状态
        ClipboardManager.shared.isWindowVisible = true
        
        // 启动点击外部区域监听器
        startClickOutsideMonitoring()
        
        print("✅ 剪贴板窗口已显示")
    }
    
    // 隐藏窗口
    func hideWindow() {
        guard let window = window else { return }
        
        // 停止点击外部区域监听器
        stopClickOutsideMonitoring()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            window.animator().alphaValue = 0.0
        }) {
            window.orderOut(nil)
            ClipboardManager.shared.isWindowVisible = false
        }
        
        print("📴 剪贴板窗口已隐藏")
    }
    
    // 切换窗口显示状态
    func toggleWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        ClipboardManager.shared.isWindowVisible = false
        
        // 恢复之前的活动应用
        if let bundleId = UserDefaults.standard.string(forKey: "LastActiveApp"),
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first {
            app.activate(options: [])
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // NoFocusWindow 永远不会获得焦点，所以这个方法不会被调用
        // 点击外部关闭功能由全局事件监听器处理
    }
    
    // MARK: - 点击外部区域自动关闭功能
    
    // 启动点击外部区域监听器
    private func startClickOutsideMonitoring() {
        // 先停止之前的监听器（如果存在）
        stopClickOutsideMonitoring()
        
        // 添加全局鼠标点击事件监听器
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self,
                  let window = self.window,
                  window.isVisible else { return }
            
            // 获取鼠标点击的屏幕坐标
            let clickScreenLocation = NSEvent.mouseLocation
            
            // 获取窗口在屏幕上的边界
            let windowFrame = window.frame
            
            // 检查点击是否在窗口外部
            if !windowFrame.contains(clickScreenLocation) {
                print("🔍 检测到点击外部区域 (\(clickScreenLocation.x), \(clickScreenLocation.y))，窗口范围：\(windowFrame)")
                DispatchQueue.main.async {
                    self.hideWindow()
                }
            } else {
                print("🎯 点击在窗口内部 (\(clickScreenLocation.x), \(clickScreenLocation.y))，窗口范围：\(windowFrame)")
            }
        }
        
        print("👂 启动点击外部区域监听器")
    }
    
    // 停止点击外部区域监听器
    private func stopClickOutsideMonitoring() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
            print("🛑 停止点击外部区域监听器")
        }
    }
    
    // 确保在窗口销毁时清理监听器
    deinit {
        stopClickOutsideMonitoring()
    }
    
    // 旧的焦点检测代码已移除，现在使用全局事件监听
}

// 快速访问视图（菜单栏弹出）
struct QuickAccessView: View {
    @EnvironmentObject var manager: ClipboardManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("最近剪贴")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    // 显示完整窗口 - 使用单例管理
                    HotkeyManager.shared.showClipboardWindow()
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // 最近的5个项目
            if manager.recentItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无剪贴板历史")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(height: 100)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(manager.recentItems) { item in
                            QuickAccessRow(item: item)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            
            Divider()
            
            // 底部操作
            HStack {
                Button("Option+V 打开完整界面") {
                    // 使用单例管理，避免重复创建
                    HotkeyManager.shared.showClipboardWindow()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("清空历史") {
                    manager.clearHistory()
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// 快速访问行组件
struct QuickAccessRow: View {
    let item: ClipboardItem
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Text(item.contentType.icon)
                .font(.body)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(item.sourceApp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            ClipboardManager.shared.pasteItem(item)
        }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}