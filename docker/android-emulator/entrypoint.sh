#!/usr/bin/env bash
set -Eeuo pipefail

export DISPLAY="${DISPLAY:-:0}"
export HOME="${HOME:-/home/android}"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-${HOME}/.android/avd}"
export AVD_NAME="${AVD_NAME:-remote_android_14}"
export EMULATOR_WIDTH="${EMULATOR_WIDTH:-1080}"
export EMULATOR_HEIGHT="${EMULATOR_HEIGHT:-1920}"
export EMULATOR_DENSITY="${EMULATOR_DENSITY:-420}"
export EMULATOR_MEMORY_MB="${EMULATOR_MEMORY_MB:-2048}"
export NOVNC_PORT="${NOVNC_PORT:-6080}"

log() {
  printf '[android-remote] %s\n' "$*"
}

cleanup() {
  local exit_code=$?
  log "Shutting down child processes."
  jobs -pr | xargs -r kill 2>/dev/null || true
  wait || true
  exit "${exit_code}"
}
trap cleanup EXIT INT TERM

if [[ ! -c /dev/kvm ]]; then
  log "ERROR: /dev/kvm is unavailable. Start this container with --device /dev/kvm."
  exit 1
fi

mkdir -p "${ANDROID_AVD_HOME}"
rm -f /tmp/android-ready /tmp/.X0-lock

log "Starting virtual display ${DISPLAY} (${EMULATOR_WIDTH}x${EMULATOR_HEIGHT})."
Xvfb "${DISPLAY}" \
  -screen 0 "${EMULATOR_WIDTH}x${EMULATOR_HEIGHT}x24" \
  -ac +extension GLX +render -noreset \
  > /tmp/xvfb.log 2>&1 &

for _ in $(seq 1 30); do
  if xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
xdpyinfo -display "${DISPLAY}" >/dev/null

openbox > /tmp/openbox.log 2>&1 &
x11vnc \
  -display "${DISPLAY}" \
  -localhost \
  -forever \
  -shared \
  -nopw \
  -noxrecord \
  -rfbport 5900 \
  > /tmp/x11vnc.log 2>&1 &

websockify \
  --web /usr/share/novnc \
  "${NOVNC_PORT}" \
  localhost:5900 \
  > /tmp/websockify.log 2>&1 &

log "Starting Android 14 / Google Play AVD '${AVD_NAME}'."
emulator \
  "@${AVD_NAME}" \
  -accel on \
  -gpu swiftshader_indirect \
  -noaudio \
  -no-boot-anim \
  -no-snapshot \
  -wipe-data \
  -memory "${EMULATOR_MEMORY_MB}" \
  -skin "${EMULATOR_WIDTH}x${EMULATOR_HEIGHT}" \
  -dpi-device "${EMULATOR_DENSITY}" \
  > /tmp/emulator.log 2>&1 &
emulator_pid=$!

log "Waiting for Android boot completion."
booted="false"
for _ in $(seq 1 180); do
  if ! kill -0 "${emulator_pid}" 2>/dev/null; then
    log "ERROR: Android emulator exited during startup."
    tail -n 120 /tmp/emulator.log >&2 || true
    exit 1
  fi

  if adb wait-for-device shell getprop sys.boot_completed 2>/dev/null | grep -q '^1$'; then
    booted="true"
    break
  fi
  sleep 2
done

if [[ "${booted}" != "true" ]]; then
  log "ERROR: Timed out waiting for Android boot completion."
  tail -n 120 /tmp/emulator.log >&2 || true
  exit 1
fi

adb shell settings put global window_animation_scale 0 || true
adb shell settings put global transition_animation_scale 0 || true
adb shell settings put global animator_duration_scale 0 || true
touch /tmp/android-ready

log "Android is ready. noVNC is listening on port ${NOVNC_PORT}."
wait "${emulator_pid}"
