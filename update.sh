#!/bin/bash
# ─────────────────────────────────────────────────────────
# RSA Registry — 更新スクリプト
#
# index.html を修正した後、このスクリプトを実行すると
# GitHub に push されて全員のアプリに反映されます。
# ─────────────────────────────────────────────────────────

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}🔄 RSA Registry — Update${NC}"
echo "────────────────────────────────────────"
echo ""

if [ ! -d ".git" ]; then
  echo -e "${RED}❌ git リポジトリが見つかりません${NC}"
  echo "   先に bash deploy.sh でデプロイしてください。"
  exit 1
fi

# 変更があるか確認
if git diff --quiet && git diff --cached --quiet; then
  echo -e "${YELLOW}⚠  変更がありません${NC}"
  echo "   index.html を編集してから再度実行してください。"
  exit 0
fi

# 変更内容を表示
echo -e "${BLUE}📝 変更されたファイル:${NC}"
git status --short
echo ""

# コミットメッセージ
read -p "変更内容を簡単に書いてください（例: PDFリンクを追加）: " msg
msg=${msg:-"Update RSA Registry"}

# Commit & push
git add .
git commit -q -m "$msg"
echo -e "${GREEN}✓${NC} コミット完了"

echo ""
echo -e "${BLUE}⬆  GitHub に push 中...${NC}"
git push -q

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${BOLD}${GREEN}✨ 更新完了！${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  数十秒〜1分で全員のアプリに反映されます。"
echo "  ホーム画面のアプリを再起動すると最新版が読み込まれます。"
echo ""
