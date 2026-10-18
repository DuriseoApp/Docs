#!/usr/bin/env bash
# Claude 세션을 열 때(SessionStart 훅)와 /prd-sync 시작 때 실행된다.
# GitHub에서 머지된 최신 문서를 받아 온다. 작업 중인 내용은 절대 건드리지 않는다.
#  - main이고 저장 안 한 변경이 없으면: main을 최신으로 빨리감기
#  - 작업 브랜치인데 이미 머지됐고 변경이 없으면: main으로 옮기고 최신으로
#  - 그 밖(작업 중, 충돌 가능): 아무것도 하지 않고 알리기만
# 어떤 경우에도 세션을 막지 않도록 항상 exit 0. macOS 기본 bash(3.2)에서 동작한다.

cd "$(dirname "$0")/.." 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

say() { echo "[문서 동기화] $1"; }

if ! git fetch --quiet origin main 2>/dev/null; then
  say "GitHub에 연결하지 못해 최신 문서를 받지 못했어요. 지금 있는 문서로 작업해요."
  exit 0
fi

branch="$(git branch --show-current)"
dirty="$(git status --porcelain)"

# 브랜치의 커밋이 모두 origin/main에 들어갔는지 (일반·리베이스 머지 모두 인식)
merged_into_main() {
  git merge-base --is-ancestor HEAD origin/main 2>/dev/null && return 0
  [ -z "$(git cherry origin/main HEAD 2>/dev/null | grep '^+')" ]
}

if [ "$branch" != "main" ]; then
  if [ -z "$dirty" ] && merged_into_main; then
    if git switch --quiet main 2>/dev/null && git merge --ff-only --quiet origin/main 2>/dev/null; then
      say "'$branch' 브랜치가 머지돼서 main으로 옮기고 최신 문서를 받았어요."
    else
      say "'$branch'가 머지된 것 같은데 main으로 옮기지 못했어요. 확인이 필요해요."
    fi
  else
    behind="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)"
    say "'$branch' 브랜치에서 작업 중이라 그대로 뒀어요. (main에 새 커밋 ${behind}개)"
  fi
  exit 0
fi

if [ -n "$dirty" ]; then
  say "저장하지 않은 변경이 있어서 최신 문서를 받지 않았어요."
  exit 0
fi

before="$(git rev-parse HEAD)"
if ! git merge --ff-only --quiet origin/main 2>/dev/null; then
  say "main이 GitHub와 갈라져 있어 자동으로 받지 못했어요. 확인이 필요해요."
  exit 0
fi
after="$(git rev-parse HEAD)"
if [ "$before" != "$after" ]; then
  count="$(git rev-list --count "$before..$after")"
  say "최신 문서를 받았어요 (커밋 ${count}개):"
  git log --format='  - %s' "$before..$after" | head -10
fi
exit 0
