import SwiftUI
import UIKit

struct ContentView: View {
    @State private var store = PhraseStore()
    @State private var speechService = SpeechService()
    @State private var chineseText = ""
    @State private var statusMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    inputPanel
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                if store.cards.isEmpty {
                    emptyState
                } else {
                    Section("旅行小卡") {
                        ForEach(store.cards) { card in
                            PhraseCardRow(
                                card: card,
                                onTranslate: {
                                    store.update(card, korean: sampleKorean(for: card.chinese))
                                    statusMessage = "已加入韓文範例，下一步會接 Gemini"
                                },
                                onCopy: {
                                    copyKorean(from: card)
                                },
                                onSpeak: {
                                    speakKorean(from: card)
                                },
                                onDelete: {
                                    store.delete(card)
                                    statusMessage = "已刪除小卡"
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Seoul Phrase Buddy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.seedExamplesIfNeeded()
                        statusMessage = "已加入首爾旅行範例"
                    } label: {
                        Label("範例", systemImage: "sparkles")
                    }
                }
            }
        }
    }

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("輸入等等可能要說的中文")
                .font(.headline)

            TextField("例如：請問這裡可以刷卡嗎？", text: $chineseText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)

            Button {
                addCard()
            } label: {
                Label("新增小卡", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(chineseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var emptyState: some View {
        Section {
            ContentUnavailableView(
                "還沒有旅行小卡",
                systemImage: "text.bubble",
                description: Text("先輸入一句中文，或按右上角加入範例。")
            )
        }
    }

    private func addCard() {
        store.add(chinese: chineseText)
        chineseText = ""
        statusMessage = "已新增小卡，可稍後翻譯"
    }

    private func copyKorean(from card: PhraseCard) {
        guard !card.korean.isEmpty else {
            statusMessage = "這張小卡還沒有韓文"
            return
        }

        UIPasteboard.general.string = card.korean
        statusMessage = "已複製韓文"
    }

    private func speakKorean(from card: PhraseCard) {
        guard !card.korean.isEmpty else {
            statusMessage = "這張小卡還沒有韓文"
            return
        }

        speechService.speakKorean(card.korean)
        statusMessage = "正在播放韓文"
    }

    private func sampleKorean(for chinese: String) -> String {
        if chinese.contains("刷卡") || chinese.contains("信用卡") {
            return "카드 결제 가능할까요?"
        }

        if chinese.contains("海鮮") || chinese.contains("過敏") {
            return "제가 해산물 알레르기가 있는데, 이 음식에 해산물이 들어가나요?"
        }

        if chinese.contains("洗手間") || chinese.contains("廁所") {
            return "화장실이 어디에 있나요?"
        }

        if chinese.contains("弘大") || chinese.contains("車") || chinese.contains("地鐵") {
            return "이 열차가 홍대입구역까지 가나요?"
        }

        return "안녕하세요. 이것을 한국어로 자연스럽게 말하고 싶어요."
    }
}

private struct PhraseCardRow: View {
    let card: PhraseCard
    let onTranslate: () -> Void
    let onCopy: () -> Void
    let onSpeak: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.chinese)
                .font(.body)
                .foregroundStyle(.secondary)

            Text(card.korean.isEmpty ? "尚未翻譯" : card.korean)
                .font(.title3.weight(.semibold))
                .foregroundStyle(card.korean.isEmpty ? .tertiary : .primary)
                .textSelection(.enabled)

            HStack(spacing: 8) {
                Button(action: onSpeak) {
                    Label("播放", systemImage: "play.fill")
                }
                .disabled(card.korean.isEmpty)

                Button(action: onCopy) {
                    Label("複製", systemImage: "doc.on.doc")
                }
                .disabled(card.korean.isEmpty)

                Button(action: onTranslate) {
                    Label(card.korean.isEmpty ? "翻譯" : "重翻", systemImage: "translate")
                }

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("刪除")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
