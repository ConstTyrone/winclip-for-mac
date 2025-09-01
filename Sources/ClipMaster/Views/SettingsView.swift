import SwiftUI
import ServiceManagement
import Foundation

// 备份数据结构
struct ClipMasterBackup: Codable {
    let version: String
    let exportDate: Date
    let items: [ClipboardItem]
    let settings: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case version, exportDate, items, settings
    }
    
    init(version: String, exportDate: Date, items: [ClipboardItem], settings: [String: Any]) {
        self.version = version
        self.exportDate = exportDate
        self.items = items
        self.settings = settings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        exportDate = try container.decode(Date.self, forKey: .exportDate)
        items = try container.decode([ClipboardItem].self, forKey: .items)
        
        // 处理settings的Any类型
        if let settingsData = try? container.decode(Data.self, forKey: .settings),
           let settingsDict = try? JSONSerialization.jsonObject(with: settingsData) as? [String: Any] {
            settings = settingsDict
        } else {
            settings = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(exportDate, forKey: .exportDate)
        try container.encode(items, forKey: .items)
        
        // 将settings转换为Data
        let settingsData = try JSONSerialization.data(withJSONObject: settings)
        try container.encode(settingsData, forKey: .settings)
    }
}

// DateFormatter扩展
extension DateFormatter {
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
    
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

// 设置视图
struct SettingsView: View {
    @EnvironmentObject var manager: ClipboardManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 100.0
    @AppStorage("maxHistoryDays") private var maxHistoryDays = 30.0
    @AppStorage("enableSmartCategories") private var enableSmartCategories = true
    @AppStorage("enableContentSummary") private var enableContentSummary = false
    @AppStorage("enableSimilarMerging") private var enableSimilarMerging = false
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    
    var body: some View {
        TabView {
            // 通用设置
            GeneralSettingsView(
                launchAtLogin: $launchAtLogin,
                showMenuBarIcon: $showMenuBarIcon,
                maxHistoryItems: $maxHistoryItems,
                maxHistoryDays: $maxHistoryDays,
                appearanceMode: $appearanceMode
            )
            .tabItem {
                Label("通用", systemImage: "gearshape")
            }
            
            // 快捷键设置
            HotkeySettingsView()
            .tabItem {
                Label("快捷键", systemImage: "keyboard")
            }
            
            // 智能功能
            IntelligenceSettingsView(
                enableSmartCategories: $enableSmartCategories,
                enableContentSummary: $enableContentSummary,
                enableSimilarMerging: $enableSimilarMerging
            )
            .tabItem {
                Label("智能功能", systemImage: "brain.head.profile")
            }
            
            // 高级设置
            AdvancedSettingsView()
            .tabItem {
                Label("高级", systemImage: "slider.horizontal.3")
            }
        }
        .frame(minWidth: 600, idealWidth: 700, maxWidth: .infinity,
               minHeight: 450, idealHeight: 500, maxHeight: .infinity)
    }
}

// 通用设置
struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var showMenuBarIcon: Bool
    @Binding var maxHistoryItems: Double
    @Binding var maxHistoryDays: Double
    @Binding var appearanceMode: String
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                Toggle("开机自启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        setLaunchAtLogin(enabled)
                    }
                    .help("应用将在系统启动时自动运行")
                
