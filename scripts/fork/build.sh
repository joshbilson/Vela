#!/usr/bin/env bash
# Build a signed release APK on oracle.
#   scripts/fork/build.sh            next run number (counter in ~/.local/state/vela/run)
#   scripts/fork/build.sh --test     also run :core:test first
# Output: ~/.local/state/vela/apks/vela-maps-0.5.<run>.apk (+ prints its path last).
# Version scheme matches upstream's updater: name 0.5.<run>, code (2000+run)*10. Our counter
# starts at 3000 so it never collides with upstream tags it shares a scheme with.
set -euo pipefail
. "$(dirname "$0")/env.sh"
cd "$ROOT"
[ -n "${VELA_KEYSTORE_PASSWORD:-}" ] || { echo "error: no release keystore; run scripts/fork/setup.sh" >&2; exit 1; }
"$(dirname "$0")/fetch-runtime.sh" >/dev/null

mkdir -p "$STATE_DIR/apks"
run=$(( $(cat "$STATE_DIR/run" 2>/dev/null || echo 2999) + 1 ))
name="0.5.$run"; code=$(( (2000 + run) * 10 ))

[ "${1:-}" = "--test" ] && ./gradlew :core:test --no-daemon -q
./gradlew :app:assembleRelease --no-daemon -PappVersionName="$name" -PappVersionCode="$code"

apk=$(ls -t app/build/outputs/apk/release/*.apk | head -1)
"$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)/apksigner" verify --print-certs "$apk" \
  | grep -q 'CN=Vela Maps (Bilson build)' || { echo "error: APK not signed with the fork key" >&2; exit 1; }
out="$STATE_DIR/apks/vela-maps-$name.apk"
cp "$apk" "$out"
echo "$run" > "$STATE_DIR/run"
printf '%s\t%s\t%s\n' "$name" "$code" "$(git rev-parse --short HEAD)" >> "$STATE_DIR/builds.tsv"
echo "$out"
