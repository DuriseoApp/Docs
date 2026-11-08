# 디자인 변경 요청서: PRD v0.9

> 상태: 반영 완료 (2026-11-06, 캔버스 버전 41)
> 기준 문서: 둘이서 PRD v0.9 (`docs/PRD.md`), `docs/SCREENS.md`, `sync/archive/prd-v0.9.md`
> 작성일: 2026-11-01

claude.ai 프로젝트 채팅에서 "디자인 반영해줘"라고 하면 `/design-sync`가 아래 내용대로 디자인 캔버스를 고치고, 이 파일의 상태를 "반영 완료"로 바꿔요.

**v0.8 요청서(`design/change-requests/archive/prd-v0.8.md`)가 아직 "요청됨"이에요. v0.8 요청서를 먼저(또는 함께) 반영해 주세요.** 6번의 `ConnectionInfo.dc.html`은 v0.8에서 건드리지 않는 보드라 겹치지 않아요.

이번 변경은 Android 단위 3(커플) 범위 점검에서 나온 빈 곳을 사용자가 정한 결과예요 (PRD D-93~D-103, Q-13). **새 화면 ID와 새 토큰은 없어요.** 아래 새 보드는 모두 이미 있는 화면의 새 상태예요. 새 상태는 이미지 7개이고, 기존 보드 1개(`ConnectionInfo`)에서 안 쓰는 부분을 빼요.

보드 값과 문구는 지금 캔버스(버전 38)가 맞아요. 이번에 바뀐 문구와 규칙(오류 문구 표, 개수 문구, 공유·복사 동작, 우리 색상 저장 시점 등)은 `docs/SCREENS.md`에 적었고, 아래에 적은 곳만 보드를 고쳐요.

---

## 디자인 변경 내용

