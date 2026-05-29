# Contributing

## Privacy Rules (重要！)

**嚴禁將以下資訊提交到公開 Repo：**

- Discord 頻道 ID、Bot ID、用戶 ID
- Bot 使用者名稱（如：YourBot#0000）
- Token、API Key、密碼
- IP 位址
- 真實姓名（LICENSE 作者欄除外）

**提交前必須執行：**
```bash
bash scripts/check_privacy.sh
```

**替換規則：**
- 頻道 ID → `YOUR_CHANNEL_ID_HERE`
- Bot ID → `YOUR_BOT_ID_HERE`
- Bot 名稱 → `YourBotName#0000`
- Token → `YOUR_TOKEN_HERE`

## Pull Request 流程

1. Fork 專案
2. 建立功能分支 (`git checkout -b feature/amazing-feature`)
3. 確認無個資洩漏
4. 提交變更 (`git commit -m 'Add amazing feature'`)
5. 推送到分支 (`git push origin feature/amazing-feature`)
6. 開啟 Pull Request

## License

貢獻即表示您同意將您的貢獻許可於 MIT License。
