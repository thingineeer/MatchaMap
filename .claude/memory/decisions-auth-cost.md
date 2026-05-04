---
name: decisions-auth-cost
description: Auth 비용 절감 옵션 (a)/(b)/(c) 단계 전환 결정 — MAU 임계별 server-auth 책임 액션
type: project
---

**결정**: ADR-303 §5 + auth-cost-mitigation.md — Auth 비용은 **단계 전환** 모델로 통제.

**Why:**
- Identity Platform Auth 비용($0.0055/MAU @ 50K~99K)이 MatchaMap 비용 곡선의 **점프 항목**.
- MAU 50K 도달 = Auth 무료 한도 초과 = ADR-301 트리거 #1($100/월)의 86% 도달.
- MAU 100K = 월 $478 중 Auth가 $275 (58%) 차지 → 통제 안 하면 Firebase 유지 불가.
- po-lead 우선순위 #1 검토 결과: 옵션 (a)/(b)/(c) 정량 비교 후 단계적 전환 권고.

**3개 옵션**:
- (a) Firebase Auth + Identity Platform 활성 — 현재 디폴트.
- (b) 자체 OIDC + Firebase custom token — Identity Platform 비활성, MAU 비용 0. 구현 1주.
- (c) Apple Sign In 유지 + 휴면 30일 자동 삭제 — 활성 사용자만 카운트. 구현 3일.

**단계 전환 추천** (server-auth + po-lead 합의):
- Phase 2 (현재) ~ MAU 40K: **(a) 단독**. 추가 작업 없음.
- MAU 40K (사전 경보): Cloud Monitoring 알림 → po-lead SendMessage + ADR-303-rev1 검토 시작.
- MAU 50K: **(a) + (c)**. 휴면 30일 정책 활성화 (3일 작업).
- MAU 100K (트리거 #1 발화): **(a) + (b) + (c)**. 옵션 (b) 도입 (1주 작업) + (c) 유지.
- MAU 500K+: **(b) 단독**. (c) 효과 미미.

**How to apply:**
- 본 결정은 `docs/server/auth-cost-mitigation.md` § 단계 전환 추천에 단일 진실로. 임계 도달 시 server-lead가 server-auth + po-lead에 SendMessage로 ADR-303-revN 작성 트리거.
- iOS 클라 변경: 옵션 (a)/(c)는 0, (b)는 ASAuthorizationAppleIDProvider → 콜러블 `appleSignIn` 패턴 변경 (uid는 Apple sub로 동일 유지 → 데이터 마이그레이션 0).
- 정량 비교 표는 auth-cost-mitigation.md §4.2 — MAU 100K에서 (b) -$275, (c) -$165, MAU 500K에서 (b) -$2,344.
