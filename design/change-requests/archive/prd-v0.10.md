# 디자인 변경 요청서: PRD v0.10

> 상태: 반영 완료 (2026-11-06, 캔버스 버전 41)
> 기준 문서: 둘이서 PRD v0.10 (`docs/PRD.md`), `docs/SCREENS.md`, `sync/archive/prd-v0.10.md`
> 작성일: 2026-11-05

claude.ai 프로젝트 채팅에서 "디자인 반영해줘"라고 하면 `/design-sync`가 아래 내용대로 디자인 캔버스를 고치고, 이 파일의 상태를 "반영 완료"로 바꿔요.

**v0.8(`design/change-requests/archive/prd-v0.8.md`)과 v0.9(`design/change-requests/archive/prd-v0.9.md`) 요청서가 아직 "요청됨"이에요. 두 요청서를 먼저(또는 함께) 반영해 주세요.** 3번에서 가져다 쓰는 `StartDateSheet.dc.html`의 연도·월 선택은 v0.9 요청서 3번과 같은 모양이어야 해요.

이번 변경은 Android 단위 4(캘린더) 범위 점검에서 나온 빈 곳을 사용자가 정한 결과예요 (PRD D-107, D-109, D-112, Q-16). **새 화면 ID와 새 토큰은 없어요.** 아래 새 보드는 모두 이미 있는 화면의 새 상태예요. 요청은 6건(6번은 Q-16 조건부)이고, 새 보드와 이미지는 7개예요.

보드 값과 문구는 지금 캔버스(버전 38)가 맞아요. 이번에 바뀐 문구와 규칙(시간 서식, 입력 제한, 기본 날짜·시간, 오류 처리 등)은 `docs/SCREENS.md`에 적었고, 아래에 적은 곳만 보드를 그려요.

---

## 디자인 변경 내용

