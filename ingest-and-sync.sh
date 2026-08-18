#!/usr/bin/env bash
# ingest-and-sync.sh - Process and sync multi-site media to Cloudflare R2
set -euo pipefail

BASE_DIR="$HOME/projects/media-master"
INBOX="$BASE_DIR/inbox"
READY="$BASE_DIR/ready"
ARCHIVE="$BASE_DIR/archive"
LOG_FILE="$BASE_DIR/ingest.log"

RCLONE_TARGET="cloudflare-r2:blog-media-bucket"
SITES=("sydneytech" "benburke" "leonardkoan")

shopt -s nullglob

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting multi-site media ingest pipeline..."

for site in "${SITES[@]}"; do
    site_inbox="$INBOX/$site"
    site_ready="$READY/$site"
    site_archive="$ARCHIVE/$site"

    mkdir -p "$site_ready" "$site_archive"

    # Find files in site inbox
    for file in "$site_inbox"/*.mp4 "$site_inbox"/*.mp3 "$site_inbox"/*.m4a; do
        filename=$(basename "$file")
        extension="${filename##*.}"

        log "[$site] Processing: $filename"

        if [[ "${extension,,}" =~ ^(mp4|m4v)$ ]]; then
            # Remux with faststart for streaming
            if ffmpeg -y -i "$file" -c copy -movflags +faststart "$site_ready/$filename" 2>> "$LOG_FILE"; then
                log "[$site] Remuxed successfully: $filename"
                mv "$file" "$site_archive/"
            else
                log "[$site] ERROR remuxing $filename. Check $LOG_FILE" >&2
            fi
        elif [[ "${extension,,}" =~ ^(mp3|m4a)$ ]]; then
            # Direct copy for audio
            if cp "$file" "$site_ready/$filename"; then
                log "[$site] Audio staged: $filename"
                mv "$file" "$site_archive/"
            else
                log "[$site] ERROR copying $filename" >&2
            fi
        fi
    done
done

log "Syncing 'ready' directory to Cloudflare R2 ($RCLONE_TARGET)..."

# Syncs ready/ directly into the root of blog-media-bucket
if rclone sync "$READY" "$RCLONE_TARGET" --update --fast-list -v >> "$LOG_FILE" 2>&1; then
    log "Rclone sync completed successfully."
else
    log "ERROR: Rclone sync failed. Inspect $LOG_FILE for details." >&2
fi

log "Pipeline execution complete."
echo "----------------------------------------" >> "$LOG_FILE"
