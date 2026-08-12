# 実装判断メモ

| 論点 | 確認内容 | 出典 |
| --- | --- | --- |
| Android 14 | Android 14 は API level 34。 | [Android SDK Platform release notes](https://developer.android.com/tools/releases/platforms) |
| Google Play | `Google Play` とラベル付けされたシステムイメージは Play Store を含む。 | [Android SDK Platform release notes](https://developer.android.com/tools/releases/platforms) |
| AVD 作成 | `avdmanager create avd -n <name> -k <sdk_id>` で SDK システムイメージを指定して AVD を作成できる。 | [avdmanager](https://developer.android.com/tools/avdmanager) |
| CI の KVM | GitHub Actions の Linux ランナーでハードウェアアクセラレーションを利用する際は KVM デバイス権限の設定が必要。 | [android-emulator-runner README](https://github.com/ReactiveCircus/android-emulator-runner) |
| トンネル | Cloudflare のリモート管理トンネルはトンネルトークンを使用して実行し、公開アプリケーションでは公開ホスト名からローカルサービスへルーティングできる。 | [Create a tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/) |
| 公開保護 | Cloudflare Access は公開ホスト名の前に認証・許可ポリシーを置ける。Access 未設定の公開アプリケーションはインターネット公開される。 | [Publish a self-hosted application](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/) |

通常版 Docker-Android は README 上で Google Play Store を未対応としているため、本実装は SDK の `system-images;android-34;google_apis_playstore;x86_64` を Dockerfile 内で明示的に取得する独自イメージ方式を採用する。

| Quick Tunnel | `cloudflared tunnel --url http://localhost:8080` は Cloudflare アカウントや DNS 設定なしでランダムな `trycloudflare.com` サブドメインを発行する。 | [Cloudflare Quick Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/) |
| Quick Tunnel の制約 | テスト・開発用途限定で、SLA はなく、同時プロキシ要求は 200 件まで、SSE は非対応。 | [Cloudflare Quick Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/) |

Quick Tunnel は Cloudflare Access の保護を設定できないため、noVNC 側で VNC パスワードを必須にする。パスワードは GitHub Actions シークレットで与え、Quick Tunnel の URL と組み合わせて接続を制限する。
