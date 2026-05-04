---
name: no-squash-merge
description: 모든 브랜치 머지는 git merge --no-ff 강제. 스쿼시 머지·force push·--no-verify 우회 시도가 보이면 즉시 차단하고 사용자에게 보고. 머지/PR/브랜치 통합 작업이 필요할 때 매번 호출.
---

# 스쿼시 금지 + no-ff 머지

## 규칙

```sh
# 항상
git merge --no-ff <branch>

# 절대 금지
git merge --squash      # ← 차단
git push --force        # ← dev/main/release/1.x.x에서 차단
git commit --no-verify  # ← 차단
gh pr merge --squash    # ← 차단
gh pr merge --rebase    # ← 일반적으로 금지 (사용자 명시 시만)
```

## 왜

사용자 명시: "스쿼시 머지는 절대로 하지마. 그냥 merge해."
- worktree 단위 작업의 경계가 머지 커밋으로 시각화됨
- 회귀 추적/롤백 시 커밋 단위 cherry-pick 가능
- 협업 이력 보존

## 머지 흐름 (매번 따른다)

1. **feat/* → 1.x.x**:
   ```sh
   git checkout 1.0.0
   git pull --ff-only origin 1.0.0
   git merge --no-ff feat/<area>-<purpose> -m "merge: <area>/<purpose>"
   git push origin 1.0.0
   ```

2. **1.x.x → dev**:
   ```sh
   git checkout dev
   git merge --no-ff 1.0.0 -m "merge: 1.0.0 통합 → dev"
   ```

3. **dev → main** (QA 사인오프 후):
   ```sh
   git checkout main
   git merge --no-ff dev -m "release: prepare v1.0.0-rc"
   git tag v1.0.0-rc1
   ```

4. **main → release** (앱스토어 배포 완료 후):
   ```sh
   git checkout release
   git merge --no-ff main -m "release: v1.0.0 published"
   git tag v1.0.0
   ```

## GitHub PR

- "Create a merge commit" 만 사용.
- "Squash and merge" 옵션은 레포 설정에서 disable 권장.
- "Rebase and merge" 도 disable.

## 자동 가드

`.claude/hooks/git-safety.sh`가 PreToolUse Bash에서 차단:
- `git merge --squash` → block
- `git push --force` (dev/main/release/1.*) → block
- `git commit --no-verify` → block
- `gh repo edit --visibility public` → block (사용자 명시 승인 필요)

## 예외

없다. 사용자가 직접 "이번엔 squash로" 라고 말하지 않는 한 모두 차단.