```
PRD가 v0.9로 바뀌어서 캔버스를 수정해 줘. 기존 화면은 지우지 말고 "이전 버전" 줄로 옮긴 뒤 새 화면을 만들어 줘.
디자인 시스템의 토큰과 컴포넌트만 써 줘. 새 색이나 새 컴포넌트가 필요하면 만들기 전에 먼저 물어봐 줘.
화면마다 보드 이름 앞에 화면 ID를 붙여 줘 (예: "SCR-COUPLE-03 초대코드 입력 · 오류").
문구는 디자인 시스템 말투(해요체, 결과가 보이는 동사, 이모지 없음)를 따라 줘. 아래에 따옴표로 적은 문구는 그대로 써 줘.
[N], [처음 만난 날] 같은 대괄호는 자리표시야. 따옴표 안에 샘플 값이 적힌 곳만 그 값으로 바꾸고 나머지는 그대로 둬.
새 보드는 기존 보드를 가져다 쓰고 상태 설정(boolean)만 더하는 방식으로 만들어도 돼.
항목 번호는 아래 "반영 확인" 표와 같아. [수정]이 6번이고 [새 화면]이 1~5번이야.

[수정]
6. SCR-SET-01 연결 정보 · 혼자 사용 중 (보드: ConnectionInfo.dc.html, mode "solo") — PRD D-97, D-37
   - 보드에서 아래 두 가지를 빼 줘.
     ① 화면 안 코드 패널 (96~111행: "내 초대코드", 코드 칸 6개, "24시간 동안 유효 · 23시간 59분 남음", [코드 복사] [공유하기], "상대가 코드를 입력하면 바로 연결돼요"). 연결 정보 안에서는 코드를 만들지 않아.
     ② `justDisconnected` 안내 (29행: "연결을 해제했어요. 이제 혼자 사용하고 있어요."). 해제하면 SCR-COUPLE-01로 가서 이 안내를 볼 일이 없어.
   - 혼자 사용 중 화면에는 소개문 "상대를 초대하면 캘린더와 메모를 함께 쓸 수 있어요.\n혼자 쓴 기록은 연결할 때 가져올지 고를 수 있어요."와 버튼 두 개만 남겨 줘.
     [초대코드 만들기] (부제 "코드를 만들어 상대에게 보내요")는 누르면 SCR-COUPLE-02(`InviteCreate.dc.html`)로, [받은 초대코드 입력하기]는 SCR-COUPLE-03(`InviteEnter.dc.html`)으로 가게 연결해 줘.
   - 연결됨(connected) 상태와 연결 해제 다이얼로그는 바꾸지 마.
   - 이 보드는 `ConnectionInfoSolo`, `ConnectionInfoDialog`, 새 `ConnectionInfoNoStartDate`가 가져다 쓰고 있어서 이전 모습을 "이전 버전" 줄로 옮기면 연결이 끊길 수 있어. 그러면 그 자리에서 고치고 이전 모습은 캔버스 버전 기록에 남겨 줘. 어떻게 했는지 알려 줘.
   - 이미지 `SCR-SET-01--couple-solo.png`를 다시 만들어 줘.

[새 화면]  (새 화면 ID는 없어. 기존 화면의 새 상태야)
1. SCR-COUPLE-03 초대코드 입력 · 오류 (보드: InviteEnter.dc.html → 새 InviteEnterError, InviteEnterRateLimited) — PRD D-95, FR-COUPLE-02 AC2~AC4
   - 코드 칸 아래에 오류 문구를 한 줄로, `danger-600` 글자로 보여 줘. 오류 표시 규칙은 SCR-CAL-03 오류(`AddEventError.dc.html`, `AddEvent.dc.html` 115행)를 따라 줘. 크기와 간격은 디자이너가 정해 줘.
   - InviteEnterError: 6자리를 입력한 상태(예: K7Q29X), [연결하고 시작하기] 활성, 코드 칸 아래 "없는 코드예요. 코드를 다시 확인해 주세요."
   - InviteEnterRateLimited: 6자리를 입력한 상태, [연결하고 시작하기] 비활성, 코드 칸 아래 "코드를 너무 많이 틀렸어요. 12분 뒤에 다시 입력해 주세요." (12는 샘플 값)
   - 코드 칸 테두리를 오류 색으로 바꿀지는 디자이너가 정해서 알려 줘. 정하기 어려우면 바꾸지 말고 알려 줘.
   - 나머지 문구는 PRD 표 그대로 `docs/SCREENS.md`에 있어서 이 두 상태만 그리면 돼. (다른 오류 문구는 같은 자리에 문구만 바뀌어.)
   - 이미지 `SCR-COUPLE-03--error.png`, `SCR-COUPLE-03--rate-limited.png`

2. SCR-COUPLE-02 초대코드 만들기 · 코드 받는 중 (보드: InviteCreate.dc.html → 새 InviteCreateLoading) — PRD D-95, FR-COUPLE-01 AC6
   - 코드를 받기 전 모습: 코드 칸 6개를 빈 칸으로 두고(글자 없음), [코드 복사]와 [공유하기]는 비활성으로 그려 줘.
   - 문구와 스피너는 넣지 마.
   - 코드 패널의 "10분 동안 유효 · N분 N초 남음" 줄은 없애는 게 나을지 그대로 둘지 디자이너가 정해서 알려 줘. 남은 시간 값이 없으니 자리만 남기지는 마.
   - 비활성 버튼 모양은 기존 비활성 버튼(`InviteEnter.dc.html`의 [연결하고 시작하기] 비활성)과 `InviteCreateCooldown`의 비활성 [코드 새로 만들기]를 참고해 줘. 맞는 모양이 없으면 만들기 전에 먼저 물어봐 줘.
   - 이미지 `SCR-COUPLE-02--loading.png`

3. 처음 만난 날 선택 시트 · 연도·월 선택 (보드: StartDateSheet.dc.html → 새 StartDateSheetYearMonth) — PRD FR-COUPLE-04 AC3, D-74
   - 시트의 연·월 제목(⌄, 27행)을 누른 뒤의 상태를 그려 줘. 연도와 월을 고르는 모양은 디자인 시스템에 있는 컴포넌트로 정해 줘. 새 컴포넌트가 필요하면 먼저 물어봐 줘.
   - 고를 수 있는 연도는 1950년부터 올해까지만이고, 미래 월은 비활성이야. 샘플은 2026년 4월이 선택된 상태(그 뒤 달은 비활성)로 해 줘.
   - 이미지는 `MenuStartDateSheet`처럼 전체 메뉴 위에 시트가 뜬 모습으로 만들어 줘: `SCR-SET-01--start-date-sheet-year-month.png`

4. SCR-COUPLE-04 연결 완료 시트 · 처음 만난 날이 이미 있음 (보드: CalendarLinkedSheet.dc.html → 새 CalendarLinkedSheetDate) — PRD D-98, FR-COUPLE-04 AC4
   - 처음 만난 날 칸에 날짜가 들어간 상태: 칸에 "2026년 3월 14일"(샘플)을 보여 줘. 값이 있으니 placeholder 색이 아니라 입력값 색으로 그려 줘.
   - 이 상태에서는 [나중에 하기] 버튼이 없어. 라벨 "처음 만난 날"과 칸, 안내 문구는 그대로 둬.
   - 혼자 쓴 기록이 있는 모습(개수 안내, [가져오기]·[가져오지 않기] 카드)으로 그려 줘.
   - 개수 안내는 지금 보드 문구 "일정 [N]개, 기념일 [N]개, 메모 [N]개가 있어요." 그대로 두고 샘플 값은 넣지 마.
   - 이미지 `SCR-COUPLE-04--date-set.png`

5. SCR-SET-01 처음 만난 날이 없는 커플 (보드: Menu.dc.html → 새 MenuNoStartDate, ConnectionInfo.dc.html → 새 ConnectionInfoNoStartDate) — PRD D-99, FR-COUPLE-04 AC5
   - MenuNoStartDate: 연결된 커플의 전체 메뉴에서 프로필 카드의 D+N과 "[처음 만난 날]부터 함께하고 있어요" 줄을 빼 줘. [내 프로필 수정]과 [처음 만난 날 수정]은 그대로 둬. 빠진 자리 때문에 카드 모양이 어색하지 않게 간격만 맞춰 줘.
   - ConnectionInfoNoStartDate: 연결 정보(연결됨)에서 "처음 만난 날"과 "함께한 지" 값을 보여주지 않아. 행을 통째로 숨겼는지, 라벨만 남기고 값을 비웠는지는 디자이너가 정해서 알려 줘. "연결한 날"과 "함께 쓰는 것" 행은 그대로 둬.
   - 보드에 상태 설정(boolean) 하나를 더해 만드는 건 괜찮아.
   - 이미지 `SCR-SET-01--no-start-date.png`, `SCR-SET-01--couple-no-start-date.png`

[삭제]
- 없음. (6번에서 뺀 부분은 이전 모습을 캔버스 버전 기록에 남겨 줘.)

[확인]
7. 새 토큰·컴포넌트 필요 여부
   - 이번 변경은 새 색, 새 토큰, 새 컴포넌트 없이 기존 것만 쓰는 게 원칙이야.
   - 1번의 오류 줄, 2번의 비활성 모양, 3번의 연도·월 선택에서 새 토큰이나 컴포넌트가 필요해 보이면 만들기 전에 먼저 물어봐 줘.
8. SCR-COUPLE-01 뒤로 링크
   - `Connect.dc.html` 20행의 뒤로 링크(→ Main.dc.html)는 고치지 마. 앞 화면이 없는 진입에서는 뒤로 버튼이 없다는 규칙(D-96)은 구현이 `docs/SCREENS.md`대로 해.
9. 보드에 있는 샘플·문구는 바꾸지 마. 우리 색상 보드(`ColorSettings.dc.html`)의 한 주(11~17일)는 구현에서 오늘이 든 주로 그려서, 보드는 그대로 둬.

다 끝나면 바뀐 화면 ID 목록, 새로 만든 보드 목록, 다시 만든·새로 만든 이미지 목록, 5번에서 정한 연결 정보의 모양(행 숨김 또는 라벨만 남김), 1번에서 칸 테두리를 바꿨는지, 2번에서 남은 시간 줄을 어떻게 했는지, 6번 보드 수정 방식(그 자리에서 고쳤는지), 디자인 시스템(토큰·컴포넌트)에 바뀐 점이 있는지 정리해 줘.
```

