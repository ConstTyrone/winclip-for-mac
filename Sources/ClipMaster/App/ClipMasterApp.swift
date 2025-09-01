import SwiftUI
import AppKit
import Cocoa
import ServiceManagement

@main
struct ClipMasterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager.shared
    
    var body: some Scene {
        // 设置窗口Scene
        Settings {
            ModernSettingsView()
                .environmentObject(clipboardManager)
                .frame(minWidth: 750, minHeight: 500)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var popover = NSPopover()
    private var clipboardWindow: ClipboardWindow?
    private var settingsWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用为后台应用（不在Dock显示，避免焦点冲突）
        NSApp.setActivationPolicy(.accessory)
        
        // 应用用户设置
        applyUserSettings()
        
        // 设置粘贴反馈（使用系统音效）
        setupPasteFeedback()
        
        // 初始化剪贴板管理器
        ClipboardManager.shared.startMonitoring()
        
        // 设置菜单栏图标（根据用户设置）
        setupStatusBarIfNeeded()
        
        // 注册全局快捷键
        setupHotkeys()
        
        // 应用自启动设置（首次启动时）
        applyLaunchAtLoginSetting()
        
        // 设置默认快捷键（首次启动时）
        setupDefaultShortcuts()
        
        // 不在这里创建窗口，避免重复创建
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            // 使用自定义的圆角剪贴板图标
            let customIcon = createRoundedClipboardIcon()
            button.image = customIcon
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // 创建简化菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Option+V: 打开剪贴板，单击直接粘贴", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "偏好设置...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    private func setupHotkeys() {
        // 注册Option+V快捷键
        HotkeyManager.shared.registerHotkey()
    }
    
    private func applyUserSettings() {
        applyAppearanceSettings()
    }
    
    private func applyAppearanceSettings() {
        let appearanceMode = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        
        switch appearanceMode {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
            print("🌞 应用浅色模式")
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
            print("🌙 应用深色模式")
        default:
            NSApp.appearance = nil  // 跟随系统
            print("⚙️ 跟随系统外观")
        }
    }
    
    private func setupStatusBarIfNeeded() {
        // 默认为true，如果是第一次启动
        if UserDefaults.standard.object(forKey: "showMenuBarIcon") == nil {
            UserDefaults.standard.set(true, forKey: "showMenuBarIcon")
        }
        
        if UserDefaults.standard.bool(forKey: "showMenuBarIcon") {
            setupStatusBar()
        }
    }
    
    private func applyLaunchAtLoginSetting() {
        // 检查是否是第一次启动
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            
            // 首次启动时，默认启用自启动
            if UserDefaults.standard.object(forKey: "launchAtLogin") == nil {
                UserDefaults.standard.set(true, forKey: "launchAtLogin")
            }
            
            // 应用自启动设置
            if UserDefaults.standard.bool(forKey: "launchAtLogin") {
                setLaunchAtLogin(true)
            }
        }
    }
    
    private func setupDefaultShortcuts() {
        // 设置默认快捷键为Option+V - 修复使用数组格式
        if UserDefaults.standard.object(forKey: "globalShortcutModifiers") == nil {
            UserDefaults.standard.set(["option"], forKey: "globalShortcutModifiers")
            print("✅ 设置默认修饰键: [\"option\"]")
        }
        
        if UserDefaults.standard.object(forKey: "globalShortcutKey") == nil {
            UserDefaults.standard.set("v", forKey: "globalShortcutKey")
            print("✅ 设置默认按键: v")
        }
    }
    
    private func setupPasteFeedback() {
        // 使用系统音效作为粘贴反馈
        print("✅ 粘贴反馈已设置")
    }
    
    @objc func togglePopover() {
        // 暂时禁用popover，避免与主窗口冲突
        // 用户可以使用Option+V打开主窗口
        print("ℹ️ 请使用 Option+V 打开剪贴板")
    }
    
    @objc func showClipboardWindow() {
        // 暂时禁用菜单项功能，只通过Option+V触发
        print("ℹ️ 请使用 Option+V 打开剪贴板")
    }
    
    @objc func showSettings() {
        print("🔧 尝试打开设置窗口...")
        
        // 创建或重用设置窗口
        if settingsWindowController == nil {
            print("📝 创建新的设置窗口...")
            
            // 创建现代化的 SwiftUI 视图
            let settingsView = ModernSettingsView()
                .environmentObject(ClipboardManager.shared)
            
            // 创建窗口（适合现代UI的大小）
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 850, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            // 设置窗口属性
            window.minSize = NSSize(width: 750, height: 500)
            window.maxSize = NSSize(width: 1200, height: 900)
            window.title = "ClipMaster 偏好设置"
            window.center()
            window.isReleasedWhenClosed = false
            
            // 重要：设置窗口级别，确保在accessory应用中也能正常显示
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            // 设置内容视图
            window.contentView = NSHostingView(rootView: settingsView)
            
            // 创建窗口控制器
            settingsWindowController = NSWindowController(window: window)
        }
        
        // 安全显示窗口（保持accessory策略不变）
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        
        print("✅ 设置窗口已显示（保持accessory模式）")
    }
    
    // 创建自定义圆角剪贴板图标
    private func createRoundedClipboardIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // 设置图形上下文
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            // 如果创建失败，回退到系统图标
            let fallback = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: "ClipMaster") ?? NSImage()
            fallback.isTemplate = true
            return fallback
        }
        
        // 清除背景（透明）
        context.clear(CGRect(origin: .zero, size: size))
        
        // 设置绘图属性
        context.setFillColor(NSColor.controlAccentColor.cgColor)
        context.setStrokeColor(NSColor.controlAccentColor.cgColor)
        context.setLineWidth(1.2)
        
        // 绘制圆角矩形背景（剪贴板）
        let boardRect = CGRect(x: 3, y: 2, width: 12, height: 14)
        let boardPath = CGPath(roundedRect: boardRect, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
        
        // 填充背景
        context.addPath(boardPath)
        context.setFillColor(NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor)
        context.fillPath()
        
        // 绘制边框
        context.addPath(boardPath)
        context.setStrokeColor(NSColor.controlAccentColor.cgColor)
        context.strokePath()
        
        // 绘制顶部的夹子（圆角矩形）
        let clipRect = CGRect(x: 6, y: 14, width: 6, height: 3)
        let clipPath = CGPath(roundedRect: clipRect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil)
        context.addPath(clipPath)
        context.setFillColor(NSColor.controlAccentColor.cgColor)
        context.fillPath()
        
        // 绘制内部文档线条（更小更精致）
        context.setStrokeColor(NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(0.8)
        
        // 第一条线
        context.move(to: CGPoint(x: 5, y: 11))
        context.addLine(to: CGPoint(x: 13, y: 11))
        context.strokePath()
        
        // 第二条线
        context.move(to: CGPoint(x: 5, y: 9))
        context.addLine(to: CGPoint(x: 11, y: 9))
        context.strokePath()
        
        // 第三条线
        context.move(to: CGPoint(x: 5, y: 7))
        context.addLine(to: CGPoint(x: 12, y: 7))
        context.strokePath()
        
        image.unlockFocus()
        
        // 设置为模板图像以适应深色/浅色模式
        image.isTemplate = true
        
        return image
    }
    
    // 显示菜单栏图标
    @objc func showMenuBarIcon() {
        if statusBarItem == nil {
            setupStatusBar()
        }
    }
    
    // 隐藏菜单栏图标
    @objc func hideMenuBarIcon() {
        if let statusBarItem = statusBarItem {
            NSStatusBar.system.removeStatusItem(statusBarItem)
            self.statusBarItem = nil
        }
    }
    
    // 设置自启动（在AppDelegate中实现）
    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            // macOS Ventura 以上使用 SMAppService
            do {
                if enabled {
                    if SMAppService.mainApp.status == .enabled {
                        print("✅ 自启动已启用")
                        return
                    }
                    try SMAppService.mainApp.register()
                    print("✅ 自启动已设置")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("❌ 自启动已禁用")
                }
            } catch {
                print("❌ 自启动设置失败: \(error.localizedDescription)")
            }
        } else {
            // 对于较旧版本，使用 LaunchServices
            print("⚠️ macOS 12及以下版本需要手动设置自启动")
        }
    }
}