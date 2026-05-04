# ADR-301 — 백엔드: Firebase (MatchaMapAPP) 확정

- **일자**: 2026-05-04
- **상태**: Accepted (Phase 0 인프라 셋업과 함께 결정)
- **결정자**: `server-lead`, 사인오프: `po-lead`

## 컨텍스트

말차맵 v1.0.0 백엔드 선택지: Firebase vs Supabase.

## 옵션

### 옵션 A — Firebase (MatchaMapAPP)
- 사용자가 이미 Firebase 콘솔에 `MatchaMapAPP` 프로젝트(구 `one-problem-app`)를 보유. Firebase 신규 프로젝트 생성 한도 초과 상태이므로 재활용이 효율적.
- Apple Sign In Provider, FCM, Storage, App Check, Cloud Functions(2nd gen, asia-northeast3) 즉시 사용 가능.
- AdMob과 같은 Google 생태계 통합 비용 ↓.
- FearIndex-iOS에서 검증된 패턴(Functions/규칙/Hosting) 그대로 이식 가능.

### 옵션 B — Supabase
- Postgres 트랜잭션 강함. pgvector로 매장 유사도 추천 등 강화 가능.
- 셀프 호스팅 가능, 비용 예측성 높음.
- 그러나 Apple Sign In은 추가 설정 필요, FCM 푸시는 별도 통합, Functions 가격 모델이 다름.

## 결정

**옵션 A: Firebase 채택.**

## 근거

1. **강제 조건**: Firebase 신규 프로젝트 한도 초과로 기존 `MatchaMapAPP` 재활용이 사실상 강제. Supabase 선택 시 Firebase 한도 문제와 무관하지만, 이미 보유한 자원을 버리는 비용이 크다.
2. **속도**: MVP 6주 가량의 짧은 일정에 검증된 통합(Apple Provider/FCM/Storage)이 결정적.
3. **비용**: Spark 무료 한도가 사용자 ~수만명 수준에서 충분. 그 이전 Blaze 전환은 자연 스케일.
4. **레퍼런스**: FearIndex-iOS에서 Firebase Functions(asia-northeast3) 안정 운영 검증.

## Supabase 재검토 트리거

다음 중 하나 발생 시 ADR 재작성:
- 매장 추천에 vector 검색이 필수가 됨 (pgvector 우위).
- Firestore 트랜잭션 한계 도달(다중 컬렉션 원자 갱신 패턴이 대량으로 등장).
- 월 비용이 100 USD 초과하면서 Firebase 가격 압박 명확.

## 영향

- `server-lead`는 본 ADR을 디폴트로 모든 작업 분배.
- iOS는 `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseAnalytics`, `FirebaseAppCheck`, `FirebaseMessaging`을 SPM으로 추가.
- Cloud Functions는 TypeScript 2nd gen, 리전 `asia-northeast3` 강제.

## 보류 결정 (별도 ADR)

- ADR-302: 데이터 모델 (Firestore 스키마) — `server-data` 작성.
- ADR-303: 보안 규칙 + App Check — `server-auth` 작성.

## Changelog

| 일자 | 변경 | 사인오프 |
|---|---|---|
| 2026-05-04 | Accepted | po-lead, server-lead |
