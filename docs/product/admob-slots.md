# AdMob Slots — Identifier Map

> Owner: `po-growth` · Last updated: 2026-05-04 · Implementer: `ios-auth-monetize`
>
> **시크릿 분리 원칙**: 본 파일은 **키 이름과 운영 정책만** 보유. 실제 AdMob App ID / Ad Unit ID는 `~/.env-vault/projects/matchamap-ios/admob.json`에만 존재.
>
> Phase 4-5에서 `po-growth`가 chrome 자동화로 AdMob 콘솔에서 발급 후 vault에 저장 → `ios-auth-monetize`가 환경변수로 주입.

## 1. 슬롯 매핑

| 키 이름 (코드 참조) | 종류 | 위치 | 빈도 | UX 가드 |
|---|---|---|---|---|
| `AD_APP_ID` | App ID | 전역 | — | Info.plist `GADApplicationIdentifier` |
| `AD_BANNER_MAP_ID` | Banner | 지도 화면 하단 | 상시 노출 | 첫 60초 차단, 매장 미리보기 카드 떠 있을 때 hide |
| `AD_INTERSTITIAL_STORE_ID` | Interstitial | 매장 상세 진입 시 | N=5회마다 | 쿨다운 90초, 첫 화면 차단, 첫 60초 차단 |
| `AD_REWARDED_COLLECTION_ID` | Rewarded | 도감 잠금 해제 | 사용자 자발 | 도감 항목별 쿨다운 24h |

## 2. 환경변수 / 매핑 규약

### 2.1 vault 파일 구조 (`~/.env-vault/projects/matchamap-ios/admob.json`)

```json
{
  "production": {
    "AD_APP_ID":                  "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX",
    "AD_BANNER_MAP_ID":           "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX",
    "AD_INTERSTITIAL_STORE_ID":   "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX",
    "AD_REWARDED_COLLECTION_ID":  "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
  },
  "test": {
    "AD_APP_ID":                  "ca-app-pub-3940256099942544~1458002511",
    "AD_BANNER_MAP_ID":           "ca-app-pub-3940256099942544/2934735716",
    "AD_INTERSTITIAL_STORE_ID":   "ca-app-pub-3940256099942544/4411468910",
    "AD_REWARDED_COLLECTION_ID":  "ca-app-pub-3940256099942544/1712485313"
  }
}
```

> `test` 블록은 Google이 공개한 iOS test unit ID. Debug/Beta 빌드는 자동으로 `test`를 사용 (Phase 4 ios-auth-monetize 구현 시 환경 분기).

### 2.2 코드 노출 패턴

```swift
// LocalPackages/FeatureMonetize/Sources/AdConfig.swift (예정)
enum AdConfig {
    static let appId        = ProcessInfo.processInfo.environment["AD_APP_ID"] ?? testAppId
    static let bannerMap    = ProcessInfo.processInfo.environment["AD_BANNER_MAP_ID"] ?? testBanner
    static let interStore   = ProcessInfo.processInfo.environment["AD_INTERSTITIAL_STORE_ID"] ?? testInter
    static let rewardedColl = ProcessInfo.processInfo.environment["AD_REWARDED_COLLECTION_ID"] ?? testRewarded
}
```

**금지**: 실제 production ID를 코드/Info.plist에 하드코드 금지. fastlane lane이 빌드 직전 `setup_api_key`로 주입.

## 3. UX 가드 (`ios-auth-monetize` 구현 의무)

### 3.1 첫 60초 차단

```
앱 첫 실행 / 새 세션 시작 시각 = T0
T < T0 + 60s 동안 모든 광고 노출 차단 (배너 hidden, 인터/보상 호출 무시)
```

### 3.2 인터스티셜 쿨다운

```
마지막 인터 닫힘 시각 = Tlast
T < Tlast + 90s 동안 인터 호출 무시
+ 매장 상세 진입 횟수 카운터 (mod 5)
```

### 3.3 배너 컨텍스트 hide

- 매장 미리보기 시트가 열렸을 때 (Sheet detent ≥ medium) → 배너 hidden.
- 검색 입력 포커스 시 → 배너 hidden.

### 3.4 보상형 쿨다운

- 도감 카드별로 24h 쿨다운. 같은 카드를 반복 잠금 해제 광고 시청 불가.

## 4. 발급 절차 (Phase 4-5)

| 단계 | 담당 | 도구 |
|---|---|---|
| 1. AdMob 콘솔 로그인 | `po-growth` | `mcp__claude-in-chrome__*` (사용자 OAuth 위임) |
| 2. App 등록 (Bundle `th1ngjin.MatchaMap`) | `po-growth` | 콘솔 |
| 3. 3개 Ad Unit 생성 | `po-growth` | 콘솔 |
| 4. ID를 vault에 기록 | `po-growth` | `~/.env-vault/...` |
| 5. fastlane lane으로 환경변수 주입 검증 | `ios-auth-monetize` | `fastlane sync_admob` (예정) |
| 6. 광고 노출 테스트 (Test ID로) | `qa-functional` | 시뮬레이터 |

## 5. 정책 / 컴플라이언스

- **Apple 심사 5.1.1 / 5.5.4**: 광고와 콘텐츠 명확 분리, 광고 클릭 외 의도치 않은 클릭 유도 금지.
- **Google AdMob 정책**: 클릭 유도, 부적절한 위치(전면 모달 첫 화면), 광고 클릭당 보상 금지.
- **GDPR / DSGVO**: EU 사용자에게 *동의 요청 메시지(UMP SDK)* 노출, *비동의 시 비개인화 광고* fallback.
- **CCPA**: California 사용자 *Do Not Sell* 옵션 제공.

## 6. 미정 사항 / 후속

- AdMob mediation 적용 여부 (v1.1.x).
- 도감 잠금 해제 보상 광고 *완료 시 카드 자동 등록* 인터랙션 디자인 — `designer-lead`와 합의.
- 배너 광고와 디자인 시스템 색상 충돌 — DesignSystem 토큰의 cream/paper 위 광고 영역 격리 padding 결정.
