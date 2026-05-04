---
name: conventions-git
description: Git 브랜치/머지 규칙 — release ← main ← dev ← 1.x.x ← worktree feat/*. 모든 머지 --no-ff, 스쿼시 금지
type: feedback
---

**규칙**: 모든 머지는 `git merge --no-ff <branch>`. **스쿼시 머지 절대 금지.**

**Why:**
- 사용자가 "스쿼시 머지는 절대로 하지마. 그냥 merge해."라고 명시했다. 이력 보존이 핵심 요구사항.
- worktree 단위 작업의 경계가 머지 커밋으로 시각화되어야 후속 회귀/롤백이 쉽다.

**브랜치 위계**:
```
release  ← 앱스토어 배포된 빌드만
main     ← QA 사인오프 통과 (배포 후보)
dev      ← 통합 베이스, default
1.x.x    ← dev에서 분기, 버전 단위 통합
feat/*   ← worktree, 1.x.x에서 분기, N개 커밋 후 머지
```

**금지**:
- `git merge --squash`
- `git push --force` (특히 `dev`/`main`/`release`)
- `git commit --no-verify` (pre-commit 훅 우회)
- `git rebase -i` (대화형 모드 — 비파괴 작업 위주)

**How to apply:**
- 새 기능: `git checkout 1.0.0 && EnterWorktree(name: "feat/<area>-<purpose>")` → 작업 → `git merge --no-ff feat/...` (대상은 `1.0.0`).
- 버전 통합 후: `git checkout dev && git merge --no-ff 1.0.0`.
- QA 통과: `git checkout main && git merge --no-ff dev` + 태그 후보(`v1.0.0-rc1` 등).
- 스토어 배포: `git checkout release && git merge --no-ff main && git tag v1.0.0`.
