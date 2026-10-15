# AGENTS.md — Vela (Bilson fork)

1. Read `FORK.md` first: what this fork changes, where the keys are, and the build/publish scripts.
2. Then `CLAUDE.md` (upstream's agent guide) for the codebase itself.

Fork rules:
- Never commit anything from `~/.vela-signing`; never print `release.env`.
- Never re-enable GitHub Actions on `joshbilson/Vela` without Josh.
- Never re-sign a `calibration.json` that did not first verify under upstream's key, or that you
  edited, without Josh reviewing it: it can carry JavaScript the app runs.
- Keep fork changes small and marked `FORK` so upstream merges stay clean.
