# Server 허브 (docs/server)

> `server-lead` + `server-data` + `server-functions` + `server-auth` 공동 소유.

## 인덱스

- [erd.md](erd.md) — 엔티티 관계도
- [schema.md](schema.md) — Firestore 컬렉션/문서 스키마
- [api-contract.md](api-contract.md) — Cloud Functions 콜러블 함수 입출력
- [security-rules.md](security-rules.md) — Firestore/Storage rules 가이드
- [auth-strategy.md](auth-strategy.md) — Apple Provider + Passkey AASA
- [storage-paths.md](storage-paths.md) — 사진 업로드 경로/제한
- [push-payload.md](push-payload.md) — FCM 페이로드 명세
- [cost-projection.md](cost-projection.md) — Spark→Blaze 임계 추정

## 결정

- **백엔드**: Firebase (`MatchaMapAPP`, 구 `one-problem-app`).
- **리전**: `asia-northeast3` (서울).
- **Auth**: Apple Sign In + Passkey. 이메일/비번 미사용.
- **Storage**: Firebase Storage. 사진 업로드 사이즈 제한.
- **Functions**: 2nd gen TS. fanout/검증/모더레이션.
- **App Check**: DeviceCheck + App Attest 강제.
