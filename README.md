# wrist-ntfy

Send and receive messages on your Garmin watch via WiFi using [ntfy.sh](https://ntfy.sh) — no phone needed.

```
Watch (Connect IQ) ←WiFi→ ntfy.sh ←→ Phone (ntfy App)
```

## Features

- Send and receive messages directly over WiFi, no Bluetooth or phone required
- Chat-style UI: sent messages aligned right (blue), received aligned left (gray)
- Pending (unsent) messages shown in muted blue; synced messages in bright blue
- 8 quick replies + custom text input via TextPicker
- Message history saved in watch Storage (up to 50 messages)
- Sent messages prefixed with "wrist-ntfy:" so you can identify the sender
- Works with any device running the [ntfy app](https://ntfy.sh) on the other end

## Supported Devices

### Vivoactive
vivoactive 3 Music, vivoactive 4 / 4S, vivoactive 5, vivoactive 6

### Venu
Venu, Venu 2 / 2S / 2 Plus, Venu 3 / 3S, Venu D, Venu 4 (41mm / 45mm)

### Fenix
Fenix 7 / 7S / 7X, Fenix 7 Pro / 7S Pro / 7X Pro, Fenix 8 (43mm / 47mm), Fenix 8 Pro 47mm, Fenix 8 Solar (47mm / 51mm), Fenix E

### Epix
Epix 2, Epix 2 Pro (42mm / 47mm / 51mm)

### Forerunner
FR 165 Music, FR 265 / 265S, FR 570 (42mm / 47mm), FR 955, FR 965, FR 970

### Others
D2 Air X10, D2 Mach 1 / 2, MARQ 2 / MARQ 2 Aviator, Enduro 3, Approach S70 (42mm / 47mm), Descent Mk3 (43mm / 51mm)

> **Requirement:** Round touchscreen Garmin watch with Connect IQ 3.1+ and WiFi.

## Getting Started

### 1. Install

Install **wrist-ntfy** from the [Connect IQ Store](https://apps.garmin.com/zh-TW/apps/83b77f53-c046-4992-bd10-7c75692590d6) on your watch.

Or build from source (see [Building](#building) below).

### 2. Configure your ntfy topic

1. Open the **Garmin Connect** app on your phone
2. Go to the app settings for **wrist-ntfy**
3. Set your **ntfy Topic** — choose a unique, hard-to-guess string (e.g. `my-secret-channel-abc123`)

> Both sides (watch and phone) must use the same topic to communicate.

### 3. Set up the phone side

1. Install the [ntfy app](https://ntfy.sh) on your phone (Android/iOS)
2. Subscribe to the **same topic** you set on the watch

### 4. Usage

**On the watch:**
- **Tap screen** — Open the action menu
  - **Sync** — Connect to WiFi, send queued messages, and fetch new messages
  - **Send Message** — Choose from 8 quick replies or type a custom message
  - **Clear Messages** — Delete all stored messages
- **Swipe up/down** (or physical buttons) — Scroll through messages

**On the phone:**
- Send a message to your ntfy topic — it will appear on the watch after the next sync
- Messages sent from the watch will appear in the ntfy app with a "wrist-ntfy:" prefix

## Building

Requires the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/).

```bash
cd connectiq-app

# Debug build (for simulator)
monkeyc -d vivoactive5 -f monkey.jungle -o bin/wrist-ntfy.prg -y path/to/developer_key.der

# Release build (.iq package for store/sideload)
monkeyc -e -f monkey.jungle -o bin/wrist-ntfy.iq -y path/to/developer_key.der
```

Or open the `connectiq-app/` folder in VS Code with the Monkey C extension.

## How It Works

1. The watch connects to WiFi and sends queued messages via `PUT https://ntfy.sh/TOPIC?message=...`
2. Then fetches new messages via `GET https://ntfy.sh/TOPIC/json?poll=1&since=TIMESTAMP`
3. ntfy returns NDJSON (newline-delimited JSON); the app parses this manually since the CIQ SDK doesn't support NDJSON
4. Messages are stored locally and displayed in a chat-style bubble UI

## Limitations

- Requires the watch to be connected to WiFi for syncing (no Bluetooth relay)
- WiFi usage drains the watch battery faster than normal — sync only when needed, avoid frequent syncing
- ntfy topics are not encrypted — use a long, random topic name for privacy
- Watch stores up to 50 messages
- ntfy.sh retains messages for up to 12 hours by default

## Security

- Your ntfy topic acts as both the address and the "password" — anyone who knows the topic can read/write messages
- Use a long, random topic name (e.g. `wntfy-a8f3b2c1d4e5`) for security
- Consider [self-hosting ntfy](https://docs.ntfy.sh/install/) for additional privacy

## License

MIT

---

> This project was built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic Claude).
