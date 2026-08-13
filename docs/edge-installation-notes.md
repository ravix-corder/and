# Microsoft Edge 導入と noVNC 表示固定の確認記録

- Microsoft Edge の正規配布先は Google Play であり、パッケージ名は `com.microsoft.emmx`、提供元は Microsoft Corporation である。Google Play システムイメージでの通常導入には Google アカウントが必要となる可能性がある。
- Microsoft のモバイル向け案内も Android 版 Edge の入手を案内しているが、直接 APK の公式 URL は提供していない。
- APKMirror の Microsoft Corporation 掲載ページでは、Microsoft Edge 151.0.4129.70 の最新バリアントを確認した。現在の Android 14 Google Play x86_64 エミュレータに直接適合する x86_64 バリアントは確認できず、現行版には arm-v7a/arm64-v8a バリアントが示されている。
- ARM バイナリが Google Play x86_64 エミュレータで動作可能かは、実際に `adb install` 後の起動で確認する。導入する APK はパッケージ名と署名者が Microsoft Corporation であることを検証する。
- noVNC の URL は `resize=remote` だった。固定の 1080x1920 画面をブラウザ内で縮小表示し、表示位置の変化を避けるため、URL パラメータを `resize=scale` へ変更する。

## 参照先

1. https://play.google.com/store/apps/details?id=com.microsoft.emmx&hl=en_US
2. https://explore.microsoft.com/en-us/edge/mobile
3. https://www.apkmirror.com/apk/microsoft-corporation/microsoft-edge/
4. https://github.com/novnc/noVNC/wiki/


## 選定した APK

- 配布ページ: https://www.apkmirror.com/apk/microsoft-corporation/microsoft-edge/microsoft-edge-151-0-4129-70-release/microsoft-edge-151-0-4129-70-android-apk-download/
- 直接ダウンロード URL: https://downloadr2.apkmirror.com/wp-content/uploads/2026/08/28/microsoft-edge-151-0-4129-70-android-apk-download-069fe0fffa11ed701c6eaa41feac1e18a3aea7f6.apk
- 対象: Microsoft Edge 151.0.4129.70 (412907005)、arm64-v8a、Android 10 以上、単体 APK、約 250.62 MB。
- パッケージ名: `com.microsoft.emmx`。
- 表示された既知の署名: SHA-1 `3f640e279f63bcea71082ae7e8c7efa2da014cad`、SHA-256 `01e1999710a82c2749b4d50c445dc85d670b6136089d0a766a73827c82a1eac9`。証明書の所有者は Microsoft Corporation と表示された。

導入時には、ダウンロード済み APK の SHA-256 を記録し、Android パッケージ名・バージョン・起動可否を ADB で確認する。

## 取得時の制約

APKMirror の最終配布 URL は GitHub Actions ランナーから HTTP 403 を返し、通常の `curl`・参照元・ブラウザ風 User-Agent のいずれでも自動取得できなかった。ブラウザ経由のダウンロード操作も人間確認ページへ遷移したため、このサイトの検証回避は行わない。代替配布元を用いる場合も、導入前に `apksigner` で Microsoft の SHA-256 証明書指紋との一致を検証する。
