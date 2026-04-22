import Foundation
import SwiftData

@Model
final class DailyDigest: Identifiable {
    @Attribute(.unique) var date: String
    var id: String
    var headlineInsight: String
    var topOpportunityIds: [String]
    var marketMood: String
    var dutchContextNote: String
    var weeklyPromptQuestion: String
    var weeklyPromptCategory: String
    var createdAt: Date

    init(
        id: String,
        date: String,
        headlineInsight: String,
        topOpportunityIds: [String],
        marketMood: String,
        dutchContextNote: String,
        weeklyPromptQuestion: String,
        weeklyPromptCategory: String,
        createdAt: Date
    ) {
        self.id = id
        self.date = date
        self.headlineInsight = headlineInsight
        self.topOpportunityIds = topOpportunityIds
        self.marketMood = marketMood
        self.dutchContextNote = dutchContextNote
        self.weeklyPromptQuestion = weeklyPromptQuestion
        self.weeklyPromptCategory = weeklyPromptCategory
        self.createdAt = createdAt
    }

    var marketMoodIcon: String {
        switch marketMood {
        case "Rising": return "arrow.up.circle.fill"
        case "Cautious": return "exclamationmark.circle.fill"
        default: return "minus.circle.fill"
        }
    }

    var marketMoodColor: CategoryColor {
        switch marketMood {
        case "Rising": return .foodHealth
        case "Cautious": return .beauty
        default: return .businessServices
        }
    }
}
