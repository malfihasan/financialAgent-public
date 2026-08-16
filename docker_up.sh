#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
PROFILE="${FINAGENT_PROFILE:-personal}"
PORT="${DASHBOARD_PORT:-3001}"
DOCS_PORT="${DOCS_PORT:-}"
IMAGE="${FINAGENT_IMAGE:-finagent:release}"
STATEMENTS_PATH=""
PROCESSING_PATH=""
CONFIG_PATH="${FINAGENT_CONFIG_DIR:-$SCRIPT_DIR/.docker-config}"
LLM_PROVIDER="${FINAGENT_LLM_PROVIDER:-}"
OLLAMA_MODEL="${FINAGENT_OLLAMA_MODEL:-}"
LLM_PROVIDER_OVERRIDE=false
OLLAMA_MODEL_OVERRIDE=false
ENV_FILE=""
DRY_RUN=false
OLLAMA_CHOICE_SET=false

[[ -n "$LLM_PROVIDER" ]] && LLM_PROVIDER_OVERRIDE=true
[[ -n "$OLLAMA_MODEL" ]] && OLLAMA_MODEL_OVERRIDE=true

usage() {
  cat <<EOF
Usage: ./docker_up.sh [options]

Starts the loaded FinAgent release image. Only the selected host folders and
dashboard port are exposed to the container.

Options:
  --statements PATH      Host path for statement files (required unless prompted)
  --processing PATH      Host path for processing output (required unless prompted)
  --profile NAME         Runtime profile (personal or dev; default: personal)
  --port NUMBER          Dashboard port on localhost (default: 3001)
  --docs-port NUMBER     Documentation port (default: dashboard port + 2)
  --config PATH          Host path for Docker config storage
  --image NAME           Loaded image tag (default: finagent:release)
  --llm-provider NAME    ollama, claude, open_router, or none
  --ollama-model [NAME]  Pull an Ollama model (default: qwen2.5:0.5b)
  --no-ollama-model      Do not download an Ollama model
  --env-file PATH        Read ANTHROPIC_API_KEY or OPENROUTER_API_KEY securely
  --dry-run              Print the command without starting Docker
  -h, --help             Show this help
EOF
}

validate_port() {
  local name="$1"
  local value="$2"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "Invalid $name '$value'. Use a whole number from 1024 to 65535 (for example, 3001)." >&2
    exit 2
  fi
  if (( value < 1024 || value > 65535 )); then
    echo "Invalid $name '$value'. Choose an unprivileged port from 1024 to 65535." >&2
    exit 2
  fi
}

load_provider_env() {
  local file="$1"
  local line key value
  [[ -f "$file" ]] || { echo "Environment file not found: $file" >&2; exit 2; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" == *=* ]] || { echo "Invalid line in $file. Expected KEY=value." >&2; exit 2; }
    key="${line%%=*}"
    value="${line#*=}"
    case "$key" in
      ANTHROPIC_API_KEY|OPENROUTER_API_KEY) export "$key=$value" ;;
      *) echo "Unsupported key '$key' in $file. Only ANTHROPIC_API_KEY and OPENROUTER_API_KEY are allowed." >&2; exit 2 ;;
    esac
  done < "$file"
}

resolve_path() {
  python3 - "$1" <<'PY'
import os
import sys

print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --statements|--processing|--profile|--port|--docs-port|--config|--image|--llm-provider|--env-file)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 1; }
      case "$1" in
        --statements) STATEMENTS_PATH="$2" ;;
        --processing) PROCESSING_PATH="$2" ;;
        --profile) PROFILE="$2" ;;
        --port) PORT="$2" ;;
        --docs-port) DOCS_PORT="$2" ;;
        --config) CONFIG_PATH="$2" ;;
        --image) IMAGE="$2" ;;
        --llm-provider) LLM_PROVIDER="$2"; LLM_PROVIDER_OVERRIDE=true ;;
        --env-file) ENV_FILE="$2" ;;
      esac
      shift 2
      ;;
    --ollama-model)
      OLLAMA_CHOICE_SET=true
      OLLAMA_MODEL_OVERRIDE=true
      OLLAMA_MODEL="qwen2.5:0.5b"
      if [[ $# -ge 2 && "$2" != --* ]]; then
        OLLAMA_MODEL="$2"
        shift
      fi
      shift
      ;;
    --no-ollama-model)
      OLLAMA_CHOICE_SET=true
      OLLAMA_MODEL=""
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

validate_port "dashboard port" "$PORT"
if (( PORT > 65533 )); then
  echo "Dashboard port '$PORT' is incompatible with FinAgent's internal documentation port. Choose --port 65533 or lower." >&2
  exit 2
fi
if [[ -z "$DOCS_PORT" ]]; then DOCS_PORT=$((PORT + 2)); fi
validate_port "documentation port" "$DOCS_PORT"
if [[ "$PORT" == "$DOCS_PORT" ]]; then
  echo "Dashboard and documentation ports must be different. Change --docs-port (for example, $((PORT + 2)))." >&2
  exit 2
fi
INTERNAL_DOCS_PORT=$((PORT + 2))
case "$PROFILE" in personal|dev) ;; *) echo "Invalid profile '$PROFILE'. Use personal or dev." >&2; exit 2 ;; esac
case "$LLM_PROVIDER" in ""|ollama|claude|open_router|none) ;; *) echo "Invalid LLM provider '$LLM_PROVIDER'. Use ollama, claude, open_router, or none." >&2; exit 2 ;; esac
if [[ -n "$ENV_FILE" ]]; then
  ENV_FILE="$(resolve_path "$ENV_FILE")"
  load_provider_env "$ENV_FILE"
