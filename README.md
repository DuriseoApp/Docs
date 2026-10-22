# 둘이서 Docs

둘이서(커플 일정·메모 앱)의 기획 문서 레포예요. PRD가 단일 기준이고, ERD·API·화면 명세는 PRD에서 파생돼요. Server, Android, iOS 레포의 에이전트도 이 문서를 보고 개발해요.

처음 설치는 [SETUP.md](SETUP.md)를 보세요.

## 폴더

```
Docs/
├── CLAUDE.md                  에이전트가 항상 읽는 규칙
├── docs/
│   ├── PRD.md                 단일 기준 (사람과 리드가 의논해서 고치는 유일한 문서)
│   ├── ERD.md, ERD.png        데이터 모델 (이미지 원본: erd/erd.html)
│   ├── API.md                 API 범위·권한·흐름
│   └── SCREENS.md             화면 명세 (앱 구현 기준)
├── design/
│   ├── design-system.md       디자인 원칙·말투·컴포넌트
│   ├── tokens.json            색·글꼴·간격 값 (Android·iOS 테마의 원본)
│   ├── screens/               화면 이미지 SCR-*.png (/design-sync가 채움)
│   ├── source/                디자인 캔버스 보드 원본 (*.dc.html, canvas.json). 정확한 크기·간격·색은 여기서 읽음
│   ├── canvas-map.md          디자인 캔버스 보드 ↔ 화면 ID 대응표
│   └── change-requests/       디자인 변경 요청서 (/prd-sync가 만들고 /design-sync가 반영)
├── sync/                      PRD 버전별 영향 분석 기록
├── scripts/                   check-ids.sh (정합성 검사), render.mjs (ERD → PNG), render-design.mjs (디자인 보드 → PNG)
└── .claude/
    ├── settings.json          에이전트 팀 켜기, 권한
    ├── agents/                팀원 4명 정의
    └── skills/                /prd-sync (맥·프로젝트 채팅), /design-sync (claude.ai 프로젝트 채팅)
```

## 기획팀 (에이전트 팀)

| 팀원 | 정의 파일 | 맡은 파일 |
| --- | --- | --- |
| 리드 | (메인 세션) | docs/PRD.md, sync/, 커밋·PR |
| data | data-architect | docs/ERD.md, docs/erd/erd.html, docs/ERD.png |
| api | api-designer | docs/API.md |
| screen | screen-designer | docs/SCREENS.md, design/change-requests/ |
| review | reviewer | 읽기 전용 (검수) |

## 쓰는 법

### PRD를 바꿀 때

```
cd Duriseo/Docs && claude

> 캘린더에 반복 일정을 넣고 싶어        ← 리드와 의논, 리드가 PRD 수정
> /prd-sync                              ← 영향 분석 표가 나옴
> start                                  ← 팀원 3명 병렬 작업 → 검수 → PR
```

GitHub에서 PR을 보고 머지해요. PR에 디자인 변경 요청서가 있으면 다음 단계로 가요.

### 디자인을 바꿀 때

**claude.ai 프로젝트 채팅에서 `/prd-sync`를 돌리면** 디자인까지 한 번에 반영돼요. 문서·디자인·화면 이미지가 PR 하나로 올라오고 Android 이슈도 함께 만들어져요. PR만 확인하고 머지하면 돼요.

**맥 터미널에서 `/prd-sync`를 돌렸고** PR에 디자인 변경 요청서가 있으면, 머지한 뒤:

1. claude.ai 프로젝트 "둘이서" 채팅에서 **"디자인 반영해줘"**
2. Claude가 디자인 캔버스를 고치고, 화면 PNG·tokens.json·SCREENS.md를 갱신해 PR을 올리고, Android 레포에 이슈를 만들어요.
3. 캔버스에서 바뀐 디자인을 보고, PR을 머지해요.

### 최신 문서 받기 (자동)

Claude를 열 때마다 `scripts/sync-main.sh`가 GitHub에서 머지된 최신 문서를 받아요. `git pull`을 직접 할 필요가 없어요.

- main이고 작업 중인 변경이 없으면 최신으로 받아요.
- 작업 브랜치가 이미 머지됐으면 main으로 옮기고 최신으로 받아요.
- 작업 중이면 아무것도 건드리지 않고 알려만 줘요.

### 점검

- `/prd-sync --dry-run`: 문서를 고치지 않고 팀 전체가 정합성만 점검해요.
- `bash scripts/check-ids.sh`: ID와 PRD 버전만 빠르게 검사해요.

## 사람이 하는 일

| 언제 | 할 일 |
| --- | --- |
| PRD 의논 | 무엇을 바꿀지 정하기 |
| `/prd-sync` 중간 | 영향 분석 표를 보고 "start" |
| PR | 확인하고 머지 (에이전트는 머지하지 않아요) |
| 디자인 | claude.ai 프로젝트 채팅에서 "디자인 반영해줘", 결과 확인 후 PR 머지 |

## 다른 레포에서 이 문서 보기

Server·Android·iOS 레포의 `CLAUDE.md`에 아래를 넣고, 세션은 `claude --add-dir ../Docs`로 열어요.

```markdown
## 기준 문서
기획 문서는 ../Docs 레포에 있다. 이 문서와 코드가 다르면 문서가 맞다.
- 요구사항: ../Docs/docs/PRD.md (커밋·PR·테스트 이름에 FR ID를 쓴다)
- 데이터: ../Docs/docs/ERD.md / API: ../Docs/docs/API.md
- 화면: ../Docs/docs/SCREENS.md, 이미지 ../Docs/design/screens/, 보드 원본 ../Docs/design/source/, 토큰 ../Docs/design/tokens.json
문서에 없는 기능은 만들지 않는다. 문서가 틀려 보이면 작업을 멈추고 보고한다.
```
