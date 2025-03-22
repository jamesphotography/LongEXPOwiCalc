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
        (1, 0, NSLocalizedString("1 sec", comment: "Preset for 1 second"), NSLocalizedString("Wave Streaking", comment: "Photography style")),
        (5, 8, NSLocalizedString("5 sec", comment: "Preset for 5 seconds"), NSLocalizedString("Waterfall/Stream", comment: "Photography style")),
        (15, 12, NSLocalizedString("15 sec", comment: "Preset for 15 seconds"), NSLocalizedString("Misty Waves", comment: "Photography style")),
        (30, 15, NSLocalizedString("30 sec", comment: "Preset for 30 seconds"), NSLocalizedString("Misty Waves", comment: "Photography style")),
        (60, 17, NSLocalizedString("1 min", comment: "Preset for 1 minute"), NSLocalizedString("Crowd Removal", comment: "Photography style")),
        (120, 19, NSLocalizedString("2 min", comment: "Preset for 2 minutes"), NSLocalizedString("Fog Effect", comment: "Photography style")),
        (300, 22, NSLocalizedString("5 min", comment: "Preset for 5 minutes"), NSLocalizedString("Minimalist", comment: "Photography style"))
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
                Section(header: Text(NSLocalizedString("Current Settings", comment: "Section title for current camera settings")).frame(maxWidth: .infinity, alignment: .center)) {
                    HStack {
                        Image(systemName: "camera.circle")
                        Picker(NSLocalizedString("Shutter Speed", comment: "Label for shutter speed picker"), selection: $shutterSpeedIndex) {
                            ForEach(0..<shutterSpeeds.count, id: \.self) {
                                Text(self.shutterSpeeds[$0])
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "camera.aperture")
                            Text(NSLocalizedString("Aperture", comment: "Label for aperture control"))
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
                
                Section(header: Text(NSLocalizedString("Long Exposure", comment: "Section title for long exposure settings")).frame(maxWidth: .infinity, alignment: .center)) {
                    // 曝光时间显示
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "stopwatch")
                            Text(NSLocalizedString("Target Exposure Time", comment: "Label for target exposure time"))
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
                        Text(NSLocalizedString("Calculate", comment: "Button to calculate exposure"))
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
            .navigationTitle(NSLocalizedString("Pro Calculator", comment: "Navigation title"))
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
                    title: Text(NSLocalizedString("No ND Filters Selected", comment: "Alert title for no filters selected")),
                    message: Text(NSLocalizedString("You must select the ND filters you own before calculating.", comment: "Alert message for no filters selected")),
                    dismissButton: .default(Text(NSLocalizedString("OK", comment: "Alert dismiss button"))) {
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
            return String(format: NSLocalizedString("%d:%02d", comment: "Time format minutes:seconds"), minutes, remainingSeconds)
        } else if seconds.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: NSLocalizedString("%ds", comment: "Time format seconds"), Int(seconds))
        } else {
            return String(format: NSLocalizedString("%.1fs", comment: "Time format decimal seconds"), seconds)
        }
    }
    
    func startCalculation() {
        if settingsManager.selectedNDFilters.isEmpty {
            showNoFilterAlert = true
        } else {
            print(NSLocalizedString("Calculation started:", comment: ""))
            print("- " + NSLocalizedString("Original aperture: f/%.1f", comment: "Log message").replacingOccurrences(of: "%.1f", with: String(format: "%.1f", availableApertures[Int(apertureIndex)])))
            print("- " + NSLocalizedString("Original ISO: %d", comment: "Log message").replacingOccurrences(of: "%d", with: "\(isoValues[Int(isoIndex)])"))
            print("- " + NSLocalizedString("Original shutter speed: %@", comment: "Log message").replacingOccurrences(of: "%@", with: shutterSpeeds[shutterSpeedIndex]))
            print("- " + NSLocalizedString("Target exposure time: %.1f seconds", comment: "Log message").replacingOccurrences(of: "%.1f", with: "\(exposureTimes[Int(exposureTimeIndex)])"))
            
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
                
                print(NSLocalizedString("Calculation completed, ready to show results:", comment: ""))
                print("- " + NSLocalizedString("Recommended filters: %@", comment: "Log message").replacingOccurrences(of: "%@", with: result.formattedNDFilters))
                print("- " + NSLocalizedString("Adjusted aperture: f/%.1f", comment: "Log message").replacingOccurrences(of: "%.1f", with: String(format: "%.1f", result.aperture)))
                print("- " + NSLocalizedString("Adjusted ISO: %d", comment: "Log message").replacingOccurrences(of: "%d", with: "\(result.iso)"))
                print("- " + NSLocalizedString("Exposure time: %@", comment: "Log message").replacingOccurrences(of: "%@", with: result.formattedShutterSpeed))
                print("- " + NSLocalizedString("Countdown seconds: %d", comment: "Log message").replacingOccurrences(of: "%d", with: "\(self.countdownSeconds)"))
                
                withAnimation {
                    self.showResultPopup = true
                }
            }
        }
    }
}
