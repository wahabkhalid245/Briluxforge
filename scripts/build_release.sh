#!/usr/bin/env bash
# =============================================================================
# Briluxforge — Release Build Script
# Section 7.4 of CLAUDE.md: every release build uses --obfuscate.
# Run from the project root: bash scripts/build_release.sh [windows|macos|linux|all]
# =============================================================================

set -euo pipefail

PLATFORM="${1:-all}"
DEBUG_INFO_DIR="build/debug-info"
DIST_DIR="dist"

# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------
preflight() {
  echo "==> Running pre-flight checks..."

  command -v flutter >/dev/null 2>&1 || { echo "ERROR: flutter not found in PATH."; exit 1; }
  command -v dart >/dev/null 2>&1 || { echo "ERROR: dart not found in PATH."; exit 1; }

  [[ -f "pubspec.yaml" ]] || { echo "ERROR: Must run from project root (pubspec.yaml not found)."; exit 1; }
  [[ -f "assets/brain/model_profiles.json" ]] || { echo "ERROR: assets/brain/model_profiles.json missing."; exit 1; }
  [[ -f "lib/main.dart" ]] || { echo "ERROR: lib/main.dart missing."; exit 1; }

  # Verify benchmark model is present in model_profiles.json
  if ! grep -q '"isBenchmark"' assets/brain/model_profiles.json; then
    echo "WARNING: No isBenchmark entry found in model_profiles.json."
    echo "         Savings tracker will use the hard-coded Opus 4.6 fallback."
  fi

  echo "    Pre-flight: OK"
}

# -----------------------------------------------------------------------------
# Code generation (Riverpod + Drift + JSON)
# -----------------------------------------------------------------------------
codegen() {
  echo ""
  echo "==> Regenerating code (Riverpod + Drift + JSON)..."
  dart run build_runner build --delete-conflicting-outputs
  echo "    Code generation: OK"
}

# -----------------------------------------------------------------------------
# Build a single platform
# -----------------------------------------------------------------------------
build_platform() {
  local platform="$1"
  echo ""
  echo "==> Building release for $platform..."
  flutter build "$platform" \
    --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_DIR/$platform"
  echo "    Done: build/$platform/release/"
}

