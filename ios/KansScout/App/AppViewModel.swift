import Foundation
import Observation
import SwiftData

@Observable
final class AppViewModel {
    var opportunities: [OpportunityDTO] = []
    var digest: DigestDTO?
    var categories: [CategorySummaryDTO] = []
    var digestHistory: [DigestDTO] = []

    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    var selectedCategory: String?

    // MARK: - Load

    func loadAll(context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadDigest(context: context) }
            group.addTask { await self.loadOpportunities(context: context) }
            group.addTask { await self.loadCategories() }
        }
        lastUpdated = Date()
    }

    func loadOpportunities(context: ModelContext) async {
        do {
            let response = try await APIService.shared.fetchOpportunities(
                category: selectedCategory,
                sort: "score",
                page: 1,
                pageSize: 50
            )
            opportunities = response.results
            cacheOpportunities(response.results, context: context)
        } catch {
            if opportunities.isEmpty {
                opportunities = loadCachedOpportunities(context: context)
            }
            errorMessage = error.localizedDescription
        }
    }

    func loadDigest(context: ModelContext) async {
        do {
            digest = try await APIService.shared.fetchLatestDigest()
            if let d = digest {
                cacheSingleDigest(d, context: context)
                await NotificationService.shared.scheduleDailyDigest(
                    headlineInsight: d.headlineInsight ?? ""
                )
            }
        } catch {
            if digest == nil {
                digest = loadCachedDigest(context: context)
            }
        }
    }

    func loadCategories() async {
        do {
            categories = try await APIService.shared.fetchCategories()
        } catch {
            // Non-critical — silently fail
        }
    }

    func loadDigestHistory() async {
        do {
            digestHistory = try await APIService.shared.fetchDigestHistory(days: 14)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - SwiftData Cache

    private func cacheOpportunities(_ dtos: [OpportunityDTO], context: ModelContext) {
        for dto in dtos {
            let opp = Opportunity(
                id: dto.id,
                title: dto.title,
                category: dto.category,
                descriptionText: dto.description ?? "",
                usp: dto.usp ?? "",
                capitalMin: dto.capitalMin ?? 0,
                capitalMax: dto.capitalMax ?? 0,
                scoreCapital: dto.scoreCapital ?? 5,
                scoreScalability: dto.scoreScalability ?? 5,
                scoreUniqueness: dto.scoreUniqueness ?? 5,
                scoreRegulatory: dto.scoreRegulatory ?? 5,
                scoreKnowledge: dto.scoreKnowledge ?? 5,
                scoreMarketTiming: dto.scoreMarketTiming ?? 5,
                scoreOverall: dto.scoreOverall ?? 0,
                knowledgeRequired: dto.knowledgeRequired ?? [],
                regulatoryFlags: dto.regulatoryFlags ?? [],
                actionableSteps: dto.actionableSteps ?? [],
                sources: dto.sources ?? [],
                generatedAt: ISO8601DateFormatter().date(from: dto.generatedAt ?? "") ?? Date(),
                isNewToday: dto.isNewToday ?? false,
                date: dto.date ?? ""
            )
            context.insert(opp)
        }
        try? context.save()
    }

    private func loadCachedOpportunities(context: ModelContext) -> [OpportunityDTO] {
        let descriptor = FetchDescriptor<Opportunity>(
            sortBy: [SortDescriptor(\.scoreOverall, order: .reverse)]
        )
        let cached = (try? context.fetch(descriptor)) ?? []
        return cached.map { opp in
            OpportunityDTO(
                id: opp.id,
                title: opp.title,
                category: opp.category,
                description: opp.descriptionText,
                usp: opp.usp,
                capitalMin: opp.capitalMin,
                capitalMax: opp.capitalMax,
                scoreCapital: opp.scoreCapital,
                scoreScalability: opp.scoreScalability,
                scoreUniqueness: opp.scoreUniqueness,
                scoreRegulatory: opp.scoreRegulatory,
                scoreKnowledge: opp.scoreKnowledge,
                scoreMarketTiming: opp.scoreMarketTiming,
                scoreOverall: opp.scoreOverall,
                knowledgeRequired: opp.knowledgeRequired,
                regulatoryFlags: opp.regulatoryFlags,
                actionableSteps: opp.actionableSteps,
                sources: opp.sources,
                generatedAt: ISO8601DateFormatter().string(from: opp.generatedAt),
                isNewToday: opp.isNewToday,
                date: opp.date
            )
        }
    }

    private func cacheSingleDigest(_ dto: DigestDTO, context: ModelContext) {
        let digest = DailyDigest(
            id: dto.id ?? UUID().uuidString,
            date: dto.date,
            headlineInsight: dto.headlineInsight ?? "",
            topOpportunityIds: dto.topOpportunityIds ?? [],
            marketMood: dto.marketMood ?? "Stable",
            dutchContextNote: dto.dutchContextNote ?? "",
            weeklyPromptQuestion: dto.weeklyPromptQuestion ?? "",
            weeklyPromptCategory: dto.weeklyPromptCategory ?? "",
            createdAt: ISO8601DateFormatter().date(from: dto.createdAt ?? "") ?? Date()
        )
        context.insert(digest)
        try? context.save()
    }

    private func loadCachedDigest(context: ModelContext) -> DigestDTO? {
        let descriptor = FetchDescriptor<DailyDigest>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let cached = try? context.fetch(descriptor).first else { return nil }
        return DigestDTO(
            id: cached.id,
            date: cached.date,
            headlineInsight: cached.headlineInsight,
            topOpportunityIds: cached.topOpportunityIds,
            marketMood: cached.marketMood,
            dutchContextNote: cached.dutchContextNote,
            weeklyPromptQuestion: cached.weeklyPromptQuestion,
            weeklyPromptCategory: cached.weeklyPromptCategory,
            createdAt: nil
        )
    }
}
