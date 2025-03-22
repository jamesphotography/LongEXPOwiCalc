import SwiftUI

struct InitialSetupView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showAlert = false
    @Binding var shouldQuitApp: Bool
    
    let ndFilters = [
        "ND8 (3 stops)", "ND16 (4 stops)", "ND32 (5 stops)",
        "ND64 (6 stops)", "ND128 (7 stops)", "ND256 (8 stops)",
        "ND1000 (10 stops)", "ND4000 (12 stops)", "ND6400 (13 stops)",
        "ND64000 (16 stops)"
    ]
    
    @State private var localSelectedNDFilters: Set<String> = []
    @State private var localMaxApertureIndex: Int = 5
    @State private var localMinUsableApertureIndex: Int = 11
    @State private var localLowestNativeISO: Int = 100
    @State private var localMaxUsableISO: Int = 400
    @State private var localISOStepSize: Double = 1.0/3.0
    @State private var localEnableExtendedISO: Bool = true
    @State private var localCalculationMode: CalculationMode = .none
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Restart required after initial setup").font(.headline)) {
                    Text("Initial setup is required before first use")
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Required: Select Your ND Filters").font(.headline)) {
                    ForEach(ndFilters, id: \.self) { filter in
                        Toggle(isOn: Binding(
                            get: { self.localSelectedNDFilters.contains(filter) },
                            set: { isSelected in
                                if isSelected {
                                    self.localSelectedNDFilters.insert(filter)
                                } else {
                                    self.localSelectedNDFilters.remove(filter)
                                }
                            }
                        )) {
                            NDFilterLabel(filter: filter)
                        }
                    }
                }
                
                Section(header: Text("Basic Settings").font(.headline)) {
                    Picker("Max Aperture", selection: $localMaxApertureIndex) {
                        ForEach(0..<settingsManager.maxApertures.count, id: \.self) {
                            Text(String(format: "f/%.1f", settingsManager.maxApertures[$0]))
                        }
                    }
                    
                    Picker("Min Usable Aperture", selection: $localMinUsableApertureIndex) {
                        ForEach(localMaxApertureIndex..<settingsManager.maxApertures.count, id: \.self) {
                            Text(String(format: "f/%.1f", settingsManager.maxApertures[$0]))
                        }
                    }
                    
                    Picker("Lowest Native ISO", selection: $localLowestNativeISO) {
                        ForEach(settingsManager.lowestNativeISOOptions, id: \.self) { iso in
                            Text("ISO \(iso)")
                        }
                    }
                    
                    Toggle("Enable Extended ISO", isOn: $localEnableExtendedISO)
                    
                    Picker("ISO Step Size", selection: $localISOStepSize) {
                        Text("1 stop").tag(1.0)
                        Text("1/3 stop").tag(1.0/3.0)
                    }
                }
            }
            .navigationTitle("Initial Setup")
            .navigationBarItems(
                trailing: Button("Done") {
                    if localSelectedNDFilters.isEmpty {
                        showAlert = true
                    } else {
                        saveAndQuit()
                    }
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Select ND Filters"),
                    message: Text("You must select at least one ND filter to continue"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveAndQuit() {
        // Save all settings
        settingsManager.saveSelectedNDFilters(localSelectedNDFilters)
        settingsManager.maxApertureIndex = localMaxApertureIndex
        settingsManager.minUsableApertureIndex = localMinUsableApertureIndex
        settingsManager.lowestNativeISO = localLowestNativeISO
        settingsManager.maxUsableISO = localMaxUsableISO
        settingsManager.isoStepSize = localISOStepSize
        settingsManager.enableExtendedISO = localEnableExtendedISO
        settingsManager.calculationMode = localCalculationMode
        
        // Mark first launch complete
        settingsManager.completeFirstLaunch()
        
        // Trigger app exit
        shouldQuitApp = true
    }
}

#Preview {
    InitialSetupView(shouldQuitApp: .constant(false))
        .environmentObject(SettingsManager())
}
