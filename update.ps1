# ─────────────────────────────────────────────────────────
# RSA Registry — Windows PowerShell 用更新スクリプト
#
# index.html を修正した後、以下を実行:
#   powershell -ExecutionPolicy Bypass -File update.ps1
# ─────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "RSA Registry - Update" -ForegroundColor White
Write-Host "----------------------------------------"
Write-Host ""

if (-not (Test-Path ".git")) {
    Write-Host "[ERROR] git リポジトリが見つかりません" -ForegroundColor Red
    Write-Host "        先に deploy.ps1 でデプロイしてください。"
    exit 1
}

# Check changes
git diff --quiet
$hasUnstaged = ($LASTEXITCODE -ne 0)
git diff --cached --quiet
$hasStaged = ($LASTEXITCODE -ne 0)

# Untracked files
$untracked = git ls-files --others --exclude-standard
$hasUntracked = (-not [string]::IsNullOrWhiteSpace($untracked))

if (-not ($hasUnstaged -or $hasStaged -or $hasUntracked)) {
    Write-Host "[INFO] 変更がありません" -ForegroundColor Yellow
    Write-Host "       index.html を編集してから再度実行してください。"
    exit 0
}

Write-Host "変更されたファイル:" -ForegroundColor Cyan
git status --short
Write-Host ""

$msg = Read-Host "変更内容を簡単に書いてください (例: PDFリンクを追加)"
if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "Update RSA Registry" }

git add .
git commit -q -m $msg
Write-Host "[OK] コミット完了" -ForegroundColor Green

Write-Host ""
Write-Host "GitHub に push 中..." -ForegroundColor Cyan
git push -q

Write-Host ""
Write-Host "========================================================"
Write-Host "  更新完了！" -ForegroundColor Green
Write-Host "========================================================"
Write-Host ""
Write-Host "  数十秒～1分で全員のアプリに反映されます。"
Write-Host "  ホーム画面のアプリを再起動すると最新版が読み込まれます。"
Write-Host ""
