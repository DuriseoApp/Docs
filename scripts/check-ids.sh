#!/usr/bin/env bash
# 둘이서 문서 정합성 검사
#  1. 파생 문서(ERD, API, SCREENS)가 PRD에 없는 ID를 쓰지 않는지
#  2. PRD의 모든 FR이 파생 문서 어딘가에 연결됐는지
#  3. PRD의 모든 화면(SCR)이 SCREENS.md에 있는지
#  4. 파생 문서 헤더의 PRD 버전이 PRD와 같은지
# 오류가 있으면 종료 코드 1. macOS 기본 bash(3.2)에서 동작한다.

set -u
cd "$(dirname "$0")/.." || exit 2

PRD="docs/PRD.md"
DERIVED="docs/ERD.md docs/API.md docs/SCREENS.md"
ID_RE='(NFR-[A-Z]+-[0-9]{2}|SCR-[A-Z]+-[0-9]{2}|FR-[A-Z]+-[0-9]{2}|D-[0-9]{2}|Q-[0-9]{2})'

errors=0
warnings=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "  ✗ $1"; errors=$((errors + 1)); }
warn() { echo "  ! $1"; warnings=$((warnings + 1)); }

[ -f "$PRD" ] || { echo "PRD가 없습니다: $PRD"; exit 2; }

grep -hoE "$ID_RE" "$PRD" | sort -u > "$tmp/prd"
grep -E '^FR-' "$tmp/prd" > "$tmp/prd_fr"
grep -E '^SCR-' "$tmp/prd" > "$tmp/prd_scr"
: > "$tmp/derived_all"

prd_ver="$(grep -m1 -oE '문서 버전: [0-9]+\.[0-9]+' "$PRD" | grep -oE '[0-9]+\.[0-9]+')"
echo "PRD 버전: ${prd_ver:-알 수 없음} (ID $(wc -l < "$tmp/prd" | tr -d ' ')개, FR $(wc -l < "$tmp/prd_fr" | tr -d ' ')개, 화면 $(wc -l < "$tmp/prd_scr" | tr -d ' ')개)"
[ -n "$prd_ver" ] || fail "PRD 머리에서 '문서 버전: X.Y'를 찾지 못했습니다"

for f in $DERIVED; do
  echo ""
  echo "[$f]"
  if [ ! -f "$f" ]; then
    fail "파일이 없습니다"
    continue
  fi
  grep -hoE "$ID_RE" "$f" | sort -u > "$tmp/ids"
  cat "$tmp/ids" >> "$tmp/derived_all"

  dangling="$(comm -23 "$tmp/ids" "$tmp/prd")"
  if [ -n "$dangling" ]; then
    for id in $dangling; do fail "PRD에 없는 ID: $id"; done
  else
    echo "  ✓ 모든 ID가 PRD에 있음"
  fi

  if [ -n "$prd_ver" ]; then
    if grep -m1 -qE "PRD v${prd_ver}([^0-9]|$)" "$f"; then
      echo "  ✓ 기준 PRD v${prd_ver}"
    else
      found="$(grep -m1 -oE 'PRD v[0-9]+\.[0-9]+' "$f")"
      fail "헤더의 기준 PRD 버전이 다름: ${found:-없음} (PRD는 v${prd_ver})"
    fi
  fi
done

echo ""
echo "[PRD → 파생 문서 연결]"
sort -u "$tmp/derived_all" > "$tmp/derived"
missing_fr="$(comm -23 "$tmp/prd_fr" "$tmp/derived")"
if [ -n "$missing_fr" ]; then
  for id in $missing_fr; do fail "어느 파생 문서에도 연결되지 않은 FR: $id"; done
else
  echo "  ✓ 모든 FR이 ERD·API·SCREENS 중 하나 이상에 연결됨"
fi

if [ -f docs/SCREENS.md ]; then
  grep -hoE "$ID_RE" docs/SCREENS.md | grep -E '^SCR-' | sort -u > "$tmp/scr_in_screens"
  missing_scr="$(comm -23 "$tmp/prd_scr" "$tmp/scr_in_screens")"
  if [ -n "$missing_scr" ]; then
    for id in $missing_scr; do fail "SCREENS.md에 없는 화면: $id"; done
  else
    echo "  ✓ PRD의 모든 화면이 SCREENS.md에 있음"
  fi
  not_designed="$(grep -cE '^- \*\*디자인\*\*: (미반영|변경 요청됨)' docs/SCREENS.md)"
  [ "$not_designed" -gt 0 ] && warn "디자인이 아직 반영되지 않은 화면 ${not_designed}개 (/design-handoff 필요)"
fi

echo ""
if [ "$errors" -gt 0 ]; then
  echo "결과: 오류 ${errors}건, 주의 ${warnings}건"
  exit 1
fi
echo "결과: 통과 (주의 ${warnings}건)"
exit 0
