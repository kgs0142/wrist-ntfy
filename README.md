# wrist-ntfy

Garmin vivoactive 5 上的訊息收發 App，透過 WiFi 直連 [ntfy.sh](https://ntfy.sh)，不需要手機。

```
手錶 (Connect IQ) ←WiFi→ Cloudflare Worker ←→ ntfy.sh ←→ 手機 (ntfy App)
```

## 功能

- 透過手錶 WiFi 直接收發訊息，不依賴藍牙或手機
- 聊天式介面：發送的訊息靠右（藍色），收到的靠左（灰色）
- 8 組快捷回覆 + 自訂文字輸入
- 訊息歷史保存在手錶 Storage 中
- 從 Garmin Connect App 設定 topic 和 Worker URL

## 架構

**為什麼需要 Cloudflare Worker？**

ntfy.sh 回傳 NDJSON（每行一個 JSON），但 Garmin Connect IQ SDK 只能解析標準 JSON，且 root 必須是 dict。Worker 負責格式轉換。

## 快速開始

### 1. 部署 Cloudflare Worker

```bash
cd cloudflare-worker
npm install
npm run deploy
```

部署後記下 Worker URL（例如 `https://ntfy-garmin-proxy.xxx.workers.dev`）。

### 2. 建置 Connect IQ App

需要 [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)。

```bash
cd connectiq-app
monkeyc -d vivoactive5 -f monkey.jungle -o bin/NtfyMessages.prg
```

或使用 VS Code 的 Monkey C 擴充套件開啟 `connectiq-app/` 資料夾進行建置。

### 3. 設定

安裝 App 到手錶後，在 Garmin Connect App 中設定：

- **Worker URL** — 你的 Cloudflare Worker 網址
- **ntfy Topic** — 你的 ntfy topic（當作頻道名稱，建議用難猜的字串）

### 4. 使用

在手機上安裝 [ntfy App](https://ntfy.sh)，訂閱同一個 topic。

手錶端操作：
- **Menu 鍵** → 觸發 WiFi 同步（收發訊息）
- **Select 鍵** → 開啟發送選單（快捷回覆 / 自訂輸入）
- **上下滑動** → 捲動訊息

## 檔案結構

```
wrist-ntfy/
├── cloudflare-worker/
│   ├── worker.js          # NDJSON → JSON 代理
│   ├── wrangler.toml      # Cloudflare 部署設定
│   └── package.json
└── connectiq-app/
    ├── manifest.xml
    ├── monkey.jungle
    ├── source/
    │   ├── NtfyApp.mc              # App 進入點
    │   ├── MessageStore.mc         # Storage 封裝
    │   ├── MessageListView.mc      # 訊息列表 UI
    │   ├── MessageListDelegate.mc  # 輸入處理
    │   ├── NtfySyncDelegate.mc     # WiFi 同步核心
    │   ├── SendMenuDelegate.mc     # 發送選單
    │   └── SettingsDelegate.mc     # 設定畫面
    └── resources/
        ├── drawables/
        ├── strings/
        └── settings/
```

## 限制

- 目前僅支援 vivoactive 5（可在 `manifest.xml` 新增其他支援 WiFi 的裝置）
- 需要手錶連上 WiFi 才能同步
- ntfy topic 沒有加密，建議使用長且隨機的 topic 名稱作為安全措施
- 手錶端最多保留 50 則訊息

## License

MIT

---

> This project was vibe-coded with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic Claude).
