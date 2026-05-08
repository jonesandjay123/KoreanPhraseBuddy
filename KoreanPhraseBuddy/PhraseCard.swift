import Foundation

struct PhraseCard: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var chinese: String
    var korean: String = ""
    var createdAt: Date = Date()
}
