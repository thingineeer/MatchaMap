#!/usr/bin/env bash
# UserPromptSubmit hook: 사용자가 squash 머지를 요청하면 경고 메시지를 추가한다.
# stdout으로 출력된 텍스트는 사용자 프롬프트 컨텍스트에 추가됨.
set -euo pipefail

input=$(cat || true)

if echo "$input" | grep -qiE 'squash[- ]?merge|--squash|git rebase -i'; then
  cat <<'EOF'
[guard] 주의: 본 프로젝트는 스쿼시 머지/대화형 rebase를 금지합니다.
- 모든 머지: git merge --no-ff
- 자세한 정책: CLAUDE.md § 6 + .claude/memory/feedback-no-squash.md
EOF
fi

exit 0
