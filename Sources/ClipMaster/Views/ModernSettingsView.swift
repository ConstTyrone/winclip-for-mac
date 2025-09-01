import SwiftUI
import ServiceManagement

// 现代化的设置视图
struct ModernSettingsView: View {
    @EnvironmentObject var manager: ClipboardManager
    @State private var selectedTab = "general"
    
    // 设置项
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 100.0
    @AppStorage("maxHistoryDays") private var maxHistoryDays = 30.0
    @AppStorage("enableSmartCategories") private var enableSmartCategories = true
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    
    var body: some View {
        HSplitView {
            // 左侧导航
            SidebarView(selectedTab: $selectedTab)
                .frame(width: 200)
                .background(Color(NSColor.controlBackgroundColor))
            
            // 右侧内容
            ScrollView {
                VStack(spacing: 0) {
                    // 标题区域
                    HeaderView(title: tabTitle(for: selectedTab))
                        .padding(.bottom, 20)
                    
                    // 内容区域
                    Group {
                        switch selectedTab {
                        case "general":
                            ModernGeneralSettings(
                                launchAtLogin: $launchAtLogin,
                                showMenuBarIcon: $showMenuBarIcon,
                                appearanceMode: $appearanceMode
                            )
                        case "storage":
                            ModernStorageSettings(
                                maxHistoryItems: $maxHistoryItems,
                                maxHistoryDays: $maxHistoryDays
                            )
                        case "shortcuts":
                            ModernShortcutsSettings()
                        case "advanced":
                            ModernAdvancedSettings()
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer(minLength: 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 750, idealWidth: 850, maxWidth: .infinity,
               minHeight: 500, idealHeight: 600, maxHeight: .infinity)
    }
    
    func tabTitle(for tab: String) -> String {
        switch tab {
        case "general": return "通用"
        case "storage": return "存储"
        case "shortcuts": return "快捷键"
        case "advanced": return "高级"
        default: return ""
        }
    }
}

// 侧边栏视图
struct SidebarView: View {
    @Binding var selectedTab: String
    
    let tabs = [
        ("general", "gearshape.fill", "通用"),
        ("storage", "internaldrive.fill", "存储"),
        ("shortcuts", "keyboard.fill", "快捷键"),
        ("advanced", "slider.horizontal.3", "高级")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // Logo 区域
            VStack(spacing: 10) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                Text("ClipMaster")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("偏好设置")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 25)
            
            Divider()
                .padding(.horizontal)
            
            // 导航项
            VStack(spacing: 4) {
                ForEach(tabs, id: \.0) { tab in
                    SidebarButton(
                        icon: tab.1,
                        title: tab.2,
                        isSelected: selectedTab == tab.0
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab.0
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 20)
            
            Spacer()
            
            // 底部信息
            VStack(spacing: 8) {
                Divider()
                    .padding(.horizontal)
                
                Text("版本 1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("© 2024 ClipMaster")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 侧边栏按钮
struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : 
                          isHovering ? Color.gray.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// 标题视图
struct HeaderView: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 28, weight: .semibold))
                .padding(.horizontal, 30)
                .padding(.top, 30)
            
            Divider()
                .padding(.top, 20)
        }
    }
}

// 现代化通用设置
struct ModernGeneralSettings: View {
    @Binding var launchAtLogin: Bool
    @Binding var showMenuBarIcon: Bool
    @Binding var appearanceMode: String
    
    var body: some View {
        VStack(spacing: 30) {
            // 启动设置卡片
            SettingCard(
                icon: "power",
                title: "启动设置",
                description: "控制应用的启动行为"
            ) {
                VStack(spacing: 16) {
                    ModernToggle(
                        icon: "arrow.up.square.fill",
                        title: "开机自启动",
                        subtitle: "登录时自动启动 ClipMaster",
                        isOn: Binding(
                            get: { launchAtLogin },
                            set: { newValue in
                                launchAtLogin = newValue
                                setLaunchAtLogin(newValue)
                            }
                        )
                    )
                    
                    ModernToggle(
                        icon: "menubar.rectangle",
                        title: "显示菜单栏图标",
                        subtitle: "在菜单栏显示快速访问图标",
                        isOn: Binding(
                            get: { showMenuBarIcon },
                            set: { newValue in
                                showMenuBarIcon = newValue
                                toggleMenuBarIcon(newValue)
                            }
                        )
                    )
                }
            }
            
            // 外观设置卡片
            SettingCard(
                icon: "paintbrush.fill",
                title: "外观设置",
                description: "自定义应用的视觉外观"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("主题模式")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ThemeButton(
                            icon: "circle.lefthalf.filled",
                            title: "跟随系统",
                            isSelected: appearanceMode == "system"
                        ) {
                            appearanceMode = "system"
                            applyAppearance("system")
                        }
                        
                        ThemeButton(
                            icon: "sun.max.fill",
                            title: "浅色",
                            isSelected: appearanceMode == "light"
                        ) {
                            appearanceMode = "light"
                            applyAppearance("light")
                        }
                        
                        ThemeButton(
                            icon: "moon.fill",
                            title: "深色",
                            isSelected: appearanceMode == "dark"
                        ) {
                            appearanceMode = "dark"
                            applyAppearance("dark")
                        }
                    }
                }
            }
        }
    }
    
    private func applyAppearance(_ mode: String) {
        DispatchQueue.main.async {
            switch mode {
            case "light":
                NSApp.appearance = NSAppearance(named: .aqua)
            case "dark":
                NSApp.appearance = NSAppearance(named: .darkAqua)
            default:
                NSApp.appearance = nil
            }
        }
    }
    
    // 设置自启动（委托给AppDelegate实现）
    private func setLaunchAtLogin(_ enabled: Bool) {
        if NSApp.delegate is AppDelegate {
            // 调用AppDelegate中的实现
            // 在生产环境中应该实际调用AppDelegate的方法
        }
    }
    
    // 切换菜单栏图标显示
    private func toggleMenuBarIcon(_ show: Bool) {
        DispatchQueue.main.async {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                if show {
                    appDelegate.showMenuBarIcon()
                } else {
                    appDelegate.hideMenuBarIcon()
                }
                print(show ? "✅ 菜单栏图标已显示" : "❌ 菜单栏图标已隐藏")
            }
        }
    }
}

// 现代化存储设置
struct ModernStorageSettings: View {
    @Binding var maxHistoryItems: Double
    @Binding var maxHistoryDays: Double
    
    var body: some View {
        VStack(spacing: 30) {
            SettingCard(
                icon: "clock.arrow.circlepath",
                title: "历史记录",
                description: "管理剪贴板历史的存储策略"
            ) {
                VStack(spacing: 24) {
                    ModernSlider(
                        icon: "number.square.fill",
                        title: "最大记录数量",
                        value: $maxHistoryItems,
                        range: 50...500,
                        step: 50,
                        unit: "条"
                    )
                    
                    ModernSlider(
                        icon: "calendar",
                        title: "保存天数",
                        value: $maxHistoryDays,
                        range: 7...90,
                        step: 1,
                        unit: "天"
                    )
                    
                    // 存储统计
                    HStack {
                        Label("当前存储", systemImage: "chart.pie.fill")
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        Text("\(ClipboardManager.shared.items.count) 条记录")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
            }
        }
    }
}

// 现代化快捷键设置 - 修复支持数组存储格式
struct ModernShortcutsSettings: View {
    // 注意：@AppStorage不直接支持数组，需要自定义getter/setter
    private var shortcutModifiers: [String] {
        get { UserDefaults.standard.stringArray(forKey: "globalShortcutModifiers") ?? ["option"] }
        set { UserDefaults.standard.set(newValue, forKey: "globalShortcutModifiers") }
    }
    @AppStorage("globalShortcutKey") private var shortcutKey = "v"
    @State private var isEditingShortcut = false
    
    // 权限状态管理
    @State private var accessibilityPermissionGranted: Bool = false
    @State private var isCheckingPermission: Bool = false
    @State private var showPermissionResult: Bool = false
    @State private var permissionResultMessage: String = ""
    
    init() {
        print("🏗️ ModernShortcutsSettings 视图初始化")
    }
    
    var body: some View {
        VStack(spacing: 30) {
            SettingCard(
                icon: "keyboard.fill",
                title: "全局快捷键",
                description: "自定义打开剪贴板历史的快捷键"
            ) {
                VStack(spacing: 20) {
                    // 主快捷键配置
                    HStack {
                        Image(systemName: "command.square.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("打开剪贴板历史")
                                .font(.system(size: 14, weight: .medium))
                            Text("点击下方按钮自定义快捷键")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            print("🖱️ 点击了自定义快捷键按钮，即将显示Sheet")
                            isEditingShortcut = true
                            print("📊 isEditingShortcut 设置为: \(isEditingShortcut)")
                        }) {
                            ShortcutBadge(keys: getShortcutKeys())
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.08))
                    )
                    
                    // 操作说明（简化版）
                    VStack(spacing: 12) {
                        ShortcutRow(description: "单击项目直接粘贴", keys: ["鼠标左键"])
                        ShortcutRow(description: "点击窗口外关闭", keys: ["鼠标"])
                    }
                }
            }
            
            // 权限状态和刷新
            SettingCard(
                icon: "checkmark.shield.fill",
                title: "权限状态",
                description: "检查和刷新辅助功能权限"
            ) {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "accessibility")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                        
                        Text("辅助功能权限")
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        // 权限状态指示器
                        HStack(spacing: 8) {
                            if isCheckingPermission {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 20, height: 20)
                                Text("检查中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: accessibilityPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(accessibilityPermissionGranted ? .green : .red)
                                
                                Text(accessibilityPermissionGranted ? "已授权" : "未授权")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(accessibilityPermissionGranted ? .green : .red)
                            }
                        }
                        
                        Button("刷新权限") {
                            refreshPermissionStatus()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCheckingPermission)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("如果设置权限后快捷键仍不生效，请点击刷新权限")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        // 权限设置指导
                        if !accessibilityPermissionGranted {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                    
                                    Text("权限设置指导：")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                }
                                
                                Text("1. 打开系统偏好设置 → 安全性与隐私 → 辅助功能")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("2. 点击")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(3)
                                    
                                    Text("号手动添加 ClipMaster（推荐方式）")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("3. 选中 ClipMaster 并确认授权")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    // 权限检查结果提示
                    if showPermissionResult {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            
                            Text(permissionResultMessage)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                        .transition(.opacity)
                    }
                }
                .padding(16)
            }
            
            // 快捷键重置
            SettingCard(
                icon: "arrow.counterclockwise.circle.fill",
                title: "重置设置",
                description: "恢复默认快捷键配置"
            ) {
                HStack {
                    Text("将快捷键重置为默认的 Option+V")
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Button("重置") {
                        UserDefaults.standard.set(["option"], forKey: "globalShortcutModifiers")
                        shortcutKey = "v"
                        // 通知HotkeyManager更新快捷键
                        NotificationCenter.default.post(name: NSNotification.Name("ShortcutChanged"), object: nil)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $isEditingShortcut) {
            ShortcutEditorView(
                modifiers: Binding(
                    get: { shortcutModifiers.joined(separator: ",") },
                    set: { _ in /* 通过ShortcutEditorView内部处理 */ }
                ),
                key: $shortcutKey,
                isPresented: $isEditingShortcut
            )
        }
        .onAppear {
            // 页面加载时立即检查权限状态
            checkInitialPermissionStatus()
        }
    }
    
    // MARK: - 权限状态管理方法
    
    /// 页面加载时检查初始权限状态（无动画）
    private func checkInitialPermissionStatus() {
        accessibilityPermissionGranted = HotkeyManager.shared.getAccessibilityPermissionStatus()
        print("🔍 初始权限状态检查: \(accessibilityPermissionGranted)")
    }
    
    /// 刷新权限状态（带动画和反馈）
    private func refreshPermissionStatus() {
        // 开始检查动画
        withAnimation(.easeInOut(duration: 0.3)) {
            isCheckingPermission = true
        }
        
        // 隐藏之前的结果
        showPermissionResult = false
        
        // 延迟检查以显示加载效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let wasGranted = accessibilityPermissionGranted
            
            // 执行权限检查
            HotkeyManager.shared.checkPermissionImmediately()
            let newStatus = HotkeyManager.shared.getAccessibilityPermissionStatus()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isCheckingPermission = false
                accessibilityPermissionGranted = newStatus
            }
            
            // 显示检查结果
            var resultMessage = ""
            if newStatus {
                if !wasGranted {
                    resultMessage = "✅ 检测到权限已授予，快捷键将在2-3秒后生效"
                } else {
                    resultMessage = "✅ 权限状态正常，快捷键应该可以正常使用"
                }
            } else {
                resultMessage = "❌ 未检测到辅助功能权限，请前往系统设置授权"
            }
            
            // 显示结果提示
            withAnimation(.easeInOut(duration: 0.3)) {
                permissionResultMessage = resultMessage
                showPermissionResult = true
            }
            
            // 5秒后隐藏结果提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPermissionResult = false
                }
            }
            
            print("🔄 权限刷新完成: \(wasGranted) → \(newStatus)")
        }
    }
    
    // 修复快捷键显示逻辑 - 支持数组格式
    private func getShortcutKeys() -> [String] {
        var keys: [String] = []
        
        // 添加修饰键符号
        for modifier in shortcutModifiers {
            switch modifier {
            case "command": keys.append("⌘")
            case "option": keys.append("⌥")
            case "control": keys.append("⌃")
            case "shift": keys.append("⇧")
            default: break
            }
        }
        
        // 添加主键
        keys.append(shortcutKey.uppercased())
        
        return keys
    }
}


