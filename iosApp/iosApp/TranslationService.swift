import Foundation

// MARK: - Translation service backed by MyMemory (free, no API key needed)
// Docs: https://mymemory.translated.net/doc/spec.php

enum TranslationError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case apiError(String)
    case noResult

    var errorDescription: String? {
        switch self {
        case .invalidURL:        return "Could not build translation URL."
        case .httpError(let c):  return "HTTP \(c) from translation service."
        case .apiError(let msg): return "Translation API: \(msg)"
        case .noResult:          return "Translation returned an empty result."
        }
    }
}

enum TranslationService {
    /// Translate `text` from `srcTag` (BCP-47 e.g. "en-US") to `tgtTag` (e.g. "es-ES").
    /// Pass `srcTag = nil` to auto-detect the source language.
    static func translate(_ text: String, from srcTag: String?, to tgtTag: String) async throws -> String {
        // MyMemory expects 2-letter codes: "en", "es", "fr", etc.
        let src = srcTag.flatMap { $0.split(separator: "-").first.map(String.init) } ?? "auto"
        let tgt = tgtTag.split(separator: "-").first.map(String.init) ?? tgtTag

        var comps = URLComponents(string: "https://api.mymemory.translated.net/get")!
        comps.queryItems = [
            URLQueryItem(name: "q",        value: text),
            URLQueryItem(name: "langpair", value: "\(src)|\(tgt)")
        ]
        guard let url = comps.url else { throw TranslationError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw TranslationError.httpError(http.statusCode)
        }

        let body = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
        guard body.responseStatus == 200 else {
            throw TranslationError.apiError(body.responseDetails)
        }
        let result = body.responseData.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { throw TranslationError.noResult }
        return result
    }
}

// MARK: - MyMemory response model

private struct MyMemoryResponse: Decodable {
    let responseData:    ResponseData
    let responseStatus:  Int
    let responseDetails: String

    struct ResponseData: Decodable {
        let translatedText: String
    }
}
