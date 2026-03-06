# TODO: Make PinchTab Railway-Compatible

## Steps:

- [x] 1. Update `internal/config/config.go` - Change default BRIDGE_BIND from "127.0.0.1" to "0.0.0.0" (binds to all interfaces including IPv4/IPv6)
- [x] 2. Update `dashboard/src/components/molecules/ScreencastTile.tsx` - Replace hardcoded localhost WebSocket with relative path via proxy
- [x] 3. Update `cmd/pinchtab/cmd_dashboard.go` - Add WebSocket proxy endpoint (/screencast-proxy) and update log message for Railway
- [x] 4. Update `internal/config/config_test.go` - Update test to expect "0.0.0.0" as default
- [x] 5. Update `internal/handlers/middleware.go` - Allow WebSocket and /screencast-proxy without auth (needed for Railway)

## Notes:

- Internal localhost connections (dashboard to Chrome instances) remain unchanged as they're within the same container
- Railway supports IPv6 (docs: https://docs.railway.com/networking) - binding to 0.0.0.0 covers both IPv4 and IPv6