// 现代化高级设置
struct ModernAdvancedSettings: View {
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    
    var body: some View {
        VStack(spacing: 30) {
            SettingCard(
                icon: "gearshape.2.fill",
                title: "高级选项",
                description: "开发者和高级用户选项"
            ) {
                VStack(spacing: 16) {
                    ModernToggle(
                        icon: "ant.fill",
                        title: "调试模式",
                        subtitle: "显示详细的调试信息",
                        isOn: $enableDebugMode
                    )
                    
                    HStack {
                        Label("重置所有设置", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        Button("重置") {
                            // 重置逻辑
                        }
                        .buttonStyle(DangerButtonStyle())
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.08))
                    )
                }
            }
        }
    }
}

// MARK: - 自定义组件

// 设置卡片
struct SettingCard<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let content: Content
    
    init(icon: String, title: String, description: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            content
                .padding(.leading, 40)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// 现代化开关
struct ModernToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .labelsHidden()
        }
    }
}

// 现代化滑块
struct ModernSlider: View {
    let icon: String
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Text("\(Int(value))")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.accentColor)
                + Text(" \(unit)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(.accentColor)
                .padding(.leading, 28)
        }
    }
}

// 主题按钮
struct ThemeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : 
                          isHovering ? Color.gray.opacity(0.08) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// 快捷键徽章
