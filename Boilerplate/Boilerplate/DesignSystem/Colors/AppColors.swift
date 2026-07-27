//
//  AppColors.swift
//  Boilerplate
//
//  Created by Ayush Kumar Sethi on 27/07/26.
//

import SwiftUI

/// Centralized color tokens for the app.
///
/// Every color is defined as a `light`/`dark` pair via `Color(light:dark:)` rather
/// than pulling from the asset catalog, so the whole palette lives in one reviewable
/// file. Swap this out for `Color("token", bundle: .main)` lookups if you'd rather
/// manage colors in `Assets.xcassets`.
enum AppColors {

    // MARK: - Brand

    static let primary = Color(light: Color(red: 0.20, green: 0.40, blue: 0.95),
                                dark: Color(red: 0.35, green: 0.55, blue: 1.00))

    static let secondary = Color(light: Color(red: 0.45, green: 0.45, blue: 0.50),
                                  dark: Color(red: 0.65, green: 0.65, blue: 0.70))

    static let disabled = Color(light: Color(red: 0.78, green: 0.80, blue: 0.86),
                                 dark: Color(red: 0.30, green: 0.31, blue: 0.35))

    // MARK: - Semantic

    static let success = Color(light: Color(red: 0.20, green: 0.70, blue: 0.35),
                                dark: Color(red: 0.30, green: 0.80, blue: 0.45))

    static let warning = Color(light: Color(red: 0.95, green: 0.65, blue: 0.10),
                                dark: Color(red: 1.00, green: 0.75, blue: 0.25))

    static let error = Color(light: Color(red: 0.85, green: 0.20, blue: 0.20),
                              dark: Color(red: 1.00, green: 0.40, blue: 0.40))

    // MARK: - Surfaces

    static let background = Color(light: Color(white: 0.97), dark: Color(white: 0.07))
    static let surface = Color(light: .white, dark: Color(white: 0.13))
    static let border = Color(light: Color(white: 0.85), dark: Color(white: 0.24))

    // MARK: - Text

    static let text = Color(light: Color(white: 0.10), dark: Color(white: 0.95))
    static let secondaryText = Color(light: Color(white: 0.40), dark: Color(white: 0.65))
}

// MARK: - Dynamic Color Helper

extension Color {
    /// Builds a `Color` that resolves to `light` or `dark` depending on the current
    /// `colorScheme`, without requiring an asset catalog entry.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        }))
        #else
        self = light
        #endif
    }
}
