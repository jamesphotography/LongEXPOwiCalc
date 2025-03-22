import SwiftUI

// NDFilterLabel 视图组件定义
struct NDFilterLabel: View {
    let filter: String
    
    var body: some View {
        HStack(spacing: 2) {
            let components = filter.split(separator: " ")
            if components.count > 1 {
                let number = String(components[0].dropFirst(2))
                let rest = components[1...]
                
                Text("ND").foregroundColor(.secondary)
                if shouldBeBold(number) {
                    Text(number).bold()
                } else {
                    Text(number)
                }
                Text(" " + rest.joined(separator: " ")).foregroundColor(.secondary)
            } else {
                Text(filter)
            }
        }
    }
    
    private func shouldBeBold(_ number: String) -> Bool {
        return ["8", "64", "1000"].contains(number)
    }
}

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode
    @State private var localSelectedNDFilters: Set<String> = []
    @State private var localMaxApertureIndex: Int = 5
    @State private var localMinUsableApertureIndex: Int = 10
    @State private var localLowestNativeISO: Int = 100
    @State private var localMaxUsableISO: Int = 400
    @State private var localISOStepSize: Double = 1.0
    @State private var localEnableExtendedISO: Bool = true
    @State private var localCalculationMode: CalculationMode = .none
    @State private var showRestartAlert = false
    @State private var shouldQuitApp = false
    
    let ndFilters = ["ND8 (3 stops)", "ND16 (4 stops)", "ND32 (5 stops)", "ND64 (6 stops)", "ND128 (7 stops)", "ND256 (8 stops)", "ND1000 (10 stops)", "ND4000 (12 stops)", "ND6400 (13 stops)", "ND12800 (14 stops)", "ND25600 (15 stops)", "ND64000 (16 stops)"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("CALCULATION MODE Ver 1.3")) {
                    Picker("Adjustment Priority", selection: $localCalculationMode) {
                        Text("Auto (Both)").tag(CalculationMode.none)
                        Text("Aperture Priority").tag(CalculationMode.aperture)
                        Text("ISO Priority").tag(CalculationMode.iso)
                    }
                }
                
                Section(header: Text("APERTURE SETTINGS")) {
                    Picker("Max Aperture", selection: $localMaxApertureIndex) {
                        ForEach(0..<settingsManager.maxApertures.count, id: \.self) {
                            Text(String(format: "f/%.1f", self.settingsManager.maxApertures[$0]))
                        }
                    }
                    
                    Picker("Min Usable Aperture", selection: $localMinUsableApertureIndex) {
                        ForEach(localMaxApertureIndex..<settingsManager.maxApertures.count, id: \.self) {
                            Text(String(format: "f/%.1f", self.settingsManager.maxApertures[$0]))
                        }
                    }
                }
                
                Section(header: Text("ISO SETTINGS")) {
                    Picker("Lowest Native ISO", selection: $localLowestNativeISO) {
                        ForEach(settingsManager.lowestNativeISOOptions, id: \.self) { iso in
                            Text("ISO \(iso)")
                        }
                    }
                    
                    Picker("Max Usable ISO", selection: $localMaxUsableISO) {
                        ForEach(settingsManager.maxUsableISOOptions, id: \.self) { iso in
                            Text("ISO \(iso)")
                        }
                    }
                    
                    Picker("ISO Step Size", selection: $localISOStepSize) {
                        Text("1 stop").tag(1.0)
                        Text("1/3 stop").tag(1.0/3.0)
                    }
                    
                    Toggle("Enable Extended ISO", isOn: $localEnableExtendedISO)
                }
                
                Section(header: Text("ND FILTERS")) {
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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveSettings()
                }
            )
            .alert("Settings saved", isPresented: $showRestartAlert) {
                Button("Restart Now", role: .destructive) {
                    exit(0)  // 强制退出应用
                }
                Button("Later", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Please restart the app for settings to take effect")
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        localSelectedNDFilters = settingsManager.selectedNDFilters
        localMaxApertureIndex = settingsManager.maxApertureIndex
        localMinUsableApertureIndex = settingsManager.minUsableApertureIndex
        localLowestNativeISO = settingsManager.lowestNativeISO
        localMaxUsableISO = settingsManager.maxUsableISO
        localISOStepSize = settingsManager.isoStepSize
        localEnableExtendedISO = settingsManager.enableExtendedISO
        localCalculationMode = settingsManager.calculationMode
    }
    
    private func saveSettings() {
        // 检查设置是否有变化
        let hasChanges = localSelectedNDFilters != settingsManager.selectedNDFilters ||
            localMaxApertureIndex != settingsManager.maxApertureIndex ||
            localMinUsableApertureIndex != settingsManager.minUsableApertureIndex ||
            localLowestNativeISO != settingsManager.lowestNativeISO ||
            localMaxUsableISO != settingsManager.maxUsableISO ||
            localISOStepSize != settingsManager.isoStepSize ||
            localEnableExtendedISO != settingsManager.enableExtendedISO ||
            localCalculationMode != settingsManager.calculationMode
        
        // 保存所有设置
        settingsManager.saveSelectedNDFilters(localSelectedNDFilters)
        settingsManager.maxApertureIndex = localMaxApertureIndex
        settingsManager.minUsableApertureIndex = localMinUsableApertureIndex
        settingsManager.lowestNativeISO = localLowestNativeISO
        settingsManager.maxUsableISO = localMaxUsableISO
        settingsManager.isoStepSize = localISOStepSize
        settingsManager.enableExtendedISO = localEnableExtendedISO
        settingsManager.calculationMode = localCalculationMode
        
        // 如果设置有变化，显示重启提示
        if hasChanges {
            showRestartAlert = true
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// 预览
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsManager())
    }
}
