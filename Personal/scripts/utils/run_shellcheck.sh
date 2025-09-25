#!/usr/bin/env bash
# run_shellcheck.sh - Run shellcheck on repository shell scripts
# Usage: ./run_shellcheck.sh [files...]
# Example: ./run_shellcheck.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/logging.sh"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ $# -eq 0 ]; then
  # Find all .sh files under repo root
  mapfile -t files < <(find "$repo_root" -type f -name '*.sh' -print | sort)
else
  files=("$@")
fi

if [ ${#files[@]} -eq 0 ]; then
  info "No .sh files to check"
  exit 0
fi

info "Running shellcheck on ${#files[@]} files..."
echo "Running: shellcheck -x -e SC1091 ${files[*]}"
# Exclude SC1091 to avoid noise about user-local sources
if shellcheck -x -e SC1091 "${files[@]}"; then
    ok "Shellcheck passed for all files"
else
    warn "Shellcheck found issues in some files"
fi
