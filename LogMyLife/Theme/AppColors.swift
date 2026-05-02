import SwiftUI

struct AppColors {
    let background: Color
    let surface: Color
    let surfaceVariant: Color
    let onBackground: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let primary: Color
    let onPrimary: Color
    let inputBackground: Color
    let inputBorder: Color
    let isDark: Bool
}

let LightAppColors = AppColors(
    background: Color(hex: "F8FAFC"),
    surface: Color(hex: "FFFFFF"),
    surfaceVariant: Color(hex: "F1F5F9"),
    onBackground: Color(hex: "0F172A"),
    onSurface: Color(hex: "1E293B"),
    onSurfaceVariant: Color(hex: "64748B"),
    primary: Color(hex: "13EC5B"),
    onPrimary: Color(hex: "0F172A"),
    inputBackground: Color(hex: "F8FAFC"),
    inputBorder: Color(hex: "E2E8F0"),
    isDark: false
)

let DarkAppColors = AppColors(
    background: Color(hex: "0F1117"),
    surface: Color(hex: "1A1D27"),
    surfaceVariant: Color(hex: "252836"),
    onBackground: Color(hex: "F8FAFC"),
    onSurface: Color(hex: "E2E8F0"),
    onSurfaceVariant: Color(hex: "94A3B8"),
    primary: Color(hex: "13EC5B"),
    onPrimary: Color(hex: "0F172A"),
    inputBackground: Color(hex: "1A1D27"),
    inputBorder: Color(hex: "2D3142"),
    isDark: true
)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    static let orange500 = Color(hex: "F97316")
    static let green600  = Color(hex: "16A34A")
}

private struct AppColorsKey: EnvironmentKey {
    static let defaultValue = LightAppColors
}

extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }
}
