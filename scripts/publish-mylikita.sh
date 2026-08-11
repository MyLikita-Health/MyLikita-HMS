#!/usr/bin/env bash
#
# publish-mylikita.sh — manual first-release publisher for the @mylikita npm
# packages.
#
# Publishes, in order:
#   1. @mylikita/booking-widget        (vanilla JS widget)
#   2. @mylikita/booking-widget-react  (React wrapper — depends on #1 at the
#                                      exact version, so #1 MUST go first)
#
# Then verifies both are live on the unpkg CDN.
#
# Usage:
#   ./scripts/publish-mylikita.sh            # real publish
#   ./scripts/publish-mylikita.sh --dry-run  # build+test+pack, no upload
#   ./scripts/publish-mylikita.sh --tag v0.1.0  # also create + push a git tag
#
# Preconditions (one-time, must be done by a human):
#   1. npm account that OWNS the @mylikita org/scope (create it at
#      https://www.npmjs.com/settings/<you>/orgs if missing — only org
#      members can publish to the scope).
#   2. Log in: `npm login` (or set NPM_TOKEN and npm config set
#      //registry.npmjs.org/:_authToken=$NPM_TOKEN).
#
# Safety: refuses to publish a version npm already has; refuses to publish
# the react wrapper before the widget; runs build+test first (prepublishOnly
# does this again automatically, which is harmless).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIDGET_DIR="$ROOT/packages/booking-widget"
REACT_DIR="$ROOT/packages/booking-widget-react"

DRY_RUN=0
TAG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --tag=*) TAG="${1#--tag=}"; shift ;;
    -h|--help) echo "usage: $0 [--dry-run] [--tag=vX.Y.Z]"; exit 0 ;;
    *) echo "unknown arg: $1 (use --dry-run or --tag=vX.Y.Z)"; exit 2 ;;
  esac
done

say()  { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m[ERROR] %s\033[0m\n' "$*" >&2; exit 1; }
step() { printf '\033[1;32m  ✔ %s\033[0m\n' "$*"; }

# ── helpers ────────────────────────────────────────────────────────────────
pkg_version() { node -p "require('$1/package.json').version"; }

verify_unpkg() { # verify_unpkg <name> <version> <grep-expected>
  local name="$1" ver="$2" expect="$3"
  local url="https://unpkg.com/${name}@${ver}"
  local body ok=""
  for _ in 1 2 3 4 5; do
    body="$(curl -fsSL "$url" 2>/dev/null || true)"
    if printf '%s' "$body" | grep -q "$expect"; then ok=1; break; fi
    sleep 2
  done
  [ -n "$ok" ] && step "unpkg $url exposes '$expect'" \
                || die "unpkg $url did not expose '$expect' after 5 tries"
}

# ── 0. auth + scope preflight ───────────────────────────────────────────────
say "Preflight"
WHOAMI="$(npm whoami 2>/dev/null || true)"
[ -n "$WHOAMI" ] || die "not logged in to npm — run 'npm login' first (account must own the @mylikita org)"
step "logged in as $WHOAMI"

if npm view @mylikita/booking-widget >/dev/null 2>&1; then
  say "Note: @mylikita/booking-widget already exists on the registry."
fi
# npm view of a never-published scoped package returns 404 even when the
# scope exists — so a 404 here is EXPECTED for the first release. The real
# scope check happens at publish time; the error message then tells us if
# the org is missing.

# ── 1. version consistency ──────────────────────────────────────────────────
say "Version check"
WVER="$(pkg_version "$WIDGET_DIR")"
RVER="$(pkg_version "$REACT_DIR")"
RDEP="$(node -p "require('$REACT_DIR/package.json').dependencies['@mylikita/booking-widget']")"

step "booking-widget        v$WVER"
step "booking-widget-react  v$RVER  (depends on @mylikita/booking-widget@$RDEP)"
[ "$RVER" = "$WVER" ] || die "versions differ ($RVER vs $WVER) — release them together"
[ "$RDEP" = "$WVER" ] || die "react wrapper depends on @$WVER but declares @$RDEP"

if [ "$DRY_RUN" = 0 ]; then
  for name_ver in "@mylikita/booking-widget@$WVER" "@mylikita/booking-widget-react@$RVER"; do
    if npm view "$name_ver" >/dev/null 2>&1; then
      die "npm already has $name_ver — bump the version in package.json and the react dep before re-publishing"
    fi
  done
fi

# ── 2. widget ───────────────────────────────────────────────────────────────
say "Building + testing @mylikita/booking-widget"
( cd "$WIDGET_DIR" && npm install --no-audit --no-fund >/dev/null )
( cd "$WIDGET_DIR" && npm run build && npm test )
if [ "$DRY_RUN" = 1 ]; then
  ( cd "$WIDGET_DIR" && npm publish --dry-run )
  step "widget: dry-run only (not uploaded)"
else
  ( cd "$WIDGET_DIR" && npm publish --access public )
  step "published @mylikita/booking-widget@$WVER"
  verify_unpkg "@mylikita/booking-widget" "$WVER" "MyLikitaBookingWidget"
fi

# ── 3. react wrapper ────────────────────────────────────────────────────────
say "Building + testing @mylikita/booking-widget-react"
( cd "$REACT_DIR" && npm install --no-audit --no-fund >/dev/null )
( cd "$REACT_DIR" && npm run build && npm test )
if [ "$DRY_RUN" = 1 ]; then
  ( cd "$REACT_DIR" && npm publish --dry-run )
  step "react wrapper: dry-run only (not uploaded)"
else
  ( cd "$REACT_DIR" && npm publish --access public )
  step "published @mylikita/booking-widget-react@$RVER"
  verify_unpkg "@mylikita/booking-widget-react" "$RVER" "createBookingWidget"
fi

# ── 4. optional git tag ─────────────────────────────────────────────────────
if [ -n "$TAG" ]; then
  say "Tagging $TAG"
  git -C "$ROOT" tag -f "$TAG"
  git -C "$ROOT" push origin "$TAG"
  step "pushed tag $TAG (triggers the installer pipeline + publish-npm.yml)"
fi

if [ "$DRY_RUN" = 1 ]; then
  say "Dry run complete — nothing was uploaded. Run without --dry-run to publish."
else
  say "All done — both packages live on npm:"
  echo "  https://www.npmjs.com/package/@mylikita/booking-widget"
  echo "  https://www.npmjs.com/package/@mylikita/booking-widget-react"
fi