                Toggle("显示菜单栏图标", isOn: $showMenuBarIcon)
                    .help("在菜单栏显示 ClipMaster 图标")
                }
            } header: {
                Label("启动设置", systemImage: "power")
                    .font(.headline)
            }
            
            Section {
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Label("历史记录保存数量", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Text("\(Int(maxHistoryItems)) 条")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.accentColor)
                        }
                        Slider(value: $maxHistoryItems, in: 50...500, step: 50)
                            .accentColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Label("历史记录保存天数", systemImage: "calendar")
                            Spacer()
                            Text("\(Int(maxHistoryDays)) 天")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.accentColor)
                        }
                        Slider(value: $maxHistoryDays, in: 7...90, step: 1)
                            .accentColor(.blue)
                    }
                }
            } header: {
                Label("存储设置", systemImage: "internaldrive")
                    .font(.headline)
            }
            
            Section("外观设置") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("界面主题")
                        .font(.headline)
                    
                    Picker("界面主题", selection: $appearanceMode) {
                        Label("跟随系统", systemImage: "gearshape").tag("system")
                        Label("浅色模式", systemImage: "sun.max").tag("light")
                        Label("深色模式", systemImage: "moon").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: appearanceMode) { newValue in
                        applyAppearanceMode(newValue)
                    }
                    
                    Text("主题更改将在下次启动应用时生效")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        // .formStyle(.grouped) // 需要macOS 13.0+
        .padding()
        .onAppear {
            // 应用当前外观设置
            applyAppearanceMode(appearanceMode)
        }
    }
    
    // 应用外观模式
    private func applyAppearanceMode(_ mode: String) {
        DispatchQueue.main.async {
            switch mode {
            case "light":
                NSApp.appearance = NSAppearance(named: .aqua)
                print("🌞 切换到浅色模式")
            case "dark":
                NSApp.appearance = NSAppearance(named: .darkAqua)
                print("🌙 切换到深色模式")
            default:
                NSApp.appearance = nil  // 跟随系统
                print("⚙️ 跟随系统外观")
            }
        }
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if #available(macOS 13.0, *) {
                // 使用现代ServiceManagement API
                if enabled {
                    try SMAppService.mainApp.register()
                    print("✅ 开机启动已启用")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("✅ 开机启动已禁用")
                }
            } else {
                // macOS 12及以下版本的兼容实现
                let success = SMLoginItemSetEnabled(Bundle.main.bundleIdentifier! as CFString, enabled)
                if success {
                    print("✅ 开机启动设置成功: \(enabled)")
                } else {
                    print("❌ 开机启动设置失败")
                }
            }
        } catch {
            print("❌ 开机启动设置错误: \(error.localizedDescription)")
            // 用户友好的错误提示
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "开机启动设置失败"
                alert.informativeText = "请检查系统权限设置。错误：\(error.localizedDescription)"
                alert.addButton(withTitle: "确定")
                alert.runModal()
            }
        }
    }
}

// 快捷键设置
struct HotkeySettingsView: View {
    var body: some View {
        Form {
            Section("全局快捷键") {
                HStack {
                    Text("打开剪贴板历史")
                    Spacer()
                    Text("⌥V")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(6)
                }
                .padding(.vertical, 4)
                
                Text("推荐使用 Option+V 以获得最佳体验")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("如需更改快捷键，请重新编译应用")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Section("窗口内快捷键") {
                VStack(alignment: .leading, spacing: 8) {
                    HotkeyRow(key: "↑ ↓", description: "上下选择项目")
                    HotkeyRow(key: "Enter", description: "选中并粘贴")
                    HotkeyRow(key: "Space", description: "预览内容")
                    HotkeyRow(key: "⌘ + 数字", description: "快速选择前9项")
                    HotkeyRow(key: "⌘ + D", description: "删除项目")
                    HotkeyRow(key: "⌘ + P", description: "固定/取消固定")
                    HotkeyRow(key: "Tab", description: "切换分类")
                    HotkeyRow(key: "Esc", description: "关闭窗口")
                }
            }
            
            Section("权限说明") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("使用全局快捷键需要以下权限：")
                        .font(.headline)
                    
                    Label("辅助功能权限", systemImage: "hand.raised")
                        .font(.body)
                    Text("用于监听全局快捷键Option+V")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("打开系统偏好设置") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        // .formStyle(.grouped) // 需要macOS 13.0+
        .padding()
    }
}

// 快捷键行组件
struct HotkeyRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(4)
            
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}


// 智能功能设置
struct IntelligenceSettingsView: View {
    @Binding var enableSmartCategories: Bool
    @Binding var enableContentSummary: Bool
    @Binding var enableSimilarMerging: Bool
    
