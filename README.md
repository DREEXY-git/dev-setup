# dev-setup

DREEXY の開発標準ツールチェーンを、新しいMac端末に**1コマンド**で導入するインストーラ。

> このリポジトリは公開ですが、**秘密情報は含みません**（ツール導入とMCPサーバURLの登録のみ）。
> 会社標準の本体・ドキュメントは非公開リポジトリ `DREEXY-git/ai-dev-platform` にあります。

## 使い方

新しい端末の**ターミナル**で、次の1行をコピペして実行するだけ:

```bash
curl -fsSL https://raw.githubusercontent.com/DREEXY-git/dev-setup/main/setup.sh | bash
```

これで自動導入されます（sudo・Homebrew不要、約5〜10分）:

- Node.js (LTS) / npm / pnpm
- gh（GitHub CLI）
- Claude Code / Codex CLI
- 標準MCP（context7 / sentry / linear / playwright）の登録

## このあと（各自1回・数分）

ツールは入りますが、**認証は本人のアカウントで**行います:

1. 新しいターミナルを開く（PATH反映のため）
2. `gh auth login` … 法人 **DREEXY-git** で認証
3. Claude Code にログイン（会社SSO）
4. `codex` でログイン
5. `claude` 起動 → `/mcp` → **sentry** と **linear** を Authenticate

context7・playwright は認証不要で即利用可。
