# ADR-301 — 백엔드: Firebase (MatchaMapAPP) 확정

- **일자**: 2026-05-04 (초안) / 2026-05-04 보강 v2
- **상태**: Accepted (Phase 0 인프라 셋업과 함께 결정)
- **결정자**: `server-lead`, 사인오프: `po-lead`
- **리뷰어**: `ios-lead`, `server-data`, `server-auth`, `server-functions`

## 컨텍스트

말차맵 v1.0.0 백엔드 선택지: **Firebase** vs **Supabase**.

MVP 범위:
- iOS 26.2 클라이언트 1개 (안드로이드는 추후 트리거 발생 시).
- Apple Sign In + Passkey, 이메일/비번 미사용.
- 매장 read-heavy(맵 카메라 이동 시 viewport bbox 쿼리), 리뷰/사진 write 빈도는 매장당 수~수십/일.
- 글로벌 6개 언어(KR/JP/US/UK/DE/FR)지만 트래픽의 70% 이상은 KR+JP 추정 (PO Growth ICP 기반).
- 6주 내 TestFlight, 8주 내 App Store 제출 목표.
- 광고 = AdMob (Google 생태계).

## 옵션

### 옵션 A — Firebase (MatchaMapAPP)
- 사용자가 이미 Firebase 콘솔에 `MatchaMapAPP` 프로젝트(구 `one-problem-app`)를 보유. Firebase 신규 프로젝트 생성 한도 초과 상태이므로 재활용이 효율적.
- Apple Sign In Provider, FCM, Storage, App Check(DeviceCheck/App Attest), Cloud Functions(2nd gen, asia-northeast3) 즉시 사용 가능.
- AdMob과 같은 Google 생태계 통합 비용 ↓.
- FearIndex-iOS에서 검증된 패턴(Functions/규칙/Hosting) 그대로 이식 가능.

### 옵션 B — Supabase
- Postgres 트랜잭션 강함. pgvector로 매장 유사도 추천 등 강화 가능.
- 셀프 호스팅 가능, 비용 예측성 높음(고정 $25/mo Pro부터).
- Apple Sign In은 Provider 추가 설정 필요(가능, 그러나 Firebase보다 한 단계 손이 더 감), FCM 푸시는 별도 통합(Edge Functions에서 APNs 직접 또는 OneSignal 등 게이트웨이).
- App Check 동등물(Vault/RLS+JWT)은 있으나 DeviceCheck/App Attest 클라 통합 패턴이 Firebase 대비 미성숙.

## 결정

**옵션 A: Firebase 채택.**

## 가중 평가 매트릭스

평가 축과 가중치(합 100%):

| 축 | 가중치 | 근거 |
|---|---|---|
| 시간(Time-to-Market) | 30% | 6주 MVP, 검증 패턴 보유 가산 |
| 비용(Cost) | 25% | Spark 한도/Blaze 단가 + 유지비 |
| 보안(Security) | 20% | App Check, 규칙, IAM, 시크릿 |
| 통합(Integration) | 15% | Apple Sign In/FCM/AdMob/Maps |
| 운영 부담(Ops) | 10% | 콘솔/모니터링/장애 복구 |

점수 척도: 1(약함) ~ 5(강함). 가중 점수 = 점수 × 가중치.

| 축 | 가중치 | Firebase 점수 | Firebase 가중 | Supabase 점수 | Supabase 가중 | 비고 |
|---|---|---|---|---|---|---|
| 시간 | 30 | 5 | 150 | 3 | 90 | 기존 프로젝트 재활용 + FearIndex 이식 패턴. Supabase는 Apple/FCM/App Check 추가 작업. |
| 비용 | 25 | 4 | 100 | 4 | 100 | MVP 규모는 동률 — Firebase는 Spark 무료 한도 넉넉, Supabase는 Free → Pro $25/mo 고정. 임계 도달 시 재평가 트리거 적용. |
| 보안 | 20 | 5 | 100 | 3 | 60 | App Check(DeviceCheck/App Attest) 1급 지원이 결정적. RLS는 강력하나 클라 attestation 동등물 미성숙. |
| 통합 | 15 | 5 | 75 | 3 | 45 | Apple Provider 즉시·FCM 1급·AdMob 같은 Google 가족. Maps SDK도 Google. |
| 운영 부담 | 10 | 4 | 40 | 4 | 40 | 둘 다 SaaS. 콘솔 학습 곡선 동률. |
| **합계** | **100** | | **465** | | **335** | Firebase +130pt. |

→ **Firebase 압도적 우위, 채택**.

## 근거 (요약)

