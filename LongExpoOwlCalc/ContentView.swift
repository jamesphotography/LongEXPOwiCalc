import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var shutterSpeedIndex = 19 // Default to 1/160
    @State private var apertureIndex = 12.0 // Default to f/11 (index 12)
    @State private var isoIndex = 3.0 // Default to ISO 64 (index 3)
    @State private var exposureTimeIndex = 15.0 // Default to 30 seconds (index 15)
    @State private var calculationResult = ""
    @State private var showCountdownView = false
    @State private var countdownSeconds: Int = 0
    @State private var showSettingsView = false
    @State private var showNoFilterAlert = false
    
    let shutterSpeeds = ["1/8000", "1/4000","1/3200","1/2500", "1/2000","1/1600","1/1250", "1/1000", "1/800", "1/640", "1/500", "1/400","1/320", "1/250", "1/200", "1/160", "1/125", "1/100", "1/80","1/60","1/50","1/40","1/30","1/25","1/20", "1/15","1/13", "1/10","1/8","1/6", "1/5","1/4","1/3","1/2.5","1/2","1/1.6", "1/1.3", "1"]
    let apertures = [1.4, 1.6, 1.8, 2.0, 2.4, 2.8, 3.2, 3.5, 4, 4.5, 5, 5.6, 6.3, 7.1, 8, 9, 10, 11, 13, 14, 16]
    let isoValues = [32, 40, 50, 64, 80, 100, 125, 160, 200, 250, 320, 400]
    let exposureTimes = [1, 1.3, 1.6, 2, 2.5, 3, 4, 5, 6, 8, 10, 13, 15, 20, 25, 30, 45, 60, 90, 120, 180, 240, 300, 480, 600, 720, 900]
    
    private var availableApertures: [Double] {
        let maxAperture = settingsManager.maxApertures[settingsManager.maxApertureIndex]
        return apertures.filter { $0 >= maxAperture }
    }
    
    var body: some View {
        Form {
            Section(header: Text("CURRENT SETTINGS")) {
                HStack {
                    Image(systemName: "camera.circle")
                    Picker("Shutter Speed", selection: $shutterSpeedIndex) {
                        ForEach(0..<shutterSpeeds.count, id: \.self) {
                            Text(self.shutterSpeeds[$0])
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                HStack {
                    Image(systemName: "camera.aperture")
                    Text("Aperture")
                    Spacer()
                    Slider(value: $apertureIndex, in: 0...Double(availableApertures.count - 1), step: 1)
                    Text("f/\(String(format: "%.1f", availableApertures[Int(apertureIndex)]))")
                }
                
                HStack {
                    Image(systemName: "speedometer")
                    Text("ISO")
                    Spacer()
                    Slider(value: $isoIndex, in: 0...Double(isoValues.count - 1), step: 1)
                    Text("\(isoValues[Int(isoIndex)])")
                }
            }
            
            Section(header: Text("LONG EXPOSURE")) {
                HStack {
                    Image(systemName: "stopwatch")
                    Text("Target")
                    Spacer()
                    Slider(value: $exposureTimeIndex, in: 0...Double(exposureTimes.count - 1), step: 1)
                    Text(formatExposureTime(exposureTimes[Int(exposureTimeIndex)]))
                }
            }
            
            Section {
                Button(action: startCalculation) {
                    Text("Calculate")
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
                
                if !calculationResult.isEmpty {
                    Text(calculationResult)
                        .font(.headline)
                        .padding(.top)
                        .lineLimit(nil)
                    
                    if countdownSeconds > 30 {
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
            return String(format: "%ds", Int(seconds))
        } else {
            return String(format: "%.1fs", seconds)
        }
    }
    
    func startCalculation() {
        if settingsManager.selectedNDFilters.isEmpty {
            showNoFilterAlert = true
        } else {
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
                self.calculationResult = result
                self.countdownSeconds = Int(self.exposureTimes[Int(self.exposureTimeIndex)])
            }
            
            print("Calculation completed, result:\n\(result)")
        }
    }
}