```
PRD가 v0.10으로 바뀌어서 캔버스를 수정해 줘. 기존 화면은 지우지 말고 "이전 버전" 줄로 옮긴 뒤 새 화면을 만들어 줘.
디자인 시스템의 토큰과 컴포넌트만 써 줘. 새 색이나 새 컴포넌트가 필요하면 만들기 전에 먼저 물어봐 줘.
화면마다 보드 이름 앞에 화면 ID를 붙여 줘 (예: "SCR-CAL-03 일정 작성 · 날짜 선택").
문구는 디자인 시스템 말투(해요체, 결과가 보이는 동사, 이모지 없음)를 따라 줘. 아래에 따옴표로 적은 문구는 그대로 써 줘.
새 보드는 기존 보드를 가져다 쓰고 상태 설정(boolean)만 더하는 방식으로 만들어도 돼.
항목 번호는 아래 "반영 확인" 표와 같아. [새 화면]이 1~6번이야.

[수정]
- 없음. (기존 보드의 모양은 바꾸지 않고 새 상태 보드만 만들어.)

[새 화면]  (새 화면 ID는 없어. 기존 화면의 새 상태야)
1. SCR-CAL-03 날짜 선택 (보드: AddEvent.dc.html → 새 AddEventDatePicker) — PRD FR-CAL-01 AC6, D-74
   - 시작·종료 날짜 칩(AddEvent.dc.html 103~104행, 110~111행)을 누른 뒤의 날짜 시트를 그려 줘.
   - `StartDateSheet.dc.html`과 같은 컴포넌트를 써 줘. 범위는 1950-01-01 ~ 2050-12-31이고 미래 날짜도 고를 수 있어야 해. 범위 밖은 비활성이야.
   - 안내 줄은 넣지 마. 연도·월 선택은 v0.9 요청서 3번과 같은 모양으로 해 줘.
   - 이미지 `SCR-CAL-03--date-picker.png`

2. SCR-CAL-03 시간 선택 (보드: AddEvent.dc.html → 새 AddEventTimePicker) — PRD FR-CAL-02 AC1
   - 시간 칩을 누른 뒤의 시간 선택 모양을 그려 줘.
   - 지금 디자인 시스템에 시간 선택 컴포넌트가 없어. 새 컴포넌트가 필요하면 만들기 전에 먼저 물어봐 줘.
   - 이미지 `SCR-CAL-03--time-picker.png`

3. SCR-CAL-03 내 알림 시트 (보드: AddEvent.dc.html → 새 AddEventReminderSheet) — PRD D-107, FR-CAL-02 AC4
   - "내 알림" 행(AddEvent.dc.html 117~120행)을 누른 뒤의 하단 시트를 그려 줘.
   - 칩은 `EventDetail.dc.html` 58~62행과 같은 모양과 문구로 해 줘. 시간 일정은 5개(없음, 정시, 10분 전, 1시간 전, 1일 전), 종일 일정은 3개(없음, 당일 오전 9시, 1일 전 오전 9시)야.
   - 시간 일정 상태를 기본으로 그리고, 종일 일정 상태도 같은 보드에서 상태 설정(boolean)으로 보여 줄 수 있으면 함께 만들어 줘.
   - 이미지 `SCR-CAL-03--reminder-sheet.png`

4. SCR-CAL-02 개인 공간 상세·삭제 다이얼로그 (보드: EventDetail.dc.html → 새 EventDetailSolo, EventDetailSoloDialog) — PRD D-109, FR-CAL-03 AC6
   - EventDetailSolo: 개인 공간의 일정 상세. 커플 공간 상세와 같은 구성에서 대상 칩은 "나", "작성" 줄은 내 닉네임, 내 알림, [수정]과 [일정 삭제]를 보여 줘.
   - EventDetailSoloDialog: 개인 공간 삭제 확인 다이얼로그. 제목 "일정을 삭제할까요?", 본문 "삭제하면 되돌릴 수 없어요.", 버튼 [취소] [삭제](`danger-700`).
   - 커플 공간의 삭제 확인 본문("삭제하면 상대 캘린더에서도 사라지고 되돌릴 수 없어요.", `EventDetail.dc.html` 77·78행)은 지금 보드 그대로 둬.
   - 이미지 `SCR-CAL-02--solo.png`, `SCR-CAL-02--solo-delete-dialog.png`

5. SCR-CAL-01 탭 있는 화면의 스낵바 (보드: Calendar.dc.html → 새 CalendarSnackbar) — PRD NFR-OFF-02, D-88
   - 하단 탭이 있는 화면에서 스낵바가 뜨는 위치를 그려 줘. 예시 문구는 "인터넷 연결이 필요해요"야.
   - 스낵바 모양은 디자인 시스템 "스낵바" 그대로 쓰고, 위치만 정해 줘. 정한 위치(위에서 얼마, 또는 바닥에서 얼마)를 알려 주면 `design-system.md` "스낵바"에 적어.
   - 지금 `Calendar.dc.html`에는 하단 탭이 없어(SCREENS SCR-CAL-01 "차이"). 하단 탭(`Memo.dc.html` 104~112행)을 함께 그리면 위치를 정하기 좋아.
   - 지금 구현은 임시로 위에서 40(`Main.dc.html` 51행)에 띄우고 있어. 그림이 나오면 그림을 따라.
   - 이미지 `SCR-CAL-01--snackbar.png`

6. SCR-CAL-01 당겨서 새로고침 (조건부, 보드: Calendar.dc.html → 새 CalendarRefresh) — PRD Q-16, NFR-SYNC-02
   - 날짜 목록을 당겨서 새로고침할 때의 표시를 그려 줘. Q-16이 기본값(유지)이면 그려. 사람이 Q-16을 "뺀다"로 정하면 이 항목은 지워.
   - 지금 디자인 시스템에 당겨서 새로고침 표시가 없어. 새 컴포넌트가 필요하면 만들기 전에 먼저 물어봐 줘.
   - 이미지 `SCR-CAL-01--refresh.png`

[삭제]
- 없음.

[확인]
7. 새 토큰·컴포넌트 필요 여부
   - 이번 변경은 새 색, 새 토큰, 새 컴포넌트 없이 기존 것만 쓰는 게 원칙이야.
   - 2번(시간 선택)과 6번(당겨서 새로고침)은 새 컴포넌트가 필요해 보여. 만들기 전에 먼저 물어봐 줘.
   - 1번의 날짜 시트, 3번의 알림 칩, 4번의 개인 공간 상세, 5번의 스낵바 위치는 기존 컴포넌트와 토큰만으로 되는지 확인해 줘. 안 되면 먼저 물어봐 줘.
8. 보드에 있는 샘플·문구는 바꾸지 마.

다 끝나면 바뀐 화면 ID 목록, 새로 만든 보드 목록, 새로 만든 이미지 목록, 2번에서 정한 시간 선택 모양, 5번에서 정한 스낵바 위치, 6번을 그렸는지(Q-16 결과), 디자인 시스템(토큰·컴포넌트)에 바뀐 점이 있는지 정리해 줘.
```

---

## 이미지 이름