---

## 이미지 이름

화면 ID + `--<상태>`로 만들어요. 새 이미지 7개와 다시 만드는 이미지 1개예요. `design/canvas-map.md` 표에는 `/design-sync`가 새 보드를 추가해요.

| 보드 | 이미지 | 이유 |
| --- | --- | --- |
| InviteEnterError (새) | `SCR-COUPLE-03--error.png` | 코드 오류 문구 (D-95) |
| InviteEnterRateLimited (새) | `SCR-COUPLE-03--rate-limited.png` | 입력 제한 문구 (D-83, D-95) |
| InviteCreateLoading (새) | `SCR-COUPLE-02--loading.png` | 코드를 받기 전 빈 칸 (D-95) |
| StartDateSheetYearMonth (새) | `SCR-SET-01--start-date-sheet-year-month.png` | 연도·월 선택 (Android 6) |
| CalendarLinkedSheetDate (새) | `SCR-COUPLE-04--date-set.png` | 처음 만난 날이 이미 있는 시트 (D-98) |
| MenuNoStartDate (새) | `SCR-SET-01--no-start-date.png` | 처음 만난 날 없는 커플의 프로필 카드 (D-99) |
| ConnectionInfoNoStartDate (새) | `SCR-SET-01--couple-no-start-date.png` | 처음 만난 날 없는 커플의 연결 정보 (D-99) |
| ConnectionInfo (solo, 수정) | `SCR-SET-01--couple-solo.png` | 코드 패널·해제 안내 빼기 (D-97) |

