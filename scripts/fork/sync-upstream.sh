#!/usr/bin/env bash
# Merge upstream main into the fork, then carry upstream's signed settings file (calibration.json)
# across under OUR key -- but only after it verifies under UPSTREAM's key, so a tampered file is
# never re-signed. Review `git log -p HEAD@{1}..HEAD -- calibration.json` (it can carry transform JS)
# before pushing. Does not push.
set -euo pipefail
. "$(dirname "$0")/env.sh"
cd "$ROOT"
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "error: tracked changes; commit first" >&2; exit 1; }
git fetch upstream --no-tags -q
git merge --no-edit upstream/main || {
  # The sig always conflicts (both sides change it); take upstream's pair, re-signed below.
  git checkout --theirs calibration.json calibration.json.sig 2>/dev/null && git add calibration.json calibration.json.sig
  if git diff --name-only --diff-filter=U | grep -q .; then
    echo "error: merge conflicts outside calibration.json -- resolve, commit, rerun" >&2; exit 1
  fi
  git commit --no-edit -q
}
git show upstream/main:calibration.json > /tmp/vela-up-cal.json
git show upstream/main:calibration.json.sig > /tmp/vela-up-cal.sig
pub=$(mktemp); trap 'rm -f "$pub" /tmp/vela-up-cal.json /tmp/vela-up-cal.sig' EXIT
{ echo "-----BEGIN PUBLIC KEY-----"; echo "$UPSTREAM_CAL_PUBKEY" | fold -w64; echo "-----END PUBLIC KEY-----"; } > "$pub"
openssl dgst -sha256 -verify "$pub" -signature <(base64 -d < /tmp/vela-up-cal.sig) /tmp/vela-up-cal.json >/dev/null \
  || { echo "error: upstream calibration.json does NOT verify under upstream's key; not re-signing" >&2; exit 1; }
openssl ec -in "$VELA_CALIBRATION_KEY" -pubout -out "$pub.ours" 2>/dev/null
if cmp -s /tmp/vela-up-cal.json calibration.json \
   && openssl dgst -sha256 -verify "$pub.ours" -signature <(base64 -d < calibration.json.sig) calibration.json >/dev/null 2>&1; then
  echo "calibration.json unchanged and already signed by us"
else
  cp /tmp/vela-up-cal.json calibration.json
  ./scripts/sign-calibration.sh
fi
rm -f "$pub.ours"
if ! git diff --quiet -- calibration.json calibration.json.sig; then
  git add calibration.json calibration.json.sig
  git commit -q -m "Fork: re-sign upstream calibration.json (version $(python3 -c 'import json;print(json.load(open("calibration.json"))["version"])'))"
fi
git log --oneline -1
echo "synced; review, then: git push origin main && scripts/fork/build.sh --test && scripts/fork/publish.sh"
