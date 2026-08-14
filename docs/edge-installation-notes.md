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

## 実機検証で判明した互換性制約

x86_64 の Android 14 Google Play イメージで、Microsoft Edge 151.0.4129.70 の ARM64 APK は Microsoft の SHA-256 証明書指紋と一致し、インストールにも成功した。しかし `libchrome.so` 内で SIGSEGV が発生し、アプリは起動しなかった。同じリリースの ARMv7 APK は `INSTALL_FAILED_NO_MATCHING_ABIS` となった。現在の安定版 Edge は x86/x86_64 APK を提供していないため、この x86_64 エミュレータ上では最新 Edge を ADB サイドロードして正常起動させることはできない。

APKMirror では Microsoft 署名付き Edge 45.03.26.4952 の x86 APK と、その SHA-256 `3d97a445afa4fc16251a9135ae662f52e16fa9db4bde9f54f1d90666fb892989` を確認した。配布サーバーの自動取得は HTTP 403 で拒否されるため、検証回避は行わない。

Evozi/AKPCube は Google Play パッケージ `com.microsoft.emmx` の APK 取得機能を案内しており、Microsoft Edge 151.0.4129.70 を検出した。配布するファイルは必ず `apksigner` により、Microsoft の SHA-256 証明書指紋 `01e1999710a82c2749b4d50c445dc85d670b6136089d0a766a73827c82a1eac9` と一致する場合だけ導入する。

## 旧 x86 Edge APK の取得状況

導入対象は Microsoft Edge 45.03.26.4952（versionCode 4952026、x86、191,205,928 bytes）である。APKMirror が提示する期待 SHA-256 は `3d97a445afa4fc16251a9135ae662f52e16fa9db4bde9f54f1d90666fb892989`、期待する Microsoft 証明書 SHA-256 は `01e1999710a82c2749b4d50c445dc85d670b6136089d0a766a73827c82a1eac9` である。APKMirror の通常ダウンロード URL は Cloudflare challenge により自動取得が HTTP 403 となり、4PDA の同一ファイル添付も同様に HTTP 403 となった。検証回避や不明なバイナリの導入は行わず、ファイルを取得できた場合に限り上記二つの検証を通過したものだけを使用する。
