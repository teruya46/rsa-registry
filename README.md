# RSA Registry

人工肩関節置換術（Reverse Shoulder Arthroplasty）患者レジストリのウェブアプリです。
iPhone / Android のホーム画面に追加してアプリとして起動できます。

## 構成

- `index.html` — ウェブアプリ本体（単一HTMLファイル）
- `deploy.sh` — GitHub Pages へのデプロイ自動化スクリプト
- `update.sh` — 修正内容を GitHub に push する自動化スクリプト

## 使い方

### 初回デプロイ

```bash
bash deploy.sh
```

### 修正の反映

`index.html` を編集後：

```bash
bash update.sh
```

詳細は配布時の説明書を参照。
