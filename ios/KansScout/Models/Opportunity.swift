import Foundation
import SwiftData

@Model
final class Opportunity: Identifiable {
    @Attribute(.unique) var id: String
    var title: String
    var category: String
    var descriptionText: String
    var usp: String
    var capitalMin: Int
    var capitalMax: Int
    var scoreCapital: Int
    var scoreScalability: Int
    var scoreUniqueness: Int
    var scoreRegulatory: Int
    var scoreKnowledge: Int
    var scoreMarketTiming: Int
    var scoreOverall: Double
    var knowledgeRequired: [String]
    var regulatoryFlags: [String]
    var actionableSteps: [String]
    var sources: [String]
    var generatedAt: Date
    var isNewToday: Bool
    var date: String

    init(
        id: String,
        title: String,
        category: String,
        descriptionText: String,
        usp: String,
        capitalMin: Int,
        capitalMax: Int,
        scoreCapital: Int,
        scoreScalability: Int,
        scoreUniqueness: Int,
        scoreRegulatory: Int,
        scoreKnowledge: Int,
        scoreMarketTiming: Int,
        scoreOverall: Double,
        knowledgeRequired: [String],
        regulatoryFlags: [String],
        actionableSteps: [String],
        sources: [String],
        generatedAt: Date,
        isNewToday: Bool,
        date: String
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.descriptionText = descriptionText
        self.usp = usp
        self.capitalMin = capitalMin
        self.capitalMax = capitalMax
        self.scoreCapital = scoreCapital
        self.scoreScalability = scoreScalability
        self.scoreUniqueness = scoreUniqueness
        self.scoreRegulatory = scoreRegulatory
        self.scoreKnowledge = scoreKnowledge
        self.scoreMarketTiming = scoreMarketTiming
        self.scoreOverall = scoreOverall
        self.knowledgeRequired = knowledgeRequired
        self.regulatoryFlags = regulatoryFlags
        self.actionableSteps = actionableSteps
        self.sources = sources
        self.generatedAt = generatedAt
        self.isNewToday = isNewToday
        self.date = date
    }
}