# -----------------------------------------------------------------------------
# Package build output into dist/ for distribution
# Produces a self-contained archive the user can download and extract.
# -----------------------------------------------------------------------------
package_platform() {
  local platform="$1"
  mkdir -p "$DIST_DIR"

  case "$platform" in
    windows)
      local src="build/windows/x64/runner/Release"
      local out="$DIST_DIR/Briluxforge-windows-x64.zip"
      if command -v zip >/dev/null 2>&1; then
        (cd "$src" && zip -r "../../../../$out" .)
        echo "    Package: $out"
      else
        echo "    Skipping zip (zip not available). Output is at: $src"
      fi
      ;;
    macos)
      local src="build/macos/Build/Products/Release/briluxforge.app"
      local out="$DIST_DIR/Briluxforge-macos.zip"
      if [[ -d "$src" ]]; then
        ditto -c -k --sequesterRsrc --keepParent "$src" "$out"
        echo "    Package: $out"
      else
        echo "    macOS .app not found at expected path: $src"
      fi
      ;;
    linux)
      local src="build/linux/x64/release/bundle"
      local out="$DIST_DIR/Briluxforge-linux-x64.tar.gz"
      if [[ -d "$src" ]]; then
        tar -czf "$out" -C "$(dirname "$src")" "$(basename "$src")"
        echo "    Package: $out"
      else
        echo "    Linux bundle not found at expected path: $src"
      fi
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Smoke test checklist
# Printed after a successful build. Manual verification steps before shipping.
# -----------------------------------------------------------------------------
print_smoke_test_checklist() {
  cat <<'EOF'

=============================================================================
SMOKE TEST CHECKLIST — verify on a clean machine before distributing
=============================================================================
Install & Launch
  [ ] App launches without errors on a fresh OS install
  [ ] Window respects 900×600 minimum size (try resizing smaller)
  [ ] Title bar shows "Briluxforge"
  [ ] Dark mode is default; light mode toggles correctly in Settings

Authentication
  [ ] Sign up with a new email + password (no credit card shown)
  [ ] "Start your free trial — no credit card required" copy is visible
  [ ] Log in with the same account
  [ ] "Forgot password?" sends a reset email
  [ ] Log out clears the session

Licensing
  [ ] Free trial countdown banner is visible (shows days remaining)
  [ ] License key input screen opens from Settings → License
  [ ] Valid license key activates successfully (green confirmation)
  [ ] Invalid key shows actionable error message (not a raw exception)

Onboarding (first run)
  [ ] Welcome screen → Use-Case selection → API Buying Guide → Add Key → Done
  [ ] Use-case selection persists and sets the correct default model
  [ ] Skip button works on steps 3–5

API Key Management
  [ ] Add a DeepSeek API key → green "Connected" indicator
  [ ] Add an invalid key → specific, actionable error (not generic "error")
  [ ] Delete a key → status clears
  [ ] Keys survive app restart (stored in platform-native secure storage)

Delegation Engine
  [ ] Send a coding prompt (e.g. "Write a Python function to reverse a string")
      → delegation badge shows DeepSeek was selected
  [ ] Send a writing prompt (e.g. "Write a short poem about the ocean")
      → delegation badge shows Claude Sonnet was selected (if key connected)
  [ ] Send a very long prompt (>30 000 tokens) → Gemini Flash selected
  [ ] With only one API key connected → no delegation dialog, just sends
  [ ] Manual override: tap delegation badge → model picker → select different model

Chat Interface
  [ ] Messages send and stream token-by-token (no waiting for full response)
  [ ] Assistant responses render as rich markdown (headings, bold, lists)
  [ ] Code blocks have syntax highlighting + copy button
  [ ] Links in assistant messages open in the system browser
  [ ] New conversation (Ctrl/Cmd+N) creates a fresh chat
  [ ] Conversation list in sidebar shows all chats
  [ ] Conversations persist after app restart (Drift/SQLite)

Skills System
  [ ] 5 built-in skills appear in Skills screen (cannot be deleted)
  [ ] Enable "Code Expert" skill → chat input shows "1 skill active"
  [ ] Send a prompt → verify the system prompt includes the skill text
  [ ] Create a custom skill → appears in the list, can be enabled/disabled

Savings Tracker
  [ ] Tracker shows $0.00 saved on first launch
  [ ] After sending a prompt, savings number increases
  [ ] Tap the tracker → breakdown modal shows per-model token counts
  [ ] Breakdown math matches: (benchmark cost) − (actual cost) = savings shown
  [ ] "X× cheaper than Claude Opus 4.6" multiple is displayed

Keyboard Shortcuts
  [ ] Ctrl/Cmd+N → new conversation
  [ ] Ctrl/Cmd+Enter → sends message
  [ ] Ctrl/Cmd+, → opens Settings
  [ ] Ctrl/Cmd+K → opens model selector

Offline Behavior
  [ ] Disconnect network → app does not crash
  [ ] API key list still shows (metadata from memory/storage)
  [ ] Chat history still loads (Drift works offline)
  [ ] Sending a message while offline shows a clear "no connection" error

Security Spot-Check
  [ ] Open strings/hex dump of the binary — no API keys, no secrets visible
  [ ] Debug symbols NOT present in the distributed bundle
  [ ] build/debug-info/ directory exists locally but is NOT in the zip/dmg/tarball

=============================================================================
EOF
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
preflight
codegen

case "$PLATFORM" in
  windows)
    build_platform windows
    package_platform windows
    ;;
  macos)
    build_platform macos
    package_platform macos
    ;;
  linux)
    build_platform linux
    package_platform linux
    ;;
  all)
    echo "Building for host platform..."
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
      build_platform windows
      package_platform windows
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      build_platform macos
      package_platform macos
    else
      build_platform linux
      package_platform linux
    fi
    ;;
  *)
    echo "Usage: $0 [windows|macos|linux|all]"
    exit 1
    ;;
esac

echo ""
echo "==> Release build complete."
echo "    Debug symbols (DO NOT SHIP): $DEBUG_INFO_DIR/"
echo "    Distribution packages:       $DIST_DIR/"
echo ""
echo "    Verify $DEBUG_INFO_DIR/ is NOT included in any distributed archive."

print_smoke_test_checklist
