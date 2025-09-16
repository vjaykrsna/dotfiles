# 🗂️ Dotfiles Management with `yadm`

This repository is managed with `yadm` and keeps the home directory as the worktree. This document records the exact configuration and workflows used here: what is tracked, which paths are encrypted, how `.gitignore` maps to the encrypt list, and how Git LFS and submodules are handled. Facts marked "(verified)" come from reading local files; anything else is noted as such.

---

## Overview & goals

- Purpose: keep a single-source-of-truth for dotfiles that is portable, auditable, and safe for secrets.
- Strategy: whitelist-first `.gitignore` (ignore `*`, then `!` rules), track small trusted config files, and encrypt secrets into the `yadm` archive.

---

## Top-level facts (verified)

- Worktree: `/home/vijay` (verified via `~/.local/share/yadm/repo.git/config`)
- `yadm` managed: yes (verified)
- Encrypt list file: `~/.config/yadm/encrypt` (verified)
- Encrypted archive path: `~/.local/share/yadm/archive` (expected and referenced) (verified)
- `.gitignore` uses a whitelist-first strategy (verified: `/home/vijay/.gitignore` contains `*` then `!` rules)
- Git LFS: present in repo config (`[lfs]` section present in `~/.local/share/yadm/repo.git/config`) — indicates LFS is configured for the repository (verified)

---

## Exact encrypt list (from `~/.config/yadm/encrypt`) (verified)

```
.ssh/id_*
.gnupg/
.env
.git-credentials
.config/gsconnect/private.pem
.config/gsconnect/certificate.pem
**/.env
.var/app/app.zen_browser.zen/.zen/*/key4.db
.var/app/app.zen_browser.zen/.zen/*/logins.json
.var/app/app.zen_browser.zen/.zen/*/cookies.sqlite
```

Notes:
- Private SSH keys (`.ssh/id_*`) are encrypted; public keys are tracked separately via `.gitignore` exceptions.
- Patterns include both explicit files and globs (e.g., `**/.env`) to catch env files under subdirectories.

---

## `.gitignore` mapping and intent (verified)

Highlights from `/home/vijay/.gitignore` (strategy and key rules):

- The file begins with `*` (ignore everything), followed by explicit `!` whitelist entries for files and directories that should be tracked.
- Whitelisted core files: `/.bashrc`, `/.zshrc`, `/.profile`, `/.gitconfig`, `/.gitmodules`, `/.gitattributes`.
- Personal directories are whitelisted: `/Personal/` and its contents.
- `/.local/share/yadm/` and `/.local/share/yadm/archive` are whitelisted so the encrypted archive and yadm metadata can be tracked.
- Encrypted sources are re-ignored (final override) to avoid committing plaintext: e.g. `/.ssh/id_*`, `/.gnupg/`, `/.env`, `/.git-credentials`, and the browser/profile db paths under `.var/app/...` — these mirror entries in `~/.config/yadm/encrypt` (verified mapping).

Practical effect:
- Plaintext secret files are not committed directly. Their patterns are in `~/.config/yadm/encrypt`; instead the encrypted archive (`~/.local/share/yadm/archive`) is tracked.

---

## Quick workflows (concise)

These are straightforward, intentionally concise steps (no basic git hand-holding):

- Add a tracked config: ensure parent dir is whitelisted, `yadm add <path>`, commit, push.
- Add an encrypted secret: add the path to `~/.config/yadm/encrypt`, run `yadm encrypt`, then `yadm add ~/.local/share/yadm/archive`, commit, push.
- Bootstrapping a new machine: clone with `yadm clone` and run `yadm decrypt` if archive exists.

---

## Git LFS (verified presence + configuration)

- The repo's bare config (`~/.local/share/yadm/repo.git/config`) contains a `[lfs]` section — Git LFS is configured for the repository (verified).
- You already have a top-level `.gitattributes` at `~/.gitattributes` with comprehensive patterns for images, fonts, archives, video/audio and more (verified). Do not duplicate patterns in `Personal/` unless you specifically want repo-scoped attributes.

