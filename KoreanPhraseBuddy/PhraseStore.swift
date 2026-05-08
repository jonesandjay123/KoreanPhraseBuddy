import Foundation

@Observable
final class PhraseStore {
    private let storageKey = "seoul_phrase_buddy_cards"
    private let userDefaults: UserDefaults

    var cards: [PhraseCard] = [] {
        didSet {
            save()
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.cards = Self.loadCards(from: userDefaults, key: storageKey)
    }

    func add(chinese: String) {
        let trimmed = chinese.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        cards.insert(
            PhraseCard(chinese: trimmed),
            at: 0
        )
    }

    func delete(_ card: PhraseCard) {
        cards.removeAll { $0.id == card.id }
    }

    func update(_ card: PhraseCard, korean: String) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index].korean = korean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func replaceCards(_ updatedCards: [PhraseCard]) {
        cards = updatedCards
    }

    func moveCards(from source: IndexSet, to destination: Int) {
        var updatedCards = cards
        let sortedSource = source.sorted()
        let movingCards = sortedSource.map { updatedCards[$0] }

        for index in sortedSource.reversed() {
            updatedCards.remove(at: index)
        }

        let adjustedDestination = destination - sortedSource.filter { $0 < destination }.count
        let safeDestination = max(0, min(adjustedDestination, updatedCards.count))
        updatedCards.insert(contentsOf: movingCards, at: safeDestination)
        cards = updatedCards
    }

    func seedExamplesIfNeeded() {
        guard cards.isEmpty else { return }

        cards = [
            PhraseCard(
                chinese: "請問這裡可以刷卡嗎？",
                korean: "여기 카드 결제 가능할까요?"
            ),
            PhraseCard(
                chinese: "我對海鮮過敏，請問這道菜有海鮮嗎？",
                korean: "제가 해산물 알레르기가 있는데, 이 음식에 해산물이 들어가나요?"
            ),
            PhraseCard(
                chinese: "請問這班車會到弘大入口嗎？",
                korean: "이 열차가 홍대입구역까지 가나요?"
            )
        ]
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(cards)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save phrase cards: \(error)")
        }
    }

    private static func loadCards(from userDefaults: UserDefaults, key: String) -> [PhraseCard] {
        guard let data = userDefaults.data(forKey: key) else { return [] }

        do {
            return try JSONDecoder().decode([PhraseCard].self, from: data)
        } catch {
            return []
        }
    }
}
