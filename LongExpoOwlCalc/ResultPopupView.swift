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
                    Text("计算结果")
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
                            Text("推荐使用滤镜")
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
                            Text("目标曝光时间")
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
                            Text("适合：\(result.photographyEffect)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal)
                        
                        // 相机设置卡片
                        VStack(spacing: 5) {
                            Text("相机设置调整")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            VStack(spacing: 15) {
                                // 光圈设置
                                HStack(spacing: 20) {
                                    Text("光圈")
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
                                    
                                    Text(result.warningLevel == .info ? "提示" : "警告")
                                        .font(.headline)
                                        .foregroundColor(result.warningLevel.color)
                                }
                                
                                Text(warningMessage)
                                    .font(.subheadline)
                                
                                if let suggestion = result.suggestion {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("建议:")
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
                                    Text("开始曝光")
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
