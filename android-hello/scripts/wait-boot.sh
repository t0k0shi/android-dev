#!/usr/bin/env bash
set -euo pipefail
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

adb kill-server || true
adb start-server
adb connect 127.0.0.1:5555 >/dev/null 2>&1 || true

echo "[wait-boot] waiting for emulator-5554 to boot (heartbeat every 2s)"
for i in $(seq 1 600); do
  echo "[wait-boot] tick=$i"
  adb devices -l || true
  if adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; then
    adb -s emulator-5554 shell wm dismiss-keyguard >/dev/null 2>&1 || true
    adb -s emulator-5554 shell settings put global window_animation_scale 0 >/dev/null 2>&1 || true
    adb -s emulator-5554 shell settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
    adb -s emulator-5554 shell settings put global animator_duration_scale 0 >/dev/null 2>&1 || true
    echo "[wait-boot] BOOTED"; exit 0
  fi
  sleep 2
done
echo "[wait-boot] timeout"; exit 124
