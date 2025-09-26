#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source core logging
source "$SCRIPT_DIR/logging.sh"

# Set up error handling
set_robust_error_handling

# Source utilities and config
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"
