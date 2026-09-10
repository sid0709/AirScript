import Foundation

enum GoogleGTXTranslator: Sendable {
    nonisolated static func translate(_ text: String, from source: String = "en", to target: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }
        guard let endpoint = URL(string: "https://translate.googleapis.com/translate_a/single") else {
            throw GoogleGTXError.invalidURL
        }

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "sl", value: source),
            URLQueryItem(name: "tl", value: target),
            URLQueryItem(name: "dj", value: "1"),
            URLQueryItem(name: "hl", value: target),
            URLQueryItem(name: "dt", value: "t"),
        ]
        guard let url = components.url else { throw GoogleGTXError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw GoogleGTXError.httpStatus(http.statusCode)
        }
        return try translatedText(from: data)
    }

    nonisolated static func translatedText(from data: Data) throws -> String {
        if let html = String(data: data, encoding: .utf8), html.localizedCaseInsensitiveContains("<html") {
            throw GoogleGTXError.blocked
        }
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        let joined = payload.sentences?
            .compactMap(\.trans)
            .joined()
            .replacingOccurrences(of: "\n ", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let joined, !joined.isEmpty else { throw GoogleGTXError.emptyTranslation }
        return joined
    }
}

enum GoogleGTXError: Error, Equatable, Sendable {
    case invalidURL
    case httpStatus(Int)
    case blocked
    case emptyTranslation
}

private struct Payload: Decodable, Sendable {
    struct Sentence: Decodable, Sendable {
        var trans: String?
    }

    var sentences: [Sentence]?
}
