import SwiftUI
import UIKit

struct ContentView: View {
    @State private var store = PhraseStore()
    @State private var speechService = SpeechService()
    @State private var chineseText = ""
    @State private var statusMessage = ""
    @State private var translatingCardIDs: Set<UUID> = []
    @State private var cardPendingDeletion: PhraseCard?
    @State private var isDeleteConfirmationPresented = false
    @State private var isImportSheetPresented = false

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
                    Section {
                        ForEach(store.cards) { card in
                            PhraseCardRow(
                                card: card,
                                isTranslating: translatingCardIDs.contains(card.id),
                                onTranslate: {
                                    translate(card)
                                },
                                onCopy: {
                                    copyKorean(from: card)
                                },
                                onSpeak: {
                                    speakKorean(from: card)
                                },
                                onDelete: {
                                    cardPendingDeletion = card
                                    isDeleteConfirmationPresented = true
                                }
                            )
                        }
                    } header: {
                        phraseListHeader
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
        .confirmationDialog(
            "刪除這張小卡？",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("刪除", role: .destructive) {
                if let card = cardPendingDeletion {
                    store.delete(card)
                    statusMessage = "已刪除小卡"
                }
                cardPendingDeletion = nil
            }
            Button("取消", role: .cancel) {
                cardPendingDeletion = nil
            }
        } message: {
            if let card = cardPendingDeletion {
                Text(card.chinese)
            }
        }
        .sheet(isPresented: $isImportSheetPresented) {
            BatchImportSheet(
                onImport: { jsonText in
                    do {
                        let result = try ExternalTranslationBridge.importTranslations(
                            from: jsonText,
                            currentCards: store.cards
                        )
                        store.replaceCards(result.cards)
                        statusMessage = "已更新 \(result.updatedCount) 張小卡"
                        isImportSheetPresented = false
                    } catch {
                        statusMessage = error.localizedDescription
                    }
                }
            )
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

    private var phraseListHeader: some View {
        HStack {
            Text("旅行小卡")
            Spacer()
            Button {
                exportAllCardsForExternalTranslation()
            } label: {
                Label("匯出", systemImage: "square.and.arrow.up")
            }
            Button {
                isImportSheetPresented = true
            } label: {
                Label("匯入", systemImage: "square.and.arrow.down")
            }
        }
        .font(.subheadline)
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

    private func translate(_ card: PhraseCard) {
        translatingCardIDs.insert(card.id)
        statusMessage = "Gemini 正在翻譯..."

        Task {
            do {
                let korean = try await GeminiTranslator().translateToKorean(chinese: card.chinese)
                store.update(card, korean: korean)
                statusMessage = "已補上韓文"
            } catch {
                statusMessage = "\(error.localizedDescription)。可按「匯出」改用網頁版 LLM。"
            }

            translatingCardIDs.remove(card.id)
        }
    }

    private func exportAllCardsForExternalTranslation() {
        do {
            UIPasteboard.general.string = try ExternalTranslationBridge.buildExportPrompt(cards: store.cards)
            statusMessage = "已複製整批匯出 prompt"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

private struct PhraseCardRow: View {
    let card: PhraseCard
    let isTranslating: Bool
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

            if isTranslating {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Gemini 正在整理成自然韓文...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Button(action: onSpeak) {
                    Label("播放", systemImage: "play.fill")
                }
                .disabled(card.korean.isEmpty || isTranslating)

                Button(action: onCopy) {
                    Label("複製", systemImage: "doc.on.doc")
                }
                .disabled(card.korean.isEmpty || isTranslating)

                Button(action: onTranslate) {
                    Label(translateButtonTitle, systemImage: "translate")
                }
                .disabled(isTranslating)

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("刪除")
                .disabled(isTranslating)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
    }

    private var translateButtonTitle: String {
        if isTranslating { return "翻譯中" }
        return card.korean.isEmpty ? "翻譯" : "重翻"
    }
}

private struct BatchImportSheet: View {
    let onImport: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var jsonText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("貼上 ChatGPT / Gemini 網頁版回傳的 JSON 陣列。App 會用 id 對應目前小卡，只補上 korean 欄位。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("JSON") {
                    TextEditor(text: $jsonText)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("匯入外部翻譯")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("匯入") {
                        onImport(jsonText)
                    }
                    .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
