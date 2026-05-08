import Foundation

enum ExternalTranslationError: LocalizedError {
    case noCards
    case invalidJSONArray
    case noImportableTranslations
    case noMatchingCards

    var errorDescription: String? {
        switch self {
        case .noCards:
            return "目前沒有可匯出的旅行小卡"
        case .invalidJSONArray:
            return "請貼上合法 JSON 陣列"
        case .noImportableTranslations:
            return "JSON 裡找不到可匯入的 korean 結果"
        case .noMatchingCards:
            return "JSON 裡的 id 沒有對應到目前小卡"
        }
    }
}

struct ExternalTranslationImportResult {
    let cards: [PhraseCard]
    let updatedCount: Int
}

enum ExternalTranslationBridge {
    static func buildExportPrompt(cards: [PhraseCard]) throws -> String {
        guard !cards.isEmpty else { throw ExternalTranslationError.noCards }

        let exportCards = cards.map { ExportCard(id: $0.id.uuidString, chinese: $0.chinese, korean: $0.korean) }
        let data = try JSONEncoder.prettyPrinted.encode(exportCards)
        let json = String(decoding: data, as: UTF8.self)

        return """
        你是台灣旅人在韓國首爾旅行時的現場口譯助手。
        請把下方 JSON 中每個 chinese 翻成自然、禮貌、適合直接對韓國店員、站務、飯店櫃檯或路人說的韓文。
        可以稍微潤飾成更自然的韓文，但不要新增中文沒有提到的事實。
        請保留 id、chinese 和順序，只填寫或更新 korean。
        請只回傳合法 JSON 陣列，不要 Markdown，不要解釋，不要包在 ``` 裡。

        JSON:
        \(json)
        """
    }

    static func importTranslations(from rawText: String, currentCards: [PhraseCard]) throws -> ExternalTranslationImportResult {
        let jsonText = try extractJSONArrayText(from: rawText)
        guard let data = jsonText.data(using: .utf8) else {
            throw ExternalTranslationError.invalidJSONArray
        }

        let importedCards: [ExportCard]
        do {
            importedCards = try JSONDecoder().decode([ExportCard].self, from: data)
        } catch {
            throw ExternalTranslationError.invalidJSONArray
        }

        let translationsByID = Dictionary(
            uniqueKeysWithValues: importedCards.compactMap { card -> (UUID, String)? in
                guard
                    let id = UUID(uuidString: card.id),
                    let korean = card.korean?.trimmingCharacters(in: .whitespacesAndNewlines),
                    !korean.isEmpty
                else {
                    return nil
                }
                return (id, korean)
            }
        )

        guard !translationsByID.isEmpty else {
            throw ExternalTranslationError.noImportableTranslations
        }

        var updatedCount = 0
        let updatedCards = currentCards.map { card in
            guard let korean = translationsByID[card.id] else { return card }
            updatedCount += 1
            var updatedCard = card
            updatedCard.korean = korean
            return updatedCard
        }

        guard updatedCount > 0 else {
            throw ExternalTranslationError.noMatchingCards
        }

        return ExternalTranslationImportResult(cards: updatedCards, updatedCount: updatedCount)
    }

    private static func extractJSONArrayText(from rawText: String) throws -> String {
        let trimmed = rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let start = trimmed.firstIndex(of: "["),
            let end = trimmed.lastIndex(of: "]"),
            start < end
        else {
            throw ExternalTranslationError.invalidJSONArray
        }

        return String(trimmed[start...end])
    }
}

private struct ExportCard: Codable {
    let id: String
    let chinese: String
    let korean: String?
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
