# 🗂️ Dotfiles Management with `yadm`

This repository is managed using **`yadm` (Yet Another Dotfiles Manager)**.
It uses a **whitelist-based `.gitignore` strategy** and integrates **encryption for secrets**, ensuring reproducibility across machines without leaking private data.

This document is a **master guide** for managing this repo—written so even an AI assistant (or a new human contributor) with zero prior knowledge can confidently handle the setup.

---

## 🚀 Overview of Setup

* **Strategy**:

  * Ignore everything (`*`) by default.
  * Explicitly whitelist files and directories to track.
  * Explicitly blacklist caches, temp files, and noisy configs.
  * Encrypt sensitive files with `yadm-crypt`.

* **What gets tracked**:

  * Core shell dotfiles (`.bashrc`, `.zshrc`, `.profile`, `.gitconfig`, etc.)
  * Personal scripts and projects under `~/Personal/`
  * Select configuration files in `~/.config/` (portable ones like `starship`, `input-remapper`, `micro`, etc.)
  * Autostart entries and wallpapers for reproducible desktop setup
  * User directories (`.config/user-dirs.dirs`) for consistent \$HOME structure

* **What gets excluded**:

  * Caches (`*/cache/`), logs, browser configs, noisy editors like VSCode’s `workspaceStorage/`
  * Browser/session data (`BraveSoftware/`, `Code/`, `chromium/`, etc.)
  * System/runtime files (pulse runtime, ibus socket, ssh agent locks)
  * Shell history files

* **What gets encrypted**:

  * SSH keys (`~/.ssh/`)
  * GnuPG keys (`~/.gnupg/`)
  * `.env` files
  * Git credentials (`.git-credentials`)
  * GSConnect certs (`certificate.pem`, `private.pem`)

---

## 🔑 Key Files

### `.gitignore`

* Implements the **whitelist approach**.
* Ensures parent directories are un-ignored before child files.
* Sections:

  * Whitelisted dotfiles
  * Whitelisted configs
  * Common ignores (caches, logs, browser profiles, temp)
  * Explicit ignores (history, runtime sockets, junk)

### `.gitattributes`

* Defines which files are handled by `yadm-crypt`.
* Uses:

  ```
  filter=yadm-crypt diff=yadm-crypt merge=yadm-crypt  
  ```

  → Encrypt/decrypt seamlessly when committing/pulling.

### `.config/yadm/encrypt`

* Master list of encrypted paths.
* Drives `yadm encrypt` → creates `~/.local/share/yadm/archive`.
* Examples in current setup: `.ssh/`, `.gnupg/`, `.env`, `gsconnect` keys.

### `.gitmodules`

* Declares Git submodules.
* Current setup:

  * `Personal/myGithub/vscode-settings`

---

## 📦 Daily Workflow

### 1. Check status

```bash
yadm status        # tracked files only  
yadm status -u     # include untracked  
```

### 2. Add changes

```bash
yadm add .         # add all whitelisted changes  
yadm add <file>    # add specific files if needed  
```

### 3. Commit & push

```bash
yadm commit -m "Update <something>"  
yadm push  
```

---

## 🔐 Handling Secrets

### Encrypt new files

1. Add path to `.config/yadm/encrypt`.
2. Add same path to `.gitignore` (explicit ignore).
3. Run:

   ```bash
   yadm encrypt
   yadm add ~/.local/share/yadm/archive
   ```

### Update encrypted files

1. Edit file normally.
2. Run:

   ```bash
   yadm encrypt
   yadm add ~/.local/share/yadm/archive
   ```

### Decrypt on new machine

```bash
yadm decrypt
```

---

## 🖥️ Restoring Environment

On a new machine:

```bash
yadm clone <repo-url>  
yadm decrypt          # restore secrets  
```

This will restore:

* Shell configs, aliases, and functions
* Personal scripts (`~/Personal/`)
* Select desktop configs (`autostart`, `wallpapers`, `input-remapper`)
* User directory layouts

⚠️ **What won’t restore automatically**:

* GNOME session/dconf (`.config/dconf/user`) is tracked to sync desktop settings.
* Application-specific states (browser history, VSCode sessions, etc.).

---

## 🛠️ Customization

### Add a new tracked config

1. Ensure parent directory is whitelisted.
2. Add exact path to `.gitignore` with `!`.
3. Run `yadm add <file>`.

### Add a new encrypted config

Follow the "Encrypt new files" workflow.

### Ignore noisy files

If a config starts creating random junk, add an ignore rule under *Explicitly Ignored*.

---

## ✅ Quick Command Reference

* **Status**: `yadm status -u`
* **Add all**: `yadm add .`
* **Commit**: `yadm commit -m "message"`
* **Push**: `yadm push`
* **Encrypt secrets**: `yadm encrypt && yadm add ~/.local/share/yadm/archive`
* **Decrypt secrets**: `yadm decrypt`

---

## 📌 Notes on Current Setup

* **Whitelist-first strategy** → keeps repo minimal, reproducible, and portable.
* **GNOME dconf tracking enabled** → Restores desktop/session data for a consistent environment.
* **Browser/editor states excluded** → prevents bloat.
* **Personal scripts fully tracked** → ensures your custom tooling is portable.

---

## 🖼️ Handling Large Files with `git lfs`

This repository uses `git lfs` (Large File Storage) to manage large binary files, such as wallpapers. `git lfs` stores the large files on a separate server, and keeps lightweight pointers in the `git` repository.

### Current `git lfs` Configuration

*   **Tracked files**:
    * `*.png` and `*.jpg` files in the `Personal/Wallpaper/` directory.
    * Font files (`.ttf`, `.otf`, `.woff`, `.woff2`) in the `.local/share/fonts/` directory.

### Workflow for Large Files

1.  **Add the file**: Place the large file in the appropriate directory (e.g., `Personal/Wallpaper/` or `.local/share/fonts/`).
2.  **Track the file type**: If it's a new file type, run `yadm lfs track "*.new_extension"`.
3.  **Add the file to git**: Run `yadm add <path_to_file>`.
4.  **Commit and push**: Commit and push your changes as usual.

---
