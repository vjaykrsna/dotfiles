# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Stack
- Shell scripting (Bash/Zsh)
- Docker & Docker Compose
- LiteLLM (AI Gateway)
- PostgreSQL (Database)
- Redis (Caching)
- YAML (Configuration)

## Core Architecture
- Modular Docker services (LiteLLM, Redis, PostgreSQL) in separate directories
- Zsh functions for service management (startllm/stopllm)
- Environment-based configuration (.env files)
- Automated setup scripts for system provisioning

## Critical Commands
- `startllm` - Start all services in correct order (Redis → PostgreSQL → LiteLLM)
- `stopllm` - Stop all services in reverse order (LiteLLM → PostgreSQL → Redis)
- `./scripts/setup.sh` - Run the interactive setup utility
- `source ~/.zshrc` - Reload shell configuration after changes

## Custom Patterns
- Service-specific .env files in each service directory
- Zsh functions use subshells with directory changes for service isolation
- Docker Compose files without version attribute (modern Docker Compose)
- LiteLLM configuration uses YAML anchors for model parameter reuse
- Multiple API keys rotated through environment variables

## Code Style
- Shell scripts use `set -euo pipefail` for error handling
- Functions use `#autoload` directive for Zsh autoloading
- Environment variables follow UPPER_SNAKE_CASE naming
- Docker Compose files use service-specific networks and volumes
- YAML configuration uses anchors and references for DRY principles

## Testing
- Services must be started in dependency order
- LiteLLM requires Redis and PostgreSQL to be available before startup
- Health checks implemented in Docker Compose files
- Manual verification needed after service startup

## Gotchas
- Docker group membership requires logout/login to take effect
- Service directories are hardcoded in startllm/stopllm functions
- LiteLLM configuration references Redis/PostgreSQL by container names
- Environment variables must be consistent across service configurations
