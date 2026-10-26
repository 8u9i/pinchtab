#!/bin/sh
set -eu

home_dir="${HOME:-/data}"
xdg_config_home="${XDG_CONFIG_HOME:-$home_dir/.config}"
default_config_path="$home_dir/.pinchtab/config.json"

# A bind-mounted data volume (Railway included) arrives owned by root. When the
# container is started as root, take ownership and drop to the unprivileged user
# before any config or Chrome profile is written.
if [ "$(id -u)" = "0" ]; then
  mkdir -p "$home_dir" "$xdg_config_home" "$(dirname "$default_config_path")"
  pinchtab_uid="$(id -u pinchtab)"
  for dir in "$home_dir" "$xdg_config_home"; do
    if [ "$(stat -c %u "$dir")" != "$pinchtab_uid" ]; then
      chown -R pinchtab:pinchtab "$dir"
    fi
  done
  exec su-exec pinchtab "$0" "$@"
fi

if ! mkdir -p "$home_dir" "$xdg_config_home" "$(dirname "$default_config_path")" 2>/dev/null; then
  echo "docker-entrypoint: cannot create $home_dir; if this is a root-owned bind mount (Railway volume), set RAILWAY_RUN_UID=0" >&2
  exit 1
fi

# Generate a persisted config on first boot.
# The PINCHTAB_TOKEN env var can be used to set an auth token via Docker secrets
# or environment variables. Prefer Docker secrets for sensitive data:
#   docker run -e PINCHTAB_TOKEN_FILE=/run/secrets/pinchtab_token
if [ -z "${PINCHTAB_CONFIG:-}" ]; then
  if [ ! -f "$default_config_path" ]; then
    /usr/local/bin/pinchtab config init >/dev/null
  fi
  # Re-apply container settings on every start so a volume created by an older
  # image picks up the platform bind, port and proxy settings.
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

# Opt-in: print the API token to the deployment log so the first login works
# without shell access. Anyone who can read the logs can use the token, so
# prefer setting PINCHTAB_TOKEN and unset PINCHTAB_LOG_TOKEN after logging in.
if [ -z "${PINCHTAB_TOKEN:-}" ] && [ "${PINCHTAB_LOG_TOKEN:-}" = "1" ]; then
  echo "pinchtab: API token (PINCHTAB_LOG_TOKEN=1; unset it after login):"
  /usr/local/bin/pinchtab config token --stdout
fi

exec "$@"