fi

if [[ -z "$STATEMENTS_PATH" ]]; then
  read -r -p "Statements host path: " STATEMENTS_PATH
fi
if [[ -z "$PROCESSING_PATH" ]]; then
  read -r -p "Processing host path: " PROCESSING_PATH
fi

if [[ -z "$STATEMENTS_PATH" || -z "$PROCESSING_PATH" ]]; then
  echo "Both statements and processing paths are required." >&2
  exit 1
fi
if [[ "$OLLAMA_CHOICE_SET" == "false" && -z "$OLLAMA_MODEL" && -t 0 ]]; then
  read -r -p "Download the small Ollama model qwen2.5:0.5b? [y/N] " pull_model
  case "$pull_model" in
    y|Y|yes|YES)
      OLLAMA_MODEL="qwen2.5:0.5b"
      OLLAMA_MODEL_OVERRIDE=true
      ;;
  esac
fi
if [[ -n "$OLLAMA_MODEL" ]]; then
  if [[ -n "$LLM_PROVIDER" && "$LLM_PROVIDER" != "ollama" ]]; then
    echo "An Ollama model cannot be selected with provider '$LLM_PROVIDER'. Use --llm-provider ollama or --no-ollama-model." >&2
    exit 2
  fi
  LLM_PROVIDER="ollama"
  LLM_PROVIDER_OVERRIDE=true
fi
if [[ -z "$LLM_PROVIDER" ]]; then LLM_PROVIDER="none"; fi
if [[ "$LLM_PROVIDER" == "claude" && -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "Claude requires ANTHROPIC_API_KEY. Put it in a mode-600 env file and pass --env-file PATH." >&2
  exit 2
fi
if [[ "$LLM_PROVIDER" == "open_router" && -z "${OPENROUTER_API_KEY:-}" ]]; then
  echo "OpenRouter requires OPENROUTER_API_KEY. Put it in a mode-600 env file and pass --env-file PATH." >&2
  exit 2
fi

STATEMENTS_PATH="$(resolve_path "$STATEMENTS_PATH")"
PROCESSING_PATH="$(resolve_path "$PROCESSING_PATH")"
CONFIG_PATH="$(resolve_path "$CONFIG_PATH")"
mkdir -p "$STATEMENTS_PATH" "$PROCESSING_PATH" "$CONFIG_PATH"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required but was not found in PATH." >&2
  exit 1
fi
if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
else
  echo "Neither docker compose nor docker-compose is available." >&2
  exit 1
fi

export FINAGENT_PROFILE="$PROFILE"
export FINAGENT_IMAGE="$IMAGE"
export DASHBOARD_PORT="$PORT"
export DOCS_PORT
export FINAGENT_INTERNAL_DOCS_PORT="$INTERNAL_DOCS_PORT"
export FINAGENT_LLM_PROVIDER="$LLM_PROVIDER"
export FINAGENT_OLLAMA_MODEL="$OLLAMA_MODEL"
export FINAGENT_LLM_PROVIDER_OVERRIDE="$LLM_PROVIDER_OVERRIDE"
export FINAGENT_OLLAMA_MODEL_OVERRIDE="$OLLAMA_MODEL_OVERRIDE"
export STATEMENTS_PATH
export PROCESSING_PATH
export CONFIG_PATH

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Would run:"
  printf '%q ' "${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" --project-name finagent up -d
  echo
  printf 'Image: %s\nDashboard: http://localhost:%s\nDocumentation: http://localhost:%s\n' "$IMAGE" "$PORT" "$DOCS_PORT"
  printf 'LLM provider: %s\nOllama model: %s\n' "$LLM_PROVIDER" "${OLLAMA_MODEL:-not requested}"
  printf 'Statements: %s -> /data/statements\n' "$STATEMENTS_PATH"
  printf 'Processing: %s -> /data/processing\n' "$PROCESSING_PATH"
  printf 'Config: %s -> /config\n' "$CONFIG_PATH"
  exit 0
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Docker image '$IMAGE' is not loaded." >&2
  echo "Run: docker load -i FinAgent-Docker-x86_64.tar.gz" >&2
  exit 1
fi

"${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" --project-name finagent up -d

printf '\nFinAgent Docker is running.\n'
printf '  Dashboard: http://localhost:%s\n' "$PORT"
printf '  Documentation: http://localhost:%s\n' "$DOCS_PORT"
printf '  Statements mount: %s -> /data/statements\n' "$STATEMENTS_PATH"
printf '  Processing mount: %s -> /data/processing\n' "$PROCESSING_PATH"
printf '  Config mount: %s -> /config\n' "$CONFIG_PATH"