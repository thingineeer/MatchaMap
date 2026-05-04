---
name: decisions-launch-sequence
description: 출시 시퀀스 ADR-PROD-003 확정 — 3그룹 시차 출시(APAC D0 / 글로벌 D+30 / EU D+60)
type: project
---

**출시 그룹**:
- **그룹 1 — APAC 비치헤드(D-7 베타 → D0 출시)**: KR + JP. 모국어 운영 + 본토 인증.
- **그룹 2 — 글로벌 매출(D+30)**: US + UK. iOS eCPM 압도적 우위(US $14.32 인터 / $19.63 보상).
- **그룹 3 — EU 확장(D+60)**: DE + FR. 비건/플랜트베이스 + 빠띠스리 결합. UMP SDK 통합 필수(GDPR/DSGVO).

**Why:**
- 비치헤드 4축 평가에서 KR(8.0) vs US(8.0) 동률, JP(7.2) → 단일 시장 베팅이 데이터로 강하게 지지되지 않음.
- 30일 간격 그룹핑으로 (1) 운영 부담 분산(po-lead+po-growth+qa-localization 3명 응대 한계) + (2) APAC 30일 데이터로 US ASO 키워드/메시징/슬롯 빈도 보강 후 진입(가설 H6 검증).
- US 출시 30일 지연의 매출 손실은 후속 그룹 효율 향상으로 부분 회수.

**How to apply:**
- po-growth: 인플루언서 컨택을 그룹별 분할(KR+JP 5+3 → US+UK 5+3 → DE+FR 3+2). 같은 그룹은 같은 빌드.
- server-lead cost-projection 시나리오 B(MAU 25K)는 KR+JP+US+UK D+60 합산 가정.
- qa-localization: 카탈로그 회귀 일정도 그룹 순서대로(KR/JP → US/UK → DE/FR).
- v1.0.0 한정. v1.1.0에서 D+30 시점 US D7/ARPU 결과로 시퀀스 재검토(가설 H4').
