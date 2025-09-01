import Foundation
import SwiftUI
import AppKit

// MARK: - String Extensions
extension String {
    // 四字符代码转换
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in self.utf16 {
            result = (result << 8) | FourCharCode(char & 0xFF)
        }
        return result
    }
    
    // 安全的子字符串
    func safeSubstring(to index: Int) -> String {
        guard index <= self.count else { return self }
        return String(self.prefix(index))
    }
    
    // 检查是否为URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return NSWorkspace.shared.urlForApplication(toOpen: url) != nil
    }
    
    // 检查是否为文件路径
    var isFilePath: Bool {
        return hasPrefix("/") || hasPrefix("~") || hasPrefix("file://")
    }
    
    // 检查是否为JSON
    var isJSON: Bool {
        guard let data = self.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }
    
    // 移除多余的空白字符
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Data Extensions
extension Data {
    // 转换为人类可读的大小
    var humanReadableSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self.count))
    }
}

// MARK: - Date Extensions
extension Date {
    // 相对时间格式
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // 格式化时间
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = style
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}

// MARK: - NSImage Extensions
extension NSImage {
    // 调整图片大小
    func resized(to size: NSSize) -> NSImage? {
        let image = NSImage(size: size)
        image.lockFocus()
        
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high
        
        self.draw(in: NSRect(origin: .zero, size: size),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        
        image.unlockFocus()
        return image
    }
    
    // 生成缩略图
    var thumbnail: NSImage? {
        return resized(to: NSSize(width: 64, height: 64))
    }
    
    // 转换为Data
    var pngData: Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}

// MARK: - NSPasteboard Extensions
extension NSPasteboard {
    // 获取所有可用的类型
    var availableTypes: [NSPasteboard.PasteboardType] {
        return types ?? []
    }
    
    // 检查是否包含文本
    var hasString: Bool {
        return string(forType: .string) != nil
    }
    
    // 检查是否包含图片
    var hasImage: Bool {
        return availableTypes.contains(.tiff) || availableTypes.contains(.png)
    }
    
    // 检查是否包含文件URL
    var hasFileURL: Bool {
        return availableTypes.contains(.fileURL)
    }
    
    // 获取内容摘要
    var contentSummary: String {
        if let string = string(forType: .string) {
            return string.safeSubstring(to: 100) + (string.count > 100 ? "..." : "")
        } else if hasImage {
            return "[图片内容]"
        } else if hasFileURL {
            return "[文件路径]"
        } else {
            return "[未知内容]"
        }
    }
}

// MARK: - Color Extensions
extension Color {
    // 从十六进制字符串创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // 转换为十六进制字符串
    var hexString: String? {
        guard let components = NSColor(self).cgColor.components,
              components.count >= 3 else { return nil }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - View Extensions
extension View {
    // 条件修饰符
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // 添加边框
    func border(_ color: Color, width: CGFloat, cornerRadius: CGFloat) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
            )
    }
    
    // 阴影
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // 震动反馈
    func hapticFeedback(_ style: NSHapticFeedbackManager.FeedbackPattern = .generic) -> some View {
        self.onTapGesture {
            NSHapticFeedbackManager.defaultPerformer.perform(style, performanceTime: .default)
        }
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    // 安全获取对象
    func object<T: Codable>(forKey key: String, type: T.Type) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // 安全设置对象
    func setObject<T: Codable>(_ object: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        set(data, forKey: key)
    }
}

// MARK: - NSApplication Extensions
extension NSApplication {
    // 获取应用版本
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    // 获取构建版本
    var buildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    // 重启应用
    func restart() {
        let url = Bundle.main.bundleURL
        let path = "/usr/bin/open"
        let arguments = [url.path]
        
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        
        task.launch()
        NSApp.terminate(self)
    }
}

// MARK: - NSWindow Extensions
extension NSWindow {
    // 居中显示
    func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let windowRect = frame
        
        let x = screenRect.midX - windowRect.width / 2
        let y = screenRect.midY - windowRect.height / 2
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    // 在鼠标位置显示
    func showAtMouseLocation() {
        let mouseLocation = NSEvent.mouseLocation
        let windowSize = frame.size
        
        var origin = NSPoint(
            x: mouseLocation.x - windowSize.width / 2,
            y: mouseLocation.y - windowSize.height / 2
        )
        
        // 确保窗口在屏幕内
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            if origin.x < screenFrame.minX {
                origin.x = screenFrame.minX + 20
            }
            if origin.x + windowSize.width > screenFrame.maxX {
                origin.x = screenFrame.maxX - windowSize.width - 20
            }
            if origin.y < screenFrame.minY {
                origin.y = screenFrame.minY + 20
            }
            if origin.y + windowSize.height > screenFrame.maxY {
                origin.y = screenFrame.maxY - windowSize.height - 20
            }
        }
        
        setFrameOrigin(origin)
    }
}

// MARK: - Bundle Extensions
extension Bundle {
    // 获取应用名称
    var appName: String {
        return infoDictionary?["CFBundleName"] as? String ?? "ClipMaster"
    }
    
    // 获取应用标识符
    var appBundleID: String {
        return bundleIdentifier ?? "com.clipmaster.app"
    }
}