import SwiftUI

enum WarningLevel: Int {
    case none = 0
    case info = 1
    case warning = 2
    
    var color: Color {
        switch self {
        case .none: return .primary
        case .info: return .blue
        case .warning: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .none: return ""
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        }
    }
}

struct ExposureResult {
    let ndFilters: [String]
    let aperture: Double
    let iso: Int
    let shutterSeconds: Double
    let warningLevel: WarningLevel
    let warningMessage: String?
    let suggestion: String?
    
    // 格式化曝光时间
    var formattedShutterSpeed: String {
        if shutterSeconds >= 60 {
            let minutes = Int(shutterSeconds) / 60
            let remainingSeconds = Int(shutterSeconds) % 60
            return String(format: "%d分 %d秒", minutes, remainingSeconds)
        } else if shutterSeconds.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%d秒", Int(shutterSeconds))
        } else {
            return String(format: "%.1f秒", shutterSeconds)
        }
    }
    
    // 格式化滤镜组合
    var formattedNDFilters: String {
        return ndFilters.joined(separator: " + ")
    }
    
    // 获取适合的摄影效果
    var photographyEffect: String {
        if shutterSeconds <= 1 {
            return "微运动模糊效果"
        } else if shutterSeconds <= 5 {
            return "流水/瀑布效果"
        } else if shutterSeconds <= 15 {
            return "海浪拉丝效果"
        } else if shutterSeconds <= 30 {
            return "海浪雾化效果"
        } else if shutterSeconds <= 60 {
            return "人流消失效果"
        } else if shutterSeconds <= 120 {
            return "浓雾效果"
        } else {
            return "极简风景效果"
        }
    }
}