struct ShortcutBadge: View {
    let keys: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}

// 快捷键行
struct ShortcutRow: View {
    let description: String
    let keys: [String]
    
    var body: some View {
        HStack {
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            ShortcutBadge(keys: keys)
        }
        .padding(.horizontal, 4)
    }
}

// 危险按钮样式
struct DangerButtonStyle: ButtonStyle {
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.red.opacity(configuration.isPressed ? 0.8 : isHovering ? 0.9 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

// 快捷键编辑器 - 修复支持数组格式
struct ShortcutEditorView: View {
    // 注意：这里仍然需要维持Binding兼容性，但内部使用数组
    @Binding var modifiers: String  // 保持与父视图的兼容性
    @Binding var key: String
    @Binding var isPresented: Bool
    
    @State private var tempModifiers: [String] = []  // 修复为数组格式
    @State private var tempKey = ""
    @State private var isCapturingShortcut = false
    @State private var eventMonitor: Any?
    
    // 冲突检测状态
    @State private var conflictInfo: (hasConflict: Bool, message: String?) = (false, nil)
    @State private var suggestedShortcuts: [(modifiers: [String], key: String, displayName: String)] = []
    @State private var showConflictWarning = false
    
    // 录制体验优化
    @State private var recordingTimeRemaining = 0
    @State private var recordingTimer: Timer?
    private let maxRecordingTime = 30  // 30秒超时
    
    init(modifiers: Binding<String>, key: Binding<String>, isPresented: Binding<Bool>) {
        self._modifiers = modifiers
        self._key = key
        self._isPresented = isPresented
        print("🏗️ ShortcutEditorView 初始化 - modifiers: \(modifiers.wrappedValue), key: \(key.wrappedValue)")
        fflush(stdout)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text("自定义快捷键")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(isCapturingShortcut ? "请按下快捷键组合..." : "按下您想要设置的快捷键组合")
                .font(.body)
                .foregroundColor(isCapturingShortcut ? .accentColor : .secondary)
                .multilineTextAlignment(.center)
            
            // 快捷键显示区域
            VStack(spacing: 16) {
                Text("当前快捷键:")
                    .font(.headline)
                
                ShortcutBadge(keys: getCurrentShortcutKeys())
                    .scaleEffect(1.2)
                
                if isCapturingShortcut {
                    VStack(spacing: 6) {
                        Text("🎯 录制模式已激活")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                        
                        Text("请按下快捷键组合...")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .fontWeight(.medium)
                        
                        Text("\(recordingTimeRemaining)秒后自动停止")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // 添加调试状态显示
                        VStack(spacing: 2) {
                            Text("状态: \(eventMonitor != nil ? "✅监听器已创建" : "❌监听器创建失败")")
                                .font(.caption2)
                                .foregroundColor(eventMonitor != nil ? .green : .red)
                            
                            Text("权限: 检查控制台日志")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                            .opacity(0.8)
                    }
                }
                
                // 冲突警告显示
                if conflictInfo.hasConflict {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(conflictInfo.message ?? "快捷键冲突")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        // 显示建议的替代快捷键
                        if !suggestedShortcuts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("建议的替代快捷键：")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                    ForEach(suggestedShortcuts.prefix(6), id: \.displayName) { suggestion in
                                        Button(suggestion.displayName) {
                                            tempModifiers = suggestion.modifiers
                                            tempKey = suggestion.key
                                            conflictInfo = (false, nil)
                                            suggestedShortcuts = []
                                        }
                                        .buttonStyle(.bordered)
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            
            // 操作按钮
            HStack(spacing: 16) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button(isCapturingShortcut ? "停止录制" : "开始录制") {
                    print("🖱️ 录制按钮被点击！当前状态: isCapturingShortcut=\(isCapturingShortcut)")
                    fflush(stdout)
                    if isCapturingShortcut {
                        print("🛑 点击停止录制")
                        stopCapturing()
                    } else {
                        print("🎯 点击开始录制，即将调用startCapturingShortcut()")
                        fflush(stdout)
                        startCapturingShortcut()
                    }
                    print("🔄 按钮点击处理完成，新状态: isCapturingShortcut=\(isCapturingShortcut)")
                    fflush(stdout)
                }
                .buttonStyle(.borderedProminent)
                
                Button("保存") {
                    checkConflictAndSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(tempModifiers.isEmpty || tempKey.isEmpty)
            }
        }
        .padding(32)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            print("📱 ShortcutEditorView onAppear 被调用")
            // 初始化时转换为数组格式
            if !modifiers.isEmpty {
                // 如果是老格式（逗号分隔），转换为数组
                tempModifiers = modifiers.components(separatedBy: ",")
            } else {
                // 从 UserDefaults 获取数组格式
                tempModifiers = UserDefaults.standard.stringArray(forKey: "globalShortcutModifiers") ?? ["option"]
            }
            tempKey = key
            print("📊 初始化完成: tempModifiers=\(tempModifiers), tempKey=\(tempKey)")
        }
        .onDisappear {
            stopCapturing()
        }
    }
    
    // 修复当前快捷键显示逻辑 - 支持数组格式
    private func getCurrentShortcutKeys() -> [String] {
        var keys: [String] = []
        let currentModifiers = tempModifiers.isEmpty ? 
            UserDefaults.standard.stringArray(forKey: "globalShortcutModifiers") ?? ["option"] : 
            tempModifiers
        let currentKey = tempKey.isEmpty ? key : tempKey
        
        for modifier in currentModifiers {
            switch modifier {
            case "command": keys.append("⌘")
            case "option": keys.append("⌥")
            case "control": keys.append("⌃")
            case "shift": keys.append("⇧")
            default: break
            }
        }
        
        keys.append(currentKey.uppercased())
        return keys
    }
    
    // 优化的快捷键录制方法 - 完整调试版本
    private func startCapturingShortcut() {
        print("\n" + String(repeating: "=", count: 50))
        print("🎯 startCapturingShortcut() 方法开始执行")
        print("📊 执行前状态: isCapturingShortcut=\(isCapturingShortcut)")
        print(String(repeating: "=", count: 50))
        
        // 先清理之前的监听器和定时器，但不重置状态
        cleanupMonitors()
        
        // 然后设置录制状态
        isCapturingShortcut = true
        recordingTimeRemaining = maxRecordingTime
        print("📊 状态设置完成: isCapturingShortcut=\(isCapturingShortcut)")
        
        // 启动倒计时
        startRecordingCountdown()
        
        // 检查辅助功能权限 - 改进权限检查
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            print("⚠️ 缺少辅助功能权限，快捷键录制可能无法正常工作")
            // 显示用户友好的权限提示
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "需要辅助功能权限"
                alert.informativeText = "要录制自定义快捷键，请在系统偏好设置 > 隐私与安全性 > 辅助功能中授权ClipMaster。"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "打开设置")
                alert.addButton(withTitle: "取消")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
            // 仍然尝试录制，可能在某些情况下仍能工作
        } else {
            print("✅ 辅助功能权限已获得，开始录制快捷键")
        }
        
        // 实现键盘监听 - 修复：使用全局监听器并添加详细调试
        print("🔧 开始设置键盘事件监听器...")
        
        // 同时使用全局和本地监听器以确保能捕获到按键
        print("🔧 尝试添加全局监听器...")
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            print("🎹 [全局] 接收到按键事件: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")
            self.handleKeyEvent(event)
        }
        
        print("🔧 尝试添加本地监听器作为备份...")
        // 添加本地监听器作为备份
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            print("🎹 [本地] 接收到按键事件: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")
            self.handleKeyEvent(event)
            return event  // 继续传递事件
        }
        
        // 将本地监听器也存储起来（需要修改存储方式）
        if let localMonitor = localMonitor {
            print("✅ 本地监听器创建成功")
        }
        
        if eventMonitor != nil {
            print("✅ 全局键盘监听器创建成功")
        } else {
            print("❌ 全局键盘监听器创建失败")
        }
    }
    
