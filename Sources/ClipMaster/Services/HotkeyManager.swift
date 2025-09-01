import Foundation
import AppKit
import Carbon

// 快捷键后端类型
enum HotkeyBackend {
    case carbon      // 使用Carbon API (macOS 12及更早版本)
    case nsEvent     // 使用NSEvent API (macOS 13+, 特别是Sequoia 15.0+)
    case unavailable // 不可用
}

// 快捷键管理器
class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotkeyRef: EventHotKeyRef?
    private var hotkeyShiftRef: EventHotKeyRef?  // 备用快捷键
    private var eventHandler: EventHandlerRef?
    private var globalMonitor: Any?  // NSEvent全局监听器
    private let hotkeyID: EventHotKeyID = EventHotKeyID(signature: OSType("CLIP".fourCharCodeValue), id: 1)
    private let hotkeyShiftID: EventHotKeyID = EventHotKeyID(signature: OSType("CLIP".fourCharCodeValue), id: 2)
    
    // 快捷键后端管理
    private var currentBackend: HotkeyBackend = .unavailable
    private var preferredBackend: HotkeyBackend = .unavailable
    
    // 权限提示状态管理 - 添加动态监控
    private var hasShownPermissionAlert = false
    private var lastPermissionCheck: Date?
    private var permissionCheckTimer: Timer?
    private var wasAccessibilityGranted = false  // 跟踪上次权限状态
    
    // 注册状态跟踪 - 防止重复注册
    private var isRegistering = false
    private var registrationAttempts = 0
    private var maxRegistrationAttempts = 3
    
    // 用户自定义快捷键设置 - 修复存储格式为数组
    private var currentModifiers: [String] {
        UserDefaults.standard.stringArray(forKey: "globalShortcutModifiers") ?? ["option"]
    }
    private var currentKey: String {
        UserDefaults.standard.string(forKey: "globalShortcutKey") ?? "v"
    }
    
    // 关键：记录用户按快捷键时的真实意图
    private var targetApplication: NSRunningApplication?
    
    // 窗口单例管理
    private var clipboardWindow: ClipboardWindow?
    
    private init() {
        // 监听快捷键变更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutChanged),
            name: NSNotification.Name("ShortcutChanged"),
            object: nil
        )
        
        // 监听应用激活事件 - 解决权限响应延迟问题
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 启动权限监控
        startPermissionMonitoring()
        
        // 检测最佳快捷键后端
        preferredBackend = detectOptimalBackend()
        print("🔧 检测到最佳快捷键后端: \(preferredBackend)")
    }
    
    // 注册全局快捷键
    func registerHotkey() {
        // 注册用户自定义快捷键
        registerSystemHotkey()
        
        // 使用原生API实现
        setupKeyboardShortcuts()
        
        // 更新权限状态
        wasAccessibilityGranted = checkAccessibilityPermission()
    }
    
    // 快捷键变更处理
    @objc private func shortcutChanged() {
        print("🔄 快捷键配置已变更，重新注册...")
        unregisterHotkey()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.registerHotkey()
        }
    }
    
    // 应用激活事件处理 - 立即检查权限状态
    @objc private func applicationDidBecomeActive() {
        print("🌟 应用重新获得焦点，立即检查权限状态")
        checkPermissionImmediately()
    }
    
    // 注销快捷键 - 统一清理所有后端资源
    func unregisterHotkey() {
        print("🧹 开始清理快捷键资源 (当前后端: \(currentBackend))")
        
        // 清理Carbon API资源
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
            print("✅ 已清理Carbon快捷键")
        }
        
        if let hotkeyShiftRef = hotkeyShiftRef {
            UnregisterEventHotKey(hotkeyShiftRef)
            self.hotkeyShiftRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
            print("✅ 已清理Carbon事件处理器")
        }
        
        // 清理NSEvent监听器（支持单个或数组）
        if let globalMonitor = globalMonitor {
            if let monitors = globalMonitor as? [Any] {
                // 处理监听器数组
                for monitor in monitors {
                    NSEvent.removeMonitor(monitor)
                }
                print("✅ 已清理NSEvent监听器数组 (\(monitors.count)个)")
            } else {
                // 处理单个监听器
                NSEvent.removeMonitor(globalMonitor)
                print("✅ 已清理NSEvent监听器")
            }
            self.globalMonitor = nil
        }
        
        // 重置后端状态
        currentBackend = .unavailable
        print("✅ 已重置后端状态")
        
        // 重置注册状态
        isRegistering = false
        registrationAttempts = 0
        print("✅ 已重置注册状态")
        
        // 停止权限监控
        stopPermissionMonitoring()
    }
    
    // 注册系统级快捷键 - 优化权限检查逻辑
    private func registerSystemHotkey() {
        // 检查辅助功能权限（静默检查）
        guard checkAccessibilityPermission() else {
            print("❌ 缺少辅助功能权限，无法注册全局快捷键")
            
            // 避免重复显示权限提示
            if !hasShownPermissionAlert {
                hasShownPermissionAlert = true
                DispatchQueue.main.async {
                    self.showAccessibilityAlert()
                }
            } else {
                print("ℹ️ 权限提示已显示过，跳过重复提示")
            }
            return
        }
        
        print("🔐 辅助功能权限已授予，开始注册快捷键...")
        
        // 防止重复注册
        guard !isRegistering else {
            print("⚠️ 快捷键注册正在进行中，跳过重复请求")
            return
        }
        
        isRegistering = true
        registrationAttempts = 0
        
        // 重置权限提示状态（权限已获得）
        hasShownPermissionAlert = false
        
        // 增加延迟以确保 macOS 权限完全生效
        print("⏳ 等待 macOS 权限系统准备就绪...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.performHotkeyRegistrationWithRetry()
        }
    }
    
    // 带重试机制的快捷键注册
    private func performHotkeyRegistrationWithRetry() {
        registrationAttempts += 1
        
        print("🔄 尝试第 \(registrationAttempts) 次快捷键注册...")
        
        // 确保当前仍有权限
        guard checkAccessibilityPermission() else {
            print("❌ 权限已失效，停止注册")
            isRegistering = false
            return
        }
        
        // 先清理可能存在的旧注册
        cleanupOldRegistration()
        
        // 执行注册
        performHotkeyRegistration()
        
        // 验证注册是否成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.verifyRegistrationSuccess()
        }
    }
    
    // 实际执行快捷键注册 - 基于检测到的后端选择方法
    private func performHotkeyRegistration() {
        switch preferredBackend {
        case .carbon:
            registerWithCarbonAPI()
        case .nsEvent:
            registerWithNSEventAPI()
        case .unavailable:
            print("❌ 当前macOS版本不支持快捷键功能")
        }
    }
    
    // 清理旧的注册资源
    private func cleanupOldRegistration() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        
        if let hotkeyShiftRef = hotkeyShiftRef {
            UnregisterEventHotKey(hotkeyShiftRef)
            self.hotkeyShiftRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        
        if let globalMonitor = globalMonitor {
            if let monitors = globalMonitor as? [Any] {
                for monitor in monitors {
                    NSEvent.removeMonitor(monitor)
                }
            } else {
                NSEvent.removeMonitor(globalMonitor)
            }
            self.globalMonitor = nil
        }
    }
    
    // 验证注册是否成功，失败时重试
    private func verifyRegistrationSuccess() {
        let isSuccessful = (currentBackend == .carbon && hotkeyRef != nil) || 
                          (currentBackend == .nsEvent && globalMonitor != nil)
        
        if isSuccessful {
            print("✅ 快捷键注册成功验证 (后端: \(currentBackend))")
            isRegistering = false
            registrationAttempts = 0
        } else if registrationAttempts < maxRegistrationAttempts {
            print("⚠️ 注册验证失败，准备重试...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.performHotkeyRegistrationWithRetry()
            }
        } else {
            print("❌ 快捷键注册失败，已达到最大重试次数")
            isRegistering = false
            registrationAttempts = 0
        }
    }
    
    /// 使用Carbon API注册快捷键
    private func registerWithCarbonAPI() {
        print("🔧 使用Carbon API注册快捷键 (macOS \(getMacOSVersionString()))")
        currentBackend = .carbon
        
        // 创建事件处理器
        let eventTypeSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                          eventKind: OSType(kEventHotKeyPressed))
        
        let callback: EventHandlerProcPtr = { (nextHandler, event, userData) -> OSStatus in
            let _ = HotkeyManager.shared.handleHotkeyEvent(event)
            return noErr
        }
        
        var eventTypeSpecArray = [eventTypeSpec]
        
        let status = InstallEventHandler(GetApplicationEventTarget(),
                                         callback,
                                         1,
                                         &eventTypeSpecArray,
                                         nil,
                                         &eventHandler)
        
        guard status == noErr else {
            print("❌ Carbon API安装事件处理器失败: \(status)")
            print("💡 降级使用NSEvent方案...")
            registerWithNSEventAPI()
            return
        }
        
        print("✅ Carbon API事件处理器安装成功")
        
        // 注册用户自定义快捷键
        let (keyCode, modifierFlags) = getKeyCodeAndModifiers()
        let status2 = RegisterEventHotKey(keyCode,
                                          modifierFlags,
                                          hotkeyID,
                                          GetApplicationEventTarget(),
                                          0,
                                          &hotkeyRef)
        
        if status2 == noErr {
            print("✅ Carbon API快捷键注册成功: \(getShortcutDisplayString())")
            currentBackend = .carbon
        } else {
            print("❌ Carbon API快捷键注册失败: \(status2)")
            print("🔍 错误分析:")
            switch status2 {
            case OSStatus(eventHotKeyExistsErr):
                print("   - 快捷键已被其他应用占用")
            case OSStatus(paramErr):
                print("   - 参数错误")
            default:
                print("   - 未知错误码: \(status2)")
            }
            
            // 清理失败的 Carbon 资源
            if let eventHandler = eventHandler {
                RemoveEventHandler(eventHandler)
                self.eventHandler = nil
            }
            
            print("💡 降级使用NSEvent方案...")
            registerWithNSEventAPI()
        }
    }
    
    /// 使用NSEvent API注册快捷键
    private func registerWithNSEventAPI() {
        print("🔧 使用NSEvent API注册快捷键 (macOS \(getMacOSVersionString()))")
        currentBackend = .nsEvent
        
        // 清理可能存在的Carbon资源
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        
        // 使用本地监听器来阻止系统默认行为
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            if self.checkShortcutMatch(event: event) {
                print("🔥 NSEvent API (本地)检测到快捷键: \(self.getShortcutDisplayString())")
                DispatchQueue.main.async {
                    HotkeyManager.shared.handleShowWindow()
                }
                // 返回nil阻止系统默认行为（如Option+V输出√符号）
                return nil
            }
            return event
        }
        
        // 同时使用全局监听器处理其他应用中的快捷键
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            if self.checkShortcutMatch(event: event) {
                print("🔥 NSEvent API (全局)检测到快捷键: \(self.getShortcutDisplayString())")
                DispatchQueue.main.async {
                    HotkeyManager.shared.handleShowWindow()
                }
            }
        }
        
        // 存储两个监听器（使用数组或元组）
        if localMonitor != nil && globalMonitor != nil {
            // 将两个监听器都存储在globalMonitor中（这里使用数组）
            self.globalMonitor = [localMonitor, globalMonitor]
            print("✅ NSEvent API快捷键监听器已启动 (本地+全局): \(getShortcutDisplayString())")
        } else {
            print("❌ NSEvent API无法启动键盘监听器")
            currentBackend = .unavailable
        }
    }
    
    // 注意：registerFallbackHotkey() 方法已被 registerWithNSEventAPI() 取代
    
    // 检查快捷键是否匹配 - 修复数组检查逻辑
    private func checkShortcutMatch(event: NSEvent) -> Bool {
        let (keyCode, _) = getKeyCodeAndModifiers()
        
        // 检查按键是否匹配
        guard event.keyCode == UInt16(keyCode) else { return false }
        
        // 检查修饰键
        var requiredFlags: NSEvent.ModifierFlags = []
        for modifier in currentModifiers {
            switch modifier {
            case "command":
                requiredFlags.insert(.command)
            case "option":
                requiredFlags.insert(.option)
            case "control":
                requiredFlags.insert(.control)
            case "shift":
                requiredFlags.insert(.shift)
            default:
                break
            }
        }
        
        // 检查是否包含所有必需的修饰键
        return event.modifierFlags.intersection([.command, .option, .control, .shift]) == requiredFlags
    }
    
    // 使用原生方法替代KeyboardShortcuts库
    private func setupKeyboardShortcuts() {
        // 使用原生API已经实现，不需要额外的库
        print("🔧 使用原生API实现快捷键 (后端: \(currentBackend))")
    }
    
    // MARK: - macOS版本兼容性检测
    
    /// 检测最佳快捷键后端 - 修复：始终优先Carbon API以阻止系统默认行为
    private func detectOptimalBackend() -> HotkeyBackend {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        
        // 所有支持的macOS版本都优先尝试Carbon API
        // 因为只有Carbon API能在系统级阻止默认行为（如Option+V输出√）
        if osVersion.majorVersion >= 12 {
            print("🍎 检测到 macOS \(osVersion.majorVersion).\(osVersion.minorVersion), 优先使用Carbon API以阻止系统默认行为")
            return .carbon
        }
        else {
            print("⚠️ 检测到不支持的macOS版本: \(osVersion.majorVersion).\(osVersion.minorVersion)")
            return .unavailable
        }
    }
    
    /// 获取macOS版本字符串
    private func getMacOSVersionString() -> String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    }
    
    // 处理快捷键事件
    private func handleHotkeyEvent(_ event: EventRef?) -> OSStatus {
        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(event,
                                       EventParamName(kEventParamDirectObject),
                                       EventParamType(typeEventHotKeyID),
                                       nil,
                                       MemoryLayout<EventHotKeyID>.size,
                                       nil,
                                       &hotkeyID)
        
        if status == noErr && hotkeyID.id == self.hotkeyID.id {
            // 恢复简单的Option+V - 打开窗口
            handleShowWindow()
        }
        
        return noErr
    }
    
    // Option+V - 打开窗口，单击项目直接粘贴
    private func handleShowWindow() {
        print("🔥 Option+V 打开窗口被触发")
        
        // 记录用户目标应用
        recordTargetApplication()
        
        DispatchQueue.main.async {
            self.showClipboardWindow()
        }
    }
    
    // 记录用户目标应用的通用方法
    private func recordTargetApplication() {
        let currentApp = NSWorkspace.shared.frontmostApplication
        if let app = currentApp, 
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApplication = app
            print("🎯 记录用户目标应用: \(app.localizedName ?? "Unknown") [Bundle: \(app.bundleIdentifier ?? "Unknown")]")
        } else {
            // 如果当前是ClipMaster，寻找之前的活动应用
            let runningApps = NSWorkspace.shared.runningApplications
            for app in runningApps {
                if app.activationPolicy == .regular && 
                   app.bundleIdentifier != Bundle.main.bundleIdentifier &&
                   !app.isTerminated {
                    targetApplication = app
                    print("🎯 使用最近的非ClipMaster应用: \(app.localizedName ?? "Unknown")")
                    break
                }
            }
        }
    }
    
    // 显示剪贴板窗口 - 单例管理避免重复创建
    func showClipboardWindow() {
        if clipboardWindow == nil {
            clipboardWindow = ClipboardWindow()
            print("✅ 创建新的剪贴板窗口实例")
        }
        
        clipboardWindow?.showWindow()
        print("✅ 显示剪贴板窗口")
    }
    
    // 获取用户目标应用
    func getTargetApplication() -> NSRunningApplication? {
        return targetApplication
    }
    
    // 显示辅助功能权限提示（用户友好版本）
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "ClipMaster 需要辅助功能权限"
        alert.informativeText = """
        为了使用 Option+V 全局快捷键功能，ClipMaster 需要获得辅助功能权限。
        
        授权步骤：
        1. 点击「打开系统设置」按钮
        2. 在「隐私与安全性」>「辅助功能」中找到 ClipMaster
        3. 勾选 ClipMaster 旁边的复选框
        4. 等待 2-3 秒让系统权限生效
        5. 快捷键即可正常使用
        
        注意：这是一次性设置，授权后权限需要几秒钟生效时间。
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后设置")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // 打开系统设置的辅助功能面板
            if #available(macOS 13.0, *) {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            } else {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }
    
    // 隐藏剪贴板窗口
    func hideClipboardWindow() {
        clipboardWindow?.hideWindow()
    }
    
    // 检查辅助功能权限（静默检查，不弹出对话框）
    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // 获取键码和修饰键 - 修复数组匹配逻辑
    private func getKeyCodeAndModifiers() -> (UInt32, UInt32) {
        let keyCode = getKeyCode(for: currentKey)
        var modifierFlags: UInt32 = 0
        
        for modifier in currentModifiers {
            switch modifier {
            case "command":
                modifierFlags |= UInt32(cmdKey)
            case "option":
                modifierFlags |= UInt32(optionKey)
            case "control":
                modifierFlags |= UInt32(controlKey)
            case "shift":
                modifierFlags |= UInt32(shiftKey)
            default:
                break
            }
        }
        
        return (keyCode, modifierFlags)
    }
    
    // 获取键码 - 完善支持更多按键类型
    private func getKeyCode(for key: String) -> UInt32 {
        switch key.lowercased() {
        // 字母键 (A-Z)
        case "a": return 0
        case "b": return 11
        case "c": return 8
        case "d": return 2
        case "e": return 14
        case "f": return 3
        case "g": return 5
        case "h": return 4
        case "i": return 34
        case "j": return 38
        case "k": return 40
        case "l": return 37
        case "m": return 46
        case "n": return 45
        case "o": return 31
        case "p": return 35
        case "q": return 12
        case "r": return 15
        case "s": return 1
        case "t": return 17
        case "u": return 32
        case "v": return 9
        case "w": return 13
        case "x": return 7
        case "y": return 16
        case "z": return 6
        
        // 数字键 (0-9)
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "5": return 23
        case "6": return 22
        case "7": return 26
        case "8": return 28
        case "9": return 25
        case "0": return 29
        
        // 功能键 (F1-F12)
        case "f1": return 122
        case "f2": return 120
        case "f3": return 99
        case "f4": return 118
        case "f5": return 96
        case "f6": return 97
        case "f7": return 98
        case "f8": return 100
        case "f9": return 101
        case "f10": return 109
        case "f11": return 103
        case "f12": return 111
        
        // 方向键
        case "up": return 126
        case "down": return 125
        case "left": return 123
        case "right": return 124
        
        // 特殊键
        case "return": return 36
        case "tab": return 48
        case "space": return 49
        case "escape": return 53
        case "delete": return 51
        case "forwarddelete": return 117
        case "home": return 115
        case "end": return 119
        case "pageup": return 116
        case "pagedown": return 121
        
        // 标点符号键
        case "=": return 24
        case "-": return 27
        case "]": return 30
        case "[": return 33
        case "'": return 39
        case ";": return 41
        case "\\": return 42
        case ",": return 43
        case "/": return 44
        case ".": return 47
        case "`": return 50
        
        // 数字键盘
        case "keypad0": return 82
        case "keypad1": return 83
        case "keypad2": return 84
        case "keypad3": return 85
        case "keypad4": return 86
        case "keypad5": return 87
        case "keypad6": return 88
        case "keypad7": return 89
        case "keypad8": return 91
        case "keypad9": return 92
        case "keypadDecimal": return 65
        case "keypadMultiply": return 67
        case "keypadPlus": return 69
        case "keypadClear": return 71
        case "keypadDivide": return 75
        case "keypadEnter": return 76
        case "keypadMinus": return 78
        case "keypadEquals": return 81
        
        default: 
            print("⚠️ 不支持的按键: \(key), 默认使用V键")
            return 9 // 默认V键
        }
    }
    
    // 获取快捷键显示字符串 - 修复数组遍历逻辑
    private func getShortcutDisplayString() -> String {
        var parts: [String] = []
        
        for modifier in currentModifiers {
            switch modifier {
            case "command":
                parts.append("⌘")
            case "option":
                parts.append("⌥")
            case "control":
                parts.append("⌃")
            case "shift":
                parts.append("⇧")
            default:
                break
            }
        }
        
        parts.append(currentKey.uppercased())
        
        return parts.joined(separator: "+")
    }
    
    // MARK: - 动态权限监控系统
    
    /// 启动权限监控 - 优化响应速度
    private func startPermissionMonitoring() {
        // 初始检查
        wasAccessibilityGranted = checkAccessibilityPermission()
        
        // 每1秒检查一次权限状态 - 显著缩短检查间隔
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPermissionStatusChange()
        }
        
        print("🔍 权限监控已启动 (1秒间隔)")
    }
    
    /// 停止权限监控
    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
        print("🛑 权限监控已停止")
    }
    
    /// 检查权限状态变化
    private func checkPermissionStatusChange() {
        let currentStatus = checkAccessibilityPermission()
        lastPermissionCheck = Date()
        
        // 权限状态发生变化
        if currentStatus != wasAccessibilityGranted {
            print("🚨 权限状态变化: \(wasAccessibilityGranted) → \(currentStatus)")
            
            if currentStatus {
                // 权限被授予 - 防止重复注册
                print("✅ 权限已恢复，准备重新注册快捷键")
                hasShownPermissionAlert = false
                
                // 防止重复注册
                if !isRegistering {
                    self.registerSystemHotkey()
                } else {
                    print("⚠️ 快捷键注册正在进行中，跳过权限恢复触发")
                }
            } else {
                // 权限被撤销
                print("❌ 权限被撤销，快捷键功能不可用")
                unregisterHotkey()
                
                // 重新显示权限提示
                if !hasShownPermissionAlert {
                    hasShownPermissionAlert = true
                    DispatchQueue.main.async {
                        self.showAccessibilityAlert()
                    }
                }
            }
            
            wasAccessibilityGranted = currentStatus
        }
    }
    
    /// 手动触发权限检查（用于用户操作后立即检查） - 添加详细调试
    func checkPermissionImmediately() {
        print("🔄 手动触发权限检查 - checkPermissionImmediately()被调用")
        
        // 立即检查当前权限状态
        let currentStatus = checkAccessibilityPermission()
        print("🔍 当前权限状态检查结果: \(currentStatus)")
        print("📊 之前记录的权限状态: \(wasAccessibilityGranted)")
        
        // 强制触发权限状态变化检查
        checkPermissionStatusChange()
        
        print("✅ 手动权限检查完成")
    }
    
    /// 公开的权限状态检查方法（供UI调用）
    func getAccessibilityPermissionStatus() -> Bool {
        return checkAccessibilityPermission()
    }
    
    // MARK: - 改进的权限检查方法
    
    /// 检查辅助功能权限的增强版本
    private func checkAccessibilityPermissionEnhanced() -> (granted: Bool, shouldPrompt: Bool) {
        let trusted = checkAccessibilityPermission()
        let timeSinceLastCheck = lastPermissionCheck?.timeIntervalSinceNow ?? -Double.infinity
        let shouldPrompt = !trusted && !hasShownPermissionAlert && timeSinceLastCheck < -30.0 // 30秒内不重复提示
        
        return (granted: trusted, shouldPrompt: shouldPrompt)
    }
    
    // MARK: - 快捷键冲突检测系统
    
    /// 检测快捷键是否被占用
    func checkShortcutConflict(modifiers: [String], key: String) -> (hasConflict: Bool, conflictInfo: String?) {
        let (keyCode, modifierFlags) = getKeyCodeAndModifiersFor(modifiers: modifiers, key: key)
        
        // 临时注册测试快捷键
        let testID = EventHotKeyID(signature: OSType("TEST".fourCharCodeValue), id: 999)
        var testHotkeyRef: EventHotKeyRef?
        
        let status = RegisterEventHotKey(keyCode,
                                         modifierFlags,
                                         testID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &testHotkeyRef)
        
        // 立即清理测试快捷键
        if let testRef = testHotkeyRef {
            UnregisterEventHotKey(testRef)
        }
        
        switch status {
        case noErr:
            return (hasConflict: false, conflictInfo: nil)
        case OSStatus(eventHotKeyExistsErr):
            return (hasConflict: true, conflictInfo: "快捷键已被其他应用占用")
        case OSStatus(paramErr):
            return (hasConflict: true, conflictInfo: "无效的快捷键组合")
        default:
            return (hasConflict: true, conflictInfo: "未知错误 (\(status))")
        }
    }
    
    /// 获取指定修饰键和按键的键码组合（用于冲突检测）
    private func getKeyCodeAndModifiersFor(modifiers: [String], key: String) -> (UInt32, UInt32) {
        let keyCode = getKeyCode(for: key)
        var modifierFlags: UInt32 = 0
        
        for modifier in modifiers {
            switch modifier {
            case "command":
                modifierFlags |= UInt32(cmdKey)
            case "option":
                modifierFlags |= UInt32(optionKey)
            case "control":
                modifierFlags |= UInt32(controlKey)
            case "shift":
                modifierFlags |= UInt32(shiftKey)
            default:
                break
            }
        }
        
        return (keyCode, modifierFlags)
    }
    
    /// 获取快捷键的友好显示名称
    func getShortcutDisplayName(modifiers: [String], key: String) -> String {
        var parts: [String] = []
        
        for modifier in modifiers {
            switch modifier {
            case "command": parts.append("⌘")
            case "option": parts.append("⌥")
            case "control": parts.append("⌃")
            case "shift": parts.append("⇧")
            default: break
            }
        }
        
        // 格式化按键显示
        let displayKey: String
        switch key.lowercased() {
        case "return": displayKey = "↩"
        case "tab": displayKey = "⇥"
        case "space": displayKey = "Space"
        case "escape": displayKey = "⎋"
        case "delete": displayKey = "⌫"
        case "forwarddelete": displayKey = "⌦"
        case "up": displayKey = "↑"
        case "down": displayKey = "↓"
        case "left": displayKey = "←"
        case "right": displayKey = "→"
        default: displayKey = key.uppercased()
        }
        
        parts.append(displayKey)
        return parts.joined(separator: "")
    }
    
    /// 推荐可用的快捷键
    func suggestAlternativeShortcuts(basedOn originalModifiers: [String], originalKey: String) -> [(modifiers: [String], key: String, displayName: String)] {
        var suggestions: [(modifiers: [String], key: String, displayName: String)] = []
        
        // 候选修饰键组合
        let modifierCombinations: [[String]] = [
            ["option"],
            ["command"],
            ["control"],
            ["command", "option"],
            ["control", "option"],
            ["command", "control"],
            ["shift", "option"]
        ]
        
        // 候选按键
        let candidateKeys = ["v", "c", "x", "z", "b", "n", "m", "k", "j", "h", "g", "f1", "f2", "f3", "f4"]
        
        for modifierCombo in modifierCombinations {
            for candidateKey in candidateKeys {
                // 跳过原始组合
                if modifierCombo == originalModifiers && candidateKey == originalKey {
                    continue
                }
                
                let result = checkShortcutConflict(modifiers: modifierCombo, key: candidateKey)
                if !result.hasConflict {
                    let displayName = getShortcutDisplayName(modifiers: modifierCombo, key: candidateKey)
                    suggestions.append((modifiers: modifierCombo, key: candidateKey, displayName: displayName))
                    
                    // 限制建议数量
                    if suggestions.count >= 5 {
                        return suggestions
                    }
                }
            }
        }
        
        return suggestions
    }
}

// 移除重复扩展，使用Utils/Extensions.swift中的版本

// 虚拟键码常量
private let kVK_ANSI_V: Int = 0x09