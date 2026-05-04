---
name: handoff-phase2-server
description: Phase 2 server 팀 시작 시 즉시 처리할 server-lead 사인오프 항목 — 이벤트 스키마/규칙/콘솔 셋업 게이트
type: project
---

**Phase 2 진입 시 즉시 합의 필요 (server-lead Phase 1 산출물 기반):**

1. **이벤트 스키마 사인오프**: `docs/server/observability.md` § 3 이벤트 카탈로그를 ios-lead가 클라 구현 가능한지 검토. 특히 `dwell_ms`(OBS-1), `placement_session_idx`(인터스티셜 가드레일)는 SDK 레벨 측정 필요.
2. **여행 모드 판별**: 클라 우선 + 서버 IP geo 백업 정책(observability.md § 2). `home_country` 첫 30일 자동 보정 1회 → 영구 동결. 명시 변경 UI는 v1.1.0.
3. **App Check 모니터링 모드 → enforce 전환**: Phase 2 통합 직후 1주 모니터링, 정상 거부율 확인 후 enforce. `~/.env-vault/projects/matchamap-ios/appcheck-debug.txt`에 디버그 토큰.
4. **Blaze 전환 + Budget**: TestFlight 시작 직전 활성화. 알림 단계 $20/$50/$100. MAU 40K 사전 경보(트리거 #1 80%) 추가.
5. **`firebase-setup-checklist.md` § 15 게이트** 모두 체크되어야 server-data 스키마 작업 시작.
6. **ADR-303 (server-auth) 비용 영향 의무**: `docs/server/cost-projection.md` § 4.0 / § 4.2의 Auth MAU 50K 임계 분석을 ADR-303 § 비용 영향 섹션에 인용 + 4건 검증(Identity Platform 단가 다단계, Apple Sign In premium 분류 확인, MAU 40K 사전 경보 알림 등록, 탈퇴 사용자 MAU 카운트 처리) 모두 체크 후 사인오프. po-lead (a)+(c) 선호 채택 결과.

**Why:**
- Phase 1에 결정된 사항을 Phase 2 시작 시 재논의로 시간 낭비 금지.
- 트리거 #1(월 $100) 정합 재확인: **MAU 50K가 점프 임계**(Auth 무료 한도 초과 시작). 51K 시점 ~$86 = 트리거의 86%, **MAU 60K 시점 발화** 예상. MAU 40K 사전 경보 필요.

**How to apply:**
- Phase 2 server-data가 ADR-302 작성 시작 전에 본 5건을 server-lead가 ios-lead/po-lead와 합의.
- 보안 규칙은 `docs/server/security-rules.md` 패턴 P1~P6/S1~S3을 server-data 스키마 후 server-auth가 실 .rules로 변환.