    // 启动录制倒计时
    private func startRecordingCountdown() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if recordingTimeRemaining > 0 {
                    recordingTimeRemaining -= 1
                } else {
                    stopCapturing()
                }
            }
        }
    }
    
    // 优化的停止录制方法
    // 只清理监听器和定时器，不重置状态
    private func cleanupMonitors() {
        print("🧹 开始清理监听器和定时器...")
        // 清理定时器
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // 清理键盘监听器
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
            print("✅ 旧的键盘监听器已清理")
        }
    }
    
    // 通用的按键事件处理方法
    private func handleKeyEvent(_ event: NSEvent) {
        guard isCapturingShortcut else { 
            print("⚠️ 不在录制状态，忽略按键事件")
            return 
        }
        
        DispatchQueue.main.async {
            let modifierFlags = event.modifierFlags.intersection([.command, .option, .control, .shift])
            let keyCode = event.keyCode
            
            print("📝 处理按键: keyCode=\(keyCode), modifierFlags=\(modifierFlags)")
            
            // 必须有修饰键才能组成快捷键
            guard !modifierFlags.isEmpty else { 
                print("⚠️ 录制快捷键需要包含修饰键（⌘⌥⌃⇧），当前无修饰键")
                return 
            }
            
            // 转换修饰键
            var modifierStrings: [String] = []
            if modifierFlags.contains(.command) { modifierStrings.append("command") }
            if modifierFlags.contains(.option) { modifierStrings.append("option") }
            if modifierFlags.contains(.control) { modifierStrings.append("control") }
            if modifierFlags.contains(.shift) { modifierStrings.append("shift") }
            
            // 转换主键
            guard let keyString = self.keyCodeToString(keyCode) else {
                print("⚠️ 无法识别的按键码: \(keyCode)")
                return
            }
            
            print("✅ 成功录制快捷键: \(modifierStrings.joined(separator: "+"))+\(keyString)")
            
            // 更新临时值
            self.tempModifiers = modifierStrings
            self.tempKey = keyString
            
            // 停止录制
            self.stopCapturing()
            
            // 自动检查冲突
            self.checkForConflicts()
            
            print("📊 快捷键录制完成: modifiers=\(self.tempModifiers), key=\(self.tempKey)")
        }
    }
    
    private func stopCapturing() {
        print("🛑 stopCapturing() 被调用")
        isCapturingShortcut = false
        recordingTimeRemaining = 0
        
        // 清理资源
        cleanupMonitors()
    }
    
    // 键码转字符串 - 完善支持更多按键类型
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        switch keyCode {
        // 字母键 (A-Z)
        case 0: return "a"
        case 11: return "b"
        case 8: return "c"
        case 2: return "d"
        case 14: return "e"
        case 3: return "f"
        case 5: return "g"
        case 4: return "h"
        case 34: return "i"
        case 38: return "j"
        case 40: return "k"
        case 37: return "l"
        case 46: return "m"
        case 45: return "n"
        case 31: return "o"
        case 35: return "p"
        case 12: return "q"
        case 15: return "r"
        case 1: return "s"
        case 17: return "t"
        case 32: return "u"
        case 9: return "v"
        case 13: return "w"
        case 7: return "x"
        case 16: return "y"
        case 6: return "z"
        
        // 数字键 (0-9)
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        
        // 功能键 (F1-F12)
        case 122: return "f1"
        case 120: return "f2"
        case 99: return "f3"
        case 118: return "f4"
        case 96: return "f5"
        case 97: return "f6"
        case 98: return "f7"
        case 100: return "f8"
        case 101: return "f9"
        case 109: return "f10"
        case 103: return "f11"
        case 111: return "f12"
        
        // 方向键
        case 126: return "up"
        case 125: return "down"
        case 123: return "left"
        case 124: return "right"
        
        // 特殊键
        case 36: return "return"
        case 48: return "tab"
        case 49: return "space"
        case 53: return "escape"
        case 51: return "delete"
        case 117: return "forwarddelete"
        case 115: return "home"
        case 119: return "end"
        case 116: return "pageup"
        case 121: return "pagedown"
        
        // 标点符号键
        case 24: return "="           // 等号
        case 27: return "-"           // 减号
        case 30: return "]"           // 右方括号
        case 33: return "["           // 左方括号
        case 39: return "'"           // 单引号
        case 41: return ";"           // 分号
        case 42: return "\\"          // 反斜杠
        case 43: return ","           // 逗号
        case 44: return "/"           // 斜杠
        case 47: return "."           // 句号
        case 50: return "`"           // 反引号
        
        // 数字键盘
        case 82: return "keypad0"
        case 83: return "keypad1"
        case 84: return "keypad2"
        case 85: return "keypad3"
        case 86: return "keypad4"
        case 87: return "keypad5"
        case 88: return "keypad6"
        case 89: return "keypad7"
        case 91: return "keypad8"
        case 92: return "keypad9"
        case 65: return "keypadDecimal"
        case 67: return "keypadMultiply"
        case 69: return "keypadPlus"
        case 71: return "keypadClear"
        case 75: return "keypadDivide"
        case 76: return "keypadEnter"
        case 78: return "keypadMinus"
        case 81: return "keypadEquals"
        
        default: 
            // 不支持的键码，静默处理
            return nil
        }
    }
    
    // 修复保存快捷键逻辑 - 使用数组格式存储
    private func saveShortcut() {
        // 直接存储数组到 UserDefaults
        UserDefaults.standard.set(tempModifiers, forKey: "globalShortcutModifiers")
        UserDefaults.standard.set(tempKey, forKey: "globalShortcutKey")
        
        // 为了兼容性，仍然更新 Binding（但使用逗号分隔格式用于显示）
        modifiers = tempModifiers.joined(separator: ",")
        key = tempKey
        
        isPresented = false
        
        // 通知HotkeyManager更新快捷键
        NotificationCenter.default.post(name: NSNotification.Name("ShortcutChanged"), object: nil)
        
        // 快捷键已保存
    }
    
    // MARK: - 快捷键冲突检测
    
    /// 检查当前快捷键是否有冲突
    private func checkForConflicts() {
        guard !tempModifiers.isEmpty && !tempKey.isEmpty else { return }
        
        let result = HotkeyManager.shared.checkShortcutConflict(modifiers: tempModifiers, key: tempKey)
        
        DispatchQueue.main.async {
            if result.hasConflict {
                self.conflictInfo = (hasConflict: true, message: result.conflictInfo)
                self.suggestedShortcuts = HotkeyManager.shared.suggestAlternativeShortcuts(
                    basedOn: self.tempModifiers, 
                    originalKey: self.tempKey
                )
                self.showConflictWarning = true
                // 检测到冲突
            } else {
                self.conflictInfo = (hasConflict: false, message: nil)
                self.suggestedShortcuts = []
                self.showConflictWarning = false
                // 快捷键无冲突
            }
        }
    }
    
    /// 检查冲突并保存快捷键
    private func checkConflictAndSave() {
        guard !tempModifiers.isEmpty && !tempKey.isEmpty else { return }
        
        let result = HotkeyManager.shared.checkShortcutConflict(modifiers: tempModifiers, key: tempKey)
        
        if result.hasConflict {
            // 显示冲突警告，让用户选择
            conflictInfo = (hasConflict: true, message: result.conflictInfo)
            suggestedShortcuts = HotkeyManager.shared.suggestAlternativeShortcuts(
                basedOn: tempModifiers, 
                originalKey: tempKey
            )
            showConflictWarning = true
            
            // 显示确认对话框
            let alert = NSAlert()
            alert.messageText = "快捷键冲突"
            alert.informativeText = """
            快捷键 \(HotkeyManager.shared.getShortcutDisplayName(modifiers: tempModifiers, key: tempKey)) 已被占用。
            
            \(result.conflictInfo ?? "")
            
            您可以：
            1. 选择建议的替代快捷键
            2. 强制保存（可能无法正常工作）
            3. 取消并重新设置
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "取消")
            alert.addButton(withTitle: "强制保存")
            
            let response = alert.runModal()
            
            if response == .alertSecondButtonReturn {
                // 用户选择强制保存
                saveShortcut()
            }
            // 否则保持在编辑状态，显示建议
        } else {
            // 无冲突，直接保存
            saveShortcut()
        }
    }
}

// 预览
struct ModernSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernSettingsView()
            .environmentObject(ClipboardManager.shared)
    }
}