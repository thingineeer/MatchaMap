---
name: conventions-secrets
description: 시크릿은 ~/.env-vault/projects/matchamap-ios/에. 본 레포는 public OK. CodeRabbit 자유 활용 위해 분리 필수
type: feedback
---

**규칙**: 모든 시크릿은 `~/.env-vault/projects/matchamap-ios/`에 보관 + GitHub `thingineeer/thingineeer-env` 의 `projects/matchamap-ios/`로 동기화. 본 레포(`MatchaMap`)는 **Public 가능**.

**Why:**
- 사용자가 "코드래빗을 자유롭게 돌릴 수 있기 때문" Public을 선호한다고 명시. CodeRabbit AI는 Public 레포에서 더 자유롭게 동작.
- 시크릿이 본 레포에 들어가면 Public 전환 불가. 분리는 사실상 강제.

**금지**:
- `GoogleService-Info.plist` 실값 커밋 (덤플레이트 OK).
- `.env`, `*.p8`, `AuthKey_*.p8`, `*.cer`, `*.mobileprovision` 커밋.
- `fastlane/.env*`, `fastlane/api_key.json` 실값 커밋.
- 시크릿을 Slack/Notion 등 외부로 복사.
- `gh repo edit --visibility public` 시 사전 시크릿 검사 없이 실행.

**How to apply:**
- 새 시크릿 추가: `~/.env-vault/projects/matchamap-ios/.env`에 작성 → vault repo에 commit & push.
- 본 레포에서 참조: `ln -s ~/.env-vault/projects/matchamap-ios/.env .env` symlink (`.env`는 .gitignore).
- `.env.example`은 키 이름만(값 없음) 본 레포에 커밋 OK.
- API Key/p8 등 바이너리: `~/.env-vault/projects/matchamap-ios/apple/AuthKey_xxx.p8` + `apple/api_key.json`.
