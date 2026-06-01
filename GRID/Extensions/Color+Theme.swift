import SwiftUI

extension Color {
    // Backgrounds
    static let gridBg          = Color(red: 0.051, green: 0.051, blue: 0.082)  // #0D0D15
    static let gridBgPurple    = Color(red: 0.110, green: 0.102, blue: 0.176)  // #1C1A2D
    static let gridCard        = Color(red: 0.110, green: 0.110, blue: 0.165)  // #1C1C2A
    static let gridCardInner   = Color(red: 0.149, green: 0.141, blue: 0.212)  // #262436
    static let gridHistoryBg   = Color(red: 0.180, green: 0.165, blue: 0.420)  // #2E2A6B
    static let gridHistoryCard = Color(red: 0.220, green: 0.200, blue: 0.490)  // #38337D

    // Accent
    static let gridAccent      = Color(red: 0.482, green: 0.431, blue: 0.965)  // #7B6EF6
    static let gridAccentSoft  = Color(red: 0.482, green: 0.431, blue: 0.965).opacity(0.25)

    // Text
    static let gridTextPrimary   = Color.white
    static let gridTextSecondary = Color(red: 0.533, green: 0.533, blue: 0.667)  // #888888
    static let gridTextTertiary  = Color(red: 0.380, green: 0.370, blue: 0.490)  // #615E7D

    // Tab bar
    static let gridTabBar       = Color(red: 0.078, green: 0.078, blue: 0.122)  // #14141F
    static let gridTabSelected  = Color(red: 0.149, green: 0.141, blue: 0.212)  // #262436

    // Danger
    static let gridDanger = Color(red: 0.95, green: 0.25, blue: 0.25)
}

extension Font {
    static let gridTitle     = Font.system(size: 28, weight: .bold)
    static let gridHeadline  = Font.system(size: 17, weight: .semibold)
    static let gridBody      = Font.system(size: 15, weight: .bold)
    static let gridCaption   = Font.system(size: 12, weight: .regular)
    static let gridSmall     = Font.system(size: 11, weight: .medium)
    static let gridMono      = Font.system(size: 15, weight: .medium, design: .monospaced)
}
