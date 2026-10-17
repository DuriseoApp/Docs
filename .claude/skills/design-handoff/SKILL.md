---
name: design-handoff
description: claude.ai 디자인 채팅에서 수정한 디자인을 이 레포로 가져온다. 화면 이미지(design/screens), 토큰 값(design/tokens.json), 화면 명세(docs/SCREENS.md)를 디자인 기준으로 갱신하고 PR을 연다. "/design-handoff", "디자인 가져와줘", "디자인 반영해줘" 같은 요청에 쓴다.
argument-hint: "[디자인 링크]"
---

# 디자인 핸드오프

디자인 원본은 claude.ai 디자인 채팅에 있다. 이 스킬은 그 결과를 Android·iOS 에이전트가 읽을 수 있는 파일로 바꿔 레포에 넣는다. 디자인을 새로 그리거나 고치지 않는다.

## 1. 입력 확인

둘 중 하나로 받는다.

- **링크 모드**: 사용자가 디자인 링크(claude.ai/…/artifact/…)를 줬고, 이 세션에 claude.ai 아티팩트를 읽는 도구가 있으면 그 도구로 읽는다. 웹 요청(curl, WebFetch)으로 읽지 않는다.
- **파일 모드**: 사용자가 디자인에서 내보낸 파일을 `design/inbox/`에 넣었다.
  - 화면 이미지(PNG, PDF). 파일 이름에 화면 ID가 있으면 좋다 (예: `SCR-CAL-01.png`)
  - 있으면: 디자인 시스템의 `bundle.css`, 토큰 목록, 디자인 채팅이 정리한 "바뀐 화면 ID 목록"

둘 다 없으면 멈추고 사용자에게 안내한다: "디자인 채팅에서 화면을 이미지로 내보내 `design/inbox/`에 넣거나, 디자인 링크를 알려 주세요. 가능하면 디자인 시스템의 bundle.css도 함께 넣어 주세요."

## 2. 브랜치

`git switch -c design/handoff-<YYYYMMDD>` (main에서 시작한다. 이미 있으면 그대로 쓴다)

## 3. 화면 매핑

1. 각 이미지를 열어 보고 `docs/SCREENS.md`의 화면 ID에 대응시킨다. 보드 이름의 화면 ID를 먼저 쓰고, 없으면 내용으로 판단한다.
2. 대응이 확실하지 않은 이미지는 목록으로 보여주고 사용자에게 묻는다.
3. 한 화면의 상태별 이미지(빈 상태, 게스트, 다이얼로그 등)는 `SCR-XXX-NN--<상태>.png`로 이름 붙인다 (예: `SCR-SET-01--guest.png`, `SCR-SET-01--unlink-dialog.png`).
4. 결과를 `design/screens/`에 저장한다. 같은 이름이 있으면 덮어쓴다 (이전 버전은 git 기록에 남는다). PDF는 페이지를 PNG로 바꿔 저장하되, 도구가 없으면 사용자에게 PNG로 다시 내보내 달라고 한다.

## 4. 토큰 갱신

1. `bundle.css`나 토큰 목록이 있으면 `design/tokens.json`의 null 값을 채우고 바뀐 값을 고친다.
2. **이미지에서 색을 추출해서 넣지 않는다.** 근거 파일이 없는 값은 null로 둔다.
3. 새 토큰이 생겼으면 추가하고, `design/design-system.md`에도 같은 변경을 적는다.
4. `$meta.updated`를 오늘 날짜로 바꾼다.

## 5. SCREENS.md 갱신

이미지가 들어온 화면마다:

1. 구성, 상태, 다이얼로그, 문구를 디자인에 보이는 그대로 채운다. 문구는 이미지의 글자를 정확히 옮긴다.
2. 디자인과 PRD가 다르면(PRD에 없는 요소, PRD에 있는데 없는 요소, 다른 문구) 고치지 말고 화면 아래 `차이:` 줄에 적고, 마지막 보고에 모은다. PRD가 우선이다.
3. `디자인:` 줄을 `반영됨 (<YYYY-MM-DD>, design/screens/<파일>)`로 바꾼다.
4. 헤더의 "디자인 기준"을 "부분 반영" 또는 "반영"과 날짜로 바꾼다.

## 6. 변경 요청서 확인

`design/change-requests/`에서 상태가 "반영 완료"가 아닌 요청서를 열고, "반영 확인" 표를 이미지 기준으로 체크한다. 모두 반영됐으면 상태를 "반영 완료"로 바꾼다. 빠진 항목은 보고에 적는다.

## 7. 검사와 PR

1. `bash scripts/check-ids.sh`
2. `design/inbox/`의 원본 파일은 커밋하지 않는다 (.gitignore). 처리한 뒤 사용자에게 지워도 된다고 알린다.
3. 커밋: `docs(design): 디자인 핸드오프 <YYYY-MM-DD>`
4. `git push -u origin design/handoff-<YYYYMMDD>` 후 `gh pr create --base main`
   PR 본문: 반영된 화면 목록, 토큰 변경, PRD와의 차이, 변경 요청서에서 빠진 항목, 이미지 미리보기(바뀐 화면 PNG 경로)
5. 머지하지 않는다.

## 하지 않는 것

- 디자인을 새로 그리거나 화면 이미지를 편집하기
- 근거 없는 토큰 값 넣기
- PRD와 다른 디자인을 SCREENS.md에 "정답"으로 적기 (차이로만 적는다)
- PRD에 없는 화면 ID 만들기
