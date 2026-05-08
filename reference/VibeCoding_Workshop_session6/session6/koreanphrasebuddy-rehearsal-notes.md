# KoreanPhraseBuddy Rehearsal Notes

> Repo: `KoreanPhraseBuddy`
> App concept: `Seoul Phrase Buddy`
> Purpose: Jones rehearses the Codex + Xcode workflow before teaching Azunyan.

## Strategy

Development can move faster during rehearsal, but the class should be split into small steps with visible results. The app should become useful before API work begins.

Audience note:
- This repo is Jones's Traditional Chinese rehearsal version.
- Azunyan's mother tongue is Japanese, so the real class version should use Japanese-first UI copy and Japanese voice input.
- For the class build, prefer `SFSpeechRecognizer(locale: "ja-JP")` and Japanese input labels such as `音声入力`, `停止`, and `カードを追加`.
- The destination language is still Korean because the product concept is Seoul travel.

The safest teaching sequence is:

1. Run Xcode Hello World.
2. Build a first SwiftUI UI.
3. Add phrase cards in memory.
4. Save phrase cards locally.
5. Add Japanese voice input so new cards can be created without typing.
6. Add Korean display and fake translation.
7. Add copy.
8. Add Korean TTS.
9. Add Gemini only after the local app is stable.
10. Add external LLM export/import fallback.
11. Add card reordering.

Teaching sequence note:
- The rehearsal implemented Korean TTS before Chinese voice input because we were moving quickly from the local MVP.
- For Azunyan, Japanese voice input should move earlier, right after local card saving.
- That gives the student an immediate quality-of-life win: create cards by speaking Japanese, then add Korean translation and playback later.

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

## Step 4: Reorder Phrase Cards

Goal:
- Bring over the useful "reorder cards" behavior from `JapanPhraseBuddy`.
- Keep the iOS implementation low risk and native.

Implementation:
- Added `PhraseStore.moveCards(from:to:)`.
- Added `.onMove` to the SwiftUI `ForEach`.
- Added `EditButton()` in the top-left toolbar when cards exist.
- Because `PhraseStore.cards` already saves on `didSet`, the reordered list persists automatically.

Manual test:
1. Add at least three cards.
2. Tap `Edit`.
3. Drag cards into a new order.
4. Tap `Done`.
5. Quit and reopen the app.
6. Confirm the order is preserved.

Teaching note:
- This is a good low-risk feature for class.
- It demonstrates that iOS `List` already has native edit/reorder behavior.
- It also reinforces the data idea: changing the UI order is really changing the saved array order.

Student-facing prompt idea:

```text
Please add reordering to this SwiftUI phrase card list.

Requirements:
- Use the native SwiftUI List edit mode if possible
- Add an Edit button
- Let the user drag cards to reorder them
- Save the new order using the existing UserDefaults persistence
- Keep the code simple
```

## Step 5: Voice Input

Goal:
- Bring over the "fast voice input" feeling from `JapanPhraseBuddy`.
- Keep the iOS version simple: speech-to-text fills the source-language input field, then the user taps Add.
- Jones's rehearsal version uses Traditional Chinese input; Azunyan's class version should use Japanese input.

Implementation:
- Expanded `SpeechService` to import `Speech` and use `SFSpeechRecognizer`.
- Rehearsal locale: `zh-TW`.
- Class locale for Azunyan: `ja-JP`.
- Used `AVAudioEngine` to capture microphone audio.
- Added a `語音` / `停止` button beside `新增小卡`.
- Partial speech recognition results update `chineseText` live.
- Added required Info.plist keys:
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`

Manual test:
1. Run on a real iPhone / iPad if possible.
2. Tap `語音`.
3. Accept both permission prompts.
4. Speak a Chinese sentence in the rehearsal version, or a Japanese sentence in Azunyan's class version.
5. Confirm the sentence appears in the input field.
6. Tap `停止`.
7. Tap `新增小卡`.

Teaching note:
- In the real class, teach this earlier than Korean TTS, right after local persistence.
- For Azunyan, localize the UI and prompts to Japanese first. Voice input should be Japanese, not Chinese.
- This is the iOS equivalent of Android's native speech recognition flow, but iOS requires explicit privacy strings in Info.plist.
- Simulator behavior may depend on host microphone settings; real devices are a better demo target.
- If permission is denied once, the user may need to open iOS Settings to re-enable microphone or speech recognition.

Student-facing prompt idea:

```text
Please add simple Japanese voice input to this SwiftUI phrase card app.

Requirements:
- Use iOS native Speech framework
- Recognize Japanese speech with the ja-JP locale
- Add a microphone button near the text field
- While listening, update the text field with the recognized sentence
- Let the user stop listening manually
- Add the required Info.plist privacy usage descriptions
- Keep the app UI copy Japanese-first for the student build
- Keep the UI and code beginner-friendly
```

## Final Polish Notes

Current rehearsal app polish:
- The installed app display name is `Seoul Buddy` so the iPad Home Screen does not truncate `Seoul Phrase Buddy` into an awkward single-looking string.
- The in-app navigation title remains `Seoul Phrase Buddy` because there is enough space inside the app.
- A custom 1024x1024 app icon is wired through `Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- Card action buttons use a compact custom icon/text label so the icon belongs visually to its own text, not the next button.
- Microphone permission uses `AVAudioApplication.requestRecordPermission` to avoid the iOS 17 deprecation warning from `AVAudioSession.requestRecordPermission`.

Important cleanup / handoff notes:
- Do not commit `Config/Secrets.xcconfig`; it contains the local Gemini API key and is intentionally ignored.
- The key setup pitfall for iOS is still important: `Secrets.xcconfig` alone is not enough unless the target Info mapping exposes `GeminiAPIKey = $(GEMINI_API_KEY)`.
- If the app icon or Home Screen name looks stale on iPad, delete the installed app and run from Xcode again because iOS may cache those assets.
- When adapting this for Azunyan, convert UI text and source-language variables from Chinese-first to Japanese-first. The destination translation and TTS remain Korean.

Jarvis / next-agent handoff:
- Start with this file.
- Also read the root `README.md` for current manual setup and test instructions.
- For the actual Session 6 teaching guide, use the "Strategy" section above as the class order, not the order in which Jones rehearsed the implementation.
