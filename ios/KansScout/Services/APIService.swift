import Foundation

// ---------------------------------------------------------------------------
// DTOs — match the backend JSON exactly
// ---------------------------------------------------------------------------

struct OpportunityDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let category: String
    let description: String?
    let usp: String?
    let capitalMin: Int?
    let capitalMax: Int?
    let scoreCapital: Int?
    let scoreScalability: Int?
    let scoreUniqueness: Int?
    let scoreRegulatory: Int?
    let scoreKnowledge: Int?
    let scoreMarketTiming: Int?
    let scoreOverall: Double?
    let knowledgeRequired: [String]?
    let regulatoryFlags: [String]?
    let actionableSteps: [String]?
    let sources: [String]?
    let generatedAt: String?
    let isNewToday: Bool?
    let date: String?

    enum CodingKeys: String, CodingKey {
        case id, title, category, description, usp, sources, date
        case capitalMin = "capital_min"
        case capitalMax = "capital_max"
        case scoreCapital = "score_capital"
        case scoreScalability = "score_scalability"
        case scoreUniqueness = "score_uniqueness"
        case scoreRegulatory = "score_regulatory"
        case scoreKnowledge = "score_knowledge"
        case scoreMarketTiming = "score_market_timing"
        case scoreOverall = "score_overall"
        case knowledgeRequired = "knowledge_required"
        case regulatoryFlags = "regulatory_flags"
        case actionableSteps = "actionable_steps"
        case generatedAt = "generated_at"
        case isNewToday = "is_new_today"
    }
}

struct OpportunityListResponse: Decodable {
    let page: Int
    let pageSize: Int
    let results: [OpportunityDTO]

    enum CodingKeys: String, CodingKey {
        case page, results
        case pageSize = "page_size"
    }
}

struct DigestDTO: Decodable {
    let id: String?
    let date: String
    let headlineInsight: String?
    let topOpportunityIds: [String]?
    let marketMood: String?
    let dutchContextNote: String?
    let weeklyPromptQuestion: String?
    let weeklyPromptCategory: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, date
        case headlineInsight = "headline_insight"
        case topOpportunityIds = "top_opportunity_ids"
        case marketMood = "market_mood"
        case dutchContextNote = "dutch_context_note"
        case weeklyPromptQuestion = "weekly_prompt_question"
        case weeklyPromptCategory = "weekly_prompt_category"
        case createdAt = "created_at"
    }
}

struct CategorySummaryDTO: Decodable, Identifiable {
    var id: String { category }
    let category: String
    let count: Int
    let avgScore: Double?

    enum CodingKeys: String, CodingKey {
        case category, count
        case avgScore = "avg_score"
    }
}

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "Invalid API URL"
        case .unauthorized:          return "Invalid API key"
        case .notFound:              return "Resource not found"
        case .serverError(let c):    return "Server error (\(c))"
        case .decodingError(let e):  return "Decode error: \(e.localizedDescription)"
        case .networkError(let e):   return e.localizedDescription
        }
    }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

actor APIService {
    static let shared = APIService()

    private let baseURL: String
    private let apiKey: String
    private let session: URLSession

    private init() {
        // Read from Config.plist (excluded from git)
        let bundle = Bundle.main
        let plistURL = bundle.url(forResource: "Config", withExtension: "plist")
        var config: [String: Any] = [:]
        if let url = plistURL, let dict = NSDictionary(contentsOf: url) as? [String: Any] {
            config = dict
        }
        baseURL = (config["API_BASE_URL"] as? String) ?? "https://your-project.vercel.app"
        apiKey  = (config["API_KEY"] as? String) ?? ""

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        session = URLSession(configuration: cfg)
    }

    // MARK: - Opportunities

    func fetchOpportunities(
        category: String? = nil,
        sort: String = "score",
        newToday: Bool? = nil,
        page: Int = 1,
        pageSize: Int = 20
    ) async throws -> OpportunityListResponse {
        var params: [String: String] = ["sort": sort, "page": "\(page)", "page_size": "\(pageSize)"]
        if let cat = category { params["category"] = cat }
        if let nt = newToday { params["new_today"] = nt ? "true" : "false" }
        return try await get(path: "/api/opportunities", params: params)
    }

    func fetchOpportunity(id: String) async throws -> OpportunityDTO {
        try await get(path: "/api/opportunities/\(id)", params: [:])
    }

    // MARK: - Digest

    func fetchLatestDigest() async throws -> DigestDTO {
        try await get(path: "/api/digest/latest", params: [:])
    }

    func fetchDigestHistory(days: Int = 7) async throws -> [DigestDTO] {
        try await get(path: "/api/digest/history", params: ["days": "\(days)"])
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [CategorySummaryDTO] {
        try await get(path: "/api/categories", params: [:])
    }

    // MARK: - Private

    private func get<T: Decodable>(path: String, params: [String: String]) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        if !apiKey.isEmpty { request.setValue(apiKey, forHTTPHeaderField: "X-API-Key") }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200..<300: break
            case 401, 403:  throw APIError.unauthorized
            case 404:       throw APIError.notFound
            default:        throw APIError.serverError(http.statusCode)
            }
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
