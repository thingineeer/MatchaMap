# Appium UI 자동화 — MatchaMap

> Phase 5 직전부터 실제 실행. Phase 3/4는 스크립트 작성 + dry-run만.

## 환경 요구사항

| 도구 | 버전 |
|---|---|
| macOS | 14.5+ |
| Xcode | 26.3 |
| iOS Simulator | iOS 26.2 |
| Node | 20.x LTS |
| Python | 3.11+ |
| Appium Server | 2.x |
| XCUITest Driver | 7.x |

## 셋업

```sh
# Appium 서버
brew install node
npm install -g appium@next
appium driver install xcuitest

# Python 클라이언트
pip install Appium-Python-Client selenium

# (선택) WebDriverAgent 빌드 검증
appium driver doctor xcuitest
```

## 시뮬레이터 부팅

```sh
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl install booted /path/to/MatchaMap.app
```

## Appium 서버 시작

```sh
appium server --port 4723 --base-path /
```

## 골든패스 실행

```sh
cd docs/qa/appium
python -m unittest golden-onboarding.py -v
```

## 시나리오 ↔ 자동화 매핑

| 시나리오 | 자동화 파일 | 상태 |
|---|---|---|
| onboarding | `golden-onboarding.py` | 작성 완료 (Phase 5 실행) |
| map-discovery | TBD `golden-map-discovery.py` | Phase 5 작성 |
| store-detail-review | TBD `golden-review-write.py` | Phase 5 작성 |
| search-filter | TBD `golden-search.py` | Phase 5 작성 |
| wishlist-mini-world | TBD | Phase 5 작성 |
| collection-grid-memory | TBD | Phase 5 작성 (보상형 광고 mock) |
| feed-friend | TBD | Phase 5 작성 (친구 fixture 의존) |

## Accessibility ID 규약

iOS 코드(SwiftUI)에 `.accessibilityIdentifier(...)` 부여 필수. 본 자동화는 다음 ID에 의존:

| ID | 화면/컴포넌트 |
|---|---|
| `splash-root` | SplashView 루트 |
| `login-apple-cta` | LoginView Apple CTA |
| `login-passkey-cta` | LoginView Passkey CTA |
| `main-tab-root` | MainTabView 루트 |
| `tab-map` / `tab-feed` / `tab-wishlist` / `tab-profile` | 4개 탭 |
| `store-detail-root` | StoreDetailScreen 루트 |
| `review-write-cta` | "리뷰 쓰기" 버튼 |
| `review-submit` | 리뷰 등록 버튼 |
| `wishlist-mini-map` | 위시리스트 미니 세계지도 |
| `collection-grid` | 도감 grid |
| `feed-list` | 피드 리스트 |

> iOS 개발자(특히 ios-store/ios-social-collection)는 새 화면 추가 시 본 표에 ID를 등록.

## 실패 처리 정책

- 1회 자동 재시도 (네트워크/시뮬레이터 워밍업 대응).
- 재시도 실패 시 수동 검증으로 fallback. 보고서에 자동/수동 비율 기재.
- 빌드 자체가 깨지면 즉시 ios-lead에 SendMessage + 머지 차단.

## CI 통합 (Phase 5)

- GitHub Actions `macos-14` 러너 + Xcode 26.3.
- 매트릭스: iPhone 17 Pro / iPhone SE3 × ko / en-US.
- 시간 예산: 10분 이내(골든패스 1개 기준 90초 목표).
