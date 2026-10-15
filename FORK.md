# Vela — Bilson fork

Fork of [PimpinPumpkin/Vela](https://github.com/PimpinPumpkin/Vela) (GPL-3.0), built, signed and
published from **oracle** (`~/Projects/Vela`). GitHub Actions are **disabled** on this fork:
upstream's workflows (nightlies, data bakes, issue triage) must not run under our account.

## What differs from upstream

| Thing | Upstream | This fork |
| --- | --- | --- |
| Package id | `app.vela` | `app.vela.bilson` (`gradle.properties`), installs beside upstream |
| APK signing key | upstream's | ours: `~/.vela-signing/vela-release.jks` (CN=Vela Maps (Bilson build)) |
| Signed settings file (`calibration.json`: Google endpoints, notices, **transform JS**) | upstream key | our key, pinned in `CalibrationStore.PINNED_PUBLIC_KEY`; private half `~/.vela-signing/vela-calibration.key` |
| Repo / updater / What's new / settings-file links | `PimpinPumpkin/Vela` | `joshbilson/Vela` (`core/.../config/VelaLinks.kt`) |
| Open map data (regions, overlays, places, basemap, voices), map fonts | upstream releases / Pages | **unchanged**: still read from upstream, read-only public data |
| Build + release | GitHub Actions | `scripts/fork/*.sh` on oracle |

Upstream can no longer push config, notices, links or code to our builds: their bundle fails our
pinned key. We carry their Google-endpoint fixes by re-signing their `calibration.json` after it
verifies under **their** key (`sync-upstream.sh`).

Keys live only in `~/.vela-signing` (mode 700, backed up hourly by `oracle-vault`). Losing
`vela-release.jks` means installed copies can never update; reinstall would be required.

## Commands (on oracle, from the repo root)

```bash
scripts/fork/setup.sh            # once: JDK 17 (mise), Android SDK, keys if missing, runtime binaries
scripts/fork/sync-upstream.sh    # merge upstream/main, re-sign their calibration.json (review it!)
git push origin main             # the app fetches calibration.json from the fork's main
scripts/fork/build.sh --test     # :core:test + signed release APK -> ~/.local/state/vela/apks/
scripts/fork/publish.sh          # GitHub release v0.5.<run> on the fork, marked Latest
scripts/fork/publish.sh --nightly   # same, as a prerelease (Nightly channel in the app)
scripts/fork/fetch-runtime.sh --mirror   # re-mirror Cronet/TTS/OsmAnd binaries to the fork's releases
```

Version: name `0.5.<run>`, code `(2000+run)*10`, the scheme upstream's updater parses. Our run
counter (`~/.local/state/vela/run`) starts at 3000. Build log: `~/.local/state/vela/builds.tsv`.

## Installing on a phone

- **Obtainium**: add `https://github.com/joshbilson/Vela`. Tracks our Latest release.
- Or download `vela-maps-all.apk` from the fork's releases. After that, the in-app updater
  (Settings → About) checks our releases.
- Verify: `apksigner verify --print-certs vela-maps-all.apk` must show `CN=Vela Maps (Bilson build)`.

## Not done / optional

- Data bakes (obf regions, places, basemap) are upstream CI jobs with heavy inputs; we consume
  upstream's. Self-hosting them means running `scripts/build-*.sh` here and pointing the
  `-P*ManifestUrl` build properties (or a pushed `links` bundle) at our host.
- No MapTiler key (`-PmaptilerKey`): the keyless OpenFreeMap basemap is used.
- No F-Droid repo for the fork (upstream's `fdroid-repo.yml` is Actions-only).
