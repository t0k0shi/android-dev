#!/usr/bin/env bash
set -euo pipefail
export ANDROID_HOME="$HOME/Android"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

adb start-server
nohup emulator -avd pixel6api34 \
  -no-window -no-snapshot -no-metrics -noaudio -no-boot-anim \
  -gpu swiftshader_indirect -accel on -cores 2 -ports 5554,5555 \
  > "$HOME/emulator.log" 2>&1 &

echo "started: log=$HOME/emulator.log"
