# App Store 메타데이터 검증 체크리스트 — v1.0.0

> Owner: `po-lead` · Reviewers: `po-growth`, `qa-localization`, `qa-lead`
> 자동화: 본 문서 §3의 검증 스크립트는 `fastlane/metadata/` 디렉토리를 일괄 검사한다.
> 단일 진실 원천: 카피 본문은 `fastlane/metadata/{locale}/*.txt`. 본 체크리스트는 한도/완전성만 검증.

---

## 1. 적재 범위

6개 언어 × 9개 파일 = **54 file** 강제. 누락 시 fastlane `upload_metadata` lane에서 빈 필드 업로드 위험.

| 언어 | locale 코드 | App Store Connect 표시 |
|---|---|---|
| 한국어 | `ko` | 한국어 |
| 영어 (미국) | `en-US` | English (U.S.) — primary fallback |
| 영어 (영국) | `en-GB` | English (U.K.) |
| 독일어 | `de-DE` | Deutsch |
| 일본어 | `ja` | 日本語 |
| 프랑스어 | `fr-FR` | Français |

| 파일 | 한도 | App Store Connect 매핑 |
|---|---|---|
| `name.txt` | 30자 | App Name |
| `subtitle.txt` | 30자 | Subtitle |
| `description.txt` | 4000자 | Description |
| `keywords.txt` | 100자 (콤마 포함) | Keywords (검색 메타) |
| `release_notes.txt` | 4000자 | What's New |
| `promotional_text.txt` | 170자 | Promotional Text (배포 후 변경 가능) |
| `support_url.txt` | URL | Support URL |
| `marketing_url.txt` | URL | Marketing URL (선택) |
| `privacy_url.txt` | URL | Privacy Policy URL |

---

## 2. 한도 위반 검증 결과 (2026-05-05)

| locale | name | subtitle | keywords | description | promotional_text | 위반 |
|---|---|---|---|---|---|---|
| ko | 3 / 30 | 12 / 30 | 41 / 100 | 840 / 4000 | 45 / 170 | 0 |
| en-US | 9 / 30 | 20 / 30 | 80 / 100 | 1567 / 4000 | 113 / 170 | 0 |
| en-GB | 9 / 30 | 20 / 30 | 80 / 100 | 1575 / 4000 | 113 / 170 | 0 |
| de-DE | 9 / 30 | 23 / 30 | 81 / 100 | 1759 / 4000 | 118 / 170 | 0 |
| ja | 5 / 30 | 10 / 30 | 41 / 100 | 791 / 4000 | 60 / 170 | 0 |
| fr-FR | 9 / 30 | 25 / 30 | 78 / 100 | 1861 / 4000 | 132 / 170 | 0 |

**결과: 한도 위반 0건**, 6언어 × 9파일 = 54 file 모두 적재.

---

## 3. 자동 검증 스크립트

```sh
# 사용법: bash docs/po/check-metadata.sh
# 실행 결과 0이 아니면 CI fail.

set -e
LOCALES=(ko en-US en-GB de-DE ja fr-FR)
FILES=(name.txt subtitle.txt description.txt keywords.txt release_notes.txt promotional_text.txt support_url.txt marketing_url.txt privacy_url.txt)
LIMITS=(30 30 4000 100 4000 170 0 0 0)
ERRORS=0

for loc in "${LOCALES[@]}"; do
  for i in "${!FILES[@]}"; do
    f="fastlane/metadata/$loc/${FILES[$i]}"
    limit="${LIMITS[$i]}"
    if [ ! -f "$f" ]; then
      echo "MISSING: $f"; ERRORS=$((ERRORS+1)); continue
    fi
    content=$(perl -0777 -pe 's/\s+\z//' "$f")
    chars=$(printf "%s" "$content" | wc -m | tr -d ' ')
    if [ "$limit" -gt 0 ] && [ "$chars" -gt "$limit" ]; then
      echo "OVER LIMIT: $f ($chars > $limit)"; ERRORS=$((ERRORS+1))
    fi
  done
done
exit $ERRORS
```

> 본 스크립트는 PR 머지 전 `qa-lead`가 호출. 0이 아니면 머지 차단.

---

## 4. 카피 일관성 체크

- [x] 앱 이름 (KR/JA): `말차맵` / `抹茶マップ` — CLAUDE.md §1 정합
- [x] 앱 이름 (EN/DE/FR): `MatchaMap` — 동일
- [x] 시장 우선순위 카피: KR → JP → US → UK → DE → FR — 각 description 마지막 문단에 명시
- [x] AdMob 60초 보호 정책 명시 — PRD §6 정합
- [x] 6개 언어 모두 description에 [Features] / [Why MatchaMap] / [Languages] / [Get started] 4섹션 구조
- [x] release_notes는 v1.0.0 첫 출시 톤
- [x] promotional_text는 hook + 핵심 기능(미니 세계지도+도감) 강조

---

## 5. URL 검증

| URL | placeholder | 실 도메인 마감 |
|---|---|---|
| support | https://thingineeer.github.io/matchamap/support | 심사 제출 전 |
| marketing | https://thingineeer.github.io/matchamap | 심사 제출 전 |
| privacy | https://thingineeer.github.io/matchamap/privacy | 심사 제출 전 (필수) |

> Apple 심사 가이드라인 5.1.1: Privacy Policy URL이 작동하지 않으면 거절 사유. 호스팅은 GitHub Pages → 도메인 연결 권장(`server-lead` 협업).

---

## 6. 사인오프 절차

1. ✅ `po-lead` — 6언어 카피 본문 적재 + 본 체크리스트 작성
2. ⏳ `po-growth` — 시장별 키워드 ASO 보강 (`market-research-{locale}.md`와 정합 검증, 추가 키워드 제안)
3. ⏳ `qa-localization` — 6언어 자연스러움 + 길이 회귀 + String Catalog `aso.xcstrings`와의 정합
4. ⏳ `qa-lead` — `check-metadata.sh` 실행 + 0 exit 확인
5. ⏳ `po-lead` (최종) — 머지 사인오프 → 1.0.0 브랜치 머지

---

## 7. 사용자 처리 필요 (Phase 5 후반)

PO/엔지니어가 자동화로 처리할 수 없는 항목:

1. **App Store Connect 앱 본체 생성** — Bundle ID `th1ngjin.MatchaMap` 등록, Primary Language=`ko`, Category=`Food & Drink` (또는 `Travel`), Apple ID 생성. 자동화 가능하나 첫 1회는 수동.
2. **Marketing/Support/Privacy URL 실 호스팅** — GitHub Pages or Cloudflare Pages. `thingineeer.github.io/matchamap` placeholder 도메인 활성화.
3. **App Store Connect API Key (`~/.env-vault/projects/matchamap-ios/api_key.json`)** — vault에 적재 (fastlane `setup_api_key_lane` 의존).
4. **Apple Developer Program enrollment + Team ID** — `fastlane/Appfile`에 환경변수로 주입.
5. **년령 등급, IDFA 사용 여부 (AdMob), 데이터 사용 정책** — App Store Connect Privacy Nutrition Label 입력 (PO 직접 작성).

---

## 8. Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-05 | 초안 — 6언어 × 9파일 = 54 file 적재 + 한도 검증 + 자동 스크립트 + 사용자 처리 필요 항목 정리 | po-lead |

---

생성: 2026-05-05 · Owner: `po-lead`
