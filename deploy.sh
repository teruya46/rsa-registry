#!/bin/bash
# ─────────────────────────────────────────────────────────
# RSA Registry — 初回デプロイスクリプト
#
# このスクリプトは以下を全自動で実行します:
#   1. GitHub CLI (gh) の存在確認・認証確認
#   2. git の初期設定確認
#   3. このフォルダを git リポジトリ化
#   4. GitHub に public リポジトリを作成 & push
#   5. GitHub Pages を有効化
#   6. 配布用 URL を表示
#
# 使い方: このフォルダで `bash deploy.sh` を実行するだけ
# ─────────────────────────────────────────────────────────

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}🚀 RSA Registry — Deployment${NC}"
echo "────────────────────────────────────────"
echo ""

# ─── Step 1: index.html の存在確認 ───
if [ ! -f "index.html" ]; then
  echo -e "${RED}❌ index.html がカレントディレクトリにありません。${NC}"
  echo "   このスクリプトは index.html と同じフォルダで実行してください。"
  exit 1
fi
echo -e "${GREEN}✓${NC} index.html を確認しました"

# ─── Step 2: GitHub CLI の確認 ───
if ! command -v gh &> /dev/null; then
  echo ""
  echo -e "${RED}❌ GitHub CLI (gh) がインストールされていません${NC}"
  echo ""
  echo "以下のコマンドでインストールしてください:"
  echo ""
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "   ${BOLD}brew install gh${NC}"
    echo ""
    echo "(Homebrew がない場合: https://brew.sh からインストール)"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "   ${BOLD}sudo apt install gh${NC}  (Ubuntu/Debian)"
    echo "   詳細: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
  else
    echo "   公式手順: https://github.com/cli/cli#installation"
  fi
  echo ""
  echo "インストール後、もう一度このスクリプトを実行してください。"
  exit 1
fi
echo -e "${GREEN}✓${NC} GitHub CLI がインストールされています"

# ─── Step 3: GitHub 認証確認 ───
if ! gh auth status &> /dev/null; then
  echo ""
  echo -e "${YELLOW}🔐 GitHub にログインしていません。ブラウザで認証します...${NC}"
  echo ""
  gh auth login --web --git-protocol https
fi
echo -e "${GREEN}✓${NC} GitHub に認証済みです"

# ─── Step 4: git ユーザー設定確認 ───
if [ -z "$(git config --global user.email)" ]; then
  echo ""
  read -p "Git で使うメールアドレスを入力してください: " git_email
  git config --global user.email "$git_email"
fi
if [ -z "$(git config --global user.name)" ]; then
  read -p "Git で使う名前を入力してください: " git_name
  git config --global user.name "$git_name"
fi
echo -e "${GREEN}✓${NC} Git 設定 OK ($(git config --global user.name) <$(git config --global user.email)>)"

# ─── Step 5: リポジトリ名の確認 ───
echo ""
DEFAULT_REPO_NAME="rsa-registry"
read -p "リポジトリ名を入力してください [${DEFAULT_REPO_NAME}]: " input_repo
REPO_NAME=${input_repo:-$DEFAULT_REPO_NAME}

OWNER=$(gh api user --jq .login)

# 既存チェック
if gh repo view "$OWNER/$REPO_NAME" &> /dev/null; then
  echo -e "${YELLOW}⚠  リポジトリ '$OWNER/$REPO_NAME' は既に存在します${NC}"
  read -p "上書きデプロイしますか? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "中止しました"
    exit 0
  fi
  REPO_EXISTS=true
else
  REPO_EXISTS=false
fi

# ─── Step 6: git 初期化 & コミット ───
echo ""
echo -e "${BLUE}📦 ローカルリポジトリを準備中...${NC}"

if [ ! -d ".git" ]; then
  git init -q
  git branch -M main
fi

git add .
if git diff --cached --quiet; then
  echo "   (コミットすべき変更なし)"
else
  git commit -q -m "Deploy RSA Registry app"
  echo -e "${GREEN}✓${NC} コミット完了"
fi

# ─── Step 7: GitHub にリポジトリ作成 or push ───
echo ""
if [ "$REPO_EXISTS" = true ]; then
  echo -e "${BLUE}⬆  既存リポジトリに push 中...${NC}"
  if ! git remote get-url origin &> /dev/null; then
    git remote add origin "https://github.com/$OWNER/$REPO_NAME.git"
  fi
  git push -u origin main --force
else
  echo -e "${BLUE}📦 GitHub にリポジトリを作成中...${NC}"
  gh repo create "$REPO_NAME" --public --source=. --push
fi
echo -e "${GREEN}✓${NC} GitHub への push 完了"

# ─── Step 8: GitHub Pages を有効化 ───
echo ""
echo -e "${BLUE}🌐 GitHub Pages を有効化中...${NC}"

PAGES_RESULT=$(gh api -X POST "repos/$OWNER/$REPO_NAME/pages" \
  -f "source[branch]=main" -f "source[path]=/" 2>&1) || true

if echo "$PAGES_RESULT" | grep -q "already exists"; then
  echo "   (Pages は既に有効化されています)"
else
  echo -e "${GREEN}✓${NC} Pages 有効化リクエスト完了"
fi

# ─── Step 9: URL を取得して表示 ───
echo ""
echo -e "${BLUE}⏳ Pages の URL を取得中...${NC}"
sleep 3

URL=$(gh api "repos/$OWNER/$REPO_NAME/pages" --jq .html_url 2>/dev/null || echo "")

if [ -z "$URL" ]; then
  URL="https://${OWNER}.github.io/${REPO_NAME}/"
  echo "   (URL は次のはずです: 数分後にアクセス可能になります)"
fi

# ─── 完了 ───
echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${BOLD}${GREEN}✨ デプロイ完了！${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${BOLD}📱 配布用 URL:${NC}"
echo ""
echo -e "    ${BOLD}${BLUE}${URL}${NC}"
echo ""
echo "────────────────────────────────────────────────────────"
echo ""
echo "次のステップ:"
echo ""
echo "  1. 上記 URL を iPhone の Safari で開く"
echo "     (初回アクセスは反映まで 1〜3 分かかることがあります)"
echo ""
echo "  2. 共有ボタン → 「ホーム画面に追加」 でアプリ化"
echo ""
echo "  3. このメッセージを関係者に送る:"
echo ""
echo "     ──────────────────────────────────────"
echo "     RSA研究のレジストリアプリを作りました。"
echo "     iPhoneのSafariで下記URLを開き、"
echo "     共有ボタン→ホーム画面に追加でアプリ化できます。"
echo ""
echo "     ${URL}"
echo "     ──────────────────────────────────────"
echo ""
echo "後日 index.html を修正したいときは:"
echo ""
echo -e "  ${BOLD}bash update.sh${NC}"
echo ""
