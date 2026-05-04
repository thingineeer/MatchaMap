#!/usr/bin/env bash
# PreToolUse Bash hook: 위험한 git 명령을 차단한다.
# stdin으로 tool_use JSON을 받음. exit 2 = block + feedback.
set -euo pipefail

payload=$(cat || true)
cmd=$(echo "$payload" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("tool_input",{}).get("command",""))' 2>/dev/null || true)

if [ -z "$cmd" ]; then
  exit 0
fi

block() {
  echo "[git-safety] BLOCKED: $1" >&2
  exit 2
}

# 강제 push (단, dev/main/release/1.* 브랜치만 추가 보호)
if echo "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]].*(--force|-f([[:space:]]|$))'; then
  if echo "$cmd" | grep -qE '(dev|main|release|1\.[0-9]+\.[0-9]+)'; then
    block "보호 브랜치(dev/main/release/1.x.x)에 force push 금지. 사용자 명시 승인 필요."
  fi
fi

# 스쿼시 머지
if echo "$cmd" | grep -qE 'git[[:space:]]+merge[[:space:]].*--squash'; then
  block "스쿼시 머지 금지. 'git merge --no-ff <branch>'를 사용하세요. (CLAUDE.md § 6)"
fi

# pre-commit 훅 우회
if echo "$cmd" | grep -qE 'git[[:space:]]+commit[[:space:]].*--no-verify'; then
  block "--no-verify 금지. pre-commit 훅을 우회하지 말고 원인을 수정하세요."
fi

# 가시성 public 전환 (사전 검사 없이)
if echo "$cmd" | grep -qE 'gh[[:space:]]+repo[[:space:]]+edit.*--visibility[[:space:]]+public'; then
  block "Public 전환 시 시크릿 검사 + 사용자 명시 승인 필요. 본 레포는 시크릿 분리되어 있으나, 전환 전 사용자에게 확인."
fi

exit 0
