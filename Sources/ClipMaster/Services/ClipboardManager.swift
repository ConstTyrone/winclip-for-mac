import Foundation
import SwiftUI
import Combine
import AppKit

// 剪贴板管理器（单例）
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    // 发布的属性
    @Published var items: [ClipboardItem] = []
    @Published var selectedCategory = "all"
    @Published var isWindowVisible = false
    
    // 私有属性
    private var monitor: ClipboardMonitor?
    private let storageKey = "ClipboardHistory"
    private var cancellables = Set<AnyCancellable>()
    
    // 性能优化：权限状态缓存
    private var accessibilityPermissionCached: Bool?
    private var lastPermissionCheck: Date = Date.distantPast
    
    // 从用户设置读取的计算属性
    private var maxItems: Int {
        let value = UserDefaults.standard.double(forKey: "maxHistoryItems")
        return value > 0 ? Int(value) : 100  // 默认值100
    }
    
    private var maxHistoryDays: Int {
        let value = UserDefaults.standard.double(forKey: "maxHistoryDays")
        return value > 0 ? Int(value) : 30   // 默认值30天
    }
    
    // 计算属性：过滤后的项目
    var filteredItems: [ClipboardItem] {
        var filtered = items
        
        // 按分类过滤
        if selectedCategory != "all" {
            filtered = filtered.filter { item in
                switch selectedCategory {
                case "text": return item.contentType == .plainText || item.contentType == .richText
                case "link": return item.contentType == .url
                case "image": return item.contentType == .image
                case "code": return item.contentType == .code
                case "file": return item.contentType == .file
                default: return true
                }
            }
        }
        
        // 搜索功能已移除 - 专注于分类过滤和直接粘贴
        
        // 固定项目优先，然后按时间排序
        return filtered.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.timestamp > rhs.timestamp
        }
    }
    
    // 固定的项目
    var pinnedItems: [ClipboardItem] {
        items.filter { $0.isPinned }
    }
    
    // 最近的项目（用于菜单栏快速访问）
    var recentItems: [ClipboardItem] {
        Array(filteredItems.prefix(5))
    }
    
    private init() {
        loadItems()
        cleanupExpiredItems()     // 启动时清理过期项目
        enforceItemLimit()        // 启动时执行数量限制
        setupAutoSave()
    }
    
    // 开始监控
    func startMonitoring() {
        monitor = ClipboardMonitor(delegate: self)
        monitor?.startMonitoring()
    }
    
    // 停止监控
    func stopMonitoring() {
        monitor?.stopMonitoring()
        monitor = nil
    }
    
    // 添加新项目
    func addItem(_ item: ClipboardItem) {
        // 检查是否已存在相同内容（改进的去重逻辑）
        if let existingIndex = items.firstIndex(where: { isDuplicateItem($0, item) }) {
            // 更新使用次数和时间戳
            var updatedItem = items[existingIndex]
            updatedItem.useCount += 1
            items[existingIndex] = ClipboardItem(
                content: updatedItem.content,
                plainText: updatedItem.plainText,
                contentType: updatedItem.contentType,
                sourceApp: item.sourceApp,
                sourceAppIcon: updatedItem.sourceAppIcon,
                timestamp: Date(),
                isPinned: updatedItem.isPinned,
                tags: updatedItem.tags,
                useCount: updatedItem.useCount + 1
            )
            
            // 移到最前面
            let movedItem = items.remove(at: existingIndex)
            items.insert(movedItem, at: 0)
        } else {
            // 添加新项目
            items.insert(item, at: 0)
            print("📋 添加新剪贴板项目: \(item.contentType.rawValue) - \(item.displayText.prefix(50))")
        }
        
        // 添加项目后执行清理
        cleanupExpiredItems()
        enforceItemLimit()
    }
    
    // 改进的重复检测逻辑
    private func isDuplicateItem(_ existing: ClipboardItem, _ new: ClipboardItem) -> Bool {
        // 内容类型必须相同
        guard existing.contentType == new.contentType else { return false }
        
        switch new.contentType {
        case .image:
            // 对于图片，比较实际数据内容
            return existing.content == new.content
        default:
            // 对于文本类型，比较plainText
            return existing.plainText == new.plainText && existing.plainText != nil
        }
    }
    
    // 删除项目
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }
    
    // 切换固定状态
    func togglePin(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
        }
    }
    
    // 清除所有历史（保留固定项）
    func clearHistory() {
        items = items.filter { $0.isPinned }
    }
    
    // 粘贴项目到用户目标应用（性能优化版本）
    func pasteItem(_ item: ClipboardItem) {
        // 更新使用次数
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].useCount += 1
        }
        
        // 复制到剪贴板
        item.copyToPasteboard()
        
        // 获取用户的真实目标应用
        let targetApp = HotkeyManager.shared.getTargetApplication()
        let currentFrontmostApp = NSWorkspace.shared.frontmostApplication
        
        if let app = targetApp {
            // 检查目标应用是否已经是前台应用
            let isAlreadyFrontmost = app.bundleIdentifier == currentFrontmostApp?.bundleIdentifier
            
            if !isAlreadyFrontmost {
                // 需要激活应用
                app.activate(options: .activateIgnoringOtherApps)
                print("✅ 激活用户目标应用: \(app.localizedName ?? "Unknown")")
            }
            
            // 智能延迟：已激活的应用几乎无延迟，新激活的应用适度延迟
            let delay: TimeInterval
            if isAlreadyFrontmost {
                // 应用已激活，最小延迟
                delay = item.contentType == .image ? 0.05 : 0.02
            } else {
                // 需要激活应用，减少但保留必要延迟
                delay = item.contentType == .image ? 0.15 : 0.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.simulatePasteOptimized(for: item.contentType)
                if item.contentType == .image {
                    self.showPasteNotification(for: item)
                }
            }
        } else {
            print("⚠️ 没有记录目标应用，使用前台应用")
            // 降级方案：使用当前前台应用，减少延迟
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.simulatePasteOptimized(for: item.contentType)
            }
        }
    }
    
    // 模拟Cmd+V粘贴 - 根据内容类型优化
    private func simulatePaste(for contentType: ContentType) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // 检查辅助功能权限
        guard checkAccessibilityPermission() else {
            print("❌ 缺少辅助功能权限，无法模拟粘贴操作")
            return
        }
        
        // 创建Cmd+V事件
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        
        // 发送事件
        keyDown?.post(tap: .cghidEventTap)
        
        // 对于图片，添加一个小延迟确保事件处理完成
        if contentType == .image {
            usleep(10000) // 10ms
        }
        
        keyUp?.post(tap: .cghidEventTap)
        
        print("✅ 已模拟粘贴操作 (\(contentType.rawValue))")
    }
    
    // 优化后的粘贴模拟 - 使用权限缓存
    private func simulatePasteOptimized(for contentType: ContentType) {
        // 使用缓存的权限检查结果
        guard checkAccessibilityPermissionCached() else {
            print("❌ 缺少辅助功能权限，无法模拟粘贴操作")
            return
        }
        
        let source = CGEventSource(stateID: .hidSystemState)
        
        // 创建Cmd+V事件
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        
        // 发送事件
        keyDown?.post(tap: .cghidEventTap)
        
        // 对于图片，添加一个小延迟确保事件处理完成（减少到5ms）
        if contentType == .image {
            usleep(5000) // 5ms instead of 10ms
        }
        
        keyUp?.post(tap: .cghidEventTap)
        
        print("⚡ 已快速模拟粘贴操作 (\(contentType.rawValue))")
    }
    
    // 缓存的权限检查 - 避免重复系统调用
    private func checkAccessibilityPermissionCached() -> Bool {
        let now = Date()
        
        // 如果距离上次检查超过10秒或者没有缓存，重新检查
        if accessibilityPermissionCached == nil || now.timeIntervalSince(lastPermissionCheck) > 10 {
            accessibilityPermissionCached = checkAccessibilityPermission()
            lastPermissionCheck = now
            print("🔄 刷新权限缓存: \(accessibilityPermissionCached! ? "已授权" : "未授权")")
        }
        
        return accessibilityPermissionCached ?? false
    }
    
    // 显示粘贴通知
    private func showPasteNotification(for item: ClipboardItem) {
        // 使用系统音效
        NSSound.beep()
        
        // 使用系统通知 (osascript)
        let script = """
        display notification "已粘贴 \(item.contentType.icon) \(item.contentType.rawValue)" with title "ClipMaster"
        """
        
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", script]
            process.launch()
        }
    }
    
    // 恢复原来应用的焦点
    private func restoreOriginalAppFocus() {
        if let bundleId = UserDefaults.standard.string(forKey: "LastActiveApp") {
            // 尝试通过Bundle ID激活应用
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first {
                app.activate(options: .activateIgnoringOtherApps)
                print("✅ 已恢复应用焦点: \(app.localizedName ?? bundleId)")
                return
            }
        }
        
        // 如果没有记录的应用，尝试激活最近的非ClipMaster应用
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.activationPolicy == .regular && 
               app.bundleIdentifier != Bundle.main.bundleIdentifier &&
               !app.isTerminated {
                app.activate(options: .activateIgnoringOtherApps)
                print("✅ 已激活最近的应用: \(app.localizedName ?? "Unknown")")
                return
            }
        }
        
        print("⚠️ 无法找到要恢复焦点的应用")
    }
    
    // 检查辅助功能权限
    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // 加载保存的项目
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            self.items = decoded
            print("✅ 加载了 \(items.count) 条历史记录")
        }
    }
    
    // 保存项目
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    // 设置自动保存
    private func setupAutoSave() {
        $items
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveItems()
            }
            .store(in: &cancellables)
    }
    // MARK: - 存储清理功能
    
    /// 清理过期的剪贴板项目（基于maxHistoryDays设置）
    private func cleanupExpiredItems() {
        let daysToKeep = maxHistoryDays
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysToKeep, to: Date()) ?? Date.distantPast
        
        let initialCount = items.count
        
        // 只删除非固定的过期项目
        items.removeAll { item in
            !item.isPinned && item.timestamp < cutoffDate
        }
        
        let removedCount = initialCount - items.count
        if removedCount > 0 {
            print("🧹 清理了 \(removedCount) 条过期记录（超过 \(daysToKeep) 天）")
        }
    }
    
    /// 执行数量限制（基于maxHistoryItems设置）
    private func enforceItemLimit() {
        let maxAllowedItems = maxItems
        let pinnedCount = pinnedItems.count
        
        // 如果固定项目数量已经超过或等于最大限制，只保留固定项目
        if pinnedCount >= maxAllowedItems {
            let unpinnedItems = items.filter { !$0.isPinned }
            if !unpinnedItems.isEmpty {
                items.removeAll { !$0.isPinned }
                print("⚠️ 固定项目数量(\(pinnedCount))已达到或超过最大限制(\(maxAllowedItems))，移除所有非固定项目")
            }
            return
        }
        
        // 正常情况：保持固定项目 + 最新的非固定项目
        if items.count > maxAllowedItems {
            let unpinnedItems = items.filter { !$0.isPinned }
            let allowedUnpinnedCount = maxAllowedItems - pinnedCount
            
            if unpinnedItems.count > allowedUnpinnedCount {
                let itemsToKeep = pinnedItems + Array(unpinnedItems.prefix(allowedUnpinnedCount))
                let removedCount = items.count - itemsToKeep.count
                items = itemsToKeep
                
                print("🧹 执行数量限制：移除了 \(removedCount) 条记录，保留 \(itemsToKeep.count)/\(maxAllowedItems) 条")
            }
        }
    }
}

// 扩展：实现监控委托
extension ClipboardManager: ClipboardMonitorDelegate {
    func clipboardMonitor(_ monitor: ClipboardMonitor, didDetectNewItem item: ClipboardItem) {
        DispatchQueue.main.async {
            self.addItem(item)
        }
    }
}