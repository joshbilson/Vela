#!/usr/bin/env bash
# Publish a built APK as a release on the fork, which is what the in-app updater and Obtainium read.
#   scripts/fork/publish.sh [apk]            stable (Latest)
#   scripts/fork/publish.sh --nightly [apk]  prerelease
# Defaults to the newest APK in ~/.local/state/vela/apks.
set -euo pipefail
. "$(dirname "$0")/env.sh"
cd "$ROOT"
pre=()
[ "${1:-}" = "--nightly" ] && { pre=(--prerelease); shift; }
apk="${1:-$(ls -t "$STATE_DIR"/apks/*.apk | head -1)}"
name=$(basename "$apk" .apk); name=${name#vela-maps-}
run=${name##*.}; code=$(( (2000 + run) * 10 ))
tag="v$name"
prev=$(git tag -l 'v0.5.*' --sort=-v:refname | grep -v "^$tag$" | head -1 || true)
notes=$(mktemp); trap 'rm -f "$notes"' EXIT
{
  echo "Bilson build of Vela Maps, from $FORK_REPO@$(git rev-parse --short HEAD)."
  echo
  echo "versionName: $name"
  echo "versionCode: $code"
  echo
  if [ -n "$prev" ]; then git log --no-merges --format='- %s' "$prev..HEAD" | head -40
  else git log --no-merges --format='- %s' -10; fi
} > "$notes"
cp "$apk" "/tmp/vela-maps-all.apk"
git tag -f "$tag" && git push -f origin "refs/tags/$tag"
gh release create "$tag" -R "$FORK_REPO" "${pre[@]}" --title "Vela $name" --notes-file "$notes" \
  "/tmp/vela-maps-all.apk#vela-maps-all.apk"
rm -f /tmp/vela-maps-all.apk
echo "published $tag"
