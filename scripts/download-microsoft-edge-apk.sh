#!/usr/bin/env bash
set -Eeuo pipefail

output_path="${1:?Usage: download-microsoft-edge-apk.sh OUTPUT_PATH}"
readonly release_page='https://apkcombo.com/microsoft-edge/com.microsoft.emmx/download/apk'
readonly browser_user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/137.0 Safari/537.36'

page_file="$(mktemp)"
trap 'rm -f "${page_file}"' EXIT

curl --fail --location --retry 5 --retry-all-errors \
  --user-agent "${browser_user_agent}" \
  "${release_page}" --output "${page_file}"

relative_url="$(perl -0777 -ne '
  if (m{<code>arm64-v8a</code>.*?<a href="([^"]+)" class="variant"}s) {
    print $1;
  }
' "${page_file}" | sed 's/&amp;/\&/g')"

test -n "${relative_url}"
case "${relative_url}" in
  /r2?u=*) ;;
  *)
    echo 'Could not find the signed ARM64 Edge APK URL.' >&2
    exit 1
    ;;
esac

curl --fail --location --retry 5 --retry-all-errors \
  --user-agent "${browser_user_agent}" \
  "https://apkcombo.com${relative_url}" --output "${output_path}"
