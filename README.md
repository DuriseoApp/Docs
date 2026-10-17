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
│   ├── screens/               화면 이미지 SCR-*.png (핸드오프로 채움)
│   ├── change-requests/       디자인 채팅에 보낼 변경 요청서
│   └── inbox/                 디자인에서 내보낸 원본을 넣는 곳 (git 제외)
├── sync/                      PRD 버전별 영향 분석 기록
├── scripts/                   check-ids.sh (정합성 검사), render.mjs (HTML → PNG)
└── .claude/
    ├── settings.json          에이전트 팀 켜기, 권한
    ├── agents/                팀원 4명 정의
    └── skills/                /prd-sync, /design-handoff
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
> 진행                                   ← 팀원 3명 병렬 작업 → 검수 → PR
```

GitHub에서 PR을 보고 머지해요. PR에 디자인 변경 요청서가 있으면 다음 단계로 가요.

### 디자인을 바꿀 때

1. `design/change-requests/prd-v<버전>.md`의 "디자인 채팅에 붙여넣을 내용"을 claude.ai 디자인 채팅에 붙여넣어요.
2. 디자인이 끝나면 화면을 이미지로 내보내 `design/inbox/`에 넣어요 (가능하면 bundle.css도).
3. `/design-handoff` → PR을 보고 머지해요.

### 점검

- `/prd-sync --dry-run`: 문서를 고치지 않고 팀 전체가 정합성만 점검해요.
- `bash scripts/check-ids.sh`: ID와 PRD 버전만 빠르게 검사해요.

## 사람이 하는 일

| 언제 | 할 일 |
| --- | --- |
| PRD 의논 | 무엇을 바꿀지 정하기 |
| `/prd-sync` 중간 | 영향 분석 표를 보고 "진행" |
| PR | 확인하고 머지 (에이전트는 머지하지 않아요) |
| 디자인 | 요청서를 디자인 채팅에 붙여넣기, 결과 이미지 내보내기 |

## 다른 레포에서 이 문서 보기

Server·Android·iOS 레포의 `CLAUDE.md`에 아래를 넣고, 세션은 `claude --add-dir ../Docs`로 열어요.

```markdown
## 기준 문서
기획 문서는 ../Docs 레포에 있다. 이 문서와 코드가 다르면 문서가 맞다.
- 요구사항: ../Docs/docs/PRD.md (커밋·PR·테스트 이름에 FR ID를 쓴다)
- 데이터: ../Docs/docs/ERD.md / API: ../Docs/docs/API.md
- 화면: ../Docs/docs/SCREENS.md, 이미지 ../Docs/design/screens/, 토큰 ../Docs/design/tokens.json
문서에 없는 기능은 만들지 않는다. 문서가 틀려 보이면 작업을 멈추고 보고한다.
```
