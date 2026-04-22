import SwiftUI

enum CategoryColor: String, CaseIterable {
    case tech = "Tech"
    case beauty = "Beauty"
    case foodHealth = "Food & Health"
    case businessServices = "Business Services"
    case education = "Education"
    case homeLiving = "Home & Living"
    case other = "Other"

    static func from(category: String) -> CategoryColor {
        switch category {
        case "Tech":              return .tech
        case "Beauty":            return .beauty
        case "Food & Health":     return .foodHealth
        case "Business Services": return .businessServices
        case "Education":         return .education
        case "Home & Living":     return .homeLiving
        default:                  return .other
        }
    }

    var color: Color {
        switch self {
        case .tech:             return Color(hex: "4F6EF7")
        case .beauty:           return Color(hex: "E86BAF")
        case .foodHealth:       return Color(hex: "52C47D")
        case .businessServices: return Color(hex: "F5A623")
        case .education:        return Color(hex: "9B6BF7")
        case .homeLiving:       return Color(hex: "4BBFD4")
        case .other:            return Color(hex: "8E8E93")
        }
    }

    var sfSymbol: String {
        switch self {
        case .tech:             return "cpu"
        case .beauty:           return "sparkles"
        case .foodHealth:       return "leaf"
        case .businessServices: return "briefcase"
        case .education:        return "book"
        case .homeLiving:       return "house"
        case .other:            return "square.grid.2x2"
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
