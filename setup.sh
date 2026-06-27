#!/usr/bin/env bash
# DREEXY 開発標準ツールチェーン 自動セットアップ（macOS）
#
# 新しいメンバーはこれを1回実行するだけ。手探りは不要。
# 配布用の公開ミラー: DREEXY-git/dev-setup（このファイルが setup.sh として置かれる）
#   curl -fsSL https://raw.githubusercontent.com/DREEXY-git/dev-setup/main/setup.sh | bash
#
# 管理者権限(sudo)・Homebrew は不要。Homebrew があればそちらを優先利用する。
# 認証（gh login / Claude / Codex / MCP OAuth）は本人作業のため、最後に手順を案内する。

set -euo pipefail

LOCAL="$HOME/.local"
mkdir -p "$LOCAL/bin"
ARCH="$(uname -m)"  # arm64 or x86_64
case "$ARCH" in
  arm64)  NODE_ARCH="darwin-arm64"; GH_ARCH="macOS_arm64" ;;
  x86_64) NODE_ARCH="darwin-x64";   GH_ARCH="macOS_amd64" ;;
  *) echo "未対応のアーキテクチャ: $ARCH"; exit 1 ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf "\n\033[1;36m==> %s\033[0m\n" "$1"; }

# --- PATH を ~/.zshrc に登録（未登録なら）---
PROFILE="$HOME/.zshrc"
LINE='export PATH="$HOME/.local/node/bin:$HOME/.local/bin:$PATH"'
grep -qF "$HOME/.local/node/bin" "$PROFILE" 2>/dev/null || echo "$LINE" >> "$PROFILE"
export PATH="$HOME/.local/node/bin:$HOME/.local/bin:$PATH"

# --- 1) Node.js (LTS) ---
if have brew; then
  log "Homebrew 検出 → node/pnpm/gh を brew で導入"
  brew install node gh || true
  corepack enable 2>/dev/null || true
else
  if [ ! -x "$LOCAL/node/bin/node" ]; then
    log "Node.js (LTS) を ~/.local に導入"
    LTS=$(curl -fsSL https://nodejs.org/dist/index.json | \
      python3 -c "import json,sys;print(next(v['version'] for v in json.load(sys.stdin) if v['lts']))")
    PKG="node-${LTS}-${NODE_ARCH}"
    curl -fsSL -o "$LOCAL/${PKG}.tar.gz" "https://nodejs.org/dist/${LTS}/${PKG}.tar.gz"
    tar -xzf "$LOCAL/${PKG}.tar.gz" -C "$LOCAL"
    rm -f "$LOCAL/${PKG}.tar.gz"
    ln -sfn "$LOCAL/${PKG}" "$LOCAL/node"
  else
    log "Node.js は導入済み: $($LOCAL/node/bin/node --version)"
  fi
  log "pnpm を corepack で有効化"
  corepack enable --install-directory "$LOCAL/node/bin" 2>/dev/null || corepack enable 2>/dev/null || true
  corepack prepare pnpm@latest --activate 2>/dev/null || true
fi

# --- 2) gh CLI（brewが無い場合のみ）---
if ! have gh; then
  log "gh CLI を ~/.local に導入"
  GH_VER=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | \
    python3 -c "import json,sys;print(json.load(sys.stdin)['tag_name'].lstrip('v'))")
  curl -fsSL -o "$LOCAL/gh.zip" \
    "https://github.com/cli/cli/releases/download/v${GH_VER}/gh_${GH_VER}_${GH_ARCH}.zip"
  (cd "$LOCAL" && unzip -oq gh.zip && rm -f gh.zip && ln -sfn "$LOCAL/gh_${GH_VER}_${GH_ARCH}/bin/gh" "$LOCAL/bin/gh")
fi

# --- 3) Claude Code / Codex CLI ---
# ※ Claude のデスクトップアプリを使う場合、CLI版は任意。両方あっても害はない。
log "Claude Code / Codex CLI を導入"
npm i -g @anthropic-ai/claude-code @openai/codex >/dev/null 2>&1 || \
  npm i -g @anthropic-ai/claude-code @openai/codex

# --- 4) 共通MCP（user スコープ）を登録 ---
log "標準MCP（context7 / sentry / linear / playwright）を user スコープに登録"
claude mcp add --transport http context7 https://mcp.context7.com/mcp -s user 2>/dev/null || true
claude mcp add --transport http sentry   https://mcp.sentry.dev/mcp     -s user 2>/dev/null || true
claude mcp add --transport http linear   https://mcp.linear.app/mcp     -s user 2>/dev/null || true
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest 2>/dev/null || true

# --- 完了 & 認証案内 ---
log "ツール導入 完了"
printf "node:   %s\n" "$(node --version 2>/dev/null)"
printf "pnpm:   %s\n" "$(pnpm --version 2>/dev/null)"
printf "gh:     %s\n" "$(gh --version 2>/dev/null | head -1)"
printf "claude: %s\n" "$(claude --version 2>/dev/null)"
printf "codex:  %s\n" "$(codex --version 2>/dev/null)"

cat <<'NEXT'

────────────────────────────────────────────────────────
 👤 ここから本人の認証作業（各自1回・数分）
────────────────────────────────────────────────────────
 1. 新しいターミナルを開く（PATH反映のため）
 2. GitHub:   gh auth login         （法人 DREEXY-git で）
 3. Claude:   claude にログイン       （会社SSO / Maxプラン）
 4. Codex:    codex でログイン
 5. MCP認証:  claude を起動 → /mcp → sentry と linear を Authenticate
              （Sentry org: dreexy / Linear team: DREEXY）
 ※ context7 と playwright は認証不要で即利用可。
────────────────────────────────────────────────────────
NEXT