1. **강제 조건**: Firebase 신규 프로젝트 한도 초과로 기존 `MatchaMapAPP` 재활용이 사실상 강제. Supabase 선택 시 Firebase 한도 문제와 무관하지만, 이미 보유한 자원을 버리는 비용이 크다.
2. **속도**: MVP 6주 일정에 검증된 통합(Apple Provider/FCM/Storage/App Check)이 결정적.
3. **보안**: App Check(DeviceCheck + App Attest) 1급 지원으로 콜러블 함수 보호가 SDK 수준에서 완성된다.
4. **비용**: Spark 무료 한도가 사용자 ~수만명 수준에서 충분 ([cost-projection.md](../server/cost-projection.md) 참조). 그 이전 Blaze 전환은 자연 스케일.
5. **레퍼런스**: FearIndex-iOS에서 Firebase Functions(asia-northeast3) 안정 운영 검증.

## 리전 결정 — `asia-northeast3` (Seoul)

- **Firestore Native Mode** 멀티 리전이 아닌 **단일 리전**으로 시작. `asia-northeast3` 선택.
- **Cloud Functions 2nd gen**: 동일 리전 `asia-northeast3`.
- **Cloud Storage**: `asia-northeast3` (사진 업로드 대역폭 최소화).

### 리전 선택 근거

| 후보 | RTT (KR 사용자) | RTT (JP 사용자) | RTT (US) | 결론 |
|---|---|---|---|---|
| `asia-northeast3` (Seoul) | ~5–15ms | ~30–50ms | ~150–200ms | **채택** |
| `asia-northeast1` (Tokyo) | ~30–40ms | ~5–15ms | ~100–150ms | KR 우선 트래픽 손해 |
| `us-central1` | ~150–200ms | ~150–200ms | ~5–30ms | KR/JP 양쪽 큰 손해 |
| `nam5` (multi) | KR/JP에 좋지 않음 | 좋지 않음 | 좋음 | 글로벌 균등이지만 MVP 핵심 시장 손해 |

- MVP 트래픽 70%+가 KR+JP. Seoul → Tokyo RTT는 양호(~30ms). KR 사용자에게 단방 5–15ms.
- 미국/유럽 사용자는 v1.x.x에서 read-only mirror 또는 CDN 캐시(Hosting)로 보강 검토.
- **글로벌 read replica는 v1.2.0에서 검토** (조건: US/EU 합산 MAU > 10K 또는 P95 latency > 800ms).
- **Note (Storage 무료 한도)**: Cloud Storage 무료 quota는 `us-central1/us-west1/us-east1` 버킷에만 적용. Seoul 버킷은 첫 GB부터 과금되지만, MVP 규모(<수GB)에서 월 비용은 $0.026 × N 수준으로 무시 가능. 정책 일관성(latency)을 우선.

## Supabase 재검토 트리거 (정량 기준)

다음 중 **하나 이상**이 4주 연속 충족되면 ADR-301-rev1을 작성하여 재평가. 단발성 스파이크는 트리거가 아님.

1. **비용**: Firebase 월 청구액 $100 USD 초과 (3개월 이동평균).
2. **규모**: MAU 100,000 이상 도달.
3. **Vector 검색 PRD 명시**: PRD 또는 Phase Plan에 "매장 유사도 추천" 또는 "리뷰 시맨틱 검색"이 채택 기능으로 등록 (pgvector 우위).
4. **트랜잭션 한계**: 단일 사용자 액션이 다중 컬렉션 원자 갱신을 5건 이상 요구하는 패턴이 PRD에 도입 (Firestore 트랜잭션 batch 한계 500 vs Postgres ACID).
5. **글로벌 read latency**: US/EU 사용자 P95 > 1500ms 4주 연속 (CDN/Hosting 보강 후에도).

> 트리거 발화 시 `server-lead`가 `po-lead`에 SendMessage + ADR-301-rev1 초안. 단순 "Supabase가 더 좋아 보임" 같은 정성 사유는 트리거가 아니다.

## 영향

- `server-lead`는 본 ADR을 디폴트로 모든 작업 분배.
- iOS는 `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseAnalytics`, `FirebaseAppCheck`, `FirebaseMessaging`을 SPM으로 추가. (`ios-lead` Phase 2에서 SPM 사인오프).
- Cloud Functions는 TypeScript 2nd gen, 리전 `asia-northeast3` 강제. (`server-functions` 표준 템플릿 작성).
- **App Check 강제**: 모든 콜러블 함수에 `enforceAppCheck: true`. (`server-auth` Phase 2-3 책임).
- **보안 규칙 lock-down 디폴트**: Phase 1 종료 시점까지 모든 컬렉션은 `allow read, write: if false;`. 컬렉션별 규칙은 `server-data` 스키마 사인오프 후 `server-auth`가 작성.

## 보류 결정 (별도 ADR)

- **ADR-302**: 데이터 모델 (Firestore 스키마) — `server-data` 작성 (Phase 2).
- **ADR-303**: App Check + 보안 규칙 — `server-auth` 작성 (Phase 2-3).
- **ADR-304**: 글로벌 read replica 또는 CDN 전략 — v1.2.0 트리거 발화 시.

## Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | Accepted (초안) | po-lead, server-lead |
| 2026-05-04 | v2: 5축 가중 매트릭스, 정량 트리거, 리전 비교, Storage 무료 한도 노트 추가 | server-lead, **po-lead 사인오프 완료** |
