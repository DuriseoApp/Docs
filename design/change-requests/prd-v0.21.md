# 디자인 변경 요청서: PRD v0.21

> 상태: 요청 중 (2026-11-25 작성, 캔버스 반영 전)
> 기준 문서: 둘이서 PRD v0.21 (`docs/PRD.md` D-174, D-175, D-133, FR-CAL-01·02·06, FR-MEMO-01·02·03), `docs/SCREENS.md` SCR-CAL-01·SCR-CAL-03·SCR-MEMO-01·SCR-MEMO-02·SCR-MEMO-03·SCR-MEMO-04, `sync/prd-v0.21.md`
> 작성일: 2026-11-25

메모와 캘린더를 나눠요(D-174). 캘린더에서 메모를 빼고, 메모 날짜 기능과 작성 화면의 [일정]/[메모] 탭을 없애요. 새 화면 ID, 새 토큰, 새 컴포넌트는 없어요. 바뀌는 문구는 4개예요(D-175).

---

## 디자인 변경 내용

```
PRD가 v0.21로 바뀌어서 캘린더·일정 작성·메모 보드를 고쳐 줘. 메모는 메모 탭에서만 보이고 쓰고, 캘린더에는 나오지 않아.

[수정]
1. SCR-CAL-01 (보드: Calendar.dc.html, CalendarExpanded.dc.html, CalendarAnniversary.dc.html, CalendarSolo.dc.html, CalendarNoStartDate.dc.html, CalendarSnackbar.dc.html, CalendarRefresh.dc.html) — PRD D-174, D-175
   - 날짜 목록의 메모 카드("메모" 표시 + 제목 한 줄)를 모두 빼 줘. 일정 카드와 기념일 카드는 그대로야.
   - 날짜 칸의 메모 점(작성자 사람 색)을 빼 줘. 점은 일정에서만 와 (종일 일정 → 시간 일정 순, 서로 다른 사람 색, 고리 포함 최대 3개는 그대로).
   - 펼친 칸에는 원래 메모 막대가 없어. 그림에 메모 표시가 남아 있으면 빼 줘.
   - 선택한 날이 비었을 때 문구를 "아직 일정이 없어요"로 바꿔 줘 (이전 "아직 일정이나 메모가 없어요"). 아래 "+ 이 날에 추가하기"는 그대로야.
   - FAB 접근성 라벨(Calendar.dc.html 131행)을 "일정 추가"로 바꿔 줘 (이전 "일정 또는 메모 추가").
   - 메모 카드 그림에서 본문 한 줄을 빼 달라던 v0.13 요청서 ②는 메모 카드가 없어지면서 필요 없어졌어. 이 요청으로 대신해 줘.
   - 튜토리얼 5단계 그림(v0.17 요청서 ①로 새로 그리는 중)의 2단계 말풍선 문구는 "여기를 누르면 일정을 추가할 수 있어요."로 그려 줘 (이전 "여기를 누르면 일정이나 메모를 추가할 수 있어요.").
   - 다시 만들 PNG: SCR-CAL-01.png, SCR-CAL-01--expanded.png(메모 표시가 있으면), SCR-CAL-01--anniversary.png, SCR-CAL-01--solo.png, SCR-CAL-01--no-start-date.png, SCR-CAL-01--snackbar.png, SCR-CAL-01--refresh.png (각각 메모 카드·메모 점이 있는 것만), 선택한 날이 빈 상태 그림이 있으면 그것도, SCR-CAL-01--tutorial-1.png ~ -5.png (2단계 문구)

2. SCR-CAL-03 (보드: AddEvent.dc.html, AddEventSolo.dc.html, AddEventAllDay.dc.html, AddEventError.dc.html, AddEventLoading.dc.html, 시트 보드 AddEventDatePicker·AddEventTimePicker·AddEventReminderSheet) — PRD D-174, FR-CAL-02 AC10
   - 앱바 아래 종류 탭 [일정 | 메모]를 빼 줘. 앱바("새로 추가")와 제목 칸 사이 간격은 탭이 없는 AddEventEdit.dc.html(일정 수정)과 같게 해 줘. 앱바 문구와 나머지 구성은 그대로야.
   - 다시 만들 PNG: SCR-CAL-03.png, SCR-CAL-03--solo.png, SCR-CAL-03--all-day.png, SCR-CAL-03--error.png, SCR-CAL-03--loading.png. 시트 그림(--date-picker, --time-picker, --reminder-sheet)은 뒤 화면에 탭이 보이면 같이 다시 만들어 줘.
   - 일정 수정 그림(--edit, --partner-edit)은 원래 탭이 없어서 그대로야.

3. SCR-MEMO-04 메모 작성 (보드: AddEventMemo.dc.html) — PRD D-174, D-133, FR-MEMO-02 AC5
   - SCR-CAL-03의 [메모] 탭이었던 모양을 단독 화면으로 바꿔 줘. 앱바(닫기, "새로 추가", 저장)는 그대로 두고 [일정 | 메모] 탭 줄만 빼 줘.
   - 날짜 영역([날짜 추가] 버튼)을 빼 줘. 남는 구성은 제목(placeholder "예) 주말에 살 것"), 메모(본문), "상대에게 알림 보내기" 스위치예요.
   - 다시 만들 PNG: SCR-MEMO-04.png
   - 수정 화면("메모 수정")은 따로 그림이 없으면 새로 그리지 않아도 돼.

4. SCR-MEMO-03 메모 상세 (보드: MemoDetail.dc.html, MemoDetailPartner.dc.html, MemoDetailDialog.dc.html) — PRD D-174, D-129, FR-MEMO-03 AC1
   - 메모 날짜 칩을 빼 줘 (내 메모 그림에 있어). 나머지(제목, 본문, 작성자 닉네임, 고정 버튼, 즐겨찾기 버튼)는 그대로야.
   - 다시 만들 PNG: SCR-MEMO-03.png (메모 날짜 칩이 빠진 내 메모), SCR-MEMO-03--partner.png (날짜가 없던 그림이라 바뀌는 게 없는지 확인), SCR-MEMO-03--delete-dialog.png (뒤 화면에 날짜 칩이 있으면)

5. SCR-MEMO-01 메모 목록 (보드: Memo.dc.html) — PRD D-174, FR-MEMO-01 AC3
   - 핀 카드와 메모 행의 메모 날짜(날짜 칩)를 빼 줘. 작성자 닉네임, 작성일, 핀·별 버튼은 그대로야.
   - 다시 만들 PNG: SCR-MEMO-01.png

[삭제]
6. 메모 날짜 전용 보드·그림 — PRD D-174
   - AddEventMemoDate.dc.html (SCR-MEMO-04 날짜 추가됨): 지우지 말고 "이전 버전"으로 옮겨 줘. SCR-MEMO-04--date.png는 더 쓰지 않아요.
   - MemoDetailOtherYear.dc.html (SCR-MEMO-03 다른 해 날짜 칩): 지우지 말고 "이전 버전"으로 옮겨 줘. SCR-MEMO-03--other-year.png는 더 쓰지 않아요.
   - design/canvas-map.md의 두 줄도 "이전 버전"으로 표시해 줘.

[확인]
7. SCR-MEMO-02 고정 메모 전체 (보드: PinnedAll.dc.html) — 핀 카드에 메모 날짜가 있으면 빼고 SCR-MEMO-02.png를 다시 만들어 줘. 없으면 그대로 둬.
8. 다른 보드에 메모 카드·메모 점·"일정 또는 메모"·"일정이나 메모" 문구가 남아 있는지 한 번 훑어 줘. 알림 종류 "상대 일정·메모 추가"(SCR-NOTI-01, SCR-SET-02, 알림 채널)는 이름 그대로 두는 게 맞아.

[참고, 그림 없음]
- 날짜 칸 낭독의 개수 부분이 "일정·메모 N개"에서 "일정 N개"로 바뀌어 (D-175). 접근성 문구라 그림은 없어. 보드 소스에 접근성 문구가 있으면 같이 고쳐 줘.
- 새 토큰이나 컴포넌트가 필요해 보이면 먼저 물어봐 줘.
```

## 반영 확인

| # | 내용 | 상태 |
| --- | --- | --- |
| 1 | SCR-CAL-01 메모 카드·메모 점 삭제, 빈 안내 "아직 일정이 없어요", FAB 라벨 "일정 추가", 튜토리얼 2단계 문구 (D-174, D-175) | 요청 중 |
| 2 | SCR-CAL-03 종류 탭 [일정 \| 메모] 삭제 (D-174) | 요청 중 |
| 3 | SCR-MEMO-04 탭·날짜 영역 삭제 (D-174, D-133) | 요청 중 |
| 4 | SCR-MEMO-03 메모 날짜 칩 삭제 (D-174, D-129) | 요청 중 |
| 5 | SCR-MEMO-01 목록의 메모 날짜 삭제 (D-174) | 요청 중 |
| 6 | 메모 날짜 전용 보드·그림 이전 버전으로 이동 (AddEventMemoDate, MemoDetailOtherYear) | 요청 중 |
| 7 | SCR-MEMO-02 핀 카드 메모 날짜 확인 | 요청 중 |
| 8 | 다른 보드의 남은 "일정 또는 메모" 문구 훑기 | 요청 중 |
