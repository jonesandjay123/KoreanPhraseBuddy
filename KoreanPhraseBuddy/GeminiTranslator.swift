import Foundation

enum GeminiTranslationError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case emptyTranslation
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "請先在 Secrets.xcconfig 設定 GEMINI_API_KEY"
        case .invalidResponse:
            return "Gemini 回應格式無法解析"
        case .emptyTranslation:
            return "Gemini 沒有回傳韓文"
        case .requestFailed(let message):
            return message
        }
    }
}

struct GeminiTranslator {
    private let apiKey: String
    private let model = "gemini-2.5-flash-lite"

    init(apiKey: String = AppConfig.geminiAPIKey) {
        self.apiKey = apiKey
    }

    func translateToKorean(chinese: String) async throws -> String {
        let trimmedChinese = chinese.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else { throw GeminiTranslationError.missingAPIKey }
        guard !trimmedChinese.isEmpty else { throw GeminiTranslationError.emptyTranslation }

        var components = URLComponents(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        )
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let url = components?.url else { throw GeminiTranslationError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GeminiGenerateContentRequest(
            contents: [
                GeminiContent(parts: [
                    GeminiPart(text: prompt(for: trimmedChinese))
                ])
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.4,
                maxOutputTokens: 160
            )
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let message = parseErrorMessage(from: data) ?? "Gemini request failed: HTTP \(httpResponse.statusCode)"
            throw GeminiTranslationError.requestFailed(message)
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        let text = decoded.candidates
            .first?
            .content
            .parts
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            ?? ""

        guard !text.isEmpty else { throw GeminiTranslationError.emptyTranslation }
        return text
    }

    private func prompt(for chinese: String) -> String {
        """
        你是台灣旅人在韓國首爾旅行時的現場口譯助手。
        請把下面這句中文轉成自然、禮貌、適合直接對韓國店員、站務、飯店櫃檯或路人說的韓文。
        可以稍微潤飾成更自然的韓文，但不要新增中文沒有提到的事實。
        請只輸出韓文句子，不要解釋，不要 Markdown。

        中文：\(chinese)
        """
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = json["error"] as? [String: Any],
            let message = error["message"] as? String
        else {
            return nil
        }

        return message
    }
}

private struct GeminiGenerateContentRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String?
}

private struct GeminiGenerateContentResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}
