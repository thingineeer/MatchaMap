---
name: refs-fearindex
description: FearIndex-iOS를 fastlane/CLAUDE.md/coderabbit.yaml/clean architecture 패턴 레퍼런스로 사용
type: reference
---

**경로**: `/Users/imyeongjin/Desktop/FearIndex-iOS/`.

**참고할 파일**:
- `fastlane/Fastfile` — match · sync_certificates · submit_for_review · upload_ipa · refresh_dsyms · screenshots lanes 패턴.
- `fastlane/Appfile`, `fastlane/Matchfile`, `fastlane/Deliverfile`, `fastlane/ExportOptions.plist`.
- `fastlane/metadata/` — 다국어 메타데이터 디렉토리 구조 (말차맵은 6개 언어로 축소).
- `CLAUDE.md` — 세션 시작 규칙, Memory 정책, Build Commands, Tech Stack 섹션 구조.
- `.coderabbit.yaml` — 한국어 리뷰 + path_instructions 패턴.
- `LocalPackages/{Domain,Core,Data,Presentation}` — Clean Architecture 레이어 분리.
- `firebase-functions/` — Cloud Functions 디렉토리 구조 (asia-northeast3).
- `.env-vault` 패턴: `~/.env-vault/apple/apns/fearindex-iOS/` AuthKey 보관.

**FearIndex와의 차이**:
- 말차맵은 RIBs 미사용. Clean Architecture만(SwiftUI + UseCase). 사용자가 RIBs 명시 안 함.
- 광고: AdMob을 직접 통합 (FearIndex는 AdMob + 별도). 본 프로젝트는 단순화.
- 지도: FearIndex는 차트 위주, 본 프로젝트는 Google Maps SDK 핵심.
