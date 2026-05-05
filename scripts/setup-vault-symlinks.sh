#!/usr/bin/env bash
# setup-vault-symlinks.sh — vault → 본 레포 시크릿 symlink.
#
# vault 위치: ~/.env-vault/projects/matchamap-ios/
# CLAUDE.md § 9 시크릿 관리 정책 참조.
#
# 본 스크립트는 멱등(idempotent). 여러 번 실행해도 안전.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VAULT="${MATCHAMAP_VAULT:-$HOME/.env-vault/projects/matchamap-ios}"

if [[ ! -d "$VAULT" ]]; then
  echo "[setup-vault-symlinks] vault 디렉토리 없음: $VAULT" >&2
  echo "  → https://github.com/thingineeer/thingineeer-env 의 projects/matchamap-ios/ 클론 필요" >&2
  exit 1
fi

echo "[setup-vault-symlinks] vault: $VAULT"
echo "[setup-vault-symlinks] repo : $REPO_ROOT"

link() {
  local src="$1" dst="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "  linked: ${dst#$REPO_ROOT/} → $src"
  else
    echo "  skip (not found): $src"
  fi
}

# ─── 환경변수 .env (fastlane이 자동 로드) ────────────────
link "$VAULT/.env"               "$REPO_ROOT/.env"
link "$VAULT/.env"               "$REPO_ROOT/fastlane/.env"

# ─── Appfile.local / Matchfile.local (개인 비공개 ID) ───
link "$VAULT/Appfile.local"      "$REPO_ROOT/fastlane/Appfile.local"
link "$VAULT/Matchfile.local"    "$REPO_ROOT/fastlane/Matchfile.local"

# ─── ASC API JSON key ───────────────────────────────────
link "$VAULT/api_key.json"       "$REPO_ROOT/fastlane/api_key.json"

# ─── Apple Auth Key (.p8) ───────────────────────────────
shopt -s nullglob
for p8 in "$VAULT"/AuthKey_*.p8; do
  link "$p8"                     "$REPO_ROOT/fastlane/$(basename "$p8")"
done
shopt -u nullglob

# ─── GoogleService-Info.plist ───────────────────────────
link "$VAULT/GoogleService-Info.plist" "$REPO_ROOT/MatchaMap/GoogleService-Info.plist"

# ─── AdMob.local.xcconfig (실 광고 ID) ──────────────────
link "$VAULT/AdMob.local.xcconfig"     "$REPO_ROOT/Configs/AdMob.local.xcconfig"

echo "[setup-vault-symlinks] 완료. 다음 단계: bundle install && bundle exec fastlane lanes"
