#!/usr/bin/env bash
# The prebuilt binaries the build needs (gitignored): Cronet, sherpa-onnx TTS, OsmAnd router jars.
# Source order: local cache -> the fork's mirror releases -> upstream's releases. Mirrors them into
# the fork's releases (--mirror) so a deleted upstream asset can't break our builds.
set -euo pipefail
. "$(dirname "$0")/env.sh"
cd "$ROOT"
mkdir -p app/libs core/libs "$CACHE_DIR"
cronet=$(sed -n 's/^vela.cronetVersion=//p' gradle.properties)

# tag file dest min-bytes
want=(
  "cronet-runtime cronet-$cronet.aar app/libs 10000000"
  "tts-runtime sherpa-onnx-1.13.3.aar app/libs 50000000"
  "obf-runtime osmand-java.jar core/libs 10000000"
  "obf-runtime osmand-shared-jvm.jar core/libs 1000000"
  "obf-runtime gnu-trove-osmand.jar core/libs 100000"
  "obf-runtime kxml2-vela.jar core/libs 10000"
)
for w in "${want[@]}"; do
  read -r tag file dest min <<<"$w"
  c="$CACHE_DIR/$tag/$file"; mkdir -p "$(dirname "$c")"
  if [ ! -s "$c" ] || [ "$(stat -c%s "$c")" -lt "$min" ]; then
    curl -fsL -o "$c.part" "https://github.com/$FORK_REPO/releases/download/$tag/$file" \
      || curl -fsSL -o "$c.part" "https://github.com/$UPSTREAM_REPO/releases/download/$tag/$file"
    mv "$c.part" "$c"
  fi
  [ "$(stat -c%s "$c")" -ge "$min" ] || { echo "error: $file is truncated" >&2; exit 1; }
  cp -f "$c" "$dest/$file"
  if [ "${1:-}" = "--mirror" ]; then
    gh release view "$tag" -R "$FORK_REPO" >/dev/null 2>&1 \
      || gh release create "$tag" -R "$FORK_REPO" --prerelease --title "$tag (build runtime)" \
           --notes "Prebuilt build input mirrored from $UPSTREAM_REPO. Not an app release." >/dev/null
    gh release upload "$tag" "$c" -R "$FORK_REPO" --clobber >/dev/null
  fi
done
echo "runtime OK (cronet $cronet)"
