#!/usr/bin/env bash
set -euo pipefail

# ── 基本環境 ────────────────────────────────────────────────────────────────
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android}"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

step(){ echo -e "\n\033[1;36m==>\033[0m $*"; }

step "チェック: sdkmanager / adb"
command -v sdkmanager >/dev/null || { echo "sdkmanager が見つかりません"; exit 1; }
[ -x "$ANDROID_HOME/platform-tools/adb" ] || yes | sdkmanager "platform-tools"

# プラットフォームと build-tools を準備（無ければ導入）
PLAT_JAR="$ANDROID_HOME/platforms/android-34/android.jar"
if [ ! -f "$PLAT_JAR" ]; then
  step "platforms;android-34 を導入"
  yes | sdkmanager "platforms;android-34"
fi

if [ ! -d "$ANDROID_HOME/build-tools" ] || ! ls -1 "$ANDROID_HOME/build-tools" >/dev/null 2>&1; then
  step "build-tools;34.0.0 を導入"
  yes | sdkmanager "build-tools;34.0.0"
fi

BTVER="$(ls -v "$ANDROID_HOME/build-tools" | tail -1)"
BT="$ANDROID_HOME/build-tools/$BTVER"
for t in aapt2 d8 zipalign apksigner; do
  [ -x "$BT/$t" ] || { step "build-tools に $t が無いので 34.0.0 を追加導入"; yes | sdkmanager "build-tools;34.0.0"; BT="$ANDROID_HOME/build-tools/34.0.0"; }
done

# Java / zip
if ! command -v javac >/dev/null 2>&1; then
  step "openjdk-17-jdk を導入（sudo 権限が必要）"
  sudo apt-get update && sudo apt-get install -y openjdk-17-jdk
fi
command -v zip >/dev/null 2>&1 || { step "zip を導入（sudo 権限が必要）"; sudo apt-get install -y zip; }

# ── 最小プロジェクト生成 ────────────────────────────────────────────────
APPDIR="$HOME/hello"
step "プロジェクト作成: $APPDIR"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/src/com/example/hello" "$APPDIR/res/layout" "$APPDIR/bin" "$APPDIR/gen"
cd "$APPDIR"

cat > AndroidManifest.xml <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  package="com.example.hello" android:versionCode="1" android:versionName="1.0">
  <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="34"/>
  <application android:label="Hello" android:theme="@android:style/Theme.Material.Light.NoActionBar">
    <activity android:name=".MainActivity" android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
EOF

cat > res/layout/activity_main.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
  android:layout_width="match_parent" android:layout_height="match_parent">
  <TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Hello Emulator!"
    android:textSize="24sp"
    android:layout_gravity="center"/>
</FrameLayout>
EOF

cat > src/com/example/hello/MainActivity.java <<'EOF'
package com.example.hello;
import android.app.Activity;
import android.os.Bundle;
public class MainActivity extends Activity {
  @Override protected void onCreate(Bundle savedInstanceState){
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
  }
}
EOF

# ── ビルド ─────────────────────────────────────────────────────────────────
step "AAPT2: リソースコンパイル"
"$BT/aapt2" compile -o bin/res.zip res/layout/activity_main.xml

step "AAPT2: リンク & R.java 生成 & unsigned APK 作成"
"$BT/aapt2" link -o bin/hello_unsigned.apk -I "$PLAT_JAR" --manifest AndroidManifest.xml -R bin/res.zip --java gen

step "Java コンパイル（--release 8）"
mkdir -p bin/classes
javac --release 8 -cp "$PLAT_JAR" -d bin/classes gen/com/example/hello/R.java src/com/example/hello/MainActivity.java

step "classes.jar 生成 → d8 で DEX 生成 (--min-api 24)"
jar --create --file bin/classes.jar -C bin/classes .
"$BT/d8" --min-api 24 --lib "$PLAT_JAR" --output bin bin/classes.jar

step "classes.dex を APK に追加"
( cd bin && zip -u hello_unsigned.apk classes.dex >/dev/null )

step "zipalign"
"$BT/zipalign" -f 4 bin/hello_unsigned.apk bin/hello_aligned.apk

step "署名（debug keystore 自動生成）"
KS="$HOME/hello-debug.keystore"
if [ ! -f "$KS" ]; then
  keytool -genkey -v -keystore "$KS" -storepass android \
    -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android,O=Android,C=US"
fi
"$BT/apksigner" sign --ks "$KS" --ks-pass pass:android --key-pass pass:android \
  --out bin/hello.apk bin/hello_aligned.apk
"$BT/apksigner" verify bin/hello.apk

# ── 配布 & 起動 ────────────────────────────────────────────────────────────
APK="$(readlink -f bin/hello.apk)"
step "ADB 起動 & ブート完了待ち"
adb start-server
adb wait-for-device
adb shell 'while [[ "$(getprop sys.boot_completed)" != "1" ]]; do sleep 1; done'

step "（保険）既存の同一パッケージを削除"
adb uninstall com.example.hello || true

step "インストール（失敗時は push → pm install にフォールバック）"
if ! adb install -r -d "$APK"; then
  adb push "$APK" /data/local/tmp/hello.apk
  adb shell pm install -r -d /data/local/tmp/hello.apk
fi

step "起動"
adb shell am start -n com.example.hello/.MainActivity

step "スクリーンショット取得"
adb exec-out screencap -p > "$HOME/hello_after.png"

echo -e "\n\033[1;32m[OK]\033[0m APK: $APK"
echo "screenshot: $HOME/hello_after.png"
