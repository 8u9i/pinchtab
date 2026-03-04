# Dashboard build stage — builds React app inside Docker so gitignored dist
# files are never needed in the build context.
FROM oven/bun:1-alpine AS dashboard-builder
WORKDIR /app
COPY dashboard/package.json dashboard/bun.lock* ./
RUN bun install --frozen-lockfile 2>/dev/null || bun install
COPY dashboard/ ./
RUN bun run build --outDir dist 2>/dev/null || bunx vite build

# Go build stage
FROM golang:1.26-alpine AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Copy built dashboard assets into the Go embed path and rename as Go expects.
COPY --from=dashboard-builder /app/dist/ ./internal/dashboard/dashboard/
RUN mv internal/dashboard/dashboard/index.html internal/dashboard/dashboard/dashboard.html 2>/dev/null || true
RUN go build -ldflags="-s -w" -o pinchtab ./cmd/pinchtab

# Runtime stage
FROM alpine:latest

LABEL org.opencontainers.image.source="https://github.com/pinchtab/pinchtab"
LABEL org.opencontainers.image.description="High-performance browser automation bridge"

# Install Chromium and dependencies
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    dumb-init

# Copy binary from builder
COPY --from=builder /build/pinchtab /usr/local/bin/pinchtab

# Copy and sanitize entrypoint (strip UTF-8 BOM + CRLF for Windows-edited files)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN sed -i '1s/^\xEF\xBB\xBF//' /usr/local/bin/docker-entrypoint.sh \
    && sed -i 's/\r//' /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Run as root — Railway volumes are mounted root-owned at runtime;
# --no-sandbox is already required for Chrome so the non-root isolation
# benefit is moot. Running as root avoids permission errors on the volume.
WORKDIR /data

# Environment variables.
# PORT default lets Railway override it cleanly at runtime (Railway injects PORT as an integer).
# BRIDGE_STATE_DIR defaults to /tmp/pinchtab-state (always writable, no volume required).
# Set BRIDGE_STATE_DIR=/data in Railway Variables when a Volume is attached at /data
# to persist profiles and state across deploys.
# HOME=/data only matters when a volume is present; /tmp is fine otherwise.
ENV PORT=9867 \
    BRIDGE_BIND=0.0.0.0 \
    BRIDGE_PORT=9867 \
    BRIDGE_HEADLESS=true \
    BRIDGE_STATE_DIR=/tmp/pinchtab-state \
    BRIDGE_PROFILE=/tmp/chrome-profile \
    CHROME_BINARY=/usr/bin/chromium-browser \
    CHROME_FLAGS="--no-sandbox --disable-gpu --disable-dev-shm-usage" \
    HOME=/root

# EXPOSE is informational; Railway routes traffic to $PORT.
EXPOSE 9867

ENTRYPOINT ["docker-entrypoint.sh"]
CMD []