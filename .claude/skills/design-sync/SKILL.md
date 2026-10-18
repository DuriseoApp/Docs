---
name: design-sync
description: 둘이서 앱의 디자인 변경 요청서(DuriseoApp/Docs의 design/change-requests)를 claude.ai 디자인 캔버스에 반영하고, 화면 PNG·tokens.json·SCREENS.md를 갱신해 Docs 레포에 PR을 올리고 Android 레포에 이슈를 만든다. "디자인 반영해줘", "/design-sync" 요청에 쓴다. claude.ai 프로젝트 채팅에서만 실행한다.
---

# 디자인 반영 (design-sync)

PRD가 바뀌면 맥의 `/prd-sync`가 디자인 변경 요청서를 만든다. 이 스킬은 그 요청서를 읽어 **디자인 캔버스를 직접 고치고**, 앱 개발자가 쓸 파일(화면 이미지, 토큰, 화면 명세)을 Docs 레포에 넣는다. 사람은 결과를 보고 PR을 머지만 한다.

## 실행 위치

- **claude.ai 프로젝트 "둘이서" 채팅**에서 실행한다. 이 세션은 클라우드 컴퓨터에서 돌고, 디자인 캔버스(아티팩트)를 읽고 고칠 수 있고, GitHub에 push할 수 있다.
- 맥 터미널의 Claude Code에는 아티팩트 도구가 없다. 거기서 호출되면 아무것도 고치지 말고 "claude.ai 프로젝트 채팅에서 '디자인 반영해줘'라고 해 주세요"라고 안내하고 멈춘다.

## 고정 정보

| 항목 | 값 |
| --- | --- |
| Docs 레포 | DuriseoApp/Docs (쓰기) |
| 이슈를 만들 레포 | DuriseoApp/Android (iOS 레포가 생기면 DuriseoApp/iOS도) |
| 디자인 캔버스 | Docs의 `design/canvas-map.md`에 적힌 링크 (지금: 커플 공유 앱 데모) |
| 디자인 시스템 | 캔버스 안 `project/ds/duriseo/tokens.json` |

## 1. 준비

1. GitHub 레포를 연결한다: Docs는 쓰기 권한, Android는 이슈 생성용. 연결이 거부되면 이유를 그대로 전하고 멈춘다.
2. Docs를 클론하고 `npm install`을 한다 (playwright, IBM Plex 글꼴). 이 환경에 Chromium이 따로 있으면 `CHROMIUM_PATH`로 지정한다. `playwright install`로 브라우저를 내려받지 않는다.
3. `design/canvas-map.md`에서 캔버스 링크와 보드 대응표를 읽는다.

## 2. 반영할 요청서 찾기

1. `design/change-requests/*.md` 중 상태가 "반영 완료"가 아닌 것을 찾는다.
2. 없으면 "반영할 디자인 요청서가 없어요"라고 알리고 멈춘다.
3. 사용자가 요청서 없이 직접 디자인 변경을 말한 경우("FAB를 더 크게" 등): 그 말을 요청으로 삼는다. 단, PRD의 기능·정책이 바뀌는 변경이면 고치지 말고 "PRD부터 바꿔야 해요"라고 안내한다.

## 3. 캔버스 읽기

1. 캔버스를 `read`해서 아티팩트 타입(Design)의 지침을 받는다. **캔버스 파일을 고치는 방법은 그 지침을 따른다** (project/ 아래만 수정, 인덱스는 레이아웃이 바뀔 때만 보내기, 게시 거절 시 다시 읽고 재시도).
2. `project/canvas.json`과 고칠 보드 파일만 읽는다.

## 4. 캔버스 수정

요청서 항목마다:

