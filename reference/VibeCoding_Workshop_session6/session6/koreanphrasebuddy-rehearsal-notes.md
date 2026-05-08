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
