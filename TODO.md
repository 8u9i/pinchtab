# TODO: Make PinchTab Railway-Compatible

## Steps:

- [x] 1. Update `internal/config/config.go` - Change default BRIDGE_BIND from "127.0.0.1" to "0.0.0.0"
- [x] 2. Update `dashboard/src/components/molecules/ScreencastTile.tsx` - Replace hardcoded localhost WebSocket with relative path
- [x] 3. Update `cmd/pinchtab/cmd_dashboard.go` - Add WebSocket proxy endpoint and update log message
- [x] 4. Update `internal/config/config_test.go` - Update test to expect "0.0.0.0" as default
