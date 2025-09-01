import Foundation
import AppKit

// 剪贴板监控服务
class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let checkInterval: TimeInterval = 0.5
    private weak var delegate: ClipboardMonitorDelegate?
    
    init(delegate: ClipboardMonitorDelegate? = nil) {
        self.lastChangeCount = NSPasteboard.general.changeCount
        self.delegate = delegate
    }
    
    // 开始监控
    func startMonitoring() {
        print("🎯 开始监控剪贴板...")
        
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        
        // 确保timer在主线程运行
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    // 停止监控
    func stopMonitoring() {
        print("⏹ 停止监控剪贴板")
        timer?.invalidate()
        timer = nil
    }
    
    // 检查剪贴板变化
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // 检测到变化
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // 创建剪贴板项目
            if let item = ClipboardItem.from(pasteboard: pasteboard) {
                delegate?.clipboardMonitor(self, didDetectNewItem: item)
                print("📋 检测到新内容: \(item.contentType.rawValue)")
            }
        }
    }
    
}

// 监控委托协议
protocol ClipboardMonitorDelegate: AnyObject {
    func clipboardMonitor(_ monitor: ClipboardMonitor, didDetectNewItem item: ClipboardItem)
}