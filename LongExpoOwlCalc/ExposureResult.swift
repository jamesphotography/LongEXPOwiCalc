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
            return String(format: NSLocalizedString("%dm %ds", comment: "Time format"), minutes, remainingSeconds)
        } else if shutterSeconds.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: NSLocalizedString("%ds", comment: "Time format"), Int(shutterSeconds))
        } else {
            return String(format: NSLocalizedString("%.1fs", comment: "Time format"), shutterSeconds)
        }
    }
    
    // 格式化滤镜组合
    var formattedNDFilters: String {
        return ndFilters.joined(separator: " + ")
    }
    
    // 获取适合的摄影效果
    var photographyEffect: String {
        if shutterSeconds <= 1 {
            return NSLocalizedString("Subtle Motion Blur", comment: "Photography effect for exposures up to 1 second")
        } else if shutterSeconds <= 5 {
            return NSLocalizedString("Waterfall/Stream Effect", comment: "Photography effect for exposures up to 5 seconds")
        } else if shutterSeconds <= 15 {
            return NSLocalizedString("Wave Streaking Effect", comment: "Photography effect for exposures up to 15 seconds")
        } else if shutterSeconds <= 30 {
            return NSLocalizedString("Misty Water Effect", comment: "Photography effect for exposures up to 30 seconds")
        } else if shutterSeconds <= 60 {
            return NSLocalizedString("Crowd Removal Effect", comment: "Photography effect for exposures up to 60 seconds")
        } else if shutterSeconds <= 120 {
            return NSLocalizedString("Fog Effect", comment: "Photography effect for exposures up to 120 seconds")
        } else {
            return NSLocalizedString("Minimalist Landscape", comment: "Photography effect for exposures over 120 seconds")
        }
    }
}
