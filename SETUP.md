# RSA Registry - セットアップ手順 (Windows)

このフォルダの中身を、GitHub アカウントで公開し、
チーム全員が使える URL を発行するまでの手順です。

---

## 前提（最初に1回だけ）

以下の2つがインストール済みである必要があります。
**未インストールなら PowerShell で1回だけ以下を実行**：

```powershell
winget install --id Git.Git
winget install --id GitHub.cli
```

インストール後は **PowerShell をいったん閉じて開き直して** ください。

---

## 手順（合計3〜5分）

### 1. このフォルダをわかりやすい場所に置く

例：`C:\Users\tell_\Documents\01_研究・論文\rsa-registry`

### 2. PowerShell を開いてフォルダに移動

PowerShell を開いて、フォルダパスの**前に `cd` を付けて**実行：

```powershell
cd "C:\Users\tell_\Documents\01_研究・論文\rsa-registry"
```

※ パスに日本語やスペースが含まれるので **ダブルクォート `"` で囲む** のがポイント

移動できたか確認：

```powershell
ls
```

`index.html`, `deploy.ps1`, `update.ps1` などが見えればOK。

### 3. デプロイスクリプトを実行

```powershell
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

これだけです。あとはスクリプトが自動で：

- GitHub CLI の確認
- GitHub へのログイン（ブラウザが自動で開きます）
- リポジトリ作成
- ファイルのアップロード
- GitHub Pages の有効化
- 配布用 URL の表示

までを実行します。

---

## 途中で聞かれること

| 聞かれること | 答え方 |
|---|---|
| GitHub にブラウザでログイン | 普段のアカウントでログイン → 認可ボタンを押す |
| Git のメールアドレス | 任意（公開アドレスとして使われる）|
| Git の名前 | 任意 |
| リポジトリ名 | そのまま Enter で `rsa-registry` |

---

## 完了後

スクリプトの最後に表示されるURLを、関係者にLINE/メールで送るだけです。

```
配布用 URL:
    https://(あなたのGitHubユーザー名).github.io/rsa-registry/
```

iPhone Safari でアクセス → 共有ボタン → 「ホーム画面に追加」 でアプリ化。

---

## 後日 index.html を修正したいとき

`index.html` を編集してから、PowerShell で：

```powershell
cd "C:\Users\tell_\Documents\01_研究・論文\rsa-registry"
powershell -ExecutionPolicy Bypass -File update.ps1
```

これで全員のアプリに反映されます。

---

## トラブルシューティング

### `cd` で「パスが見つかりません」と出る

パスを **ダブルクォート `"` で囲んでいるか** 確認してください：

```powershell
cd "C:\Users\tell_\Documents\01_研究・論文\rsa-registry"
```

### `gh` や `git` が認識されない

インストール後に PowerShell を閉じて開き直したか確認してください。
それでもダメなら winget でインストールできているか：

```powershell
gh --version
git --version
```

### スクリプト実行で「実行ポリシー」のエラー

`-ExecutionPolicy Bypass` を必ず付けて実行してください：

```powershell
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

### それ以外のエラー

PowerShell の出力をそのままコピーして Claude に送ってください。原因と対処を案内します。

---

## macOS / Linux で実行したい場合

`deploy.sh` と `update.sh` も同梱しています。ターミナルで `bash deploy.sh` で実行できます。
