#!/bin/sh
set -e

# Railway injects PORT as an integer at runtime.
# Pinchtab reads BRIDGE_PORT for its listen port.
# Map Railway's PORT → BRIDGE_PORT so the app binds where Railway expects.
if [ -n "$PORT" ]; then
  export BRIDGE_PORT="$PORT"
fi

# Ensure BRIDGE_BIND is set to 0.0.0.0 so Railway's healthcheck can reach it.
export BRIDGE_BIND="${BRIDGE_BIND:-0.0.0.0}"

# Ensure state/profile directories exist (volume may be freshly mounted).
mkdir -p "${BRIDGE_STATE_DIR:-/data}"
mkdir -p "${BRIDGE_PROFILE:-/data/chrome-profile}"

exec /usr/bin/dumb-init -- pinchtab "$@"
