import Foundation

class ExposureCalculator {
    static func calculateExposure(shutterSpeed: String, aperture: Double, iso: Int, targetExposureTime: Double, selectedNDFilters: Set<String>, availableApertures: [Double], availableISOs: [Int], calculationMode: CalculationMode, isoStepSize: Double) -> String {
        var logOutput = NSLocalizedString("Calculation Process:\n", comment: "")
        logOutput += String(format: NSLocalizedString("Initial Settings: Shutter Speed %@, Aperture f/%.1f, ISO %d\n", comment: ""), shutterSpeed, aperture, iso)
        logOutput += String(format: NSLocalizedString("Target Exposure Time: %.1f seconds\n", comment: ""), targetExposureTime)
        logOutput += String(format: NSLocalizedString("Calculation Mode: %@\n\n", comment: ""), calculationMode == .aperture ? NSLocalizedString("Aperture Priority", comment: "") : calculationMode == .iso ? NSLocalizedString("ISO Priority", comment: "") : NSLocalizedString("Auto", comment: ""))
        
        let stopsDifference = calculateStopsDifference(currentShutterSpeed: shutterSpeed, targetExposureTime: targetExposureTime)
        logOutput += String(format: NSLocalizedString("Total Stops Difference: %d stops (%.2f)\n\n", comment: ""), Int(round(stopsDifference)), stopsDifference)
        
        let (recommendedNDFilters, remainingStops) = recommendNDFilters(stopsDifference: stopsDifference, selectedNDFilters: selectedNDFilters)
        logOutput += String(format: NSLocalizedString("Recommended ND Filter Combination: %@\n", comment: ""), recommendedNDFilters.joined(separator: " + "))
        logOutput += String(format: NSLocalizedString("Remaining Stops After Filters: %d stops (%.2f)\n\n", comment: ""), Int(round(remainingStops)), remainingStops)
        
        var adjustedAperture = aperture
        var adjustedISO = iso
        var finalRemainingStops = remainingStops
        var adjustmentMade = false

        // 如果剩余档数在±0.3范围内，无需调整
        if abs(finalRemainingStops) <= 0.3 {
            logOutput += NSLocalizedString("Remaining stops within acceptable range (±0.3), no adjustment needed\n", comment: "")
        } else {
            switch calculationMode {
            case .aperture: // 光圈优先 - 只调整ISO
                logOutput += NSLocalizedString("Aperture Priority Mode: Adjusting ISO only\n", comment: "")
                if let (newISO, newStops) = adjustISO(currentISO: iso, targetStops: finalRemainingStops, availableISOs: availableISOs, isoStepSize: isoStepSize) {
                    adjustedISO = newISO
                    finalRemainingStops = newStops
                    adjustmentMade = true
                    logOutput += String(format: NSLocalizedString("Adjusted ISO to %d, Remaining Stops: %d (%.2f)\n", comment: ""), adjustedISO, Int(round(finalRemainingStops)), finalRemainingStops)
                }
            
            case .iso: // ISO优先 - 只调整光圈
                logOutput += NSLocalizedString("ISO Priority Mode: Adjusting Aperture only\n", comment: "")
                if let (newAperture, newStops) = adjustAperture(currentAperture: aperture, targetStops: finalRemainingStops, availableApertures: availableApertures) {
                    adjustedAperture = newAperture
                    finalRemainingStops = newStops
                    adjustmentMade = true
                    logOutput += String(format: NSLocalizedString("Adjusted Aperture to f/%.1f, Remaining Stops: %d (%.2f)\n", comment: ""), adjustedAperture, Int(round(finalRemainingStops)), finalRemainingStops)
                }
                
            case .none: // 自动模式 - 同时调整光圈和ISO
                logOutput += NSLocalizedString("Auto Mode: Adjusting both Aperture and ISO\n", comment: "")
                
                // 先尝试调整光圈
                if let (newAperture, newStops) = adjustAperture(currentAperture: aperture, targetStops: finalRemainingStops, availableApertures: availableApertures) {
                    adjustedAperture = newAperture
                    finalRemainingStops = newStops
                    adjustmentMade = true
                    logOutput += String(format: NSLocalizedString("Adjusted Aperture to f/%.1f, Remaining Stops: %d (%.2f)\n", comment: ""), adjustedAperture, Int(round(finalRemainingStops)), finalRemainingStops)
                }
                
                // 如果调整光圈后仍需要调整，则调整ISO
                if abs(finalRemainingStops) > 0.3 {
                    if let (newISO, newStops) = adjustISO(currentISO: iso, targetStops: finalRemainingStops, availableISOs: availableISOs, isoStepSize: isoStepSize) {
                        adjustedISO = newISO
                        finalRemainingStops = newStops
                        adjustmentMade = true
                        logOutput += String(format: NSLocalizedString("Adjusted ISO to %d, Remaining Stops: %d (%.2f)\n", comment: ""), adjustedISO, Int(round(finalRemainingStops)), finalRemainingStops)
                    }
                }
            }
        }
        
        let result = String(format: NSLocalizedString("ND Filters: %@\nAperture: f/%.1f, ISO %d\nShutter Speed: %@",
                                                   comment: "Result format"),
                          recommendedNDFilters.joined(separator: " + "),
                          adjustedAperture,
                          adjustedISO,
                          formatExposureTime(targetExposureTime))
        
        print(logOutput)
        
        if abs(finalRemainingStops) > 0.3 {
            if abs(finalRemainingStops) <= 0.5 {
                return result + String(format: NSLocalizedString("\n\nℹ️ Note: Small exposure difference of %.1f stops", comment: ""), abs(finalRemainingStops))
            } else {
                var warning = String(format: NSLocalizedString("\n\n⚠️ Warning: Exposure difference of %.1f stops", comment: ""), abs(finalRemainingStops))
                warning += NSLocalizedString("\nSuggestions:", comment: "")
                if !adjustmentMade {
                    warning += NSLocalizedString("\n- Try a different ND filter combination", comment: "")
                } else {
                    switch calculationMode {
                    case .aperture:
                        warning += NSLocalizedString("\n- Consider unlocking aperture for more precise exposure", comment: "")
                    case .iso:
                        warning += NSLocalizedString("\n- Consider unlocking ISO for more precise exposure", comment: "")
                    case .none:
                        warning += NSLocalizedString("\n- Try a different ND filter combination", comment: "")
                    }
                }
                return result + warning
            }
        }
        
        return result
    }
    
