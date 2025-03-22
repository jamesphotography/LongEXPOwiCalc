import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    @AppStorage("selectedNDFilters") private var selectedNDFiltersData: Data = Data()
    @AppStorage("maxApertureIndex") var maxApertureIndex: Int = 5 // Default: f/5.6
    @AppStorage("minUsableApertureIndex") var minUsableApertureIndex: Int = 11 // Default: f/8
    @AppStorage("lowestNativeISO") var lowestNativeISO: Int = 100
    @AppStorage("maxUsableISO") var maxUsableISO: Int = 400
    @AppStorage("isoStepSize") var isoStepSize: Double = 1.0/3.0
    @AppStorage("enableExtendedISO") var enableExtendedISO: Bool = true
    @AppStorage("calculationMode") var calculationMode: CalculationMode = .none
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    
    @Published var selectedNDFilters: Set<String> = []
    
    // Camera settings arrays
    let maxApertures = [1.4, 1.6, 1.8, 2.0, 2.4, 2.8, 3.2, 3.5, 4, 4.5, 5, 5.6, 6.3, 7.1, 8, 9, 10, 11, 13, 14, 16, 18, 20, 22]
    let lowestNativeISOOptions = [64, 100, 200]
    let maxUsableISOOptions = [200, 400, 800, 1600]
    let allISOValues = [32, 40, 50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800, 1000, 1250, 1600]
    
    init() {
        loadSelectedNDFilters()
        validateSettings()
    }
    
    func completeFirstLaunch() {
        isFirstLaunch = false
    }
    
    private func loadSelectedNDFilters() {
        if let decoded = try? JSONDecoder().decode(Set<String>.self, from: selectedNDFiltersData) {
            selectedNDFilters = decoded
        }
    }
    
    func saveSelectedNDFilters(_ filters: Set<String>) {
        selectedNDFilters = filters
        if let encoded = try? JSONEncoder().encode(filters) {
            selectedNDFiltersData = encoded
        }
        printSettings()
    }
    
    func validateSettings() {
        // Validate aperture settings
        if minUsableApertureIndex < maxApertureIndex {
            minUsableApertureIndex = maxApertureIndex
        }
        
        // Validate ISO settings
        if lowestNativeISO > maxUsableISO {
            lowestNativeISO = lowestNativeISOOptions.first(where: { $0 <= maxUsableISO }) ?? lowestNativeISOOptions[0]
        }
    }
    
    func getAvailableApertures() -> [Double] {
        return Array(maxApertures[maxApertureIndex...minUsableApertureIndex])
    }
    
    func getAvailableISOs() -> [Int] {
        var startIndex: Int
        if enableExtendedISO {
            startIndex = allISOValues.firstIndex(where: { $0 >= lowestNativeISO / 2 }) ?? 0
        } else {
            startIndex = allISOValues.firstIndex(where: { $0 >= lowestNativeISO }) ?? 0
        }
        
        let endIndex = allISOValues.lastIndex(where: { $0 <= maxUsableISO }) ?? (allISOValues.count - 1)
        
        let availableISOs = Array(allISOValues[startIndex...endIndex])
        
        if isoStepSize == 1.0 {
            return availableISOs.filter { $0 == 100 || $0.isMultiple(of: 200) }
        } else {
            return availableISOs
        }
    }
    
    func printSettings() {
        print("User Settings:")
        print("Max Aperture: f/\(String(format: "%.1f", maxApertures[maxApertureIndex]))")
        print("Min Usable Aperture: f/\(String(format: "%.1f", maxApertures[minUsableApertureIndex]))")
        print("Lowest Native ISO: \(lowestNativeISO)")
        print("Max Usable ISO: \(maxUsableISO)")
        print("ISO Step Size: \(isoStepSize == 1.0 ? "1 stop" : "1/3 stop")")
        print("Extended ISO Enabled: \(enableExtendedISO ? "Yes" : "No")")
        print("Calculation Mode: \(calculationMode.rawValue.capitalized)")
        print("Selected ND Filters: \(selectedNDFilters.joined(separator: ", "))")
        
        print("\nAvailable Aperture Values:")
        print(getAvailableApertures().map { String(format: "f/%.1f", $0) }.joined(separator: ", "))
        
        print("\nAvailable ISO Values:")
        print(getAvailableISOs().map { String($0) }.joined(separator: ", "))
    }
}

// MARK: - Settings-related Extensions
extension SettingsManager {
    var isAnyNDFilterSelected: Bool {
        !selectedNDFilters.isEmpty
    }
    
    var hasValidSettings: Bool {
        isAnyNDFilterSelected &&
        maxApertureIndex < minUsableApertureIndex &&
        lowestNativeISO <= maxUsableISO
    }
    
    func resetToDefaults() {
        maxApertureIndex = 5
        minUsableApertureIndex = 11
        lowestNativeISO = 100
        maxUsableISO = 400
        isoStepSize = 1.0/3.0
        enableExtendedISO = true
        calculationMode = .none
        selectedNDFilters.removeAll()
        
        // Save the empty ND filters set
        if let encoded = try? JSONEncoder().encode(selectedNDFilters) {
            selectedNDFiltersData = encoded
        }
    }
}
