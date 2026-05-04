# Architecture 허브 (docs/architecture)

> `ios-lead` + `server-lead` 공동 소유. 모든 ADR은 본 디렉토리에.

## ADR 인덱스

| ID | 제목 | 상태 | 작성자 |
|---|---|---|---|
| 001 | 모듈 경계 (Clean Architecture) | **Accepted v0.1** (po-lead 사인오프 2026-05-04) — LocalPackages 9 모듈 + 의존 표 | `ios-lead` |
| 002 | 의존성 주입 전략 | **Accepted v0.1** (po-lead 사인오프 2026-05-04) — Composition Root + Factory closure (no DI 라이브러리) | `ios-lead` |
| 003 | 테스트 전략 (TDD + Layer별 책임) | **Accepted v0.1** (po-lead 사인오프 2026-05-04, qa-lead 검토 중) — swift test 16건 PASS | `ios-lead` / `qa-lead` |
| 101 | Google Maps SDK 통합 | TBD | `ios-map` |
| 201 | Auth 전략 (Apple+Passkey) | TBD | `ios-auth-monetize` |
| 202 | 수익화 구현 (AdMob) | TBD | `ios-auth-monetize` |
| 301 | 백엔드 선택 (Firebase vs Supabase) | **확정 v2: Firebase** (가중 매트릭스 + 정량 트리거) | `server-lead` |
| 302 | 데이터 모델 (Firestore 스키마) | **Accepted** — D1~D7 결정 + schema.md SSOT + indexes + migrations 템플릿 | `server-data` |
| 303 | App Check / 보안 규칙 | TBD | `server-auth` |

## 모듈 다이어그램

```
                     ┌─────────────────────┐
                     │  MatchaMap (App)    │
                     │  Composition Root   │
                     └──────────┬──────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
  ┌─────▼──────┐         ┌──────▼──────┐         ┌──────▼──────┐
  │  Feature/  │  ──→    │   Domain    │  ←──    │   Data      │
  │  Map/Auth/ │         │  (외부 0)   │         │ (Firebase / │
  │  Store/... │         │             │         │  GMaps SDK) │
  └─────┬──────┘         └─────────────┘         └─────────────┘
        │                       ▲
        │                       │
  ┌─────▼──────┐         ┌──────┴──────┐
  │ DesignSys  │         │    Core     │
  │ (토큰)     │         │ (Network/   │
  └────────────┘         │  Logger/DI) │
                         └─────────────┘
```

규칙:
- `Domain`은 외부 의존성 0 (Foundation도 최소).
- `Feature/*`는 `Domain` UseCase 프로토콜만 의존(`Data` 직접 import 금지).
- `Data`는 `Domain` 프로토콜을 구현하고 외부 SDK(Firebase/GoogleMaps)에 의존.
- 컴포지션 루트(`MatchaMap/`)에서 의존 주입.
