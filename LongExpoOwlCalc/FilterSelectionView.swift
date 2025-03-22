import SwiftUI

struct FilterSelectionView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode
    
    let ndFilters = [
        "ND8 (3 stops)", "ND16 (4 stops)", "ND32 (5 stops)",
        "ND64 (6 stops)", "ND128 (7 stops)", "ND256 (8 stops)",
        "ND1000 (10 stops)", "ND4000 (12 stops)", "ND6400 (13 stops)",
        "ND64000 (16 stops)"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Your ND Filters")) {
                    ForEach(ndFilters, id: \.self) { filter in
                        Toggle(isOn: Binding(
                            get: { self.settingsManager.selectedNDFilters.contains(filter) },
                            set: { newValue in
                                if newValue {
                                    self.settingsManager.selectedNDFilters.insert(filter)
                                } else {
                                    self.settingsManager.selectedNDFilters.remove(filter)
                                }
                            }
                        )) {
                            Text(filter)
                        }
                    }
                }
            }
            .navigationTitle("Select ND Filters")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