화면 ID + `--<상태>`로 만들어요. 새 이미지 7개예요 (`SCR-CAL-01--refresh.png`은 Q-16 조건부). `design/canvas-map.md` 표에는 `/design-sync`가 새 보드를 추가해요.

| 보드 | 이미지 | 이유 |
| --- | --- | --- |
| AddEventDatePicker (새) | `SCR-CAL-03--date-picker.png` | 일정 날짜 선택 (D-74) |
| AddEventTimePicker (새) | `SCR-CAL-03--time-picker.png` | 일정 시간 선택 |
| AddEventReminderSheet (새) | `SCR-CAL-03--reminder-sheet.png` | 작성·수정 화면의 내 알림 선택 (D-107) |
| EventDetailSolo (새) | `SCR-CAL-02--solo.png` | 개인 공간 일정 상세 (D-109) |
| EventDetailSoloDialog (새) | `SCR-CAL-02--solo-delete-dialog.png` | 개인 공간 삭제 확인 (D-109) |
| CalendarSnackbar (새) | `SCR-CAL-01--snackbar.png` | 탭 있는 화면의 스낵바 위치 |
| CalendarRefresh (새, 조건부) | `SCR-CAL-01--refresh.png` | 당겨서 새로고침 (Q-16) |

보드는 7개이고, 4번이 보드 2개를 묶어서 요청 항목은 6건이에요.

## 화면 문서와 보드의 차이 (참고)

- SCR-CAL-01: 보드에 하단 탭이 없어요. 구현은 `docs/SCREENS.md` SCR-CAL-01 "차이"대로 해요. 스낵바는 5번의 그림이 나올 때까지 위에서 40이에요.

---

## 반영 확인 (핸드오프 때 체크)

| # | 화면 | 반영 |
| --- | --- | --- |
| 1 | SCR-CAL-03: AddEventDatePicker 새 보드, 1950-01-01 ~ 2050-12-31, 미래 허용, 안내 줄 없음, 이미지 1개 | 반영됨 — AddEventDatePicker 새 보드. StartDateSheet와 같은 시트(제목 "시작 날짜", 설명·안내 줄 없음, 버튼 [완료]), 1950~2050. 이미지 `SCR-CAL-03--date-picker.png` |
| 2 | SCR-CAL-03: AddEventTimePicker 새 보드, 새 컴포넌트 필요 여부 먼저 물어보기, 이미지 1개 | 반영됨 — AddEventTimePicker 새 보드. 하단 시트 시간 휠(오전/오후·시·분). 새 컴포넌트로 design-system에 적음. 이미지 `SCR-CAL-03--time-picker.png` |
| 3 | SCR-CAL-03: AddEventReminderSheet 새 보드, 칩 5개(시간)·3개(종일), 이미지 1개 | 반영됨 — AddEventReminderSheet 새 보드. 설명 "나에게만 와요", 칩은 EventDetail과 같음(시간 5개, 종일 3개는 보드 상태 설정), [완료]. 이미지 `SCR-CAL-03--reminder-sheet.png` |
| 4 | SCR-CAL-02: EventDetailSolo, EventDetailSoloDialog 새 보드, 본문 "삭제하면 되돌릴 수 없어요.", 이미지 2개 | 반영됨 — EventDetailSolo, EventDetailSoloDialog 새 보드. 본문 "삭제하면 되돌릴 수 없어요.". 이미지 `SCR-CAL-02--solo.png`, `SCR-CAL-02--solo-delete-dialog.png` |
| 5 | SCR-CAL-01: CalendarSnackbar 새 보드, 정한 위치 알림, design-system "스낵바"에 적기, 이미지 1개 | 반영됨 — CalendarSnackbar 새 보드(하단 탭 포함). 스낵바 바닥에서 96, FAB은 스낵바 위 16(바닥에서 161). design-system "스낵바"에 적음. 이미지 `SCR-CAL-01--snackbar.png` |
| 6 | SCR-CAL-01: CalendarRefresh 새 보드 (Q-16 조건부), 새 컴포넌트 필요 여부 먼저 물어보기, 이미지 1개 | 반영됨 — CalendarRefresh 새 보드(Q-16 기본값 유지). 새 컴포넌트로 design-system에 적음. 이미지 `SCR-CAL-01--refresh.png` |
| 7 | 새 토큰·컴포넌트 필요 여부 | 새 토큰 없음. 새 컴포넌트: 연도·월 선택, 시간 휠, 원형 진행 표시(CircleIndicator), 당겨서 새로고침 (design-system 2026-11-06 절) |
| 8 | 보드 샘플·문구 그대로 | 반영됨 — 보드 샘플·문구 그대로 |
