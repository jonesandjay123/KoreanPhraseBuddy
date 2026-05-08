import Foundation

enum AppConfig {
    static var geminiAPIKey: String {
        let rawValue = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String ?? ""
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty || trimmed == "$(GEMINI_API_KEY)" || trimmed == "paste_your_gemini_api_key_here" {
            return ""
        }

        return trimmed
    }
}