Recommended checks and commands (only run these locally when needed):

```bash
# Ensure git-lfs is installed and configured for your user
git lfs install --local

# If you need to track a new pattern (adds to .gitattributes)
git lfs track "*.webp" # or use `yadm lfs track` if you prefer the yadm wrapper

# Show tracked LFS patterns
git lfs track
```

Notes:
- `yadm` wraps `git`, so `yadm lfs track` is equivalent to `git lfs track` when used in the yadm worktree, but `git lfs install` is typically a per-user action and should be run where LFS is used.
- Since `~/.gitattributes` already exists and contains the patterns you want, you generally only need to run `git lfs install` and ensure contributors have LFS installed.

---

## Submodules

- `.gitmodules` is whitelisted in `.gitignore` (verified). If you use submodules (e.g., `Personal/myGithub/vscode-settings`), they will appear in `.gitmodules` at repo root.
- If you manage submodules, prefer cloning with `--recurse-submodules` or running `git submodule update --init --recursive` after clone.

---

## yadm hooks and backend detection (verified steps)

- I inspected `~/.local/share/yadm/repo.git/config` and did not see a `yadm-crypt` hook reference (verified). That suggests the default `yadm` encrypt behavior is used (commonly `openssl`) or a custom `YADM_ENCRYPT_CMD` is configured elsewhere.

Please confirm if you use a custom encrypt backend (e.g., `yadm-crypt`) or a `YADM_ENCRYPT_CMD`; if so I will record the exact command string in `yadm.md`.

---

## yadmworktree helper (verified)

- `~/Personal/functions/yadmworktree` exists and is autoloaded from your shell (`~/.zshrc`) (verified). It provides `status`, `set`, `unset`, and `pull-safe` to manage `git update-index --skip-worktree` for runtime files.

---

## Encryption / decrypt steps (concise & accurate)

1. Add the secret path to `~/.config/yadm/encrypt` (relative to `$HOME`).
2. Run `yadm encrypt` to update `~/.local/share/yadm/archive`.
3. Stage and commit the archive: `yadm add ~/.local/share/yadm/archive && yadm commit -m "Update encrypted archive"`.
4. On other machines: `yadm decrypt` to restore plaintext files (you will need the passphrase).

Notes:
- Do not commit plaintext secret files; your `.gitignore` already mirrors the encrypt list (verified).
- If you use a custom encrypt command, document `YADM_ENCRYPT_CMD` in `yadm.md` so other machines behave the same.

---

## Helpful commands and references (selective)

- Inspect yadm config: `yadm config --list` (look for `YADM_ENCRYPT_CMD` or hooks).
- List hooks: `ls -la ~/.config/yadm/hooks || true` and `ls -la ~/.local/share/yadm/hooks || true`.
- Show encrypt file: `cat ~/.config/yadm/encrypt`.

---

## Open items & next steps

- Verified: exact `~/.config/yadm/encrypt` contents, presence of `~/.local/share/yadm/repo.git/config` with `yadm` and `lfs` sections, `.gitignore` whitelist-first strategy, `yadmworktree` helper present, and `~/.gitattributes` exists at the top level (verified).
- Needs verification from you (or by running the commands above): the exact `YADM_ENCRYPT_CMD` (if any). I did not find an explicit `yadm-crypt` setting in the repo git config; please confirm if you use a custom backend.

If you want, I can:
- Add or update `~/.gitattributes` with additional patterns (I will not duplicate entries if you prefer to keep a single top-level file).
- Capture `YADM_ENCRYPT_CMD` by running `yadm config --list` locally and update `yadm.md` with the exact command string.
- Reintroduce any other paragraphs from the previous version (e.g., the longer restore/script explanation).

---

## Notes

This document is the repository's source of truth for how `yadm` is configured here. If you want me to stage and commit this file (and optionally update `~/.gitattributes`), tell me to "commit" and provide a commit message. If you prefer additional sections restored from prior versions, tell me which ones and I will update accordingly.
