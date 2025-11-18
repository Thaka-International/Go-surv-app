//
//  Color+GoSurve.swift
//  Go-surve
//
//  GoSurve brand colors - Gold and Black palette
//

import SwiftUI

extension Color {
    // MARK: - GoSurve Gold & Black Palette
    /// Dust Grey - RGB: 211, 211, 211 (#D3D3D3)
    static let dustGrey = Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0)
    
    /// Sunflower Gold - RGB: 247, 188, 81 (#F7BC51) - Primary gold
    static let sunflowerGold = Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)
    
    /// Black - RGB: 0, 0, 0 (#000000) - Primary text
    static let goSurveBlack = Color(red: 0.0, green: 0.0, blue: 0.0)
    
    /// Golden Bronze - RGB: 192, 148, 64 (#C09440) - Darker gold accent
    static let goldenBronze = Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0)
    
    // MARK: - Legacy Support (mapped to new colors)
    /// Primary color - mapped to Sunflower Gold
    static let goServeBlue = Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)
    
    /// Dark accent - mapped to Golden Bronze
    static let goServeDarkBlue = Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0)
    
    /// Light background - mapped to Dust Grey
    static let goServeLightBlue = Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0)
    
    // MARK: - UI Colors
    /// Background - Dust Grey
    static let smartHomeBackground = Color(red: 211/255.0, green: 211/255.0, blue: 211/255.0)
    
    /// Card background - White
    static let smartHomeCard = Color.white
    
    /// Surface - Light grey
    static let smartHomeSurface = Color(red: 0.98, green: 0.98, blue: 0.99)
    
    /// Text primary - Black
    static let smartHomeTextPrimary = Color(red: 0.0, green: 0.0, blue: 0.0)
    
    /// Text secondary - Dark grey
    static let smartHomeTextSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    /// Primary accent - Sunflower Gold
    static let smartHomePrimary = Color(red: 247/255.0, green: 188/255.0, blue: 81/255.0)
    
    /// Secondary accent - Golden Bronze
    static let smartHomeSecondary = Color(red: 192/255.0, green: 148/255.0, blue: 64/255.0)
    
    /// Success - Green (kept for status indicators)
    static let smartHomeSuccess = Color(red: 0.2, green: 0.8, blue: 0.4)
    
    /// Warning - Orange (kept for warnings)
    static let smartHomeWarning = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    /// Error - Red (kept for errors)
    static let smartHomeError = Color(red: 0.95, green: 0.3, blue: 0.3)
}

