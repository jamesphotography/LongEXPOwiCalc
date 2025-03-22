import SwiftUI

struct ResultPopupView: View {
    let result: ExposureResult
    let countdownSeconds: Int
    let originalAperture: Double
    let originalISO: Int
    var onClose: () -> Void
    var onStartCountdown: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onClose()
                }
            
            // 结果卡片
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text(NSLocalizedString("Calculation Result", comment: "Title for result popup"))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 22))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.1))
                
                // 内容区
                ScrollView {
                    VStack(spacing: 20) {
                        // 推荐滤镜卡片
                        VStack(spacing: 5) {
                            Text(NSLocalizedString("Recommended Filters", comment: "Heading for filter recommendations"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Text(result.formattedNDFilters)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // 目标曝光时间卡片
                        VStack(spacing: 5) {
                            Text(NSLocalizedString("Target Exposure Time", comment: "Heading for exposure time"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            HStack {
                                Image(systemName: "stopwatch.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 20))
                                
                                Text(result.formattedShutterSpeed)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            
                            // 显示适合的摄影效果
                            Text(NSLocalizedString("Suitable for: %@", comment: "Label for photography effect suggestion").replacingOccurrences(of: "%@", with: result.photographyEffect))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal)
                        
                        // 相机设置卡片
                        VStack(spacing: 5) {
                            Text(NSLocalizedString("Camera Settings", comment: "Heading for camera settings"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            VStack(spacing: 15) {
                                // 光圈设置
                                HStack(spacing: 20) {
                                    Text(NSLocalizedString("Aperture", comment: "Label for aperture setting"))
                                        .font(.headline)
                                        .frame(width: 40, alignment: .leading)
                                    
                                    if originalAperture != result.aperture {
                                        HStack(spacing: 8) {
                                            Text(String(format: "f/%.1f", originalAperture))
                                                .strikethrough()
                                                .foregroundColor(.secondary)
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                            
                                            Text(String(format: "f/%.1f", result.aperture))
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        }
                                        .padding(8)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(6)
                                    } else {
                                        Text(String(format: "f/%.1f", result.aperture))
                                            .font(.body)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // ISO设置
                                HStack(spacing: 20) {
                                    Text("ISO")
                                        .font(.headline)
                                        .frame(width: 40, alignment: .leading)
                                    
                                    if originalISO != result.iso {
                                        HStack(spacing: 8) {
                                            Text("\(originalISO)")
                                                .strikethrough()
                                                .foregroundColor(.secondary)
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                            
                                            Text("\(result.iso)")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        }
                                        .padding(8)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(6)
                                    } else {
                                        Text("\(result.iso)")
                                            .font(.body)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // 警告区域（如果有）
                        if result.warningLevel != .none, let warningMessage = result.warningMessage {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: result.warningLevel.icon)
                                        .foregroundColor(result.warningLevel.color)
                                    
                                    Text(result.warningLevel == .info ? NSLocalizedString("Note", comment: "Title for information level warning") : NSLocalizedString("Warning", comment: "Title for warning level alert"))
                                        .font(.headline)
                                        .foregroundColor(result.warningLevel.color)
                                }
                                
                                Text(warningMessage)
                                    .font(.subheadline)
                                
                                if let suggestion = result.suggestion {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(NSLocalizedString("Suggestions:", comment: "Heading for suggestions"))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(suggestion)
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
                            .padding(.horizontal)
                        }
                        
                        // 倒计时按钮
                        if countdownSeconds > 0 {
                            Button(action: onStartCountdown) {
                                HStack {
                                    Image(systemName: "timer")
                                        .font(.headline)
                                    Text(NSLocalizedString("Start Exposure", comment: "Button to start exposure countdown"))
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 4)
            .padding(24)
            .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 400))
            .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
        }
    }
}