    var body: some View {
        Form {
            Section("智能分类") {
                Toggle("启用智能分类", isOn: $enableSmartCategories)
                Text("自动识别内容类型：代码、JSON、Markdown等")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("内容处理") {
                Toggle("启用内容摘要", isOn: $enableContentSummary)
                Text("为长文本生成摘要（实验性功能）")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("相似内容合并", isOn: $enableSimilarMerging)
                Text("自动合并重复或相似的内容")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("AI模型设置") {
                Picker("处理模式", selection: .constant("local")) {
                    Text("本地处理").tag("local")
                    Text("云端处理（未来）").tag("cloud")
                }
                .disabled(true)
            }
        }
        // .formStyle(.grouped) // 需要macOS 13.0+
        .padding()
    }
}

// 高级设置
struct AdvancedSettingsView: View {
    @EnvironmentObject var manager: ClipboardManager
    @AppStorage("enableDebugMode") private var enableDebugMode = false
    
    var body: some View {
        Form {
            // 数据管理功能
            Section("数据管理") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("当前存储", systemImage: "internaldrive")
                        Spacer()
                        Text("\(manager.items.count) 条记录")
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: 12) {
                        Button("导出数据") {
                            exportData()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("导入数据") {
                            importData()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("清空所有数据") {
                            clearAllData()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.white)
                        .background(Color.red)
                    }
                    
                    Text("导出的数据包含所有剪贴板历史和设置信息")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Section("调试选项") {
                Toggle("启用调试模式", isOn: $enableDebugMode)
                Text("显示详细的日志信息，用于问题排查")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("应用信息") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "版本", value: "1.0.0")
                    InfoRow(title: "构建版本", value: "1")
                    InfoRow(title: "系统要求", value: "macOS 12.0+")
                }
            }
            
            Section("重置选项") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("重置所有设置") {
                        resetAllSettings()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                    
                    Text("这将恢复所有设置为默认值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        // .formStyle(.grouped) // 需要macOS 13.0+
        .padding()
    }
    
    // MARK: - 数据管理方法
    
    private func exportData() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "clipmaster-backup-\(DateFormatter.filenameDateFormatter.string(from: Date())).json"
        savePanel.title = "导出ClipMaster数据"
        savePanel.message = "选择保存位置"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                // 创建导出数据结构
                let exportData = ClipMasterBackup(
                    version: "1.0",
                    exportDate: Date(),
                    items: manager.items,
                    settings: getCurrentSettings()
                )
                
                let jsonData = try JSONEncoder().encode(exportData)
                try jsonData.write(to: url)
                
                // 成功提示
                let alert = NSAlert()
                alert.messageText = "导出成功"
                alert.informativeText = "数据已保存到：\(url.lastPathComponent)"
                alert.addButton(withTitle: "确定")
                alert.alertStyle = .informational
                alert.runModal()
                
                print("✅ 数据导出成功: \(url.path)")
            } catch {
                // 错误提示
                let alert = NSAlert()
                alert.messageText = "导出失败"
                alert.informativeText = "错误信息：\(error.localizedDescription)"
                alert.addButton(withTitle: "确定")
                alert.alertStyle = .critical
                alert.runModal()
                
                print("❌ 数据导出失败: \(error)")
            }
        }
    }
    
    private func importData() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.title = "导入ClipMaster数据"
        openPanel.message = "选择备份文件"
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let jsonData = try Data(contentsOf: url)
                let backupData = try JSONDecoder().decode(ClipMasterBackup.self, from: jsonData)
                
                // 确认导入
                let alert = NSAlert()
                alert.messageText = "确认导入数据？"
                alert.informativeText = """
                备份版本：\(backupData.version)
                导出时间：\(DateFormatter.displayDateFormatter.string(from: backupData.exportDate))
                包含记录：\(backupData.items.count) 条
                
                当前数据将被覆盖，无法恢复。
                """
                alert.addButton(withTitle: "导入")
                alert.addButton(withTitle: "取消")
                alert.alertStyle = .warning
                
                if alert.runModal() == .alertFirstButtonReturn {
                    // 执行导入
                    manager.items = backupData.items
                    applyImportedSettings(backupData.settings)
                    
                    // 成功提示
                    let successAlert = NSAlert()
                    successAlert.messageText = "导入成功"
                    successAlert.informativeText = "已导入 \(backupData.items.count) 条记录"
                    successAlert.addButton(withTitle: "确定")
                    successAlert.alertStyle = .informational
                    successAlert.runModal()
                    
                    print("✅ 数据导入成功: \(backupData.items.count) 条记录")
                }
            } catch {
                // 错误提示
                let alert = NSAlert()
                alert.messageText = "导入失败"
                alert.informativeText = "文件格式不正确或已损坏。错误：\(error.localizedDescription)"
                alert.addButton(withTitle: "确定")
                alert.alertStyle = .critical
                alert.runModal()
                
                print("❌ 数据导入失败: \(error)")
            }
        }
    }
    
    private func clearAllData() {
        let alert = NSAlert()
        alert.messageText = "确认清空所有数据？"
        alert.informativeText = "此操作将删除所有剪贴板历史记录和设置，无法恢复。"
        alert.addButton(withTitle: "清空")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .critical
        
        if alert.runModal() == .alertFirstButtonReturn {
            // 清空数据
            manager.items.removeAll()
            
            // 清空设置（移除隐私相关键）
            let defaults = UserDefaults.standard
            let keys = ["ClipboardHistory", "launchAtLogin", "showMenuBarIcon", 
                       "maxHistoryItems", "maxHistoryDays", "enableSmartCategories",
                       "enableContentSummary", "enableSimilarMerging", "appearanceMode"]
            
            for key in keys {
                defaults.removeObject(forKey: key)
            }
            
            print("✅ 所有数据已清空")
        }
    }
    
    // 获取当前设置（移除隐私相关设置）
    private func getCurrentSettings() -> [String: Any] {
        let defaults = UserDefaults.standard
        return [
            "launchAtLogin": defaults.bool(forKey: "launchAtLogin"),
            "showMenuBarIcon": defaults.bool(forKey: "showMenuBarIcon"),
            "maxHistoryItems": defaults.double(forKey: "maxHistoryItems"),
            "maxHistoryDays": defaults.double(forKey: "maxHistoryDays"),
            "appearanceMode": defaults.string(forKey: "appearanceMode") ?? "system",
            "enableSmartCategories": defaults.bool(forKey: "enableSmartCategories"),
            "enableContentSummary": defaults.bool(forKey: "enableContentSummary"),
            "enableSimilarMerging": defaults.bool(forKey: "enableSimilarMerging")
        ]
    }
    
    // 应用导入的设置（移除隐私相关设置）
    private func applyImportedSettings(_ settings: [String: Any]) {
        let defaults = UserDefaults.standard
        
        if let value = settings["launchAtLogin"] as? Bool {
            defaults.set(value, forKey: "launchAtLogin")
        }
        if let value = settings["showMenuBarIcon"] as? Bool {
            defaults.set(value, forKey: "showMenuBarIcon")
        }
        if let value = settings["maxHistoryItems"] as? Double {
            defaults.set(value, forKey: "maxHistoryItems")
        }
        if let value = settings["maxHistoryDays"] as? Double {
            defaults.set(value, forKey: "maxHistoryDays")
        }
        if let value = settings["appearanceMode"] as? String {
            defaults.set(value, forKey: "appearanceMode")
        }
        if let value = settings["enableSmartCategories"] as? Bool {
            defaults.set(value, forKey: "enableSmartCategories")
        }
        if let value = settings["enableContentSummary"] as? Bool {
            defaults.set(value, forKey: "enableContentSummary")
        }
        if let value = settings["enableSimilarMerging"] as? Bool {
            defaults.set(value, forKey: "enableSimilarMerging")
        }
    }
    
    private func resetAllSettings() {
        let alert = NSAlert()
        alert.messageText = "确认重置所有设置？"
        alert.informativeText = "此操作将恢复所有设置为默认值。"
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            // 重置设置
            let defaults = UserDefaults.standard
            let dict = defaults.dictionaryRepresentation()
            for key in dict.keys {
                if key.hasPrefix("clipmaster") {
                    defaults.removeObject(forKey: key)
                }
            }
        }
    }
}

// 信息行组件
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// 移除KeyboardShortcuts依赖
// 快捷键现在通过Carbon API直接实现