import Foundation
import AppKit

// 内容类型枚举
enum ContentType: String, Codable {
    case plainText = "text"
    case richText = "rich_text"
    case image = "image"
    case file = "file"
    case url = "url"
    case code = "code"
    case color = "color"
    case json = "json"
    case markdown = "markdown"
    
    var icon: String {
        switch self {
        case .plainText, .richText: return "📝"
        case .image: return "🖼️"
        case .file: return "📁"
        case .url: return "🔗"
        case .code: return "💻"
        case .color: return "🎨"
        case .json: return "📊"
        case .markdown: return "📑"
        }
    }
    
    // 智能检测内容类型
    static func detect(from string: String) -> ContentType {
        // URL检测
        if string.hasPrefix("http://") || string.hasPrefix("https://") || 
           string.contains(".com") || string.contains(".org") {
            return .url
        }
        
        // 文件路径检测
        if string.hasPrefix("/") || string.hasPrefix("~") {
            return .file
        }
        
        // JSON检测
        if (string.hasPrefix("{") && string.hasSuffix("}")) ||
           (string.hasPrefix("[") && string.hasSuffix("]")) {
            return .json
        }
        
        // Markdown检测
        if string.contains("```") || string.hasPrefix("#") || 
           string.contains("**") || string.contains("- [ ]") {
            return .markdown
        }
        
        // 代码检测（简单规则）
        if string.contains("function") || string.contains("class") ||
           string.contains("import") || string.contains("const") ||
           string.contains("let") || string.contains("var") {
            return .code
        }
        
        // 颜色值检测
        if string.hasPrefix("#") && string.count == 7 {
            return .color
        }
        
        return .plainText
    }
}

// 剪贴板项目模型
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: Data
    let plainText: String?
    let contentType: ContentType
    let sourceApp: String
    let sourceAppIcon: Data?
    let timestamp: Date
    var isPinned: Bool
    var tags: [String]
    var useCount: Int
    
    // 计算属性
    var displayText: String {
        if let text = plainText {
            return text
        } else if contentType == .image {
            return "[图片]"
        } else if contentType == .file {
            return "[文件]"
        }
        return "[未知内容]"
    }
    
    var preview: String {
        guard let text = plainText else { return displayText }
        
        // 限制预览长度
        let maxLength = 200
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
    }
    
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // 初始化
    init(content: Data,
         plainText: String?,
         contentType: ContentType,
         sourceApp: String,
         sourceAppIcon: Data? = nil,
         timestamp: Date = Date(),
         isPinned: Bool = false,
         tags: [String] = [],
         useCount: Int = 0) {
        self.id = UUID()
        self.content = content
        self.plainText = plainText
        self.contentType = contentType
        self.sourceApp = sourceApp
        self.sourceAppIcon = sourceAppIcon
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.tags = tags
        self.useCount = useCount
    }
    
    // 从NSPasteboard创建
    static func from(pasteboard: NSPasteboard) -> ClipboardItem? {
        // 获取源应用
        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        
        // 尝试获取文本内容
        if let string = pasteboard.string(forType: .string) {
            let contentType = ContentType.detect(from: string)
            let data = string.data(using: .utf8) ?? Data()
            
            return ClipboardItem(
                content: data,
                plainText: string,
                contentType: contentType,
                sourceApp: sourceApp
            )
        }
        
        // 尝试获取图片内容
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
           let tiffData = image.tiffRepresentation {
            return ClipboardItem(
                content: tiffData,
                plainText: nil,
                contentType: .image,
                sourceApp: sourceApp
            )
        }
        
        // 尝试获取文件URL
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstURL = urls.first {
            let data = firstURL.absoluteString.data(using: .utf8) ?? Data()
            return ClipboardItem(
                content: data,
                plainText: firstURL.path,
                contentType: .file,
                sourceApp: sourceApp
            )
        }
        
        return nil
    }
    
    // 复制到剪贴板
    func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch contentType {
        case .plainText, .richText, .code, .json, .markdown:
            if let text = plainText {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let image = NSImage(data: content) {
                // 清除剪贴板并写入图片数据
                pasteboard.clearContents()
                
                // 尝试多种图片格式以确保兼容性
                if let tiffData = image.tiffRepresentation {
                    pasteboard.setData(tiffData, forType: .tiff)
                }
                
                // 同时写入NSImage对象以支持更多应用
                pasteboard.writeObjects([image])
                
                print("✅ 图片已复制到剪贴板 (大小: \(content.count) bytes)")
            } else {
                print("❌ 无法处理图片数据")
            }
        case .url:
            if let urlString = plainText, let url = URL(string: urlString) {
                pasteboard.writeObjects([url as NSURL])
            }
        case .file:
            if let path = plainText, let url = URL(string: "file://\(path)") {
                pasteboard.writeObjects([url as NSURL])
            }
        case .color:
            if let text = plainText {
                pasteboard.setString(text, forType: .string)
            }
        }
    }
}