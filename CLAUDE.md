# 둘이서 Docs 레포 규칙

이 레포는 둘이서(커플 일정·메모 앱)의 기획 문서 단일 기준이다. Server, Android, iOS 레포의 에이전트도 이 레포의 문서를 기준으로 개발한다.

## 언어

- 사용자에게는 항상 한국어로 답한다.
- 문서도 한국어로 쓴다. 코드 식별자(테이블, 컬럼, API 경로, enum)는 영어 그대로 쓴다.

## 문서 관계

```
docs/PRD.md  ──(단일 출처)──┬──> docs/ERD.md (+ docs/erd/erd.html → docs/ERD.png)
                            ├──> docs/API.md
                            └──> docs/SCREENS.md ──> design/change-requests/*.md ──(사람)──> claude.ai 디자인
                                                                                              │
              design/screens/*.png, design/tokens.json, docs/SCREENS.md  <──(/design-handoff)──┘
```

- PRD가 단일 출처다. ERD, API, SCREENS는 PRD에서 파생된다. 파생 문서와 PRD가 다르면 PRD가 맞다.
- 디자인 원본은 claude.ai 디자인 채팅에 있다. 이 레포에서는 디자인을 직접 그리지 않고, 변경 요청서를 만들고 결과를 받아온다.
- 파생 문서의 헤더에는 기준 PRD 버전(`PRD v0.3` 형식)을 적는다. PRD 버전이 바뀌면 파생 문서 헤더도 같이 바꾼다.

## ID 규칙

| 접두어 | 정의하는 곳 | 뜻 |
| --- | --- | --- |
| FR-, SCR-, D-, NFR-, Q- | PRD | 기능, 화면, 결정, 비기능, 확인 필요 |
| DB- | ERD | 데이터 설계 결정 |
| R- | API | API 규칙 |

- ID는 바꾸거나 재사용하지 않는다. 항목을 없앨 때는 지우지 않고 "삭제됨 (PRD vX.Y)"으로 표시한다.
- 새 항목에는 그 접두어의 다음 번호를 붙인다.
- 파생 문서는 PRD에 없는 FR, SCR, D, NFR, Q ID를 쓰면 안 된다. `bash scripts/check-ids.sh`로 검사한다.

## PRD를 바꿀 때 (리드)

1. `main`에 바로 커밋하지 않는다. `sync/prd-v<새 버전>` 브랜치에서 작업한다 (예: `sync/prd-v0.4`).
2. PRD 머리의 "문서 버전"을 올리고, 12장 변경 이력에 한 줄을 추가한다.
3. 의논 중에는 PRD만 고친다. 파생 문서는 `/prd-sync`에서 고친다.
4. 사용자가 정하지 않은 내용은 추측해서 넣지 않는다. 11장 확인 필요 사항(Q-)에 올리고 묻는다.

## 하지 않는 것

- `main` 브랜치에 커밋하거나 push하지 않는다. 머지는 사람이 GitHub에서 한다.
- `git push --force`, `git reset --hard`, `rm -rf`를 쓰지 않는다.
- 디자인 토큰 값을 지어내지 않는다. 값이 없으면 null로 두고 핸드오프를 기다린다.
- 문서에 비밀값(키, 토큰, 비밀번호)을 쓰지 않는다.

## 명령

| 명령 | 하는 일 |
| --- | --- |
| `/prd-sync` | PRD 변경을 ERD, API, SCREENS, 디자인 변경 요청서에 반영하고 PR을 연다 (에이전트 팀) |
| `/design-handoff` | 수정된 디자인을 화면 이미지, tokens.json, SCREENS.md로 가져와 PR을 연다 |
| `bash scripts/check-ids.sh` | 문서 간 ID와 PRD 버전이 맞는지 검사한다 |
| `npm run render:erd` | `docs/erd/erd.html`로 `docs/ERD.png`를 다시 만든다 |
