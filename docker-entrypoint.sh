#!/bin/sh
set -eu

home_dir="${HOME:-/data}"
xdg_config_home="${XDG_CONFIG_HOME:-$home_dir/.config}"
default_config_path="$xdg_config_home/pinchtab/config.json"

mkdir -p "$home_dir" "$xdg_config_home" "$(dirname "$default_config_path")"

# Generate a persisted config on first boot.
# The PINCHTAB_TOKEN env var can be used to set an auth token via Docker secrets
# or environment variables. Prefer Docker secrets for sensitive data:
#   docker run -e PINCHTAB_TOKEN_FILE=/run/secrets/pinchtab_token
if [ -z "${PINCHTAB_CONFIG:-}" ] && [ ! -f "$default_config_path" ]; then
  /usr/local/bin/pinchtab config init >/dev/null
  # Docker containers need to bind to 0.0.0.0 for port publishing to work
  /usr/local/bin/pinchtab config set server.bind "0.0.0.0" >/dev/null
  # Railway injects PORT env var — override the default port if set
  if [ -n "${PORT:-}" ]; then
    /usr/local/bin/pinchtab config set server.port "$PORT" >/dev/null
  fi
  if [ -n "${PINCHTAB_TOKEN:-}" ]; then
    /usr/local/bin/pinchtab config set server.token "$PINCHTAB_TOKEN" >/dev/null
  fi
  # Trust reverse proxy headers (Railway edge sets X-Forwarded-*)
  /usr/local/bin/pinchtab config set server.trustProxyHeaders true >/dev/null
fi

exec "$@"
