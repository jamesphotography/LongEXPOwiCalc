import SwiftUI

struct StandardCalculatorView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var shutterSpeedIndex = 19
    @State private var selectedNDFilters: Set<String> = [] // Initialize as empty set
    @State private var result = ""
    @State private var showAlert = false
    @State private var showCountdownView = false
    @State private var countdownSeconds: Int = 0
    @State private var showNoFiltersSelectedAlert = false
    
    let shutterSpeeds = ["1/8000", "1/4000","1/3200","1/2500", "1/2000","1/1600","1/1250", "1/1000", "1/800", "1/640", "1/500", "1/400","1/320", "1/250", "1/200", "1/160", "1/125", "1/100", "1/80","1/60","1/50","1/40","1/30","1/25","1/20", "1/15","1/13", "1/10","1/8","1/6", "1/5","1/4","1/3","1/2.5","1/2","1/1.6", "1/1.3", "1"]
    
    var sortedNDFilters: [String] {
        settingsManager.selectedNDFilters.sorted { (filter1, filter2) -> Bool in
            let stops1 = getStops(from: filter1)
            let stops2 = getStops(from: filter2)
            if stops1 == stops2 {
                return getNDValue(from: filter1) < getNDValue(from: filter2)
            }
            return stops1 < stops2
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Shutter Speed")) {
                Picker("Shutter Speed", selection: $shutterSpeedIndex) {
                    ForEach(0..<shutterSpeeds.count, id: \.self) {
                        Text(self.shutterSpeeds[$0])
                    }
                }
                .pickerStyle(DefaultPickerStyle())
            }
            
            Section(header: Text("Available ND Filters")) {
                if sortedNDFilters.isEmpty {
                    Text("No Filters Selected")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sortedNDFilters, id: \.self) { filter in
                        Toggle(isOn: Binding(
                            get: { self.selectedNDFilters.contains(filter) },
                            set: { isSelected in
                                if isSelected {
                                    if self.selectedNDFilters.count < 2 {
                                        self.selectedNDFilters.insert(filter)
                                    } else {
                                        showAlert = true
                                    }
                                } else {
                                    self.selectedNDFilters.remove(filter)
                                }
                            }
                        )) {
                            NDFilterLabel(filter: filter)
                        }
                    }
                }
            }
            
            Section {
                Button(action: calculateExposure) {
                    Text("Calculate")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            if !result.isEmpty {
                Section(header: Text("Result")) {
                    Text(result)
                        .font(.headline)
                    
                    if countdownSeconds > 0 {
                        Button(action: {
                            showCountdownView = true
                        }) {
                            Text("Start Countdown Timer")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .navigationTitle("ND Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading:
            Image("ND OWL")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        )
        .onAppear {
            // Keep selectedNDFilters empty, no sync with settings
        }
        .onChange(of: settingsManager.selectedNDFilters) { newValue in
            // Keep selectedNDFilters empty when settingsManager filters change
            selectedNDFilters = []
        }
        .alert("Maximum Filters Selected", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only select up to 2 ND filters. Please deselect one before selecting another.")
        }
        .alert("No Filters Selected", isPresented: $showNoFiltersSelectedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please select at least one ND filter before calculating.")
        }
        .sheet(isPresented: $showCountdownView) {
            CountdownView(seconds: countdownSeconds)
        }
    }
    
    func calculateExposure() {
        if selectedNDFilters.isEmpty {
            showNoFiltersSelectedAlert = true
            return
        }
        
        let initialSpeed = parseShutterSpeed(shutterSpeeds[shutterSpeedIndex])
        let totalStops = selectedNDFilters.reduce(0.0) { total, filter in
            return total + getStops(from: filter)
        }
        
        let newExposureTime = initialSpeed * pow(2, totalStops)
        let finalExposureTime = newExposureTime
        
        let formattedTime: String
        if finalExposureTime >= 60 {
            let minutes = Int(finalExposureTime) / 60
            let seconds = Int(finalExposureTime) % 60
            formattedTime = String(format: NSLocalizedString("%dm %ds", comment: ""), minutes, seconds)
        } else if finalExposureTime < 1 {
            // 对于小于1秒的情况，保留一位小数
            formattedTime = String(format: NSLocalizedString("%.1fs", comment: ""), finalExposureTime)
        } else {
            // 对于1秒到60秒之间的情况
            if finalExposureTime.truncatingRemainder(dividingBy: 1) == 0 {
                formattedTime = String(format: NSLocalizedString("%ds", comment: ""), Int(finalExposureTime))
            } else {
                formattedTime = String(format: NSLocalizedString("%.1fs", comment: ""), finalExposureTime)
            }
        }
        
        result = String(format: NSLocalizedString("Initial: %@\nND Filters: %@\nNew Exposure Time: %@",
                                              comment: "Calculation result format"),
                       shutterSpeeds[shutterSpeedIndex],
                       selectedNDFilters.joined(separator: " + "),
                       formattedTime)
        
        countdownSeconds = Int(ceil(finalExposureTime))
    }
    
    // Other functions remain unchanged...
    func getStops(from filter: String) -> Double {
        let ndFilterMap: [String: Double] = [
            "ND8": 3.0, "ND16": 4.0, "ND32": 5.0, "ND64": 6.0, "ND128": 7.0,
            "ND256": 8.0, "ND1000": 10.0, "ND4000": 12.0, "ND6400": 13.0, "ND64000": 16.0
        ]
        
        let components = filter.split(separator: " ")
        if let ndValue = components.first.map(String.init) {
            return ndFilterMap[ndValue] ?? 0.0
        }
        return 0.0
    }
    
    func getNDValue(from filter: String) -> Int {
        let components = filter.split(separator: " ")
        if !components.isEmpty {
            let ndPart = components[0].dropFirst(2)
            return Int(ndPart) ?? 0
        }
        return 0
    }
    
    func parseShutterSpeed(_ speed: String) -> Double {
        if speed.contains("/") {
            let parts = speed.split(separator: "/")
            if parts.count == 2,
               let numerator = Double(parts[0]),
               let denominator = Double(parts[1]) {
                return numerator / denominator
            }
        } else if let value = Double(speed) {
            return value
        }
        return 1.0
    }
    
    func formatExposureTime(_ seconds: Double) -> String {
        if seconds >= 60 {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else if seconds.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%ds", Int(seconds))
        } else {
            return String(format: "%.1fs", seconds)
        }
    }
}

struct StandardCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StandardCalculatorView()
                .environmentObject(SettingsManager())
        }
    }
}
