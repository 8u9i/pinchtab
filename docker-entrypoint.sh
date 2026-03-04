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

STATE_DIR="${BRIDGE_STATE_DIR:-/data}"
PROFILE_DIR="${BRIDGE_PROFILE:-/data/chrome-profile}"

# Wipe Chrome profile on every start so stale/locked state from a previous
# deployment never causes launch failures.
echo "Clearing Chrome profile at ${PROFILE_DIR}..."
rm -rf "${PROFILE_DIR}"

# (Re-)create fresh directories — safe now that we run as root.
mkdir -p "${STATE_DIR}"
mkdir -p "${PROFILE_DIR}"

exec /usr/bin/dumb-init -- pinchtab "$@"
