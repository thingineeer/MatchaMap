# MEMORY.md (인덱스)

> 본문은 각 파일에. 이 파일은 인덱스(150자 이내 한 줄 hook)만 유지.
> 자동 메모리 글로벌 경로(`~/.claude/projects/.../memory/`)는 사용 금지 — 본 프로젝트 로컬만.

## User & Project

- [user-profile.md](user-profile.md) — 사용자(thingineeer): iOS 배포 경험자. FearIndex 성공 출시. 한국어 우선 협업.
- [project-context.md](project-context.md) — 말차맵 v1.0.0: 글로벌 말차 카페 앱. iOS 26.2 SwiftUI · Firebase · Google Maps SDK · AdMob.

## Decisions (확정 / 미정)

- [decisions-stack.md](decisions-stack.md) — 백엔드 Firebase 우선(MatchaMapAPP 프로젝트 재활용), Supabase는 비용 임계 도달 시 재검토.
- [decisions-monetization.md](decisions-monetization.md) — MVP 광고 = AdMob 3슬롯(배너/인터/보상). 첫 60초 광고 차단. 유료 전환 임계 미정.
- [decisions-design.md](decisions-design.md) — v2 화이트톤 팔레트 + Pretendard + 앱 아이콘 B(단일 잎 글래스) ACCEPTED 2026-05-04. vein 시그니처 동결.
- [decisions-ios-architecture.md](decisions-ios-architecture.md) — LocalPackages 9 모듈 + Composition Root DI(라이브러리 미사용) + TDD. ADR-001/002/003 Accepted, swift test 16 PASS.
- [decisions-auth-cost.md](decisions-auth-cost.md) — Auth 비용 단계 전환: Phase 2 (a)단독 → MAU 50K (a)+(c) → MAU 100K (a)+(b)+(c). ADR-303 §5 정합.

## Conventions

- [conventions-git.md](conventions-git.md) — release ← main ← dev ← 1.x.x ← worktree feat/*. no-ff 강제, 스쿼시 금지.
- [conventions-build-number.md](conventions-build-number.md) — `CFBundleVersion = YYMMDD_HHMM` (KST). fastlane bump_build에서 자동 주입.
- [conventions-secrets.md](conventions-secrets.md) — 시크릿은 ~/.env-vault/projects/matchamap-ios/. 본 레포는 public 가능.

## References

- [refs-fearindex.md](refs-fearindex.md) — fastlane/CLAUDE.md/coderabbit.yaml 패턴은 ~/Desktop/FearIndex-iOS/ 참조.
- [refs-handoff.md](refs-handoff.md) — 디자인 핸드오프: ./_handoff/matchamap/project/MatchaMap v2.html + mm-shared-v2.jsx 우선.

## Feedback (반복하지 말 것)

- [feedback-no-squash.md](feedback-no-squash.md) — 스쿼시 머지 금지. 모든 머지는 --no-ff. 이력 보존이 사용자 핵심 요구.
- [feedback-build-number-format.md](feedback-build-number-format.md) — 빌드 번호는 사람이 읽을 수 있는 YYMMDD_HHMM. 자동 증가 정수 금지.
- [feedback-emoji-restraint.md](feedback-emoji-restraint.md) — 이모지는 사용자가 명시 요청한 곳에서만. CLAUDE.md/코드 등 자동 추가 금지.
- [feedback-info-plist-conflict.md](feedback-info-plist-conflict.md) — `MatchaMap/Info.plist` 두지 말 것. Synced group + GENERATE_INFOPLIST_FILE 충돌. Phase 4에서 ios-lead가 확정.

## Phase 핸드오프 (이연된 합의)

- [handoff-phase3-ios-map.md](handoff-phase3-ios-map.md) — Phase 3 ios-map 시작 시 즉시 처리: 매장 핀 5건 합의(viewBox/anchor/그림자/등급매핑/Asset 이름).
- [handoff-phase2-server.md](handoff-phase2-server.md) — Phase 2 server 시작 시: 이벤트 스키마 사인오프, 여행 모드 클라+서버 백업 정책, App Check enforce 전환, Blaze + Budget, MAU 40K 사전 경보.
- [handoff-xcode-integration.md](handoff-xcode-integration.md) — ios-lead Phase 2 후속: 사용자 Xcode UI에서 LocalPackages 9개 Local Package 등록 + Unit Testing Bundle + Info.plist 권한 키 5단계.
