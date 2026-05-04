---
name: decisions-stack
description: 백엔드 스택 결정 — Firebase(MatchaMapAPP 프로젝트 재활용)를 MVP 1순위, Supabase는 비용/요건 임계 도달 시 재검토
type: project
---

**결정**: 백엔드는 **Firebase (MatchaMapAPP)** 로 시작.

**Why:**
- 사용자가 이미 Firebase 프로젝트(구 one-problem-app → MatchaMapAPP) 보유 + Firebase 신규 프로젝트 생성 한도 초과 상태이므로 재활용이 강제 조건에 가깝다.
- Apple Sign In + 이메일 미사용(Passkey 별도) 환경에서 Firebase Auth는 Apple Provider 즉시 지원.
- AdMob과 같은 Google 생태계 통합 비용이 낮다.
- FearIndex-iOS에서 검증된 Functions(asia-northeast3) 패턴을 그대로 이식 가능.

**MVP 무료 플랜 한도(Spark)**:
- Firestore 1GiB / 50K 읽기/일.
- Functions 호출 125K/월.
- Storage 5GB.
- → 사용자 ~수만명까지 무료 운영 가능. 임계 도달 시 Blaze로 업그레이드.

**Supabase 재검토 트리거**(아직 미발동):
- Postgres 트랜잭션이 강하게 필요한 기능 등장(예: 도감 통계 집계).
- Vector 검색(pgvector)으로 매장 유사도/추천 강화 필요.
- Firebase 비용이 월 100 USD 초과.

**How to apply:**
- 모든 서버 에이전트는 본 결정을 디폴트로 진행. Supabase 비교 보고는 ADR로 별도 작성하되 채택은 임계 도달 시.
