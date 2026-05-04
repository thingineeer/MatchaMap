# Auth 비용 절감 옵션 — Identity Platform $275/월@MAU 100K 대응

- **작성**: `server-auth` · 2026-05-04
- **상태**: Phase 2 — ADR-303 §5 정량 비교 단독 문서
- **상위 결정**: [ADR-303 §5](../architecture/ADR-303-app-check-security-rules.md#5-auth-비용-절감-옵션--po-우선-검토-1)
- **인용**: [cost-projection.md §4.0 마일스톤 B+](cost-projection.md#40-신규-마일스톤--auth-mau-50k-임계-b)

> 본 문서는 ADR-303 §5의 정량 분석을 단독 문서로 추출한 것. PO/server-lead가 MAU 진행에 따라 옵션 전환 시점을 판단하는 운영 가이드.

## 1. 배경 (한눈에)

- **Identity Platform Auth 비용**이 MatchaMap 비용 곡선의 점프 항목.
- MAU **50K 도달 = Auth 무료 한도 초과 시작** = ADR-301 트리거 #1($100/월) 86% 도달.
- MAU **100K = 월 $478 중 Auth가 $275 = 58%**.
- → Auth 비용 통제가 Firebase 유지 가능성을 결정.

## 2. Identity Platform 가격 (2026-05 검증, server-auth 1차 확정)

| MAU 구간 | Standard tier (Apple/Google/이메일) | Premium tier (SAML/OIDC custom) |
|---|---|---|
| 0 ~ 50,000 | 무료 | 무료 |
| 50,001 ~ 99,999 | **$0.0055/MAU** | $0.015/MAU |
| 100,000 ~ 999,999 | $0.0046/MAU | $0.0125/MAU |
| 1,000,000+ | $0.0025/MAU | $0.0075/MAU |

**Apple Sign In은 Standard tier**. (Apple은 OIDC 기반이지만 Firebase Auth 기본 제공 Provider로 분류 — Premium은 SAML/OIDC custom Provider만 해당.)

→ MAU 100K Auth 비용 = (100K - 50K) × $0.0055 = **$275/월** (cost-projection.md 정합).
→ MAU 1M Auth 비용 = $4,415/월.

## 3. 절감 옵션 (3개)

### 옵션 (a) — 현 상태 유지

- Firebase Auth + Identity Platform 활성 (Apple Provider 사용 시 자동 활성).
- 구현 비용: **0** (Phase 2 디폴트).
- 비용: § 2 표.

### 옵션 (b) — 자체 OIDC + Firebase Custom Token

- iOS 클라가 ASAuthorizationAppleIDProvider로 Apple ID Token 직접 받음.
- Cloud Functions가 Apple ID Token 검증 후 Firebase **custom token** 발급.
- Firebase Auth는 사용 안 함 → Identity Platform 비활성 → MAU 비용 0.
- 단, 콜러블 호출당 Functions 비용 (~$0.40/M, Spark 2M 내 무료).

### 옵션 (c) — Apple Sign In 유지 + 휴면 30일 자동 익명화

- Firebase Auth Apple Provider 그대로 사용.
- 30일 미사용 사용자는 "휴면" 분류 → 푸시 알림 → 7일 무응답 시 Auth user 삭제 + Firestore 데이터 익명화.
- Identity Platform MAU 카운트는 활성 사용자만 → 절감.

## 4. 시나리오별 정량 비교

### 4.1 가정

- 활성 비율: MAU 명목 대비
  - 10K 미만: 100% (정리 정책 미발동)
  - 50K: 90%
  - 100K: 70% (휴면 30일 정책 발동 시)
  - 500K: 60%

### 4.2 비용 표 ($/월, Auth 부분만)

| MAU 명목 | (a) Firebase Auth | (b) Custom Token | (c) Auth + 휴면 정리 |
|---|---|---|---|
| 10K | **$0** | $0 (불필요) | $0 (불필요) |
| 50K | **$0** | $0 | $0 |
| 51K | $0.005 | $0 | $0 |
| 100K | $275 | **$0** (-$275) | $110 (-$165) |
| 500K | $2,345 | **$0.40** (-$2,344) | $1,425 (-$920) |
| 1M | $4,415 | **$0.80** (-$4,414) | $3,690 (-$725) |

### 4.3 트레이드오프 매트릭스

| 항목 | (a) | (b) | (c) |
|---|---|---|---|
| 구현 비용 | 0 | 1주 (Apple JWKS + 토큰 검증) | 3일 (휴면 정책 cron + 푸시) |
| 유지보수 | 0 | 중 (JWKS 키 회전) | 소 |
| 보안 책임 | Firebase | server-auth 직접 | Firebase + 정책 |
| 50K 미만 절감 | — | 0 | 0 |
| 100K 절감 | — | -$275 (100%) | -$165 (60%) |
| 500K 절감 | — | -$2,344 (99%) | -$920 (39%) |
| Apple 정책 정합 | 자동 | server-auth가 보장 | 자동 + 휴면 안내 |
| iOS 클라 변경 | 0 | 중 | 0 |
| 롤백 가능성 | — | uid 동일 유지 시 호환 | 즉시 (정책 OFF) |

## 5. 단계 전환 추천 (server-auth → po-lead)

### Stage 0 (현재 ~ MAU 40K)

**옵션 (a) 디폴트**. 추가 작업 없음. ADR-303의 모든 산출물(보안 규칙, AASA, 계정 삭제, 푸시) 우선 처리.

### Stage 1 (MAU 40K — 사전 경보)

- Cloud Monitoring 알림 발화 (`firebase_auth.users.monthly_active >= 40000`).
- server-auth + po-lead 합동 ADR-303-rev1 트리거:
  - 실제 활성/휴면 비율, ARPU, 구독 전환률 데이터 입력.
  - 옵션 (b)/(c) 정량 재평가.

### Stage 2 (MAU 50K — Auth 비용 발생 시작)

**옵션 (c) 채택**. 휴면 30일 정책 활성화.

근거:
- 구현 부담 가장 낮음 (3일).
- MAU 100K에서 -$165 절감 → 트리거 #1($100) 미발화 유지 가능성 ↑.
- iOS 클라 변경 0.

### Stage 3 (MAU 100K — 트리거 #1 발화)

**옵션 (b) 도입 + (c) 유지** 검토.

근거:
- (c)만으로는 MAU 100K 시 $315 (Auth $110 + Reads $162 + Egress $21 + Photos $4 + Download $16 + Storage $2) → 트리거 발화.
- (b) 도입으로 Auth 비용 0 → 합계 $40으로 급감 → 트리거 미발화 유지 가능.
- 단, (b) 구현 부담(1주) + 보안 검토 책임 → 6주 일정 안에서 ADR-303-rev2로 작성.

### Stage 4 (MAU 500K+)

**(b) 단독으로 충분**. (c)는 효과 미미 (이미 활성 비율 자연 안정).

## 6. 옵션 (c) 휴면 정리 — 구현 가이드

### 6.1 휴면 판별

`users/{uid}.lastActiveAt` 필드 추가 (schema.md §1.1 보강 — 별도 task로 server-data 합의).

```ts
// firebase-functions/src/scheduler/dormantUsers.ts (Phase 3+)
export const flagDormantUsers = onSchedule(
  { schedule: '0 3 * * *', region: 'asia-northeast3' }, // 매일 03:00 KST
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now() - 30 * 24 * 3600 * 1000);
    const snap = await db().collection('users').where('lastActiveAt', '<', cutoff).get();
    for (const doc of snap.docs) {
      // 푸시 알림 + dormantSince 필드 set
      // 7일 무응답 시 다음 cron이 Auth deleteUser + 익명화
    }
  }
);
```

### 6.2 익명화 vs 완전 삭제

- **익명화** (옵션 (c) 권장): `users/{uid}.displayName = "익명_<hash(uid)[0..6]>"`, photoURL = null, locale/country 유지(분석 통계).
- **완전 삭제**: onUserDelete 트리거가 모두 제거 (계정 삭제와 동일 흐름).

→ Apple 정책 정합 + GDPR Right to be Forgotten — **완전 삭제 권장**. 익명화는 사용자 명시 동의가 있어야 안전.

→ **결론**: 휴면 30일 정책은 푸시 알림 → 7일 무응답 시 사용자 안내 후 **완전 삭제** (onUserDelete 흐름 재활용).

### 6.3 사용자 안내

- **30일 휴면 도달 시 푸시**: "30일간 미사용. 7일 안에 로그인하지 않으면 데이터가 삭제됩니다."
- **삭제 24h 전 푸시 + 이메일** (Apple Private Email Relay이지만 시도): "내일 데이터가 삭제됩니다."
- **삭제 직후**: 이메일 통지 (가능 시).

## 7. 옵션 (b) 자체 OIDC — 구현 가이드 (Stage 3+ 도입 시)

### 7.1 흐름

1. iOS 클라: `ASAuthorizationAppleIDProvider`로 Apple ID Token 받음 (변경 없음).
2. iOS 클라: 콜러블 `appleSignIn(idToken, rawNonce)` 호출 (Firebase Auth `signIn` 대신).
3. Functions:
   - Apple JWKS 키로 idToken 서명 검증.
   - rawNonce 검증.
   - `users/{uid}` 존재 확인 또는 신규 생성 (uid는 Apple sub claim).
   - Firebase **custom token** 발급 (`adminAuth().createCustomToken(uid, { authMethod: 'apple_oidc' })`).
4. iOS 클라: `Auth.auth().signIn(withCustomToken:)` → Firebase Auth 컨텍스트 진입.
5. 이후 모든 Firestore/Storage 호출은 Firebase Auth 토큰 그대로 사용 (변경 없음).

### 7.2 Identity Platform 비활성

- Firebase Console > Authentication > Sign-in method > Apple **Disable**.
- → Identity Platform MAU 카운트 0.
- 단, custom token 사용은 Identity Platform 의존 X (Firebase Auth Admin SDK는 Identity Platform 활성/비활성 무관).

### 7.3 Apple JWKS 검증

```ts
// firebase-functions/src/auth/appleSignIn.ts (Stage 3 작성 예정 — 의사코드)
import { createRemoteJWKSet, jwtVerify } from 'jose';

const APPLE_JWKS_URL = 'https://appleid.apple.com/auth/keys';
const jwks = createRemoteJWKSet(new URL(APPLE_JWKS_URL), { cooldownDuration: 24 * 3600 * 1000 });

async function verifyAppleIdToken(idToken: string, rawNonce: string) {
  const { payload } = await jwtVerify(idToken, jwks, {
    issuer: 'https://appleid.apple.com',
    audience: 'th1ngjin.MatchaMap',
  });
  if (payload.nonce !== sha256(rawNonce)) {
    throw new HttpsError('unauthenticated', 'nonce mismatch');
  }
  return payload.sub as string; // uid
}
```

### 7.4 마이그레이션

- Stage 3 도입 시 기존 사용자 uid는 Apple Sign In의 `sub` claim과 동일 → **uid 변경 없음**.
- Firestore 데이터 마이그레이션 불필요. iOS 클라만 `signIn(with: appleCredential)` → 콜러블 `appleSignIn(...)` 변경.
- 롤백: 콜러블 미사용 + Firebase Console에서 Apple Provider 재활성. 30분 내 가능.

## 8. 의사결정 책임

| 임계 | 책임자 | 액션 |
|---|---|---|
| MAU 40K (사전 경보) | server-lead | Cloud Monitoring 알림 → po-lead SendMessage + ADR-303-rev1 검토 시작 |
| MAU 50K (B+ 마일스톤) | server-auth + po-lead | 옵션 (c) 휴면 정책 활성화 결정 |
| MAU 60K (트리거 #1 발화) | server-lead → po-lead | 트리거 발화 보고 + ADR-301-rev1 작성 또는 옵션 (b) 검토 |
| MAU 100K (시나리오 C) | server-auth | 옵션 (b) ADR-303-rev2 작성 + 1주 구현 + 1주 모니터링 |

## 9. 리스크

- **GDPR 정합**: 휴면 30일 자동 삭제는 사용자 동의/안내가 명확해야 함. ToS 갱신 + 가입 시 동의 체크 필수.
- **사용자 경험**: 휴면 후 재방문 시 데이터 손실 충격 → 푸시 안내 + 이메일이 critical.
- **(b) 보안 책임**: Apple JWKS 검증 실수 시 인증 우회 가능 → 단위 테스트 + Penetration test 필수.
- **(b) 롤백 비용**: 사용자 segments 갈라지면 분석 일관성 깨짐 → 1회 도입 후 유지 권장.

## 10. 추천 (요약)

| 시점 | 옵션 | 액션 |
|---|---|---|
| Phase 2 (현재) | (a) 단독 | 추가 작업 없음 |
| MAU 40K | — | Cloud Monitoring 알림 + 검토 |
| MAU 50K | (a) + (c) | 휴면 30일 정책 활성화 (3일 작업) |
| MAU 100K | (a) + (b) + (c) | 옵션 (b) 도입 (1주 작업) + (c) 유지 |
| MAU 500K+ | (b) 단독 | (c) 정책 효과 미미 |

## 11. 변경 이력

| 일자 | 변경 | 작성자 |
|---|---|---|
| 2026-05-04 | 초안 (옵션 (a)/(b)/(c) 정량 비교 + 단계 전환 추천) | server-auth |
