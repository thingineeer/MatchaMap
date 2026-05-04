---
name: feedback-no-squash
description: 스쿼시 머지 절대 금지. 사용자가 명시적으로 그냥 merge(--no-ff)만 사용하라고 지시
type: feedback
---

**규칙**: 모든 브랜치 통합은 `git merge --no-ff`. 스쿼시 머지(`--squash`) 사용 금지.

**Why:**
- 사용자 원문: "스쿼시 머지는 절대로 하지마. 그냥 merge해."
- 작업 단위(브랜치 = 기능)의 커밋 이력을 보존해야 회귀 추적이 쉽다.
- 머지 커밋이 그래프상 "기능 단위 경계"로 시각화된다.

**How to apply:**
- 머지 명령은 항상 `git merge --no-ff <branch> -m "merge: <설명>"`.
- GitHub PR 머지 시: "Create a merge commit" 옵션. "Squash and merge"/"Rebase and merge" 금지.
- worktree 종료 시 자동 squash가 발생할 수 있는 hook 제거 또는 비활성화.
