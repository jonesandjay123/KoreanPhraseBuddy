# KoreanPhraseBuddy Rehearsal Notes

> Repo: `KoreanPhraseBuddy`
> App concept: `Seoul Phrase Buddy`
> Purpose: Jones rehearses the Codex + Xcode workflow before teaching Azunyan.

## Strategy

Development can move faster during rehearsal, but the class should be split into small steps with visible results. The app should become useful before API work begins.

The safest teaching sequence is:

1. Run Xcode Hello World.
2. Build a first SwiftUI UI.
3. Add phrase cards in memory.
4. Save phrase cards locally.
5. Add Korean display and fake translation.
6. Add copy and Korean TTS.
7. Add Gemini only after the local app is stable.

## Step 1: Local MVP Without Gemini

Goal:
- Replace the Xcode Hello World app with a usable local phrase-card prototype.
- Keep it API-free so Xcode, SwiftUI, state, and persistence can be tested first.

Prompt used:

```text
好 那你先按照你的步調開始執行！ 到一個你覺得合適的段落時，跟我說。
記得更新README 然後我手動測試 我說ok我們就commit請開始
```

Implementation:
- Added `PhraseCard` model.
- Added `PhraseStore` for `UserDefaults` persistence with `Codable`.
- Added `SpeechService` for Korean TTS through `AVSpeechSynthesizer`.
- Replaced `ContentView` with:
  - title
  - Chinese input
  - add-card button
  - list of cards
  - sample translation button
  - copy button
  - speak button
  - delete button
  - example-card toolbar button

Files changed:
- `KoreanPhraseBuddy/ContentView.swift`
- `KoreanPhraseBuddy/PhraseCard.swift`
- `KoreanPhraseBuddy/PhraseStore.swift`
- `KoreanPhraseBuddy/SpeechService.swift`
- `README.md`
- `reference/VibeCoding_Workshop_session6/session6/koreanphrasebuddy-rehearsal-notes.md`

Xcode result:
- Pending Jones manual test.

Potential student issues:
- Xcode may hide root-level files like `.gitignore` and `README.md` depending on project navigator mode.
- `AVSpeechSynthesizer` may not sound natural or may be muted if the device volume / silent mode blocks audio.
- `UserDefaults` persistence is invisible; teach it by adding a card, closing the app, and reopening.

Teaching note:
- This step maps cleanly to the concept from earlier sessions: data can be encoded, saved, and restored separately from the UI.
- Do not introduce Gemini here. Let the student feel that the app already exists before API complexity arrives.

## Suggested Student Prompts

### Prompt A: First UI

```text
Please update this SwiftUI app to make a simple Seoul Phrase Buddy UI.

Requirements:
- Page title: Seoul Phrase Buddy
- A text input where the user can type a Chinese phrase
- An Add Card button
- A list that shows added Chinese phrase cards
- Use @State only for now
- Do not add networking or API calls yet
- Keep the code beginner-friendly
```

### Prompt B: Local Save

```text
Please add a PhraseCard model and local saving.

Requirements:
- PhraseCard should be Identifiable and Codable
- Fields: id, chinese, korean, createdAt
- Save the card list with UserDefaults using JSONEncoder
- Load the saved list when the app starts
- Keep the implementation simple
```

### Prompt C: Korean Field And Buttons

```text
Please improve each phrase card.

Requirements:
- Show the original Chinese text
- Show Korean text if it exists
- If Korean is empty, show "尚未翻譯"
- Add buttons: Translate, Copy, Speak, Delete
- For now, Translate should set a fake Korean sample
- Do not call Gemini yet
```

### Prompt D: Copy And Speak

```text
Please implement Copy and Speak for the Korean text.

Requirements:
- Copy uses UIPasteboard
- Speak uses AVSpeechSynthesizer
- Korean speech language should be ko-KR
- If the Korean text is empty, do nothing or show a simple message
```

## Next Rehearsal Step

After Jones confirms this MVP runs in Xcode:

1. Add Gemini translation.
2. Decide where the API key goes for rehearsal.
3. Record any API or Xcode errors.
4. Convert the final path into a student-facing session6 update.

## Step 2: Gemini Key Setup And Real Translation

Goal:
- Use an Xcode-native local secret mechanism similar to Android `local.properties`.
- Keep the Gemini API key out of git.
- Replace fake translation with a real Gemini call.

