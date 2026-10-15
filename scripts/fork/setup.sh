#!/usr/bin/env bash
# One-time (idempotent) setup on oracle: JDK 17, Android SDK, signing keys, runtime binaries.
set -euo pipefail
mise install java@temurin-17 >/dev/null
SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
  zip=$(curl -fsSL https://dl.google.com/android/repository/repository2-1.xml \
    | grep -oE 'commandlinetools-linux-[0-9]+_latest.zip' | sort -uV | tail -1)
  tmp=$(mktemp -d); curl -fsSL -o "$tmp/c.zip" "https://dl.google.com/android/repository/$zip"
  unzip -q "$tmp/c.zip" -d "$tmp"; mkdir -p "$SDK/cmdline-tools"; mv "$tmp/cmdline-tools" "$SDK/cmdline-tools/latest"; rm -rf "$tmp"
fi
. "$(dirname "$0")/env.sh"
yes | sdkmanager --licenses >/dev/null || true
sdkmanager --install "platform-tools" >/dev/null   # AGP fetches the platform and build-tools it pins

# Keys: generated once, never committed, backed up by oracle-vault (~/.vela-signing is in its ITEMS).
mkdir -p "$SIGNING_DIR" && chmod 700 "$SIGNING_DIR"
if [ ! -f "$SIGNING_DIR/vela-calibration.key" ]; then
  (umask 077; openssl ecparam -name prime256v1 -genkey -noout -out "$SIGNING_DIR/vela-calibration.key")
  echo "NEW calibration key: pin its public half in CalibrationStore.PINNED_PUBLIC_KEY:"
  openssl ec -in "$SIGNING_DIR/vela-calibration.key" -pubout -outform DER 2>/dev/null | base64 -w0; echo
fi
if [ ! -f "$SIGNING_DIR/vela-release.jks" ]; then
  pw=$(openssl rand -base64 33 | tr -d '/+=\n')
  (umask 077; printf 'VELA_KEYSTORE_PASSWORD=%s\nVELA_KEY_ALIAS=vela\n' "$pw" > "$SIGNING_DIR/release.env")
  keytool -genkeypair -keystore "$SIGNING_DIR/vela-release.jks" -storetype PKCS12 -alias vela \
    -keyalg RSA -keysize 4096 -validity 36500 -storepass "$pw" -keypass "$pw" \
    -dname "CN=Vela Maps (Bilson build), O=The Bilson Company, C=AU" >/dev/null 2>&1
  chmod 600 "$SIGNING_DIR/vela-release.jks"; unset pw
  echo "NEW release keystore: $SIGNING_DIR/vela-release.jks (lose it and installed builds can never update)"
fi
"$(dirname "$0")/fetch-runtime.sh"
echo "setup OK"
