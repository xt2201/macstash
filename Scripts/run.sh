#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/MacStash.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found. Building first..."
    "$PROJECT_DIR/Scripts/build_app.sh"
fi

echo "Launching MacStash..."
open "$APP_BUNDLE"
