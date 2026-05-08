# KoreanPhraseBuddy

`KoreanPhraseBuddy` 是一個 SwiftUI iOS 原型 App，為 Vibe Coding 工作坊第六堂課預演使用。

App 的產品概念是 **Seoul Phrase Buddy**：給台灣旅人在首爾旅行時使用的輕量韓文小幫手。它不是大型片語庫，也不追求分類管理；核心用途是把等等可能要對真人說的中文先存成小卡，需要時再轉成自然、禮貌、可複製或播放的韓文。

## 目前版本

第一版本地 MVP 暫時不串 Gemini，先把 iOS App 的穩定地基做起來：

- 輸入中文句子並新增成小卡
- 用 SwiftUI `List` 顯示小卡
- 使用 `UserDefaults` + `Codable` 本機保存
- 每張小卡有韓文欄位
- 「翻譯」按鈕目前先填入範例韓文
- 可把韓文複製到 iOS 剪貼簿
- 可用 `AVSpeechSynthesizer` + `ko-KR` 播放韓文
- 右上角可加入幾張首爾旅行範例小卡

## 手動測試

用 Xcode 開啟 `KoreanPhraseBuddy.xcodeproj`，選擇 Simulator 或連接的 iPhone / iPad 執行。

請確認：

- App 可正常啟動，畫面標題為 `Seoul Phrase Buddy`
- 輸入一句中文後按「新增小卡」
- 新小卡會出現在清單最上方
- 按「翻譯」後，小卡會出現範例韓文
- 按「複製」後，韓文會進入剪貼簿
- 按「播放」後，系統會用韓文 TTS 念出來
- 關掉 App 再打開，小卡仍然存在
- 刪除小卡後，重開 App 也不會回來

Xcode console 可能會出現一些系統層 log，例如 app launch measurement、gesture gate、reporter disconnected。只要 App 沒有 crash、功能正常，這些可以先視為 Xcode / Simulator 雜訊。

## 下一步

確認本地 MVP 穩定後，下一段會接 Gemini 翻譯：

- 新增最小可用 Gemini REST client
- 將 `PhraseCard.chinese` 翻成自然、禮貌、適合首爾旅行現場使用的韓文
- 翻譯完成後更新 `PhraseCard.korean` 並保存
- 保留外部 LLM 備案，避免課堂上被 API key、quota 或網路問題卡死

## 教學拆法

Jones 自己預演時可以讓 Codex 一次做比較多；但晚上帶櫻井妹妹時，應該拆成小步驟，每一步都能在 Xcode 看到成果：

1. Xcode Hello World 跑起來
2. 做出第一版 SwiftUI UI
3. 用 `@State` 新增小卡
4. 用 `Codable` + `UserDefaults` 保存資料
5. 加韓文欄位與假翻譯
6. 加複製與韓文播放
7. 最後才接 Gemini
