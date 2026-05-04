---
name: matchamap-orchestrator
description: 말차맵 16명 에이전트 팀의 오케스트레이션 — Phase 별로 팀을 재구성하고 작업을 분배·통합한다. "팀 시작/Phase 진행/배포 전 사인오프" 등 16명 팀 전체 흐름을 관리할 때 필수로 사용. PO/디자이너/iOS/QA/서버를 어느 시점에 누구를 활성화할지, worktree를 어떻게 나눌지, dev→main→release 머지 게이트를 어떻게 운영할지 모두 본 스킬에서 결정.
---

# 말차맵 오케스트레이터

16명 팀(PO 2 / iOS 5 / QA 3 / Designer 2 / Server 4)을 Phase 단위로 재구성하며 운영. 한 번에 한 팀만 활성화 가능하므로 Phase 간 팀 해체 → 산출물 파일 저장 → 새 팀 구성 패턴.

## Phase 별 활성 팀

### Phase 0 — 인프라 셋업 (현재 완료)
- 활성: 단독 메인 세션
- 산출물: `CLAUDE.md`, `.claude/agents/*`, `.claude/memory/*`, `fastlane/`, `.gitignore`, `.coderabbit.yaml`

### Phase 1 — 제품 정의 + 디자인 + 백엔드 결정 (병렬)
- 활성 팀(5명): `po-lead`, `po-growth`, `designer-lead`, `designer-icon`, `server-lead`
- 산출물:
  - `docs/product/PRD.md`, `market-research-{kr,jp,us,uk,de,fr}.md`, `icp.md`, `monetization.md`
  - `docs/design/design-system.md`, `components.md`, `app-icon-decision.md`
  - `docs/architecture/ADR-301-backend-choice.md` (Firebase 확정)
- 게이트: PO 사인오프 → Phase 2 진입.

### Phase 2 — 데이터 모델 + 모듈 경계 + 시안 사인오프 (직렬→병렬)
- 활성 팀(5명): `server-lead`, `server-data`, `server-functions`, `ios-lead`, `designer-lead`
- 산출물:
  - `docs/server/erd.md`, `schema.md`, `api-contract.md`
  - `docs/architecture/ADR-001-module-boundary.md`, `ADR-002-clean-architecture.md`
  - `LocalPackages/<module>/Package.swift` 스켈레톤
  - 디자인 시안 픽셀-퍼펙트 매핑표
- 게이트: ios-lead + server-lead 합의된 API 계약.

### Phase 3 — iOS 구현 (병렬 worktree)
- 활성 팀(5명): `ios-lead`, `ios-map`, `ios-auth-monetize`, `ios-store`, `ios-social-collection`
- 각자 worktree 분리:
  ```
  feat/ios-map-mvp
  feat/ios-auth-passkey
  feat/ios-store-search
  feat/ios-social-feed
  feat/ios-monetize-admob
  ```
- 머지 흐름: feat/* → 1.0.0 → dev (`--no-ff`만)
- 게이트: ios-lead 코드리뷰 + CI 빌드 PASS.

### Phase 4 — QA + 다국어 (병렬)
- 활성 팀(5명): `qa-lead`, `qa-functional`, `qa-localization`, `designer-lead`, `ios-lead`
- 산출물:
  - `docs/qa/scenarios/*.md`
  - `docs/qa/regression/v1.0.0.md`
  - `fastlane/metadata/{ko,en-US,en-GB,de-DE,ja,fr-FR}/*`
- 게이트: 회귀 시트 모든 케이스 PASS + 6개 언어 누락 키 0.

### Phase 5 — 배포 (직렬)
- 활성 팀(4명): `ios-lead`, `qa-lead`, `po-lead`, `server-lead`
- 작업:
  1. `git checkout main && git merge --no-ff dev`
  2. `bundle exec fastlane beta` (TestFlight)
  3. 외부 베타 테스트 1주
  4. `bundle exec fastlane submit_for_review`
  5. 출시 후 `git checkout release && git merge --no-ff main && git tag v1.0.0`
- 게이트: PO 최종 사인오프.

## 데이터 전달 프로토콜

| 전략 | 사용처 |
|---|---|
| **메시지** (`SendMessage`) | 실시간 합의, 코드리뷰 코멘트 |
| **태스크** (`TaskCreate/Update`) | 의존성 추적, 작업 청구 |
| **파일** (`docs/`, `LocalPackages/`) | 산출물 영속화, 감사 추적 |
| **Git** (`--no-ff` 머지) | 코드 통합, 이력 보존 |

## 팀 시작 명령어 (예시)

```
/팀 시작 Phase=1
```

내부 동작:
1. `TeamCreate(team_name: "matchamap-phase-1", description: "제품 정의 + 디자인 + 백엔드 결정")`
2. 5명을 spawn (sub-agent 정의 활용 가능 — `.claude/agents/{name}.md`)
3. Phase 1 게이트 도달 시 모든 팀원 shutdown → 새 Phase 팀 구성

## 에러 핸들링

- **빌드 실패**: ios-lead가 즉시 머지 차단. 원인 격리 후 재시작.
- **API 계약 충돌**: server-lead + ios-lead 라이브 합의 (SendMessage).
- **광고 정책 충돌**: po-lead 사인오프 후 변경.
- **다국어 누락**: qa-localization이 해당 모듈 개발자 직접 핑.

## 머지 게이트 강제

| 게이트 | 통과 조건 |
|---|---|
| `feat/* → 1.x.x` | ios-lead 리뷰 + 빌드 PASS |
| `1.x.x → dev` | 통합 테스트 + 충돌 해결 |
| `dev → main` | qa-lead 사인오프 + 6언어 누락 키 0 |
| `main → release` | PO 사인오프 + 앱스토어 배포 완료 |

스쿼시 머지/--no-verify는 hook으로 차단됨(.claude/hooks/git-safety.sh).

## 테스트 시나리오

**정상**: Phase 1 시작 → 5명 spawn → 산출물 생성 → 사인오프 → Phase 2 시작.
**에러**: server-lead가 Firebase 결정을 뒤집으려 시도 → ADR 보유 + 임계 미도달이면 거부 → 메모리 갱신.
