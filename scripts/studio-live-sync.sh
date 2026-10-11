#!/usr/bin/env bash
# Run once per dev session. Automatically fast-forwards GitHub main and Rojo syncs to Studio.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
if [[ ! -d .git ]]; then
 echo "Run this script from your cloned Gorps Evolution repository."
 exit 1
fi
if ! command -v rojo >/dev/null 2>&1; then
 echo "Rojo CLI not found. Install with: brew install rojo"
 exit 1
fi
if ! command -v git >/dev/null 2>&1; then
 echo "Install Git before running live sync."
 exit 1
fi
if [[ "$(git branch --show-current)" != "main" ]]; then
 echo "Switch to main first: git switch main"
 exit 1
fi
echo "GORPS: source from origin/main; syncing to Roblox Studio at localhost:34872."
echo "Open Studio in EDIT MODE, select Plugins > Rojo > Connect (one-time)."
echo "Stop/Play after a sync to restart server scripts. Keep this Terminal window open."
git fetch --quiet origin main
if [[ -z "$(git status --porcelain)" ]]; then
 git merge --ff-only origin/main
else
 echo "Local edits detected; skipping initial auto-pull to protect your files."
fi
rojo serve default.project.json &
rojo_pid=$!
trap 'kill "$rojo_pid" 2>/dev/null || true' EXIT INT TERM
last=""
while kill -0 "$rojo_pid" 2>/dev/null; do
 sleep 15
 if [[ -n "$(git status --porcelain)" ]]; then
  if [[ "$last" != "dirty" ]]; then
   echo "WARNING: local files changed; auto-pull paused to avoid overwriting work."
   last="dirty"
  fi
  continue
 fi
 if ! git fetch --quiet origin main; then
  echo "Network unavailable; keeping last synced version."
  continue
 fi
 current="$(git rev-parse HEAD)"
 latest="$(git rev-parse origin/main)"
 if [[ "$current" != "$latest" ]]; then
  if git merge --ff-only origin/main; then
   echo "GORPS: synced new GitHub version $latest to Rojo; Stop then Play to retest."
   last=""
  else
   echo "Couldn't fast-forward main; refusing to overwrite local changes."
  fi
 fi
done
echo "Rojo stopped. Restart this script to reconnect."
