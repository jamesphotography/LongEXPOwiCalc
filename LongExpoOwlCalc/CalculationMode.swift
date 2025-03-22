//
//  CalculationMode.swift
//  LongExpoOwlCalc
//
//  Created by James Zhen Yu on 2/1/2025.
//

import Foundation

enum CalculationMode: String, Codable {
    case none     // 自动调整(光圈和ISO都调整)
    case aperture // 光圈锁定(只调整ISO)
    case iso      // ISO锁定(只调整光圈)
}