    static func calculateStopsDifference(currentShutterSpeed: String, targetExposureTime: Double) -> Double {
        let currentExposureTime = parseShutterSpeed(currentShutterSpeed)
        return log2(targetExposureTime / currentExposureTime)
    }
    
    private static func parseShutterSpeed(_ speed: String) -> Double {
        if speed.contains("/") {
            let components = speed.split(separator: "/")
            if components.count == 2, let numerator = Double(components[0]), let denominator = Double(components[1]) {
                return numerator / denominator
            }
        }
        return Double(speed) ?? 1.0
    }
    
    private static func recommendNDFilters(stopsDifference: Double, selectedNDFilters: Set<String>) -> ([String], Double) {
        let ndFilterMap: [String: Double] = [
            "ND8": 3, "ND16": 4, "ND32": 5, "ND64": 6, "ND128": 7,
            "ND256": 8, "ND1000": 10, "ND4000": 12, "ND6400": 13, "ND64000": 16
        ]
        
        let availableFilters = selectedNDFilters.compactMap { filter -> (String, Double)? in
            let filterName = filter.split(separator: " ").first.map(String.init) ?? ""
            if let stops = ndFilterMap[filterName] {
                return (filterName, stops)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
        
        // 尝试找到单个最佳滤镜
        if let bestSingleFilter = availableFilters.first(where: { abs($0.1 - stopsDifference) <= 1.5 }) {
            return ([bestSingleFilter.0], stopsDifference - bestSingleFilter.1)
        }
        
        // 尝试组合
        var bestCombination: [String] = []
        var leastRemainingStops = Double.infinity
        
        for i in 0..<availableFilters.count {
            let filter1 = availableFilters[i]
            if filter1.1 > stopsDifference { continue }
            
            let remainingStops1 = stopsDifference - filter1.1
            if abs(remainingStops1) < abs(leastRemainingStops) {
                bestCombination = [filter1.0]
                leastRemainingStops = remainingStops1
            }
            
            for j in (i+1)..<availableFilters.count {
                let filter2 = availableFilters[j]
                let totalStops = filter1.1 + filter2.1
                if totalStops > stopsDifference { continue }
                
                let remainingStops2 = stopsDifference - totalStops
                if abs(remainingStops2) < abs(leastRemainingStops) {
                    bestCombination = [filter1.0, filter2.0]
                    leastRemainingStops = remainingStops2
                }
            }
        }
        
        return (bestCombination, leastRemainingStops)
    }
    
    private static func adjustAperture(currentAperture: Double, targetStops: Double, availableApertures: [Double]) -> (Double, Double)? {
        let targetAperture = currentAperture * pow(sqrt(2), targetStops)
        let newAperture = availableApertures.min(by: { abs($0 - targetAperture) < abs($1 - targetAperture) })!
        let actualStops = log2(newAperture / currentAperture) * 2
        return (newAperture, targetStops - actualStops)
    }
    
    private static func adjustISO(currentISO: Int, targetStops: Double, availableISOs: [Int], isoStepSize: Double) -> (Int, Double)? {
        let targetISO = Double(currentISO) * pow(2, targetStops)
        let newISO = findClosestISO(in: availableISOs, to: targetISO, stepSize: isoStepSize)
        let actualStops = log2(Double(newISO) / Double(currentISO))
        return (newISO, targetStops - actualStops)
    }
    
    static func formatExposureTime(_ seconds: Double) -> String {
        if seconds >= 60 {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return String(format: NSLocalizedString("%dm %ds", comment: "Time format"), minutes, remainingSeconds)
        } else {
            if seconds.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: NSLocalizedString("%ds", comment: "Time format"), Int(seconds))
            } else {
                return String(format: NSLocalizedString("%.1fs", comment: "Time format"), seconds)
            }
        }
    }
    
    private static func findClosestISO(in values: [Int], to target: Double, stepSize: Double) -> Int {
        let steps = values.map { iso -> (Int, Double) in
            let steps = log2(Double(iso) / target) / stepSize
            return (iso, abs(steps - round(steps)))
        }
        return steps.min(by: { $0.1 < $1.1 })!.0
    }
}
