# ─────────────────────────────────────────────────────────
# RSA Registry — Windows PowerShell 用デプロイスクリプト
#
# 使い方:
#   PowerShell でこのフォルダに移動してから、以下を実行:
#     powershell -ExecutionPolicy Bypass -File deploy.ps1
# ─────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "RSA Registry - Deployment" -ForegroundColor White
Write-Host "----------------------------------------"
Write-Host ""

# ─── Step 1: index.html ───
if (-not (Test-Path "index.html")) {
    Write-Host "[ERROR] index.html がカレントディレクトリにありません。" -ForegroundColor Red
    Write-Host "        このスクリプトは index.html と同じフォルダで実行してください。"
    exit 1
}
Write-Host "[OK] index.html を確認しました" -ForegroundColor Green

# ─── Step 2: gh CLI ───
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "[ERROR] GitHub CLI (gh) がインストールされていません" -ForegroundColor Red
    Write-Host ""
    Write-Host "以下のコマンドでインストールしてください:"
    Write-Host ""
    Write-Host "    winget install --id GitHub.cli" -ForegroundColor White
    Write-Host ""
    Write-Host "(winget が動かない場合は https://cli.github.com/ からダウンロード)"
    Write-Host ""
    Write-Host "インストール後、PowerShell を一度閉じて開き直してから"
    Write-Host "もう一度このスクリプトを実行してください。"
    exit 1
}
Write-Host "[OK] GitHub CLI がインストールされています" -ForegroundColor Green

# ─── Step 3: git ───
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "[ERROR] Git がインストールされていません" -ForegroundColor Red
    Write-Host ""
    Write-Host "以下のコマンドでインストールしてください:"
    Write-Host "    winget install --id Git.Git" -ForegroundColor White
    exit 1
}
Write-Host "[OK] Git がインストールされています" -ForegroundColor Green

# ─── Step 4: gh auth ───
gh auth status *>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[INFO] GitHub にログインしていません。ブラウザで認証します..." -ForegroundColor Yellow
    Write-Host ""
    gh auth login --web --git-protocol https
}
Write-Host "[OK] GitHub に認証済みです" -ForegroundColor Green

# ─── Step 5: git config ───
$gitEmail = (git config --global user.email) 2>$null
if (-not $gitEmail) {
    Write-Host ""
    $gitEmail = Read-Host "Git で使うメールアドレスを入力してください"
    git config --global user.email $gitEmail
}
$gitName = (git config --global user.name) 2>$null
if (-not $gitName) {
    $gitName = Read-Host "Git で使う名前を入力してください"
    git config --global user.name $gitName
}
Write-Host "[OK] Git 設定: $gitName <$gitEmail>" -ForegroundColor Green

# ─── Step 6: repo name ───
Write-Host ""
$inputRepo = Read-Host "リポジトリ名を入力してください [rsa-registry]"
$repoName = if ([string]::IsNullOrWhiteSpace($inputRepo)) { "rsa-registry" } else { $inputRepo }

$owner = (gh api user --jq .login).Trim()

$repoExists = $false
gh repo view "$owner/$repoName" *>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[WARN] リポジトリ '$owner/$repoName' は既に存在します" -ForegroundColor Yellow
    $confirm = Read-Host "上書きデプロイしますか? (y/N)"
    if ($confirm -notmatch "^[Yy]$") {
        Write-Host "中止しました"
        exit 0
    }
    $repoExists = $true
}

# ─── Step 7: git init & commit ───
Write-Host ""
Write-Host "ローカルリポジトリを準備中..." -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    git init -q
    git branch -M main
}

git add .

git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -q -m "Deploy RSA Registry app"
    Write-Host "[OK] コミット完了" -ForegroundColor Green
}
else {
    Write-Host "    (コミットすべき変更なし)"
}

# ─── Step 8: push ───
Write-Host ""
if ($repoExists) {
    Write-Host "既存リポジトリに push 中..." -ForegroundColor Cyan
    git remote get-url origin *>$null
    if ($LASTEXITCODE -ne 0) {
        git remote add origin "https://github.com/$owner/$repoName.git"
    }
    git push -u origin main --force
}
else {
    Write-Host "GitHub にリポジトリを作成中..." -ForegroundColor Cyan
    gh repo create $repoName --public --source=. --push
}
Write-Host "[OK] GitHub への push 完了" -ForegroundColor Green

# ─── Step 9: enable Pages ───
Write-Host ""
Write-Host "GitHub Pages を有効化中..." -ForegroundColor Cyan

$pagesResult = (gh api -X POST "repos/$owner/$repoName/pages" -f "source[branch]=main" -f "source[path]=/" 2>&1) | Out-String
if ($pagesResult -match "already exists") {
    Write-Host "    (Pages は既に有効化されています)"
}
else {
    Write-Host "[OK] Pages 有効化リクエスト完了" -ForegroundColor Green
}

# ─── Step 10: get URL ───
Write-Host ""
Write-Host "Pages の URL を取得中..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

$url = ""
try {
    $url = ((gh api "repos/$owner/$repoName/pages" --jq .html_url) 2>$null).Trim()
}
catch {}

if ([string]::IsNullOrWhiteSpace($url)) {
    $url = "https://$owner.github.io/$repoName/"
}

# ─── Done ───
Write-Host ""
Write-Host "========================================================"
Write-Host "  デプロイ完了！" -ForegroundColor Green
Write-Host "========================================================"
Write-Host ""
Write-Host "  配布用 URL:" -ForegroundColor White
Write-Host ""
Write-Host "    $url" -ForegroundColor Cyan
Write-Host ""
Write-Host "--------------------------------------------------------"
Write-Host ""
Write-Host "次のステップ:"
Write-Host ""
Write-Host "  1. 上記 URL を iPhone の Safari で開く"
Write-Host "     (初回アクセスは反映まで 1～3 分かかることがあります)"
Write-Host ""
Write-Host "  2. 共有ボタン → 「ホーム画面に追加」 でアプリ化"
Write-Host ""
Write-Host "  3. このメッセージを関係者に送る:"
Write-Host ""
Write-Host "     --------------------------------------"
Write-Host "     RSA研究のレジストリアプリを作りました。"
Write-Host "     iPhoneのSafariで下記URLを開き、"
Write-Host "     共有ボタン → ホーム画面に追加 でアプリ化できます。"
Write-Host ""
Write-Host "     $url"
Write-Host "     --------------------------------------"
Write-Host ""
Write-Host "後日 index.html を修正したいときは:"
Write-Host ""
Write-Host "  powershell -ExecutionPolicy Bypass -File update.ps1" -ForegroundColor White
Write-Host ""
