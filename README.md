# 말차맵 (MatchaMap)

> 전세계 말차 덕후를 위한 글로벌 말차 카페 발견 · 기록 · 도감 앱.

[![iOS](https://img.shields.io/badge/iOS-26.2%2B-blue)]() [![Swift](https://img.shields.io/badge/Swift-5.0-orange)]() [![Xcode](https://img.shields.io/badge/Xcode-26.3-blue)]() [![License](https://img.shields.io/badge/license-Proprietary-lightgrey)]()

## 무엇을 만드는가

- 🗺️ **글로벌 지도**: Google Maps SDK · 인기시간 · 길찾기 · 스트리트뷰
- 🍵 **매장 큐레이션**: 말차 전문 매장만. 메뉴 · 리뷰 · 사진
- 📚 **도감(Collection)**: 시음한 말차 수집 — 등급/원산지/색감 메모
- 👥 **친구 피드**: 좋아요/댓글/스토리 (미니 SNS)
- 🔐 **로그인**: Apple Sign In + Passkey (이메일/비번 미사용)
- 📱 **iOS 26.2 SwiftUI** + Liquid Glass

## 시작 (개발자용)

```sh
# 1) 시크릿 vault에서 환경변수 + GoogleService-Info를 symlink
ln -s ~/.env-vault/projects/matchamap-ios/.env .env
ln -s ~/.env-vault/projects/matchamap-ios/GoogleService-Info.plist MatchaMap/GoogleService-Info.plist

# 2) Xcode 열기
open MatchaMap.xcodeproj

# 3) 시뮬레이터 빌드 (커맨드라인)
xcodebuild -project MatchaMap.xcodeproj -scheme MatchaMap \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## 디렉토리

```
MatchaMap/
├── CLAUDE.md                  # 에이전트 팀 최상위 규칙
├── MatchaMap.xcodeproj/
├── MatchaMap/                 # 앱 본체 (PBXFileSystemSynchronizedRootGroup)
├── LocalPackages/             # Clean Architecture 모듈 (TBD: Domain/Core/Data/Feature/DesignSystem)
├── fastlane/                  # 배포 자동화
├── docs/
│   ├── product/               # PO 산출물 (PRD, 시장조사, 수익화)
│   ├── design/                # 디자인 시스템 / 토큰 / SVG
│   ├── architecture/          # ADR / 모듈 다이어그램
│   ├── server/                # API 명세 / Firestore 스키마
│   └── qa/                    # 시나리오 / 회귀 시트
├── _handoff/                  # 디자인 핸드오프 원본 (gitignore)
└── .claude/
    ├── agents/                # 16명 에이전트 정의
    ├── skills/                # 도메인 스킬
    ├── memory/                # 프로젝트 로컬 메모리(MEMORY.md 인덱스)
    └── hooks/                 # 안전 가드 훅
```

## 브랜치 전략

```
release  ← 앱스토어 배포된 버전만 (태그)
main     ← QA 통과
dev      ← 개발 통합 (default)
1.x.x    ← 버전 통합
feat/*   ← worktree 단위 기능 (N커밋)
```

스쿼시 머지 금지. 모든 머지는 `--no-ff`. 자세한 규칙은 `CLAUDE.md` § 6 참조.

## 시크릿 분리

본 레포는 **Public 가능** (CodeRabbit AI 자유 활용 목적).
시크릿은 [`thingineeer/thingineeer-env`](https://github.com/thingineeer/thingineeer-env) 의 `projects/matchamap-ios/`로 분리.

## 라이선스

Proprietary © thingineeer. 무단 복제/배포 금지.
