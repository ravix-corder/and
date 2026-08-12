# GitHub Actions 上の遠隔 Android 14

このリポジトリは、**GitHub Actions の一時 Ubuntu ランナー**上で Docker コンテナを起動し、その内部で **Android 14（API 34）・Google Play Store 付き x86_64 エミュレータ**を動かします。画面とキーボード・マウスの操作は noVNC で提供し、Cloudflare の **Quick Tunnel** が毎回ランダムな公開 URL を発行します。Cloudflare アカウント、ドメイン、Cloudflare API トークン、DNS 設定はいずれも不要です。Android 14 は API 34 に対応し、`Google Play` と明記された SDK システムイメージには Google Play Store が含まれます。[1]

> この構成は一時的な検証・デバッグ専用です。Actions のジョブが終了、失敗、またはキャンセルされると、ランナー、コンテナ、AVD のデータ、Google ログイン状態はすべて破棄されます。

## 構成

| 層 | 実装 | 役割 |
| --- | --- | --- |
| 実行基盤 | GitHub Actions `ubuntu-latest` | 手動で開始する短時間の一時 VM を提供します。 |
| コンテナ | `docker/android-emulator/Dockerfile` | Android SDK、API 34 の Google Play システムイメージ、Xvfb、x11vnc、noVNC を格納します。 |
| 仮想デバイス | `pixel_7` プロファイルの `remote_android_14` | Android 14 と Play Store を実行します。 |
| 画面操作 | Xvfb → x11vnc → noVNC | ブラウザのキーボード・マウス入力をエミュレータ画面へ転送します。 |
| 認証 | Nginx HTTP Basic 認証 | GitHub Actions シークレットのパスワードで noVNC への接続を保護します。 |
| 外部接続 | Cloudflare Quick Tunnel | アカウントなしで、ランダムな `trycloudflare.com` URL を一時発行します。 |

コンテナは `/dev/kvm` を渡して起動します。Actions 上でハードウェアアクセラレーションを使用する際は KVM のデバイス権限を有効にする必要があります。[2] noVNC の実体はコンテナ内部の `127.0.0.1:6081` に限定され、Nginx が HTTP Basic 認証を通過したリクエストだけを `6080` で中継します。ホストの `6080` ポートも `127.0.0.1` にだけバインドされ、Quick Tunnel だけがこのローカル HTTPS 経路へ接続します。

## 必要な設定

Cloudflare 側の設定は一切不要です。GitHub リポジトリの **Settings → Secrets and variables → Actions** を開き、次の **Repository secret** だけを登録してください。`NOVNC_PASSWORD` は 20 文字以上のランダムな文字列を推奨します。この値は Actions のログ、Summary、ワークフロー入力、リポジトリ内のファイルに出力されません。

| 種別 | 名前 | 用途 |
| --- | --- | --- |
| Repository secret | `NOVNC_PASSWORD` | noVNC の HTTP Basic 認証パスワードです。 |

> リポジトリは公開状態です。Quick Tunnel の URL は Actions ログや Summary から確認できるため、URL のランダム性を認証手段として扱ってはいけません。必ず強力な `NOVNC_PASSWORD` を設定し、不要になったら変更してください。

## 実行方法

GitHub の **Actions** タブで **Remote Android 14 (Google Play)** を選択し、**Run workflow** から 15、30、45、または 60 分のセッション時間を選択して開始します。ビルド完了後、ジョブの **Summary** にランダムな noVNC リンクが表示されます。リンクをブラウザで開くと HTTP Basic 認証を求められますので、次の認証情報を入力してください。

| 項目 | 値 |
| --- | --- |
| ユーザー名 | `android` |
| パスワード | GitHub の `NOVNC_PASSWORD` シークレットに登録した値 |

認証後は Android 画面を遠隔操作できます。初回起動時は SDK の Google Play システムイメージを含む Docker イメージを構築するため時間がかかります。Play Store を操作する際の Google アカウント情報は noVNC 画面上で本人が入力してください。Google のパスワードや OAuth トークンを GitHub Secrets、ワークフロー入力、リポジトリのファイルへ保存してはいけません。

セッションは選択した時間で自動終了します。すぐ終了させるときは Actions の該当ジョブをキャンセルしてください。どちらの場合も後処理がコンテナと Quick Tunnel のプロセスを停止します。

## Quick Tunnel の制約

Quick Tunnel はテスト・開発用途向けであり、永続 URL、SLA、Cloudflare Access、固定ドメインを提供しません。毎回 URL が変わり、Cloudflare は可用性を保証しません。また、同時プロキシ要求には 200 件の上限があり、Server-Sent Events は利用できません。[3] 本構成は一人の短時間操作に限定し、機密性の高いデータを扱わないでください。

## ディレクトリ

| パス | 内容 |
| --- | --- |
| `.github/workflows/remote-android.yml` | KVM 設定、イメージのビルド、コンテナ・Quick Tunnel の開始、セッション監視、終了処理を行う手動ワークフローです。 |
| `docker/android-emulator/Dockerfile` | Android 14 / Google Play システムイメージと認証用 Nginx を組み込むコンテナ定義です。 |
| `docker/android-emulator/nginx.conf` | noVNC の HTTP と WebSocket を HTTP Basic 認証付きで中継します。 |
| `docker/android-emulator/entrypoint.sh` | Xvfb、x11vnc、noVNC、Nginx、Android Emulator を起動し、ブート完了を判定します。 |
| `docs/research-notes.md` | 設計時に確認した仕様と出典です。 |

## 参考文献

[1]: https://developer.android.com/tools/releases/platforms "Android SDK Platform release notes"
[2]: https://github.com/ReactiveCircus/android-emulator-runner "Android Emulator Runner README"
[3]: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/ "Cloudflare Quick Tunnels"
