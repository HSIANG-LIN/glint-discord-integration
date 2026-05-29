# Glint × Discord × Hermes 整合指南

將 [Glint Trade](https://glint.trade)（Polymarket prediction market 情報終端機）的 alerts 自動推送到 Discord，並透過 Hermes Agent 進行 AI 自動分析。

## 架構

```
Glint Trade ──webhook──► Discord Channel #一般
                              │
                              ▼
                    Hermes Agent (YourBotName#0000)
                              │
                              ▼
                    AI 分析（產業分類、重要性、建議）
```

## 前置需求

- Discord 伺服器 + Bot（已邀請至伺服器）
- Hermes Agent 已安裝並運行
- Glint Trade 帳號（https://glint.trade）

---

## 流程一：Discord Bot 設定

### 1. 建立 Discord Bot

1. 前往 [Discord Developer Portal](https://discord.com/developers/applications)
2. 點擊 **New Application** → 命名（如：MyBot）
3. 左側選 **Bot** → 複製 **Token**
4. 開啟 **Message Content Intent**（Privileged Gateway Intents）

### 2. 邀請 Bot 至伺服器

1. 左側選 **OAuth2** → **URL Generator**
2. Scopes 勾選：`bot`
3. Bot Permissions 勾選：
   - `Read Messages/View Channels`
   - `Read Message History`
   - `Send Messages`
4. 複製產生的 URL → 開啟瀏覽器 → 選擇伺服器 → 授權

### 3. 取得頻道 ID

1. Discord 設定 → **進階** → 開啟 **開發者模式**
2. 右鍵點擊目標頻道 → **複製頻道 ID**

---

## 流程二：Hermes Agent 設定

### 1. 環境變數（~/.hermes/.env）

```bash
# Discord Bot Token
DISCORD_BOT_TOKEN=your_token_here

# 允許接收其他 Bot 的訊息（Glint alerts 由 Glint Bot 發送）
DISCORD_ALLOW_BOTS=all

# Discord 首選頻道（可選）
DISCORD_HOME_CHANNEL=你的頻道ID
```

### 2. 設定檔（~/.hermes/config.yaml）

```yaml
discord:
  # 允許自由回應的頻道（不需要 @mention）
  free_response_channels:
    - "YOUR_CHANNEL_ID_HERE"  # 替換為你的頻道 ID

  # 各頻道的專屬分析 prompt
  channel_prompts:
    "YOUR_CHANNEL_ID_HERE": |
      你是專業的預測市場分析師。分析以下 Polymarket/Glint alerts：
      
      1. **產業分類**：歸類到哪個領域（地緣政治、總經、科技、加密貨幣等）
      2. **重要性評級**：1-5 星（5最重要）
      3. **簡短分析**：200字內說明事件背景與影響
      4. **投資/關注建議**：是否值得深入研究或關注
      
      回覆格式：
      ## 🏷️ [產業分類]
      **重要性：⭐⭐⭐⭐⭐ (X/5)**
      
      ### 📋 快速解析
      1. 事件摘要
      2. 影響分析
      3. 建議行動
```

### 3. 重啟 Gateway

```bash
hermes gateway restart
```

---

## 流程三：修復 Embed 訊息解析（關鍵）

### 問題

Glint Bot 發送的是 **embed 訊息**（富文本），而非純文字。Hermes 預設只讀取 `message.content`，導致收到空訊息：

```
[Discord] user=Glint msg='(The user sent a message with no text content)'
```

### 解決方案

修改 `plugins/platforms/discord/adapter.py`，在 `_handle_message` 方法中加入 embed 解析邏輯：

```python
# 原本
raw_content = message.content.strip()
normalized_content = raw_content

# 修改後
raw_content = message.content.strip()
normalized_content = raw_content

# Extract content from embeds (for bots like Glint that send embeds)
if not raw_content and hasattr(message, 'embeds') and message.embeds:
    embed_parts = []
    for embed in message.embeds:
        if embed.title:
            embed_parts.append(f"Title: {embed.title}")
        if embed.description:
            embed_parts.append(embed.description)
        for field in (embed.fields or []):
            if field.name:
                embed_parts.append(f"{field.name}: {field.value}" if field.value else field.name)
    if embed_parts:
        raw_content = "\n".join(embed_parts)
        normalized_content = raw_content
```

**位置**：`plugins/platforms/discord/adapter.py` 約第 4512 行

重啟 Gateway 待生效：

```bash
hermes gateway restart
```

---

## 流程四：Glint Trade 設定

### 1. 連接 Discord

1. 登入 [Glint Trade](https://glint.trade)
2. 進入 **Settings** → **Integrations**
3. 連接你的 Discord 伺服器
4. 選擇目標頻道（如：#一般）

### 2. 設定 Alerts 類型

在 **Alerts** 頁面，開啟：
- ✅ **Whale Trades**（大額交易通知）
- ✅ **Glint Signals**（AI 分析訊號）

### 3. 設定關鍵字篩選

根據你的投資興趣設定關鍵字，建議：

**台股/半導體：**
```
TSMC, Taiwan, semiconductor, chip, foxconn
```

**地緣政治：**
```
China, Taiwan strait, cross-strait, US China trade
```

**總經：**
```
Federal Reserve, Fed, interest rate, inflation, US Treasury
```

**科技/AI：**
```
NVIDIA, AI chip, data center
```

### 4. 設定 Sensitivity

- **Conservative**：5-10 alerts/day（保守）
- **Balanced**：15-25 alerts/day（平衡）
- **Aggressive**：30-40 alerts/day（積極）
- **Firehose**：50+ alerts/day（全部推送）

建議從 **Balanced** 開始，再依需求調整。

---

## 驗證步驟

### 1. 確認 Bot 連線

```bash
# 檢查 gateway logs
tail -f ~/.hermes/logs/gateway.log | grep -i discord
```

應看到：
```
[Discord] Connected as YourBotName#0000
```

### 2. 確認訊息接收

```bash
# 檢查是否有收到 Glint 訊息
grep "user=Glint" ~/.hermes/logs/gateway.log
```

### 3. 確認分析回覆

```bash
# 檢查是否有送出分析
grep "response ready.*YOUR_CHANNEL_ID_HERE" ~/.hermes/logs/gateway.log
```

### 4. 手動測試

在 Discord #一般 頻道發送一條測試訊息，確認 bot 有回應。

---

## 常見問題

### Q: Bot 收到訊息但沒回應？

A: 檢查 `free_response_channels` 是否包含該頻道 ID。

### Q: 收到 "no text content" 錯誤？

A: 確認已套用 embed 解析補丁（流程三）。

### Q: Glint Signals 沒有推送？

A: 這是 Glint 平台端問題，需檢查：
1. Glint Signals 是否開啟
2. 關鍵字設定是否正確
3. 聯繫 Glint 客服確認功能狀態

### Q: 分析結果不準確？

A: 調整 `channel_prompts` 中的分析指令，加入更明確的格式要求。

---

## 檔案結構

```
~/.hermes/
├── .env                          # 環境變數（Discord Token 等）
├── config.yaml                   # 主設定檔
├── hermes-agent/
│   └── plugins/platforms/discord/
│       └── adapter.py            # 需修改：embed 解析
└── logs/
    └── gateway.log               # 記錄檔（除錯用）
```

## License

MIT
