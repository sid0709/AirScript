import Foundation

enum GoogleGTXTranslator: Sendable {
    nonisolated static func translate(_ text: String, from source: String = "en", to target: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }
        return try joinedTranslation(await requestPayload(trimmed, from: source, to: target))
    }

    nonisolated static func translateSentences(
        _ sentences: [String],
        from source: String = "en",
        to target: String
    ) async throws -> [String] {
        let usable = sentences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !usable.isEmpty else { return [] }
        if usable.count == 1 {
            return [try await translate(usable[0], from: source, to: target)]
        }

        let payload = try await requestPayload(usable.joined(separator: "\n"), from: source, to: target)
        if let aligned = alignedTranslations(payload, expectedCount: usable.count) {
            return aligned
        }

        var result: [String] = []
        result.reserveCapacity(usable.count)
        for sentence in usable {
            result.append(try await translate(sentence, from: source, to: target))
        }
        return result
    }

    nonisolated static func translatedText(from data: Data) throws -> String {
        try joinedTranslation(decodePayload(data))
    }

    nonisolated static func alignedTranslations(from data: Data, expectedCount: Int) throws -> [String]? {
        alignedTranslations(try decodePayload(data), expectedCount: expectedCount)
    }

    nonisolated private static func requestPayload(
        _ text: String,
        from source: String,
        to target: String
    ) async throws -> Payload {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw GoogleGTXError.emptyTranslation }
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

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw GoogleGTXError.httpStatus(http.statusCode)
        }
        return try decodePayload(data)
    }

    nonisolated private static func decodePayload(_ data: Data) throws -> Payload {
        if let html = String(data: data, encoding: .utf8), html.localizedCaseInsensitiveContains("<html") {
            throw GoogleGTXError.blocked
        }
        return try JSONDecoder().decode(Payload.self, from: data)
    }

    nonisolated private static func joinedTranslation(_ payload: Payload) throws -> String {
        let joined = payload.sentences?
            .compactMap(\.trans)
            .joined()
            .replacingOccurrences(of: "\n ", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let joined, !joined.isEmpty else { throw GoogleGTXError.emptyTranslation }
        return joined
    }

    nonisolated private static func alignedTranslations(_ payload: Payload, expectedCount: Int?) -> [String]? {
        let parts = payload.sentences?
            .compactMap(\.trans)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let parts, !parts.isEmpty else { return nil }
        if let expectedCount {
            if parts.count == expectedCount { return parts }
            let byNewline = parts.joined().components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return byNewline.count == expectedCount ? byNewline : nil
        }
        return parts
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
