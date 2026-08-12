# GitHub Actions 上の遠隔 Android 14

このリポジトリは、**GitHub Actions の一時 Ubuntu ランナー**上で Docker コンテナを起動し、その内部で **Android 14（API 34）・Google Play Store 付き x86_64 エミュレータ**を動かします。画面とキーボード・マウスの操作は noVNC で提供し、接続経路は Cloudflare Tunnel に限定します。Android 14 は API 34 に対応し、`Google Play` と明記された SDK システムイメージには Google Play Store が含まれます。[1]

> この構成は一時的な検証・デバッグ専用です。Actions のジョブが終了、失敗、またはキャンセルされると、ランナー、コンテナ、AVD のデータ、Google ログイン状態はすべて破棄されます。

## 構成

| 層 | 実装 | 役割 |
| --- | --- | --- |
| 実行基盤 | GitHub Actions `ubuntu-latest` | 手動で開始する短時間の一時 VM を提供します。 |
| コンテナ | `docker/android-emulator/Dockerfile` | Android SDK、API 34 の Google Play システムイメージ、Xvfb、x11vnc、noVNC を格納します。 |
| 仮想デバイス | `pixel_7` プロファイルの `remote_android_14` | Android 14 と Play Store を実行します。 |
| 画面操作 | Xvfb → x11vnc → noVNC | ブラウザのキーボード・マウス入力をエミュレータ画面へ転送します。 |
| 外部接続 | Cloudflare Tunnel + Cloudflare Access | ランナーのローカル noVNC ポートを直接公開せず、認証済みの利用者だけを接続させます。 |

コンテナは `/dev/kvm` を渡して起動します。Actions 上でハードウェアアクセラレーションを使用するためには KVM のデバイス権限を有効にする必要があります。[2] VNC サーバー自体はコンテナ内のループバックにだけ待ち受け、ホストの noVNC ポートも `127.0.0.1:6080` にのみバインドします。外部から到達できる経路は Cloudflare Tunnel だけです。

## Cloudflare の初回設定

Cloudflare ダッシュボードで **リモート管理トンネル**を一つ作成してください。トンネル名は、例えば `github-actions-android` とします。Cloudflare の手順では、公開アプリケーションには Cloudflare 管理下のドメインと公開ホスト名を設定し、公開ホスト名をローカルのオリジンサービスへルーティングします。[3]

| Cloudflare の項目 | 設定値の例 | 注意点 |
| --- | --- | --- |
| Public Hostname | `android.example.com` | Cloudflare に追加済みのドメインのサブドメインを使用します。 |
| Service type | `HTTP` | HTTPS ではなく HTTP を選択します。TLS 終端は Cloudflare 側で行います。 |
| Service URL | `http://localhost:6080` | GitHub ランナー上の noVNC サーバーを指します。 |
| Access application | Self-hosted application | Public Hostname と同じ `android.example.com` を保護対象にします。 |
| Access policy | 自分のメールアドレスまたは所属 IdP の限定グループを Allow | **Allow everyone は設定しないでください。** |

Cloudflare Access は自己ホスト型アプリケーションの手前で認証・許可ポリシーを適用できます。Access アプリケーションを作らずにトンネルの公開ホスト名だけを設定すると、そのアプリケーションはインターネットから誰でもアクセスできる状態になります。[4]

トンネル作成画面に表示される **トークン**をコピーし、GitHub リポジトリの **Settings → Secrets and variables → Actions** を開いて、次の二つを登録してください。トークンはシークレット以外に置かず、コミットもしないでください。

| 種別 | 名前 | 値 |
| --- | --- | --- |
| Repository secret | `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare ダッシュボードで作成したリモート管理トンネルの実行トークンです。 |
| Repository variable | `ANDROID_REMOTE_URL` | 例: `https://android.example.com`。末尾の `/` は不要です。 |

## 実行方法

GitHub の **Actions** タブで **Remote Android 14 (Google Play)** を選択し、**Run workflow** から 15、30、45、または 60 分のセッション時間を選択して開始します。ビルド完了後、ジョブの **Summary** に noVNC へのリンクが表示されます。ブラウザでリンクを開き、Cloudflare Access の認証を完了すると Android の画面を遠隔操作できます。

初回起動時は SDK の Google Play システムイメージを含む Docker イメージを構築するため時間がかかります。画面が起動した後は Play Store を通常どおり操作できますが、Google アカウントは noVNC 画面上で本人が入力してください。アカウントのパスワードや OAuth トークンを GitHub Secrets、ワークフロー入力、リポジトリのファイルへ保存してはいけません。

セッションは選択した時間で自動終了します。すぐ終了させるときは Actions の該当ジョブをキャンセルしてください。どちらの場合も後処理がコンテナとトンネルのプロセスを停止します。

## ディレクトリ

| パス | 内容 |
| --- | --- |
| `.github/workflows/remote-android.yml` | KVM 設定、イメージのビルド、コンテナ・トンネルの開始、セッション監視、終了処理を行う手動ワークフローです。 |
| `docker/android-emulator/Dockerfile` | Android 14 / Google Play システムイメージを組み込むコンテナ定義です。 |
| `docker/android-emulator/entrypoint.sh` | Xvfb、x11vnc、noVNC、Android Emulator を起動し、ブート完了を判定します。 |
| `docs/research-notes.md` | 設計時に確認した仕様と出典です。 |

## 運用上の注意

GitHub のホステッドランナーは永続マシンではないため、スナップショット、アプリのデータ、ダウンロード、Play Store ログイン、端末設定はいずれもジョブ終了時に失われます。継続利用、状態の保持、常時接続が必要な用途には適しません。

noVNC はエミュレータ画面を完全に操作できるため、Cloudflare Access の許可対象は最小限にし、トンネルトークンが漏えいした可能性がある場合は Cloudflare ダッシュボードで直ちにローテーションしてください。Actions は `workflow_dispatch` の手動起動だけに制限しており、プルリクエストや push によって自動公開されることはありません。

## 参考文献

[1]: https://developer.android.com/tools/releases/platforms "Android SDK Platform release notes"
[2]: https://github.com/ReactiveCircus/android-emulator-runner "Android Emulator Runner README"
[3]: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/ "Create a tunnel"
[4]: https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/ "Publish a self-hosted application to the Internet"
