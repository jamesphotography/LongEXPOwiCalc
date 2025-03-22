import Foundation

class ExposureCalculator {
    static func calculateExposure(shutterSpeed: String, aperture: Double, iso: Int, targetExposureTime: Double, selectedNDFilters: Set<String>, availableApertures: [Double], availableISOs: [Int], calculationMode: CalculationMode, isoStepSize: Double) -> ExposureResult {
        var logOutput = "计算过程"
        logOutput += String(format: "初始设置：快门速度 %@，光圈 f/%.1f，ISO %d", shutterSpeed, aperture, iso)
        logOutput += String(format: "目标曝光时间：%.1f 秒", targetExposureTime)
        logOutput += String(format: "计算模式： %@", calculationMode == .aperture ? "光圈锁定" : calculationMode == .iso ? "ISO锁定" : "自动")
        
        let stopsDifference = calculateStopsDifference(currentShutterSpeed: shutterSpeed, targetExposureTime: targetExposureTime)
        logOutput += String(format: "总档数差异：%d 档 (%.2f)", Int(round(stopsDifference)), stopsDifference)
        
        let (recommendedNDFilters, remainingStops) = recommendNDFilters(stopsDifference: stopsDifference, selectedNDFilters: selectedNDFilters)
        logOutput += String(format: "推荐的滤镜组合：%@", recommendedNDFilters.joined(separator: " + "))
        logOutput += String(format: "滤镜后剩余档数：%d 档 (%.2f)", Int(round(remainingStops)), remainingStops)
        
        var adjustedAperture = aperture
        var adjustedISO = iso
        var finalRemainingStops = remainingStops
        var adjustmentMade = false

        // 如果剩余档数在±0.3范围内，无需调整
        if abs(finalRemainingStops) <= 0.3 {
            logOutput += "剩余档数在可接受范围内（±0.3），无需调整"
        } else {
            switch calculationMode {
            case .aperture: // 光圈优先 - 只调整ISO
                logOutput += "光圈优先模式：仅调整 ISO"
                if let (newISO, newStops) = adjustISO(currentISO: iso, targetStops: finalRemainingStops, availableISOs: availableISOs, isoStepSize: isoStepSize) {
                    adjustedISO = newISO
                    finalRemainingStops = newStops
                    adjustmentMade = true
                    logOutput += String(format: "已调整 ISO 至 %d，剩余档数：%d (%.2f)", adjustedISO, Int(round(finalRemainingStops)), finalRemainingStops)
                }
            
            case .iso: // ISO优先 - 只调整光圈
                logOutput += "ISO 优先模式：仅调整光圈"
                if let (newAperture, newStops) = adjustAperture(currentAperture: aperture, targetStops: finalRemainingStops, availableApertures: availableApertures) {
                    adjustedAperture = newAperture
                    finalRemainingStops = newStops
                    adjustmentMade = true
                    logOutput += String(format: "已调整光圈至 f/%.1f，剩余档数：%d (%.2f)", adjustedAperture, Int(round(finalRemainingStops)), finalRemainingStops)
                }
                
            case .none: // 自动模式 - 同时调整光圈和ISO
                logOutput += "自动模式：同时调整光圈和 ISO"
                
                // 先尝试调整光圈
                if let (newAperture, newStops) = adjustAperture(currentAperture: aperture, targetStops: finalRemainingStops, availableApertures: availableApertures) {
                    adjustedAperture = newAperture
                    finalRemainingStops = newStops
                    adjustmentMade = true
                    logOutput += String(format: "已调整光圈至 f/%.1f，剩余档数：%d (%.2f)", adjustedAperture, Int(round(finalRemainingStops)), finalRemainingStops)
                }
                
                // 如果调整光圈后仍需要调整，则调整ISO
                if abs(finalRemainingStops) > 0.3 {
                    if let (newISO, newStops) = adjustISO(currentISO: iso, targetStops: finalRemainingStops, availableISOs: availableISOs, isoStepSize: isoStepSize) {
                        adjustedISO = newISO
                        finalRemainingStops = newStops
                        adjustmentMade = true
                        logOutput += String(format: "已调整 ISO 至 %d，剩余档数：%d (%.2f)", adjustedISO, Int(round(finalRemainingStops)), finalRemainingStops)
                    }
                }
            }
        }
        
        print(logOutput)
        
        // 创建警告和建议
        var warningLevel = WarningLevel.none
        var warningMessage: String? = nil
        var suggestion: String? = nil
        
        if abs(finalRemainingStops) > 0.3 {
            if abs(finalRemainingStops) <= 0.5 {
                warningLevel = .info
                warningMessage = String(format: "存在 %.1f 档的轻微曝光差异", abs(finalRemainingStops))
            } else {
                warningLevel = .warning
                warningMessage = String(format: "曝光误差 %.1f 档", abs(finalRemainingStops))
                
                if !adjustmentMade {
                    suggestion = "尝试使用不同的滤镜组合"
                } else {
                    switch calculationMode {
                    case .aperture:
                        suggestion = "考虑解除光圈锁定以获得更精确的曝光"
                    case .iso:
                        suggestion = "考虑解除感光度锁定以获得更精确的曝光"
                    case .none:
                        suggestion = "尝试使用不同的滤镜组合"
                    }
                }
            }
        }
        
        // 提取滤镜名称（ND部分）
        let ndFilterNames = recommendedNDFilters.map { filterFullName -> String in
            if let ndName = filterFullName.split(separator: " ").first {
                return String(ndName)
            }
            return filterFullName
        }
        
        // 返回结构化数据
        return ExposureResult(
            ndFilters: ndFilterNames,
            aperture: adjustedAperture,
            iso: adjustedISO,
            shutterSeconds: targetExposureTime,
            warningLevel: warningLevel,
            warningMessage: warningMessage,
            suggestion: suggestion
        )
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
        
        // 用于保存符合条件的单片滤镜
        var validSingleFilters: [(String, Double)] = []
        
        // 检查所有单片滤镜，找出差异不超过1.5档的
        for filter in availableFilters {
            let remainingStops = stopsDifference - filter.1
            if abs(remainingStops) <= 1.5 {
                validSingleFilters.append((filter.0, remainingStops))
            }
        }
        
        // 如果有符合条件的单片滤镜，选择剩余差异最小的
        if !validSingleFilters.isEmpty {
            let bestSingleFilter = validSingleFilters.min(by: { abs($0.1) < abs($1.1) })!
            return ([bestSingleFilter.0], bestSingleFilter.1)
        }
        
        // 如果没有合适的单片滤镜，尝试两片滤镜组合
        var bestCombination: [String] = []
        var leastRemainingStops = Double.infinity
        
        for i in 0..<availableFilters.count {
            let filter1 = availableFilters[i]
            
            // 单滤镜情况
            let remainingStops1 = stopsDifference - filter1.1
            if abs(remainingStops1) < abs(leastRemainingStops) {
                bestCombination = [filter1.0]
                leastRemainingStops = remainingStops1
            }
            
            // 两滤镜组合情况
            for j in (i+1)..<availableFilters.count {
                let filter2 = availableFilters[j]
                let totalStops = filter1.1 + filter2.1
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
            return String(format: "%d分 %d秒", minutes, remainingSeconds)
        } else {
            if seconds.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%d秒", Int(seconds))
            } else {
                return String(format: "%.1f秒", seconds)
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
