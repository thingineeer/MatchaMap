#!/usr/bin/env bash
# App Store 메타데이터 한도/완전성 검증 스크립트
# 사용법:
#   bash docs/po/check-metadata.sh
# 결과: exit 0 = OK, exit N = N개의 위반/누락
# 호출 위치: PR 머지 전 (qa-lead) + fastlane upload_metadata 직전

set -u
cd "$(dirname "$0")/../.."

LOCALES=(ko en-US en-GB de-DE ja fr-FR)
FILES=(name.txt subtitle.txt description.txt keywords.txt release_notes.txt promotional_text.txt support_url.txt marketing_url.txt privacy_url.txt)
# 한도: 0 = URL/제한없음
LIMITS=(30 30 4000 100 4000 170 0 0 0)
ERRORS=0

for loc in "${LOCALES[@]}"; do
  for i in "${!FILES[@]}"; do
    f="fastlane/metadata/$loc/${FILES[$i]}"
    limit="${LIMITS[$i]}"
    if [ ! -f "$f" ]; then
      echo "MISSING: $f"
      ERRORS=$((ERRORS+1))
      continue
    fi
    content=$(perl -0777 -pe 's/\s+\z//' "$f")
    chars=$(printf "%s" "$content" | wc -m | tr -d ' ')
    if [ "$limit" -gt 0 ] && [ "$chars" -gt "$limit" ]; then
      echo "OVER LIMIT: $f ($chars > $limit)"
      ERRORS=$((ERRORS+1))
    fi
  done
done

if [ "$ERRORS" -eq 0 ]; then
  echo "OK — 6 locales × 9 files = 54 files, 모든 한도 통과"
fi

exit "$ERRORS"
