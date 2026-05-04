---
name: feedback-emoji-restraint
description: 이모지는 사용자가 명시적으로 요청한 경우에만 사용. CLAUDE.md/코드/커밋 메시지 등에 자동 추가 금지
type: feedback
---

**규칙**: 이모지는 사용자가 직접 요청했을 때만. 그 외에는 텍스트만.

**Why:**
- 시스템 프롬프트가 "Only use emojis if the user explicitly requests it"을 강하게 강조.
- 코드/문서 일관성을 위해 텍스트만 사용하는 것이 협업에 유리.

**How to apply:**
- CLAUDE.md, 메모리, 에이전트 정의, 커밋 메시지, PR 본문, 코드 주석에서 이모지 자동 추가 금지.
- 사용자가 답변에서 이모지를 사용한다고 해서 우리도 사용해야 하는 것은 아니다 (단방향).
- 단, fastlane lane 설명문(`desc`)에서 식별성을 위해 일부 이모지 사용은 FearIndex 패턴에서 허용 — 신규 작성 시는 자제.
