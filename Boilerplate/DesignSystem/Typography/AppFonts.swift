//
//  AppFonts.swift
//  Boilerplate
//
//  Created by Ayush Kumar Sethi on 27/07/26.
//

import SwiftUI

/// Centralized typography tokens for the app.
///
/// All fonts are built on top of Dynamic Type text styles (`.rounded` design) so the
/// whole app respects the user's preferred content size category out of the box.
enum AppFonts {

    // MARK: - Display

    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title, design: .rounded, weight: .bold)
    static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
    static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)

    // MARK: - Body

    static let body = Font.system(.body, design: .rounded, weight: .regular)
    static let bodyEmphasized = Font.system(.body, design: .rounded, weight: .medium)
    static let callout = Font.system(.callout, design: .rounded, weight: .regular)
    static let subheadline = Font.system(.subheadline, design: .rounded, weight: .regular)

    // MARK: - Small

    static let caption = Font.system(.caption, design: .rounded, weight: .medium)
    static let caption2 = Font.system(.caption2, design: .rounded, weight: .regular)
    static let footnote = Font.system(.footnote, design: .rounded, weight: .regular)

    // MARK: - Controls

    static let button = Font.system(.headline, design: .rounded, weight: .semibold)
}