Implementation:
- Added `Config/BuildSettings.xcconfig`.
- Added optional include of local-only `Config/Secrets.xcconfig`.
- Added `Config/Secrets.example.xcconfig` as the committed template.
- Added `INFOPLIST_KEY_GeminiAPIKey = "$(GEMINI_API_KEY)"` to the target build settings.
- Added `AppConfig.swift` to read `GeminiAPIKey` from the app bundle Info.plist.
- Added `GeminiTranslator.swift` with a minimal `generateContent` REST request.
- Updated the Translate button to call Gemini and save the returned Korean.

Manual key setup:

```text
Config/Secrets.xcconfig
```

```text
GEMINI_API_KEY = your_real_key_here
```

Teaching note:
- For class, show `Secrets.example.xcconfig` first, then copy it to `Secrets.xcconfig`.
- Say explicitly: this is fine for a private workshop prototype, but a production app should not ship secrets directly in the app bundle.
- If API setup blocks the student, skip Gemini and use external LLM prompt copy/paste as the fallback.

### Important Xcode Pitfall: Build Setting Is Not Enough

Observed during rehearsal:
- `Config/Secrets.xcconfig` was correct.
- `xcodebuild -showBuildSettings` showed `GEMINI_API_KEY` correctly.
- The app still showed: `請先在 Secrets.xcconfig 設定 GEMINI_API_KEY`.

Root cause:
- The key existed in Xcode build settings, but the running app reads from the app bundle `Info.plist`.
- The `Info.plist` mapping must use the same key name that `AppConfig.swift` reads.
- In this app, runtime code reads:

```swift
Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey")
```

Correct `Info.plist` mapping:

```text
GeminiAPIKey = $(GEMINI_API_KEY)
```

Manual Xcode check:
1. Open the project in Xcode.
2. Select `TARGETS -> KoreanPhraseBuddy`.
3. Open `Info`.
4. Under `Custom iOS Target Properties`, confirm there is a row:
   - Key: `GeminiAPIKey`
   - Type: `String`
   - Value: `$(GEMINI_API_KEY)`
5. Clean Build Folder, then Run again.

Teaching note:
- This is a major class pitfall. Even if the AI coding agent writes the Swift code and `.xcconfig` files correctly, Xcode may still need a manual target Info mapping.
- Tell the student the data flow explicitly:

```text
Config/Secrets.xcconfig
  -> GEMINI_API_KEY build setting
  -> Info.plist GeminiAPIKey
  -> AppConfig.swift
  -> GeminiTranslator.swift
```

Successful rehearsal result:
- Jones manually added the `GeminiAPIKey = $(GEMINI_API_KEY)` mapping.
- Gemini API translation worked in the app.

## Step 3: Travel Reliability UX

Goal:
- Make the app safer and more reliable for real travel use.
- Add a fallback path when Gemini API fails, quota is unavailable, or class Wi-Fi is unstable.

Implementation:
- Translation state:
  - Each card now disables action buttons while Gemini is translating.
  - The card shows a `ProgressView` with a short "Gemini 正在整理..." message.
- Delete safety:
  - Tapping the trash icon no longer deletes immediately.
  - A confirmation dialog appears before deleting the card.
- External LLM fallback:
  - The phrase list header has `匯出` and `匯入` buttons, matching the `JapanPhraseBuddy` design.
  - `匯出` copies a batch prompt containing the full current card list as JSON.
  - The user pastes that prompt into ChatGPT / Gemini web.
  - The external LLM returns a JSON array.
  - `匯入` opens a sheet where the user pastes that JSON array.
  - The app uses `id` to match existing cards and only updates `korean`.

Teaching note:
- This is a good moment to explain that API features need fallback routes.
- The student should learn: "If the built-in API fails, I can still use the app by exporting data to another AI and importing the result."
- This mirrors the useful idea from `JapanPhraseBuddy`: data can leave the app as JSON, be processed elsewhere, then return as JSON.

Student-facing prompt idea:

```text
Please improve this SwiftUI phrase card app for travel reliability.

Requirements:
- Show a loading state while Gemini is translating a card
- Disable that card's action buttons during translation
- Ask for confirmation before deleting a card
- Add Export and Import buttons above the card list
- Export should copy a batch prompt containing all phrase cards as JSON
- The prompt should ask an external LLM to fill the korean field for each card
- Import should accept a JSON array returned by the external LLM
- Import should use id to match existing cards and update only the korean field
- Keep the code simple and beginner-friendly
```
