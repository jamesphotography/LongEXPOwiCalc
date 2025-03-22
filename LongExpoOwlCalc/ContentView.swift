import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var shutterSpeedIndex = 19 // Default to 1/160
    @State private var apertureIndex = 12.0 // Default to f/11 (index 12)
    @State private var isoIndex = 3.0 // Default to ISO 64 (index 3)
    @State private var exposureTimeIndex = 15.0 // Default to 30 seconds (index 15)
    @State private var showCountdownView = false
    @State private var countdownSeconds: Int = 0
    @State private var showSettingsView = false
    @State private var showNoFilterAlert = false
    @State private var showResultPopup = false
    @State private var exposureResult: ExposureResult? = nil
    
    let shutterSpeeds = ["1/8000", "1/4000","1/3200","1/2500", "1/2000","1/1600","1/1250", "1/1000", "1/800", "1/640", "1/500", "1/400","1/320", "1/250", "1/200", "1/160", "1/125", "1/100", "1/80","1/60","1/50","1/40","1/30","1/25","1/20", "1/15","1/13", "1/10","1/8","1/6", "1/5","1/4","1/3","1/2.5","1/2","1/1.6", "1/1.3", "1"]
    let apertures = [1.4, 1.6, 1.8, 2.0, 2.4, 2.8, 3.2, 3.5, 4, 4.5, 5, 5.6, 6.3, 7.1, 8, 9, 10, 11, 13, 14, 16]
    let isoValues = [32, 40, 50, 64, 80, 100, 125, 160, 200, 250, 320, 400]
    let exposureTimes = [1, 1.3, 1.6, 2, 2.5, 3, 4, 5, 6, 8, 10, 13, 15, 20, 25, 30, 45, 60, 90, 120, 180, 240, 300, 480, 600, 720, 900]
    
    // 常用曝光时间预设及其用途
    let exposureTimePresets: [(time: Double, index: Int, name: String, usage: String)] = [
        (1, 0, "1秒", "海浪拉丝"),
        (5, 8, "5秒", "流水/瀑布"),
        (15, 12, "15秒", "海浪雾化"),
        (30, 15, "30秒", "海浪雾化"),
        (60, 17, "1分钟", "人流消失"),
        (120, 19, "2分钟", "浓雾效果"),
        (300, 22, "5分钟", "极简风景")
    ]
    
    // 选择显示哪些曝光时间作为标记
    private var exposureTimeMarks: [Double] {
        return [1, 5, 15, 30, 60, 120, 300]
    }
    
    private var availableApertures: [Double] {
        let maxAperture = settingsManager.maxApertures[settingsManager.maxApertureIndex]
        return apertures.filter { $0 >= maxAperture }
    }
    
    // 选择显示哪些光圈值作为标记
    private var apertureMarks: [Double] {
        let marks = [1.4, 2.8, 5.6, 8, 11, 16]
        return marks.filter { availableApertures.contains($0) }
    }
    
    // 选择显示哪些ISO值作为标记
    private var isoMarks: [Int] {
        return [32, 64, 100, 200, 400]
    }
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("当前设置").frame(maxWidth: .infinity, alignment: .center)) {
                    HStack {
                        Image(systemName: "camera.circle")
                        Picker("Shutter Speed", selection: $shutterSpeedIndex) {
                            ForEach(0..<shutterSpeeds.count, id: \.self) {
                                Text(self.shutterSpeeds[$0])
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "camera.aperture")
                            Text("Aperture")
                            Spacer()
                            Text("f/\(String(format: "%.1f", availableApertures[Int(apertureIndex)]))")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Button(action: {
                                withAnimation {
                                    if apertureIndex > 0 {
                                        apertureIndex -= 1
                                    }
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Slider(value: $apertureIndex, in: 0...Double(availableApertures.count - 1), step: 1)
                            
                            Button(action: {
                                withAnimation {
                                    if apertureIndex < Double(availableApertures.count - 1) {
                                        apertureIndex += 1
                                    }
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        // 显示刻度标记
                        GeometryReader { geometry in
                            ZStack(alignment: .top) {
                                ForEach(apertureMarks, id: \.self) { mark in
                                    if let index = availableApertures.firstIndex(of: mark) {
                                        VStack {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.5))
                                                .frame(width: 1, height: 8)
                                            
                                            Text("f/\(String(format: "%.1f", mark))")
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray)
                                                .fixedSize()
                                        }
                                        .position(
                                            x: markPosition(for: Double(index), in: 0...Double(availableApertures.count - 1), width: geometry.size.width - 32),
                                            y: 6
                                        )
                                    }
                                }
                            }
                            .frame(height: 20)
                        }
                        .frame(height: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "speedometer")
                            Text("ISO")
                            Spacer()
                            Text("\(isoValues[Int(isoIndex)])")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Button(action: {
                                withAnimation {
                                    if isoIndex > 0 {
                                        isoIndex -= 1
                                    }
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Slider(value: $isoIndex, in: 0...Double(isoValues.count - 1), step: 1)
                            
                            Button(action: {
                                withAnimation {
                                    if isoIndex < Double(isoValues.count - 1) {
                                        isoIndex += 1
                                    }
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        // 显示刻度标记
                        GeometryReader { geometry in
                            ZStack(alignment: .top) {
                                ForEach(isoMarks, id: \.self) { mark in
                                    if let index = isoValues.firstIndex(of: mark) {
                                        VStack {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.5))
                                                .frame(width: 1, height: 8)
                                            
                                            Text("\(mark)")
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray)
                                                .fixedSize()
                                        }
                                        .position(
                                            x: markPosition(for: Double(index), in: 0...Double(isoValues.count - 1), width: geometry.size.width - 32),
                                            y: 6
                                        )
                                    }
                                }
                            }
                            .frame(height: 20)
                        }
                        .frame(height: 20)
                    }
                }
                
                Section(header: Text("长曝光").frame(maxWidth: .infinity, alignment: .center)) {
                    // 曝光时间显示
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "stopwatch")
                            Text("目标曝光时间")
                            Spacer()
                            Text(formatExposureTime(exposureTimes[Int(exposureTimeIndex)]))
                                .fontWeight(.medium)
                        }
                        
                        // 常用曝光时间预设按钮
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(exposureTimePresets, id: \.index) { preset in
                                    Button(action: {
                                        withAnimation {
                                            exposureTimeIndex = Double(preset.index)
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(preset.name)
                                                .font(.system(size: 12, weight: .medium))
                                            Text(preset.usage)
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Int(exposureTimeIndex) == preset.index ?
                                                      Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Int(exposureTimeIndex) == preset.index ?
                                                        Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        
                        HStack {
                            Button(action: {
                                withAnimation {
                                    if exposureTimeIndex > 0 {
                                        exposureTimeIndex -= 1
                                    }
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Slider(value: $exposureTimeIndex, in: 0...Double(exposureTimes.count - 1), step: 1)
                            
                            Button(action: {
                                withAnimation {
                                    if exposureTimeIndex < Double(exposureTimes.count - 1) {
                                        exposureTimeIndex += 1
                                    }
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        // 显示刻度标记
                        GeometryReader { geometry in
                            ZStack(alignment: .top) {
                                ForEach(exposureTimeMarks, id: \.self) { mark in
                                    if let index = exposureTimes.firstIndex(of: mark) {
                                        VStack {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.5))
                                                .frame(width: 1, height: 8)
                                            
                                            Text(formatExposureTime(mark))
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray)
                                                .fixedSize()
                                        }
                                        .position(
                                            x: markPosition(for: Double(index), in: 0...Double(exposureTimes.count - 1), width: geometry.size.width - 32),
                                            y: 6
                                        )
                                    }
                                }
                            }
                            .frame(height: 20)
                        }
                        .frame(height: 20)
                    }
                }
                
                Section {
                    Button(action: startCalculation) {
                        Text("计算")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if !settingsManager.selectedNDFilters.isEmpty {
                        Text(String(format: NSLocalizedString("My Filters: %@", comment: ""), selectedNDFiltersString))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(String(format: NSLocalizedString("Calculation Mode: %@, ISO Step: %@, Extended ISO: %@",
                                                              comment: ""),
                                    settingsManager.calculationMode == .none ? NSLocalizedString("Auto", comment: "") : settingsManager.calculationMode.rawValue.capitalized,
                                    settingsManager.isoStepSize == 1.0 ? NSLocalizedString("1 stop", comment: "") : NSLocalizedString("1/3 stop", comment: ""),
                                    settingsManager.enableExtendedISO ? NSLocalizedString("On", comment: "") : NSLocalizedString("Off", comment: "")
                        ))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Pro Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Image("ND OWL")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24),
                trailing: Button(action: {
                    showSettingsView = true
                }) {
                    Image(systemName: "gear")
                }
            )
            .onAppear {
                if settingsManager.selectedNDFilters.isEmpty {
                    showSettingsView = true
                }
                settingsManager.printSettings()
            }
            .sheet(isPresented: $showCountdownView) {
                CountdownView(seconds: countdownSeconds)
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView().environmentObject(settingsManager)
            }
            .alert(isPresented: $showNoFilterAlert) {
                Alert(
                    title: Text("No ND Filters Selected"),
                    message: Text("You must select the ND filters you own before calculating."),
                    dismissButton: .default(Text("OK")) {
                        showSettingsView = true
                    }
                )
            }
            
            // 结果弹窗
            if showResultPopup, let result = exposureResult {
                ResultPopupView(
                    result: result,
                    countdownSeconds: countdownSeconds,
                    originalAperture: availableApertures[Int(apertureIndex)],
                    originalISO: isoValues[Int(isoIndex)],
                    onClose: {
                        withAnimation {
                            showResultPopup = false
                        }
                    },
                    onStartCountdown: {
                        showResultPopup = false
                        showCountdownView = true
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
    
    // 计算标记位置的辅助函数
    private func markPosition(for value: Double, in range: ClosedRange<Double>, width: CGFloat) -> CGFloat {
        let availableWidth = width
        let percent = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return 16 + CGFloat(percent) * availableWidth
    }
    
    private var selectedNDFiltersString: String {
        let ndFilterMap: [String: Int] = [
            "ND8": 3, "ND16": 4, "ND32": 5, "ND64": 6, "ND128": 7,
            "ND256": 8, "ND1000": 10, "ND4000": 12, "ND6400": 13, "ND64000": 16
        ]
        
        let sortedFilters = settingsManager.selectedNDFilters.sorted { (filter1, filter2) -> Bool in
            let name1 = filter1.split(separator: " ").first.map(String.init) ?? ""
            let name2 = filter2.split(separator: " ").first.map(String.init) ?? ""
            return ndFilterMap[name1, default: 0] < ndFilterMap[name2, default: 0]
        }
        
        return sortedFilters.compactMap { filter -> String? in
            let components = filter.split(separator: " ")
            if components.count > 1 {
                return String(components[0])
            }
            return nil
        }.joined(separator: ", ")
    }
    
    func formatExposureTime(_ seconds: Double) -> String {
        if seconds >= 60 {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else if seconds.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%d秒", Int(seconds))
        } else {
            return String(format: "%.1f秒", seconds)
        }
    }
    
    func startCalculation() {
        if settingsManager.selectedNDFilters.isEmpty {
            showNoFilterAlert = true
        } else {
            print("计算开始:")
            print("- 原始光圈: f/\(String(format: "%.1f", availableApertures[Int(apertureIndex)]))")
            print("- 原始ISO: \(isoValues[Int(isoIndex)])")
            print("- 原始快门: \(shutterSpeeds[shutterSpeedIndex])")
            print("- 目标曝光时间: \(exposureTimes[Int(exposureTimeIndex)])秒")
            
            let result = ExposureCalculator.calculateExposure(
                shutterSpeed: shutterSpeeds[shutterSpeedIndex],
                aperture: availableApertures[Int(apertureIndex)],
                iso: isoValues[Int(isoIndex)],
                targetExposureTime: exposureTimes[Int(exposureTimeIndex)],
                selectedNDFilters: settingsManager.selectedNDFilters,
                availableApertures: availableApertures,
                availableISOs: isoValues,
                calculationMode: settingsManager.calculationMode,
                isoStepSize: settingsManager.isoStepSize
            )
            
            DispatchQueue.main.async {
                self.exposureResult = result
                self.countdownSeconds = Int(self.exposureTimes[Int(self.exposureTimeIndex)])
                
                print("计算完成，准备显示结果:")
                print("- 推荐滤镜: \(result.formattedNDFilters)")
                print("- 调整后光圈: f/\(String(format: "%.1f", result.aperture))")
                print("- 调整后ISO: \(result.iso)")
                print("- 曝光时间: \(result.formattedShutterSpeed)")
                print("- 倒计时秒数: \(self.countdownSeconds)")
                
                withAnimation {
                    self.showResultPopup = true
                }
            }
        }
    }
}
