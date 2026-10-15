# Sourced by the fork scripts: toolchain and signing paths on oracle. See FORK.md.
# shellcheck shell=bash
FORK_REPO="joshbilson/Vela"
UPSTREAM_REPO="PimpinPumpkin/Vela"
UPSTREAM_CAL_PUBKEY="MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEuz8/zxOJFhVqKco74fkmzrLlyPra4/pTEUm7lmue/Kig0T497fcs+hjhZkaSqVZAwloNrr0+0ILi7yATmU+d3g=="

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIGNING_DIR="${VELA_SIGNING_DIR:-$HOME/.vela-signing}"
STATE_DIR="${VELA_STATE_DIR:-$HOME/.local/state/vela}"
CACHE_DIR="${VELA_CACHE_DIR:-$HOME/.cache/vela-runtime}"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
if [ -z "${JAVA_HOME:-}" ] || ! "$JAVA_HOME/bin/java" -version 2>&1 | grep -q '"17\.'; then
  JAVA_HOME="$(mise where java@temurin-17 2>/dev/null || true)"
  export JAVA_HOME
fi
[ -x "${JAVA_HOME:-}/bin/java" ] || { echo "error: JDK 17 missing; run scripts/fork/setup.sh" >&2; return 1 2>/dev/null || exit 1; }
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Release signing (read by app/build.gradle.kts). The password file never leaves ~/.vela-signing.
if [ -f "$SIGNING_DIR/release.env" ]; then
  # shellcheck disable=SC1091
  . "$SIGNING_DIR/release.env"
  export VELA_KEYSTORE_PATH="$SIGNING_DIR/vela-release.jks" VELA_KEYSTORE_PASSWORD VELA_KEY_ALIAS
fi
export VELA_CALIBRATION_KEY="$SIGNING_DIR/vela-calibration.key"
