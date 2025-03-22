import SwiftUI
import SafariServices
import WebKit

// 广告启动页视图
struct SplashAdView: View {
    @State private var timeRemaining = 10
    @State private var canSkip = false
    @State private var timer: Timer? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 广告图片背景
            Image("lensbook") // 使用应用中的图片资源
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // 倒计时和跳过按钮
                HStack {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 36, height: 36)
                            .opacity(0.7)
                        
                        Text("\(timeRemaining)")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(8)
                    
                    if canSkip {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("跳过广告")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(16)
                        }
                        .padding(.trailing, 12)
                    }
                }
                .padding(.bottom, 30)
            }
            
            // 添加"了解更多"按钮，点击时打开网站
            VStack {
                Spacer()
                
                Button(action: {
                    openWebsite()
                }) {
                    Text("了解更多")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            // 启动计时器
            startTimer()
            
            // 3秒后允许跳过
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                canSkip = true
            }
        }
        .onDisappear {
            // 清理计时器
            timer?.invalidate()
            timer = nil
        }
    }
    
    // 启动倒计时
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                dismiss()
            }
        }
    }
    
    // 打开网站
    private func openWebsite() {
        if let url = URL(string: "https://lensbook.jamesphotography.com.au/") {
            UIApplication.shared.open(url)
        }
    }
}

// Safari网页视图（如果想在应用内打开网页可以使用）
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
        // 无需更新
    }
}
