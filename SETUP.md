# 처음 설치 (맥)

지금 폴더 구조가 아래와 같다고 가정해요.

```
Duriseo/
├── Android/
├── Server/
└── Dosc/      ← 이 폴더를 Docs로 바꿔서 쓸 거예요
```

## 0. 필요한 것

| 도구 | 확인 | 없으면 |
| --- | --- | --- |
| Claude Code (최신) | `claude --version` | `claude update` |
| git | `git --version` | Xcode 명령줄 도구 |
| GitHub CLI 로그인 | `gh auth status` | `brew install gh && gh auth login` |
| Node.js 18 이상 (ERD 이미지용, 선택) | `node --version` | `brew install node` |

## 1. 폴더 이름 바꾸고 키트 넣기

압축 파일 안의 `Docs` 폴더에는 숨김 파일(`.claude/`, `.gitignore`)이 있어요. Finder로 복사하면 빠질 수 있으니 터미널로 복사해요.

```bash
cd ~/<Duriseo가 있는 경로>/Duriseo
mv Dosc Docs

unzip ~/Downloads/duriseo-docs-kit.zip -d /tmp/duriseo-kit
cp -R /tmp/duriseo-kit/Docs/. ./Docs/
ls -a Docs        # .claude  .gitignore  CLAUDE.md  docs  design ... 가 보이면 성공
```

`Docs`에 이미 다른 파일이 있었다면 덮어쓰기 전에 따로 옮겨 두세요.

## 2. GitHub 레포 만들기

```bash
cd Docs
git init -b main
git add .
git commit -m "docs: 둘이서 Docs 레포 초기 구성 (PRD v0.3)"
gh repo create DuriseoApp/Docs --private --source=. --push
```

이미 GitHub에 `DuriseoApp/Docs`를 만들었다면 마지막 줄 대신:

```bash
git remote add origin https://github.com/DuriseoApp/Docs.git
git push -u origin main
```

## 3. ERD 이미지 도구 (선택)

ERD 테이블이 바뀔 때 `ERD.png`를 다시 만드는 데 필요해요. 없으면 에이전트가 "ERD.png 갱신 필요"라고만 알려줘요.

```bash
npm install
npx playwright install chromium
npm run render:erd     # docs/ERD.png가 다시 만들어지면 성공
```

## 4. 팀원 화면 나눠 보기 (선택)

기본은 한 터미널 안에서 ↑↓로 팀원을 골라 Enter로 보는 방식이에요. 팀원마다 창을 나눠 보려면 iTerm2나 tmux에서 `~/.claude/settings.json`에 추가해요.

```json
{ "teammateMode": "tmux" }
```

## 5. 첫 실행

```bash
cd ~/<경로>/Duriseo/Docs
claude
```

1. 폴더 신뢰를 묻으면 승인해요. 신뢰해야 `.claude/agents`의 팀원 정의가 적용돼요.
2. `/agents`로 팀원 4명(data-architect, api-designer, screen-designer, reviewer)이 보이는지 확인해요.
3. 리허설: `/prd-sync --dry-run`
   - 문서를 고치지 않고 팀원 3명 + 검수 1명이 현재 문서의 정합성을 점검해요.
   - 팀이 만들어지고, 각자 보고하고, 결과 표가 나오면 설치 완료예요.

## 6. 그다음

1. 디자인은 claude.ai 프로젝트 채팅에서 "디자인 반영해줘"로 맞춰요 (v0.3 요청서는 반영 완료).
2. 맥에서 `npm install`을 다시 하면 디자인 렌더링 도구도 함께 설치돼요 (선택).
3. Android·Server 레포 `CLAUDE.md`에 README의 "다른 레포에서 이 문서 보기" 내용을 넣어요 (개발 단계에서 함께 세팅해요).

## 문제가 생기면

| 증상 | 해결 |
| --- | --- |
| `/prd-sync`가 목록에 없음 | `Docs` 폴더에서 `claude`를 열었는지 확인. `.claude/skills/`가 복사됐는지 `ls -a` |
| 팀원 대신 서브에이전트가 생김 | "에이전트 팀으로 팀원을 만들어"라고 다시 요청 |
| 팀원 권한 요청이 너무 자주 뜸 | `.claude/settings.json`의 `allow`에 자주 쓰는 명령 추가 |
| 사용량 한도로 멈춤 | 한도가 풀리면 같은 세션에서 "이어서 해줘". 세션을 닫았다면 다시 열고 `/prd-sync` (영향 분석 파일의 상태부터 이어서 해요) |
