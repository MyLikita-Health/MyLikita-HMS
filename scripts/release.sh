#!/usr/bin/env bash
#
# release.sh — automated release for the MyLikita monorepo app.
#
# Automates the release flow used for v1.35.0 → v1.38.0:
#
#   1. frontend/ (on RELEASE_FE_BRANCH, default fix/doc-consult)
#        bump package.json version, stage everything, commit "vX.Y.Z: …"
#   2. backend/  (on RELEASE_BE_BRANCH, default fix/doc-consult)
#        bump package.json version, stage everything, commit "vX.Y.Z: …"
#        (runtime dirs backups/, data/ etc. are gitignored → never staged)
#   3. root      (on RELEASE_MAIN_BRANCH, default main)
#        commit the submodule pointer updates, tag vX.Y.Z
#   4. push frontend + backend branches, then root main --tags
#
# Usage:
#   ./scripts/release.sh                    # auto minor-bump (1.38.0 → 1.39.0)
#   ./scripts/release.sh 1.39.0             # explicit version
#   ./scripts/release.sh 1.39.0 "receipt fixes"   # explicit summary
#   ./scripts/release.sh --dry-run          # print every step, change nothing
#   ./scripts/release.sh --no-push          # commit + tag, skip the pushes
#
# Preconditions (checked by the script):
#   - frontend/backend package.json versions match each other
#   - the tag vX.Y.Z does not exist yet
#   - the submodules are on their release branches and the root is on main
#
# Safety: every command is echoed first; --dry-run prints them without
# running anything. Nothing is force-pushed or force-tagged.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FE_DIR="$ROOT/frontend"
BE_DIR="$ROOT/backend"

# Release branches — override with env vars if the flow ever moves.
RELEASE_FE_BRANCH="${RELEASE_FE_BRANCH:-fix/doc-consult}"
RELEASE_BE_BRANCH="${RELEASE_BE_BRANCH:-fix/doc-consult}"
RELEASE_MAIN_BRANCH="${RELEASE_MAIN_BRANCH:-main}"

DRY_RUN=0
DO_PUSH=1
VERSION=""
SUMMARY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --no-push) DO_PUSH=0; shift ;;
    -h|--help)
      echo "usage: $0 [--dry-run] [--no-push] [VERSION [SUMMARY]]"
      echo "  VERSION   e.g. 1.39.0 (default: minor bump of the current version)"
      echo "  SUMMARY   short release summary used in all commit messages"
      echo "  --dry-run print every step without changing anything"
      echo "  --no-push commit + tag only (no pushes)"
      exit 0 ;;
    -*)
      echo "unknown arg: $1 (see --help)" >&2; exit 2 ;;
    *)
      if [ -z "$VERSION" ]; then VERSION="$1";
      elif [ -z "$SUMMARY" ]; then SUMMARY="$1";
      else echo "too many positional args (see --help)" >&2; exit 2; fi
      shift ;;
  esac
done

