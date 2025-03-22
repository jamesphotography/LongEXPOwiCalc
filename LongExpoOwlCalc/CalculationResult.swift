import SwiftUI

// 用于解析和显示计算结果的辅助结构体
struct CalculationResult {
    var ndFilters: String = ""
    var aperture: String = ""
    var iso: String = ""
    var shutterSpeed: String = ""
    var warningLevel: WarningLevel = .none
    var warningMessage: String = ""
    var suggestion: String = ""
    
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
    
    // 从字符串解析计算结果
    init(from resultString: String) {
        print("CalculationResult 初始化, 解析结果字符串:")
        print(resultString)
        
        let lines = resultString.components(separatedBy: "\n")
        
        // 解析基本结果
        for line in lines {
            if line.starts(with: "ND Filters:") || line.starts(with: "滤镜：") {
                ndFilters = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                print("解析到滤镜: \(ndFilters)")
            } else if line.starts(with: "Aperture:") || line.starts(with: "光圈：") {
                let components = line.components(separatedBy: ",")
                if components.count > 0 {
                    aperture = components[0].components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                    print("解析到光圈: \(aperture)")
                }
                if components.count > 1 {
                    iso = components[1].trimmingCharacters(in: .whitespaces)
                    print("解析到ISO: \(iso)")
                }
            } else if line.starts(with: "Shutter Speed:") || line.starts(with: "快门速度：") {
                shutterSpeed = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                print("解析到快门速度: \(shutterSpeed)")
            }
        }
        
        // 解析警告信息
        if resultString.contains("Note:") || resultString.contains("提示:") {
            warningLevel = .info
            if let range = resultString.range(of: "Note:") ?? resultString.range(of: "提示:") {
                let warningText = resultString[range.upperBound...].trimmingCharacters(in: .whitespaces)
                warningMessage = warningText.components(separatedBy: "\n").first ?? ""
                print("解析到提示信息: \(warningMessage)")
            }
        } else if resultString.contains("Warning:") || resultString.contains("警告:") {
            warningLevel = .warning
            if let range = resultString.range(of: "Warning:") ?? resultString.range(of: "警告:") {
                let warningText = resultString[range.upperBound...].trimmingCharacters(in: .whitespaces)
                warningMessage = warningText.components(separatedBy: "\n").first ?? ""
                print("解析到警告信息: \(warningMessage)")
            }
            
            // 提取建议
            if resultString.contains("Suggestions:") || resultString.contains("建议:") {
                if let range = resultString.range(of: "Suggestions:") ?? resultString.range(of: "建议:") {
                    suggestion = resultString[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    print("解析到建议: \(suggestion)")
                }
            }
        }
        
        print("CalculationResult 解析完成:")
        print("- 滤镜: \(ndFilters)")
        print("- 光圈: \(aperture)")
        print("- ISO: \(iso)")
        print("- 快门速度: \(shutterSpeed)")
        print("- 警告级别: \(warningLevel)")
    }
}

// 结果展示视图组件
struct ResultDisplayView: View {
    let result: CalculationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 主要结果区
            VStack(spacing: 12) {
                // 滤镜信息
                HStack(alignment: .center) {
                    Image(systemName: "camera.filters")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("滤镜")
                        .font(.headline)
                        .frame(width: 60, alignment: .leading)
                    
                    Text(result.ndFilters)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                // 相机设置
                HStack(alignment: .center) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("相机设置")
                        .font(.headline)
                        .frame(width: 60, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.aperture)
                            .font(.body)
                        Text(result.iso)
                            .font(.body)
                    }
                }
                
                Divider()
                
                // 曝光时间
                HStack(alignment: .center) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("曝光时间")
                        .font(.headline)
                        .frame(width: 60, alignment: .leading)
                    
                    Text(result.shutterSpeed)
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            )
            
            // 警告区域（如果有）
            if result.warningLevel != .none {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: result.warningLevel.icon)
                            .foregroundColor(result.warningLevel.color)
                        
                        Text(result.warningLevel == .info ? "提示" : "警告")
                            .font(.headline)
                            .foregroundColor(result.warningLevel.color)
                    }
                    
                    Text(result.warningMessage)
                        .font(.subheadline)
                    
                    if !result.suggestion.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("建议:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(result.suggestion)
                                .font(.subheadline)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(result.warningLevel.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(result.warningLevel.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}
