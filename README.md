# KoreanPhraseBuddy

`KoreanPhraseBuddy` 是一個 SwiftUI iOS 原型 App，為 Vibe Coding 工作坊第六堂課預演使用。

App 的產品概念是 **Seoul Phrase Buddy**：給台灣旅人在首爾旅行時使用的輕量韓文小幫手。它不是大型片語庫，也不追求分類管理；核心用途是把等等可能要對真人說的中文先存成小卡，需要時再轉成自然、禮貌、可複製或播放的韓文。

## 目前版本

目前版本已把本地 MVP 和 Gemini 翻譯管線接上：

- 輸入中文句子並新增成小卡
- 用 SwiftUI `List` 顯示小卡
- 使用 `UserDefaults` + `Codable` 本機保存
- 可用 iOS 編輯模式拖曳調整小卡順序，順序會一起保存
- 可用 iOS 語音辨識口述中文，文字會直接填入輸入框
- 每張小卡有韓文欄位
- 「翻譯」按鈕會呼叫 Gemini，把中文轉成自然、禮貌的韓文
- 翻譯中會顯示進度狀態，避免重複點擊
- 可把韓文複製到 iOS 剪貼簿
- 可用 `AVSpeechSynthesizer` + `ko-KR` 播放韓文
- 可整批匯出小卡 prompt 到 ChatGPT / Gemini 網頁版，再匯入 JSON 補回韓文
- 刪除小卡前會先確認，避免旅行現場誤刪
- 右上角可加入幾張首爾旅行範例小卡

## Gemini API Key 設定

本專案使用 Xcode 的 `.xcconfig` 方式管理本機 secret，概念類似 Android 的 `local.properties`：

- `Config/BuildSettings.xcconfig`：會進 git，負責載入設定
- `Config/Secrets.example.xcconfig`：會進 git，給學生參考格式
- `Config/Secrets.xcconfig`：不會進 git，放自己的 Gemini API key

請打開：

```text
Config/Secrets.xcconfig
```

把內容改成：

```text
GEMINI_API_KEY = 你的_Gemini_API_Key
```

如果是新 clone 的環境沒有 `Secrets.xcconfig`，請先複製範本：

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
```

再把 `paste_your_gemini_api_key_here` 換成真正的 key。

`Secrets.xcconfig` 已被 `.gitignore` 排除，不要把自己的 API key commit 進 repo。

## 手動測試

用 Xcode 開啟 `KoreanPhraseBuddy.xcodeproj`，選擇 Simulator 或連接的 iPhone / iPad 執行。

請確認：

- App 可正常啟動，畫面標題為 `Seoul Phrase Buddy`
- 輸入一句中文後按「新增小卡」
- 新小卡會出現在清單最上方
- 按「語音」後允許麥克風與語音辨識權限，口述中文會填入輸入框；再按「停止」會結束收音
- 按左上角「Edit」後，可拖曳調整小卡順序；重開 App 後順序仍保留
- 設定 Gemini API key 後，按「翻譯」會產生韓文
- Gemini 翻譯中會看到進度提示，按鈕會暫時停用
- 按「複製」後，韓文會進入剪貼簿
- 按「播放」後，系統會用韓文 TTS 念出來
- 按「匯出」會複製整批外部 LLM prompt
- 按「匯入」可貼回外部 LLM 回傳的 JSON 陣列，App 會用 id 對應小卡並補上韓文
- 按刪除時會先跳出確認
- 關掉 App 再打開，小卡仍然存在
- 刪除小卡後，重開 App 也不會回來

如果還沒設定 key，按「翻譯」時會顯示：

```text
請先在 Secrets.xcconfig 設定 GEMINI_API_KEY
```

Xcode console 可能會出現一些系統層 log，例如 app launch measurement、gesture gate、reporter disconnected。只要 App 沒有 crash、功能正常，這些可以先視為 Xcode / Simulator 雜訊。

## 下一步

下一步可以繼續補強：

- 課堂版 step-by-step prompt 整理
- 首爾旅行常用句包擴充

## 教學拆法

Jones 自己預演時可以讓 Codex 一次做比較多；但晚上帶櫻井妹妹時，應該拆成小步驟，每一步都能在 Xcode 看到成果：

1. Xcode Hello World 跑起來
2. 做出第一版 SwiftUI UI
3. 用 `@State` 新增小卡
4. 用 `Codable` + `UserDefaults` 保存資料
5. 加入 iOS 原生中文語音輸入，讓新增小卡不用一直打字
6. 加韓文欄位與假翻譯
7. 加複製韓文
8. 加韓文播放 TTS
9. 最後才接 Gemini
10. 補整批外部 LLM 匯出 / 匯入備援與刪除確認
11. 加入 iOS List 原生排序
