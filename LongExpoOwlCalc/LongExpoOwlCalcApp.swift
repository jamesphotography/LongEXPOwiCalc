import SwiftUI
import SafariServices
import WebKit

@main
struct LongExpoOwlCalcApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @State private var selectedTab = 1
    @State private var showInitialSettings = false
    @State private var shouldQuitApp = false
    @State private var showSplashAd = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if settingsManager.isFirstLaunch {
                        InitialSetupView(shouldQuitApp: $shouldQuitApp)
                            .environmentObject(settingsManager)
                    } else {
                        NavigationView {
                            TabView(selection: $selectedTab) {
                                StandardCalculatorView()
                                    .environmentObject(settingsManager)
                                    .tabItem {
                                        Label("ND Calc", systemImage: "calendar")
                                    }
                                    .tag(0)
                                
                                ContentView()
                                    .environmentObject(settingsManager)
                                    .tabItem {
                                        Label("Pro Calc", systemImage: "calendar.badge.clock")
                                    }
                                    .tag(1)
                            }
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .onChange(of: shouldQuitApp) { newValue in
                    if newValue {
                        exit(0)  // 强制退出程序
                    }
                }
                
                // 广告启动页，使用sheet方式呈现
                .fullScreenCover(isPresented: $showSplashAd) {
                    SplashAdView()
                }
            }
        }
    }
}