## 화면 문서와 보드의 차이 (참고)

- 연결 정보 · 혼자 사용 중: 보드 이전 모습의 코드 패널("24시간 동안 유효"는 v0.3 값)과 해제 안내는 PRD D-97로 쓰지 않아요. `docs/SCREENS.md` "PRD와의 차이" 25번에 기록했어요.
- SCR-COUPLE-01: 보드의 뒤로 링크는 따르지 않아요 (D-96). "PRD와의 차이" 31번.

---

## 반영 확인 (핸드오프 때 체크)

| # | 화면 | 반영 |
| --- | --- | --- |
| 1 | SCR-COUPLE-03: InviteEnterError, InviteEnterRateLimited 새 보드, 오류 줄 `danger-600`, 칸 테두리 결정 알림, 이미지 2개 | 반영됨 — InviteEnterError, InviteEnterRateLimited 새 보드. 오류 줄은 칸 아래 4(gap 12에서 -4), 아이콘 16 + 13/18/600 `danger-600`. 칸 테두리: 없는 코드는 채운 칸 테두리 1 `danger-600`, 입력 제한은 테두리 그대로(버튼만 비활성). 이미지 `SCR-COUPLE-03--error.png`, `SCR-COUPLE-03--rate-limited.png` |
| 2 | SCR-COUPLE-02: InviteCreateLoading 새 보드, 빈 칸 6개, 비활성 버튼 2개, 남은 시간 줄 결정 알림, 이미지 1개 | 반영됨 — InviteCreateLoading 새 보드. 빈 칸 6개, [코드 복사]·[공유하기] 비활성(`line-100` 면·테두리 + `ink-500` 글자). "N분 N초 남음" 줄은 뺌. 이미지 `SCR-COUPLE-02--loading.png` |
| 3 | 처음 만난 날 선택 시트: StartDateSheetYearMonth 새 보드, 1950년~올해, 미래 월 비활성, 이미지 1개 | 반영됨 — StartDateSheetYearMonth 새 보드(StartDateSheet의 연도·월 선택). 1950년~올해, 미래 월 비활성, 2026년 4월 선택. 이미지 `SCR-SET-01--start-date-sheet-year-month.png` |
| 4 | SCR-COUPLE-04: CalendarLinkedSheetDate 새 보드, 날짜 "2026년 3월 14일", [나중에 하기] 없음, 이미지 1개 | 반영됨 — CalendarLinkedSheetDate 새 보드. 칸에 "2026년 3월 14일", [나중에 하기] 없음. 이미지 `SCR-COUPLE-04--date-set.png` |
| 5 | SCR-SET-01: MenuNoStartDate, ConnectionInfoNoStartDate 새 보드, 행 숨김/라벨 남김 결정 알림, 이미지 2개 | 반영됨 — MenuNoStartDate, ConnectionInfoNoStartDate 새 보드. 연결 정보는 "처음 만난 날"·"함께한 지" 행을 통째로 숨김. 전체 메뉴 카드는 가운데 로고를 아바타 높이(72) 가운데로 맞춤. 이미지 `SCR-SET-01--no-start-date.png`, `SCR-SET-01--couple-no-start-date.png` |
| 6 | SCR-SET-01 연결 정보 · 혼자 사용 중: 코드 패널·해제 안내 빼기, 버튼 두 개 이동 연결, 수정 방식 알림, `SCR-SET-01--couple-solo.png` 다시 만들기 | 반영됨 — ConnectionInfo(혼자 사용 중)에서 코드 패널과 `justDisconnected` 안내를 뺌. [초대코드 만들기]→SCR-COUPLE-02, [받은 초대코드 입력하기]→SCR-COUPLE-03. 이미지 `SCR-SET-01--couple-solo.png` |
| 7 | 새 토큰·컴포넌트 필요 여부 | 새 토큰 없음. 연도·월 선택은 새 컴포넌트로 design-system에 적음 (2026-11-06 절) |
| 8 | SCR-COUPLE-01 뒤로 링크는 고치지 않음 | 반영됨 — `Connect.dc.html` 20행 뒤로 링크는 고치지 않음 |
| 9 | 보드 샘플·문구 그대로 | 반영됨 — 보드 샘플·문구 그대로 (`ColorSettings.dc.html` 포함) |
