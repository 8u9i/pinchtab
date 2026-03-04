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

STATE_DIR="${BRIDGE_STATE_DIR:-/tmp/pinchtab-state}"
PROFILE_DIR="${BRIDGE_PROFILE:-/tmp/chrome-profile}"

# /tmp is always writable; wipe any leftover Chrome state from a previous run.
rm -rf "${PROFILE_DIR}"
mkdir -p "${PROFILE_DIR}"

# State dir: always create it. For /tmp paths this is guaranteed to succeed.
# For volume paths (/data) this also works once Railway makes the volume writable.
mkdir -p "${STATE_DIR}"

exec /usr/bin/dumb-init -- pinchtab "$@"
