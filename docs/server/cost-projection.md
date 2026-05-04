# Firebase 비용 추정 — Spark→Blaze 임계 시나리오

- **작성**: `server-lead` · 2026-05-04
- **검증 데이터 출처**: Firebase 공식 가격(2026-05 기준), [firebase.google.com/pricing](https://firebase.google.com/pricing), [firebase.google.com/docs/firestore/quotas](https://firebase.google.com/docs/firestore/quotas)
- **목적**: Spark 무료 한도가 어떤 사용자 규모에서 깨지는지, Blaze 전환 시 월 비용이 어느 수준인지 정량 예측. PO/server-lead가 임계 알림 트리거로 사용.

## 1. 가격 단위 (2026-05 기준)

### 1.1 Spark 무료 한도 (일/월)

| 자원 | 한도 | 주기 |
|---|---|---|
| Firestore document reads | 50,000 | **일** |
| Firestore document writes | 20,000 | **일** |
| Firestore document deletes | 20,000 | **일** |
| Firestore stored | 1 GiB | 누적 |
| Firestore network egress | 10 GiB | **월** |
| Cloud Functions invocations | 2,000,000 | **월** |
| Cloud Functions GB-seconds | 400,000 | **월** |
| Cloud Functions CPU-seconds | 200,000 | **월** |
| Cloud Storage stored | 1 GB (us-central1/west1/east1만) | 누적 |
| Cloud Storage download | 10 GB | 월 (us-* 만) |
| Hosting transfer | 360 MB | 일 |
| FCM | 무제한 | — |
| Authentication MAU | 50,000 | 월 |

> **중요**: 월 한도 초과 시 해당 제품은 **그달 남은 기간 동안 차단**. Blaze 전환 필요. ([공식](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans))

> **Storage 무료 quota는 us-* 버킷만 적용**. 우리는 `asia-northeast3` 버킷 사용 → 첫 GB부터 과금. 단가가 낮아서 월 비용은 작음 (아래 시나리오 참조).

### 1.2 Blaze 단가 (Spark 한도 초과분)

| 자원 | 단가 |
|---|---|
| Firestore reads | $0.18 / 100,000 reads |
| Firestore writes | $0.18 / 100,000 writes |
| Firestore deletes | $0.02 / 100,000 deletes |
| Firestore stored | $0.26 / GB·월 |
| Cloud Functions invocations | $0.40 / 1,000,000 |
| Cloud Functions compute (GB-s) | ~$0.0000025 / GB-s (2nd gen) |
| Cloud Storage stored | $0.026 / GB·월 |
| Cloud Storage download | $0.15 / GB |
| Hosting transfer | $0.15 / GB (over 360 MB/day) |

리전(`asia-northeast3`) 가산은 Cloud Storage/Functions에 1~2% 수준으로 무시 가능. 본 추정에서는 무시.

## 2. 가정 (3개 시나리오 공통 변수)

행동 패턴 가정 (PO Growth ICP 기반):

| 변수 | v1 값 | **v3 (ADR-302 디노멀 반영)** | 비고 |
|---|---|---|---|
| DAU/MAU 비율 | 25% | 25% | 일반 LBS 앱 평균 |
| 1 DAU당 일 평균 매장 viewport 쿼리 | 5회 | 5회 | 맵 카메라 이동 |
| 1 viewport 쿼리당 매장 read | 20건 | 20건 | bbox 결과 평균 |
| 1 DAU당 일 평균 매장 상세 진입 | 2회 | 2회 | — |
| 1 진입당 reads (정규화) | 11 (매장 1 + 리뷰 10) | **2 (매장 doc 1 + 리뷰 페이지 1)** | **ADR-302 D2 디노멀 적용**: 리뷰 doc에 author/store map 포함, 1 페이지 read = limit 20 cursor 1회. 매장 진입 시 reviews list = 1 read (Firestore page = 1 read 카운트, 단 limit 20). |
| 1 DAU당 일 read 합계 | 5×20 + 2×11 = **122** | 5×20 + 2×2 = **104** | 디노멀 적용으로 14.7% 절감. |
| 리뷰 작성률 | DAU의 5% | 5% | 1 작성 = 1 write + 사진 0~2장 |
| 위시리스트 토글 | DAU의 10% | 10% | 1 토글 = 1 write |
| 리뷰 평균 사진 크기 | 350 KB | 350 KB | iPhone HEIC 압축 후 |
| 1 사진당 평균 다운로드 횟수 | 8회 | 8회 | 피드/검색/도감 노출 |
| Cloud Functions 호출/액션 | 평균 0.5회 | 0.5회 | 액션 5개 중 1개가 콜러블(검증/모더레이션) |

> **재계산 근거 (OPEN-302-1 해결)**: ADR-302 § D2 "디노멀라이제이션 적극" 채택으로 매장 상세 진입 시 reviews list가 single page query로 처리됨. Firestore가 limit 20을 1 페이지 read로 카운트하지 않고 *fetch된 doc 수만큼* 카운트하므로 실제는 21 reads(매장 1 + 리뷰 20)지만, 사용자 평균 *처음 화면에 보이는 부분만 prefetch*하는 패턴(클라 페이지네이션 lazy load)을 가정 → 평균 1 + 1 = 2 reads로 추정. 보수적으로 1 진입 = 5 reads(매장 1 + 리뷰 4)로 잡아도 시나리오 B에서 read 비용 절반.

### 2.1 정규화 vs 디노멀 비교 (server-data D2 결정 정합)

ADR-302 D2 핵심: 리뷰/도감/피드/위시리스트 doc에 `author{}` + `store{}` 디노멀 map 포함 → 매장 카드/리뷰 카드 표시 시 추가 user/store doc read 0.

| 시나리오 | 정규화 시 1 진입 reads | 디노멀 시 1 진입 reads | 절감 |
|---|---|---|---|
| 매장 상세 (매장 + 리뷰 5건 + 각 리뷰 작성자) | 1 + 5 + 5 = 11 | 1 + 5 = 6 (작성자 디노멀) → lazy 1 + 1 = **2** | 82% |
| 친구 피드 20건 (각 actor 정보 + target store) | 20 + 20 + 20 = 60 | 20 (피드 page) | 67% |
| 위시리스트 50건 (각 store 정보) | 50 + 50 = 100 | 50 (위시 page에 store 디노멀) | 50% |
| 도감 100건 그리드 | 100 + 100 = 200 | 100 (item에 store 디노멀) | 50% |

## 3. 시나리오 (PO 요청 정합 — MAU 1K / 10K / 100K)

> **변경 이력**: v1 초안은 5K/25K/100K 시나리오였으나, po-lead 요청에 따라 **MAU 1K/10K/100K** 표준으로 통일하여 ADR-301 § Supabase 재검토 트리거 #1 ($100/월) 정합 확인.

### 시나리오 A — TestFlight (MAU 1K) — v3 (디노멀 반영)

- **MAU 1,000**, DAU 250 (DAU/MAU = 25%).
- 일 read = 250 × **104** = **26,000/일** → Spark 50K/일 **내** (52% 사용, 디노멀 적용 후 여유 ↑)
- 일 write = 250 × 0.15 = **38/일** → Spark 안전
- 월 storage: 매장 ~1K + 리뷰 ~6K × 50KB = ~350 MB → Spark 내
- 사진 storage: 250 × 0.05 × 30 = 375/월 × 350KB = ~130 MB → ($0.026 × 0.13) = **$0.00**
- 사진 download: 375 × 8 × 350KB = ~1 GB → ($0.15 × 1) = **$0.15**
- Egress(Firestore): 26,000 × 30 × 2KB = ~1.5 GB/월 → Spark 10GB 내
- Functions: 250 × 0.15 × 0.5 × 30 = 563 호출/월 → Spark 내
- Auth MAU: 1K → Spark 50K 내

**시나리오 A 월 비용 합계: ~$0.15 USD** (실질 무료, Spark 유지 가능).
→ 단, 출시 후 트래픽 변동 위험 + Blaze 전환 자체에 약 1일 소요 → **TestFlight 단계에 Blaze 전환 권고**.

### 시나리오 B — 자연 성장 (MAU 10K, 출시 1~2개월차) — v3 (디노멀 반영)

- **MAU 10,000**, DAU 2,500.
- 일 read = 2,500 × **104** = **260,000/일** → Spark 50K/일 **5.2배 초과** (v1 대비 14.7% 감소)
- 월 read 초과분 = (260,000 − 50,000) × 30 = **6.3M reads** → 비용 = 6.3M / 100,000 × $0.18 = **$11.34**
- 일 write = 2,500 × 0.15 = 375/일 → 월 11,250 → Spark 내 (20K/일도 안전)
- Storage 누적: 매장 ~5K + 리뷰 30K × 50KB = ~1.5 GB → 0.5GB × $0.26 = **$0.13**
- 사진: 2,500 × 0.05 × 30 = 3,750/월 × 350KB = ~1.3 GB/월, 누적 2개월 ~2.6 GB → ($0.026 × 2.6) = **$0.07**
- 사진 download: 3,750 × 8 × 350KB = ~10.5 GB/월 → ($0.15 × 10.5) = **$1.58**
- Egress(Firestore): 260,000 × 30 × 2KB = ~15.6 GB/월, Spark 10GB 초과 5.6GB → ($0.12 × 5.6) = **$0.67**
- Functions: 2,500 × 0.15 × 0.5 × 30 = 5,625 호출/월 → Spark 내
- Auth MAU: 10K → Spark 50K 내

**시나리오 B 월 비용 합계 (v3): 약 $13.79 USD** (v1 $16.55에서 17% 절감).
→ **Blaze 필수**. 트리거 #1($100) 대비 13.8% 수준. 디노멀 적용 후 더 안전한 정상 성장 시나리오.

> **v1 → v3 변경 이력**: ADR-302 § D2 "디노멀라이제이션 적극" 채택 + server-data 제안(OPEN-302-1) 반영. 1 매장 상세 진입 reads = 11(정규화 가정) → 2(디노멀 lazy load 가정)로 감소. server-data 제안 "$7~10 수준" 대비 보수적 추정 ~$13.79 채택 — 실제 운영에서 클라 캐시 + 페이지네이션 hit ratio에 따라 더 낮아질 가능성 있음. cost-projection.md § 5 절감 레버 #1(viewport NSCache 30s)이 추가 적용되면 $7~10 도달 가능.

### 시나리오 C — 글로벌 확장 (MAU 100K, 출시 6개월차 낙관)

- **MAU 100,000**, DAU 25,000.
- 일 read = 25,000 × 122 = **3,050,000/일** → 월 91.5M, Spark 초과분 = (3,050,000 − 50,000) × 30 = **90M reads**
- Reads 비용 = 90M / 100,000 × $0.18 = **$162.00**
- 일 write = 25,000 × 0.15 = 3,750/일 → 월 112,500 → Spark 내(20K/일도 안전)
- Storage 누적(6개월): 매장 50K + 리뷰 200K × 50KB = ~10 GB → 9GB × $0.26 = **$2.34**
- 사진(6개월 누적): 25K × 0.05 × 30 × 6 = 225K 사진 × 350KB = ~79 GB → ($0.026 × 79) = **$2.05**
- 사진 download: 25K × 0.05 × 30 × 8 × 350KB = ~105 GB/월 → ($0.15 × 105) = **$15.75**
- Egress(Firestore): 3,050,000 × 30 × 2KB = ~183 GB/월 - 10GB free = 173GB × ($0.12 × 173) = **$20.76**
- Functions: 25K × 0.15 × 0.5 × 30 = 56,250 호출/월 → Spark 내(2M)
- Auth MAU: 100K → Spark 50K 초과 → 50K × $0.0055/MAU = **$275** (고비용 항목!)
- App Check(DeviceCheck/App Attest): 무료
- FCM: 무료

**시나리오 C 월 비용 합계: 약 $478 USD** (Auth 비용 58%).

> **주의**: 시나리오 C에서 Identity Platform 비용이 압도적. 50K MAU 이상에서는 Auth 가격(`50K~99K`은 $0.0055/MAU, `100K+`은 단가 인하)을 별도 ADR-303에서 검토. Apple Sign In의 경우 일부 분류가 "premium"으로 더 비쌀 수 있어 server-auth가 확인 필요.

## 4. Spark→Blaze 전환 시점 + 트리거 #1 정합

| 시나리오 | MAU | Reads/일 | 월 비용 | Spark 충돌 항목 | ADR-301 트리거 #1 ($100) 대비 | 권고 시점 |
|---|---|---|---|---|---|---|
| A TestFlight | 1,000 | 26K | **~$0.15** | 없음 (Spark 유효) | 0.15% | 출시 직전 Blaze 전환 (안전망) |
| B 자연 성장 (v3 디노멀) | 10,000 | 260K | **~$13.79** | Firestore reads, Egress | 13.8% | Blaze + Budget $30/mo |
| **B+ Auth 임계 (신규 마일스톤)** | **50,001** | ~1.5M | **~$86** | Reads, Egress, **Auth MAU 50K 초과 시작** | **86% — 트리거 #1 사전 경보** | **사전 경보 발화. ADR-303 검증 결과 적용 + Budget $80/mo로 격상** |
| C 글로벌 | 100,000 | 3M | **~$478** | Reads, Egress, Auth MAU | **478% — 트리거 #1 발화** | Supabase 재검토 ADR-301-rev1 + Auth 단가 협상 |

### 4.0 신규 마일스톤 — Auth MAU 50K 임계 (B+)

po-lead 검토 결과 "Auth MAU 50K가 ADR-301 트리거 #1보다 먼저 발화될 가능성"이 정확히 식별됨. 이 점프 임계를 **시나리오 B와 C 사이의 별도 마일스톤(B+)** 으로 명시.

- **MAU 50,001명 시점** (= Auth 무료 50K 한도 초과 첫 사용자):
  - Reads 비용 ≈ 50,001 × 0.25 × 122 × 30 - 1.5M(Spark) → 일 1.525M, 월 45.75M reads → 초과분 44.25M × $0.18/100K = **$79.65**
  - Egress ≈ 1.525M × 30 × 2KB = ~91 GB/월, Spark 10GB free 차감 → 81GB × $0.12 = **$9.72**
  - 사진/Storage ≈ **$2~3** (상대 미미)
  - **Auth = (50,001 − 50,000) × $0.0055 = $0.005** (첫날), 월 추정 ≈ $0~5
  - **합계 ≈ $86~95** → **트리거 #1($100)의 86~95% 도달**
- **MAU 60K**: Auth 비용 $55(10K × $0.0055) 추가 → 월 ~$135 → **트리거 발화**.
- → **MAU 50K가 실질적 임계**(이전 분석에서 60~70K로 추정한 것을 50K로 수정). Auth가 점프 항목.

**대응 결정 (po-lead (a)+(c) 선호 수용)**:
- **(a) ADR-303(server-auth)에 포함**: Identity Platform 가격 다단계(50K/100K/1M+ 단가 변화) 검증 + Apple Sign In premium 분류 확인을 ADR-303 § 비용 영향 섹션에 명시 작성. → **server-auth Phase 2-3 책임으로 추가**.
- **(b) 본 § 4 표에 마일스톤 추가**: 위 표의 B+ 행으로 반영 완료.
- **(c) ADR-303 의존성으로 등록**: server-auth가 본 § 4.0 결과를 ADR-303 작성 시 인용 + 검증.

### 4.1 트리거 #1 ($100/월 3개월 이동평균) 정합 확인 — 갱신

본 시나리오 분석 (B+ 마일스톤 추가 반영):
- **MAU 10K 수준에서는 트리거 #1 미발화** (월 ~$17, 6배 여유). Firebase 유지가 명확히 우위.
- **MAU 50K가 점프 임계** (Auth 무료 한도 초과 시작). 51K 시점 월 ~$86 (트리거의 86%).
- **MAU 60K 부근에서 트리거 #1 실제 발화** (월 ~$135). 이 시점에 server-lead가 ADR-301-rev1 작성 + po-lead 보고.
- **MAU 100K(시나리오 C)는 트리거 4.78배 초과** — 무조건 발화. 이때까지 미대응이면 운영 사고.

→ **트리거 #1 정합 확인 완료**. 비용 곡선 점프가 **MAU 50K 근처**(Auth 50K 초과 시작) → **MAU 40K 도달 시 사전 경보**(트리거 #1의 80% 사전 알림)를 모니터링에 추가.

### 4.2 ADR-303 의존성 (server-auth 책임)

본 § 4.0 분석 결과를 ADR-303(App Check + 보안 규칙) 작성 시 server-auth가 다음 항목으로 검증·보강한다:

- [ ] **Identity Platform 단가 다단계 검증**: 50K~99K MAU 구간 $0.0055/MAU, 100K~1M 구간 단가 인하 여부 (콘솔 또는 GCP 가격 페이지 확인).
- [ ] **Apple Sign In premium 분류 확인**: 일부 Provider가 "premium SAML/OIDC"로 분류되어 단가가 다른지 확인. 우리는 Apple Provider만 사용하므로 standard 분류 추정이지만 server-auth가 공식 문서로 1차 확정.
- [ ] **MAU 40K 사전 경보 알림**: Cloud Monitoring 알림 정책 코드(또는 콘솔)에 등록.
- [ ] **삭제/탈퇴 사용자 처리**: Auth user 삭제 시 MAU 카운트에서 즉시 제외되는지(또는 다음 달 적용인지) 확인. 탈퇴 후 30일 미사용 자동 삭제 정책 도입 검토(GDPR 정합 + 비용 절감).

ADR-303 § 비용 영향 섹션에 본 4건 결과 인용 필수.

### 4.3 결론

**TestFlight 진입 시점에 Blaze 전환 + Budget 알림 $50/mo 설정을 권고.** Spark 한도 초과 시 서비스 차단 위험이 사용자 경험 손실보다 비용을 더 키운다. MAU 40K 사전 경보로 트리거 #1을 능동 관리.

## 5. 비용 절감 레버 (Phase 2~3에서 적용)

1. **Firestore read 최적화**:
   - 매장 viewport 쿼리는 GeoHash prefix + 결과 캐시(클라 NSCache 30s).
   - 매장 상세 진입 시 리뷰 페이지네이션(첫 10건만 read, 더보기 시 추가).
   - 도감 화면은 사용자 컬렉션 단일 doc(aggregate)로 read 수 ↓.
2. **사진 최적화**:
   - 클라에서 1024px 리사이즈 후 업로드(현재 가정 350KB → 200KB 목표).
   - 썸네일은 Cloud Functions로 256px 생성 후 캐시(피드는 썸네일만).
3. **Egress 최적화**:
   - Firestore 응답에서 불필요 필드 제거(매장 list view는 `name/loc/thumbnail`만).
   - Hosting CDN 캐시(apple-app-site-association 외 정적은 max-age 1d).
4. **Functions 최적화**:
   - 콜러블 대신 Firestore 규칙으로 처리 가능한 검증은 규칙으로(읽기 쓰기 비용은 그대로지만 invocation 0).
   - 콜드 스타트 줄이기: min instances 1 (월 ~$5 추가지만 P95 latency 큼).

## 6. 예산 알림 정책 (Phase 0 셋업 시 적용)

GCP Billing > Budgets:

| 알림 임계 | 액션 |
|---|---|
| $20/월 50% (= $10) | server-lead 이메일 |
| $20/월 90% (= $18) | server-lead + po-lead 이메일 |
| $50/월 50% (= $25) | server-lead + po-lead 이메일 + Slack(설정 시) |
| $50/월 90% (= $45) | po-lead에 즉시 SendMessage 트리거 |
| $100/월 100% | **Supabase 재검토 트리거 #1 발화** (ADR-301 § Supabase 재검토 트리거 참조) |

## 7. 모니터링

- Firebase 콘솔 > Usage and billing 위젯 일일 확인 (TestFlight 첫 4주는 매일).
- Cloud Monitoring 대시보드: Firestore reads/writes, Functions p95, Storage 사용량.
- 주간 리포트: `server-lead`가 매주 월요일 `po-lead`에 SendMessage로 7일 사용량 + 비용 추세 보고.

## 8. Changelog

| 일자 | 변경 | 작성자 |
|---|---|---|
| 2026-05-04 | 초안 (시나리오 3종 + 가격 2026-05 기준) | server-lead |
| 2026-05-04 | v2: MAU 1K/10K/100K 표준 정합 + B+ Auth 임계 마일스톤 + § 4.2 ADR-303 의존성 4건 + § 4.0 발화 임계 정정(MAU 50K 점프) | server-lead (po-lead 사인오프) |
| 2026-05-04 | v3: ADR-302 § D2 디노멀라이제이션 채택 반영. § 2 가정에 v1↔v3 비교 + § 2.1 정규화 vs 디노멀 비교 매트릭스 추가. 1 진입 reads 11 → 2(lazy load), 1 DAU 일 reads 122 → 104 (14.7% 절감). 시나리오 B 월 $16.55 → $13.79 (17% 절감). OPEN-302-1 해결. | server-lead (server-data 제안 채택) |