say()  { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m[ERROR] %s\033[0m\n' "$*" >&2; exit 1; }
step() { printf '\033[1;32m  ✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }

# run_in <dir> <cmd...> — echo the command, run it in <dir> unless --dry-run.
run_in() {
  printf '  \033[1;33m$\033[0m (cd %s && %s)\n' "$1" "${*:2}"
  [ "$DRY_RUN" = 0 ] || return 0
  ( cd "$1" && "${@:2}" )
}

# git_commit <dir> <message...> — commit staged changes in <dir>.
git_commit() {
  local dir="$1"; shift
  printf '  \033[1;33m$\033[0m (cd %s && git commit -m "%s")\n' "$dir" "$1"
  [ "$DRY_RUN" = 0 ] || return 0
  ( cd "$dir" && git commit -m "$1" )
}

# bump_version <dir> <old> <new> — rewrite package.json version via node
# (JSON-safe; refuses if the current version isn't exactly <old>).
bump_version() {
  printf '  \033[1;33m$\033[0m bump %s/package.json %s → %s\n' "$1" "$2" "$3"
  [ "$DRY_RUN" = 0 ] || return 0
  node -e "
    const fs = require('fs');
    const p = '$1/package.json';
    const j = JSON.parse(fs.readFileSync(p, 'utf8'));
    if (j.version !== '$2') { console.error('expected v$2, got v' + j.version + ' in ' + p); process.exit(1); }
    j.version = '$3';
    fs.writeFileSync(p, JSON.stringify(j, null, 2) + '\n');
  "
}

# ── resolve version ─────────────────────────────────────────────────────────
say "Version"
FE_VER="$(node -p "require('$FE_DIR/package.json').version")"
BE_VER="$(node -p "require('$BE_DIR/package.json').version")"
step "frontend v$FE_VER · backend v$BE_VER"
[ "$FE_VER" = "$BE_VER" ] || die "frontend ($FE_VER) and backend ($BE_VER) versions differ — align them first"

if [ -z "$VERSION" ]; then
  VERSION="$(node -p "
    const [m, p, s] = '$FE_VER'.split('.').map(Number);
    [m, p + 1, 0].join('.')
  ")"
  step "auto minor bump → v$VERSION"
fi
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version '$VERSION' (want X.Y.Z)"
SUMMARY="${SUMMARY:-release}"
step "v$VERSION — $SUMMARY"

# ── preflight ───────────────────────────────────────────────────────────────
say "Preflight"
git -C "$ROOT" rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null 2>&1 \
  && die "tag v$VERSION already exists — bump the version"
step "tag v$VERSION is free"

[ "$(git -C "$ROOT" branch --show-current)" = "$RELEASE_MAIN_BRANCH" ] \
  || die "root is on $(git -C "$ROOT" branch --show-current), expected $RELEASE_MAIN_BRANCH"
[ "$(git -C "$FE_DIR" branch --show-current)" = "$RELEASE_FE_BRANCH" ] \
  || die "frontend is on $(git -C "$FE_DIR" branch --show-current), expected $RELEASE_FE_BRANCH"
[ "$(git -C "$BE_DIR" branch --show-current)" = "$RELEASE_BE_BRANCH" ] \
  || die "backend is on $(git -C "$BE_DIR" branch --show-current), expected $RELEASE_BE_BRANCH"
step "branches: root $RELEASE_MAIN_BRANCH · frontend $RELEASE_FE_BRANCH · backend $RELEASE_BE_BRANCH"

for d in "$FE_DIR" "$BE_DIR"; do
  git -C "$d" status --porcelain | grep -q . \
    || die "no uncommitted changes in $(basename "$d") — nothing to release"
done
FE_FILES="$(git -C "$FE_DIR" status --porcelain | wc -l | tr -d ' ')"
BE_FILES="$(git -C "$BE_DIR" status --porcelain | wc -l | tr -d ' ')"
step "frontend: $FE_FILES changed file(s) · backend: $BE_FILES changed file(s)"
if [ "$DRY_RUN" = 0 ]; then
  echo "  frontend:"
  git -C "$FE_DIR" status --short | sed 's/^/    /'
  echo "  backend:"
  git -C "$BE_DIR" status --short | sed 's/^/    /'
fi

# ── 1. frontend ─────────────────────────────────────────────────────────────
say "Frontend ($RELEASE_FE_BRANCH)"
bump_version "$FE_DIR" "$FE_VER" "$VERSION"
run_in "$FE_DIR" git add -A
git_commit "$FE_DIR" "v$VERSION: $SUMMARY"
FE_SHA="$(git -C "$FE_DIR" rev-parse --short HEAD)"
step "frontend committed $FE_SHA"

# ── 2. backend ──────────────────────────────────────────────────────────────
say "Backend ($RELEASE_BE_BRANCH)"
bump_version "$BE_DIR" "$BE_VER" "$VERSION"
run_in "$BE_DIR" git add -A
git_commit "$BE_DIR" "v$VERSION: $SUMMARY"
BE_SHA="$(git -C "$BE_DIR" rev-parse --short HEAD)"
step "backend committed $BE_SHA"

# ── 3. root commit + tag ────────────────────────────────────────────────────
say "Root ($RELEASE_MAIN_BRANCH)"
ROOT_MSG="v$VERSION: $SUMMARY

Frontend $FE_SHA — $(git -C "$FE_DIR" log -1 --format=%s)
Backend $BE_SHA — $(git -C "$BE_DIR" log -1 --format=%s)"
run_in "$ROOT" git add backend frontend
git_commit "$ROOT" "$ROOT_MSG"
run_in "$ROOT" git tag "v$VERSION"
step "tagged v$VERSION"

# ── 4. push ─────────────────────────────────────────────────────────────────
if [ "$DO_PUSH" = 1 ]; then
  say "Push"
  run_in "$FE_DIR" git push origin "$RELEASE_FE_BRANCH"
  run_in "$BE_DIR" git push origin "$RELEASE_BE_BRANCH"
  run_in "$ROOT" git push origin "$RELEASE_MAIN_BRANCH" --tags
else
  say "Push (skipped with --no-push)"
fi

if [ "$DRY_RUN" = 1 ]; then
  say "Dry run complete — nothing was changed or pushed."
else
  say "v$VERSION released"
  step "frontend $FE_SHA pushed to origin/$RELEASE_FE_BRANCH"
  step "backend $BE_SHA pushed to origin/$RELEASE_BE_BRANCH"
  step "root tagged v$VERSION and pushed to origin/$RELEASE_MAIN_BRANCH"
  echo
  echo "  Tip: run 'node scripts/generate-changelog.mjs --since <last-release-date>'"
  echo "       to draft the user-facing changelog for this release."
fi