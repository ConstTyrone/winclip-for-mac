import SwiftUI
import AppKit

// 剪贴板项目行组件
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 内容图标或图片缩略图
            Group {
                if item.contentType == .image, let image = NSImage(data: item.content) {
                    // 显示图片缩略图
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                        )
                } else {
                    // 显示类型图标
                    Text(item.contentType.icon)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // 内容信息
            VStack(alignment: .leading, spacing: 4) {
                // 内容预览
                HStack {
                    Text(item.preview)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                // 元信息
                HStack(spacing: 12) {
                    // 时间戳
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(item.formattedTime)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // 来源应用
                    HStack(spacing: 4) {
                        Image(systemName: "app")
                            .font(.caption2)
                        Text(item.sourceApp)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 使用次数（如果大于0）
                    if item.useCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                            Text("\(item.useCount)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            // 右侧操作区域 - 固定布局避免偏移
            HStack(spacing: 8) {
                // 固定状态图标
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .frame(width: 16, height: 16)
                }
                
                // 更多操作按钮 - 固定位置
                Menu {
                    Button("复制") {
                        item.copyToPasteboard()
                    }
                    
                    Button(item.isPinned ? "取消固定" : "固定") {
                        ClipboardManager.shared.togglePin(item)
                    }
                    
                    Divider()
                    
                    Button("删除") {
                        ClipboardManager.shared.deleteItem(item)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .menuStyle(.borderlessButton)
                .opacity(isHovered || isSelected ? 1.0 : 0.3)  // 使用透明度而非显示/隐藏
                .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
            .frame(width: 60)  // 固定宽度避免布局变化
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
    
    // 背景颜色
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.2)
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor)
        } else {
            return Color.clear
        }
    }
}

// 预览组件
struct ClipboardItemPreview: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text(item.contentType.icon)
                    .font(.title2)
                
                Text(item.contentType.rawValue.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Text(item.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 内容预览
            Group {
                switch item.contentType {
                case .image:
                    if let image = NSImage(data: item.content) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                    
                case .code:
                    if let code = item.plainText {
                        ScrollView {
                            Text(code)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 300)
                    }
                    
                case .json:
                    if let json = item.plainText {
                        ScrollView {
                            Text(formatJSON(json))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 300)
                    }
                    
                default:
                    if let text = item.plainText {
                        ScrollView {
                            Text(text)
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            
            // 操作按钮
            HStack {
                Button("粘贴") {
                    ClipboardManager.shared.pasteItem(item)
                }
                .buttonStyle(.borderedProminent)
                
                Button("复制") {
                    item.copyToPasteboard()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(item.isPinned ? "取消固定" : "固定") {
                    ClipboardManager.shared.togglePin(item)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 400, alignment: .leading)
    }
    
    // 格式化JSON
    private func formatJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let formattedString = String(data: formatted, encoding: .utf8) else {
            return jsonString
        }
        return formattedString
    }
}