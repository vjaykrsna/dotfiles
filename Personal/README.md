# My Dotfiles

This repository contains my personal dotfiles, managed with [yadm](https://yadm.io/).

## Restoring Setup on a New Machine

1.  **Install Prerequisites:**
    Run the following command to install `yadm` and other essential tools:
    ```bash
    sudo apt-get update && sudo apt-get install -y git curl git-lfs && sudo curl -fsLo /usr/local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm && sudo chmod a+x /usr/local/bin/yadm
    ```markdown
    # My Dotfiles

    Dotfiles managed with [yadm](https://yadm.io/).

    ## Quick restore

    1. Install yadm and basics:
    ```bash
    sudo apt-get update && sudo apt-get install -y git curl git-lfs
    sudo curl -fsLo /usr/local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm && sudo chmod a+x /usr/local/bin/yadm
    ```

    2. Clone (SSH recommended):
    ```bash
    yadm clone git@github.com:vjaykrsna/dotfiles.git
    ```

    Or for non-interactive HTTPS (fail if auth required):
    ```bash
    GIT_TERMINAL_PROMPT=0 yadm clone https://github.com/vjaykrsna/dotfiles.git
    ```

    3. Decrypt secrets:
    ```bash
    yadm decrypt
    ```

    ## If you see credential prompts
    - Use SSH instead of HTTPS.
    - Check `credential.helper` and `~/.git-credentials` (may contain stored tokens).
    - Private submodules or LFS can require auth even for a public top-level repo.

    ## Quick diagnostics (one-liners)
    ```bash
    git --version; yadm --version 2>/dev/null || true
    git config --get credential.helper || echo 'no helper'
    ls -la ~/.git-credentials 2>/dev/null || echo 'no credentials file'
    ssh -T git@github.com
    ```

    Replace the clone URL below when you want a verbose trace:
    ```bash
    GIT_TRACE=1 GIT_CURL_VERBOSE=1 yadm clone <repo-url>
    ```

    ```