- 디자인 시스템 토큰과 기존 컴포넌트 모양만 쓴다. 새 색·새 컴포넌트가 필요하면 **만들지 말고 사용자에게 먼저 묻는다**.
- 문구는 `design/design-system.md` 말투를 따른다 (해요체, 결과가 보이는 동사, 이모지 없음). PRD 용어집의 용어를 쓴다.
- 새 화면은 새 보드로 만들고, 보드 제목 앞에 화면 ID를 붙인다 (예: "SCR-ANNIV-01 기념일 목록").
- 같은 화면의 상태(게스트, 다이얼로그 열림 등)는 원래 보드에 prop을 두고, `dc-import`로 그 상태를 보여주는 작은 보드를 만든다 (예: `MenuGuest.dc.html`).
- 기존 보드는 지우지 않는다. 이전 모습은 캔버스 버전 기록에 남는다.
- 기존 보드 수정은 한 번에 모아 게시하고, 새 보드는 하나 만들 때마다 인덱스와 함께 게시한다.

## 5. 화면 이미지

1. 캔버스에서 `artifact-type/dc-runtime.js`와 `project/` 아래 모든 `.dc.html`, `canvas.json`을 한 폴더로 받는다 (dc-import가 다른 보드를 불러오기 때문).
2. `design/canvas-map.md` 대응표를 새 보드까지 갱신한다.
3. 대응표의 모든 보드를 렌더링한다:
   ```
   node scripts/render-design.mjs <받은 project 폴더> <dc-runtime.js> design/screens "Main.dc.html=SCR-START-01.png,..."
   ```
4. **바뀌거나 새로 생긴 이미지는 직접 열어 본다.** 잘림, 겹침, 화면 밖으로 밀린 요소가 있으면 캔버스를 고쳐 다시 게시하고 다시 렌더링한다.

## 6. 토큰과 명세

1. `design/tokens.json`: 캔버스의 `project/ds/duriseo/tokens.json` 값으로 갱신한다 (색, 글꼴, 간격, 모서리, 그림자, 크기). 이미지에서 색을 뽑아 넣지 않는다.
2. 토큰이 바뀌었으면 `design/design-system.md`에도 반영한다.
3. `docs/SCREENS.md`: 바뀐 화면의 구성·상태·다이얼로그·문구를 디자인에 보이는 그대로 고치고, `디자인:` 줄을 `반영됨 (<날짜>, design/screens/<파일>)`로 바꾼다. 헤더의 "디자인 기준"도 갱신한다.
4. 디자인이 PRD와 다른 점은 고치지 말고 화면의 `차이:`와 맨 아래 "PRD와의 차이" 표에 적는다.
5. 요청서의 "반영 확인" 표를 체크하고, 모두 반영됐으면 상태를 "반영 완료 (<날짜>, 캔버스 버전 N)"로 바꾼다.

## 7. 검사, PR, 이슈

1. `bash scripts/check-ids.sh`가 통과해야 한다.
2. 브랜치 `design/sync-<YYYYMMDD>`에 커밋한다. 메시지: `docs(design): PRD v<버전> 디자인 반영`
3. push 후 `gh pr create --base main`. 본문: 반영한 요청 항목, 바뀐 화면과 이미지 경로, 토큰 변경, PRD와의 차이(사람이 정할 것), 디자인 없는 화면, 캔버스 버전.
4. Android 레포에 이슈를 만든다:
   ```
   gh issue create -R DuriseoApp/Android --title "[디자인 변경] PRD v<버전> — SCR-…, SCR-…" --body "<바뀐 화면별 요약, Docs 경로(design/screens/…, docs/SCREENS.md#…), Docs PR 링크, 'Docs PR 머지 후 작업' 안내>"
   ```
5. **머지하지 않는다.**

## 8. 보고

사용자에게 짧게: 바뀐 화면 목록, 캔버스에서 확인할 곳, PR·이슈 링크, PRD와의 차이(정해야 할 것).

## 하지 않는 것

- 맥 터미널에서 캔버스 수정 시도
- 새 디자인 토큰·컴포넌트를 묻지 않고 만들기
- 기존 보드 삭제
- PRD와 다른 디자인을 SCREENS.md에 정답처럼 적기 (차이로만 적는다)
- PRD에 없는 화면 ID 만들기
- PR 머지
