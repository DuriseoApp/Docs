# 디자인 변경 요청서: PRD v0.6

> 상태: 반영 완료 (2026-10-22, 캔버스 버전 37)
> 기준 문서: 둘이서 PRD v0.6 (`docs/PRD.md`), `docs/SCREENS.md`, `sync/prd-v0.6.md`
> 작성일: 2026-10-22

claude.ai 프로젝트 채팅에서 "디자인 반영해줘"라고 하면 `/design-sync`가 아래 내용대로 디자인 캔버스를 고치고, 이 파일의 상태를 "반영 완료"로 바꿔요.

이번 변경은 2026-10-22 2차 문서 점검에서 찾은 빈칸을 사용자가 정한 결과예요 (PRD D-67~D-80). 화면에 보이는 바뀐 점은 초대코드 입력의 상대 카드 삭제, 기념일 목록의 "지난 기념일"과 처음 만난 날 없음 안내, 게스트가 이미 가입된 계정으로 연동할 때의 다이얼로그 두 개, 회원 계정 화면, 로그아웃 확인, 처음 만난 날 선택 시트예요. 지금까지 "디자인 없음"이던 상태 화면도 이번에 모두 그려요 (사용자 요청).

v0.5에서 이미 반영된 것(연결 완료 시트, 개인 공간 앱바, 일정 시작·종료 행 등)은 다시 요청하지 않아요.

---

## 디자인 변경 내용

```
PRD가 v0.6으로 바뀌어서 캔버스를 수정해 줘. 기존 화면은 지우지 말고 "이전 버전" 줄로 옮긴 뒤 새 화면을 만들어 줘.
디자인 시스템의 기존 토큰과 컴포넌트만 써 줘. 새 색, 새 토큰, 새 컴포넌트는 쓰지 말고, 필요해 보이면 만들기 전에 먼저 물어봐 줘.
화면마다 보드 이름 앞에 화면 ID를 붙여 줘 (예: "SCR-SET-01 계정 · 회원").
문구는 디자인 시스템 말투(해요체, 결과가 보이는 동사, 이모지 없음)를 따라 줘. 아래에 따옴표로 적은 문구는 그대로 써 줘.
[상대 이름], [기념일 이름], [N] 같은 대괄호는 자리표시야. 실제 이름으로 바꾸지 말고 그대로 두거나 샘플 이름·숫자를 넣어 줘.
다이얼로그, 시트, 스낵바는 v0.5에서 그린 모양(ConnectionInfoDialog, CalendarLinkedSheet, MainSessionReplaced)과 같게 그려 줘.

[수정]
1. SCR-COUPLE-03 초대코드 입력하기 (보드: InviteEnter.dc.html) — PRD D-72, FR-COUPLE-02
   - 코드를 다 넣으면 나오던 "연결할 상대" 카드(상대 이름, 다시 입력)를 빼 줘. 상대 미리보기는 없어.
   - 6자리가 다 차면 상대 카드 없이 바로 [연결하고 시작하기]가 활성인 모습이 되게 해 줘. 6자리 전에는 지금처럼 비활성이야.
   - 나머지(6칸, "영문과 숫자 6자리예요.", [붙여넣기])는 그대로 둬.
   - 고치기 전 보드는 지우지 말고 제목에 "(v0.5)"를 붙여 "이전 버전" 줄로 옮긴 뒤, 고친 보드를 새로 만들어 줘.
2. SCR-ANNIV-01 기념일 목록 (보드: Anniversaries.dc.html, AnniversariesSolo.dc.html) — PRD D-71, D-75, FR-ANNIV-04 AC1·AC3
   - "다가오는 기념일" 목록 아래, 하단 안내 문구 위에 접힌 "지난 기념일 [N]개" 행을 더해 줘 (닫힌 모양, 펼침을 알리는 화살표 포함).
   - 오늘인 기념일의 D-N 배지는 "D-day"로 보여 줘 (샘플 한 줄).
   - 목록 범위가 오늘부터 2050-12-31까지로 늘었지만 화면 구성은 그대로야. 하단 안내 문구도 그대로 둬.
   - 개인 공간 보드(AnniversariesSolo)도 같게 맞춰 줘. 빈 상태(AnniversariesSoloEmpty)는 이번에 고치지 않아.
   - 고치기 전 보드는 지우지 말고 제목에 "(v0.5)"를 붙여 "이전 버전" 줄로 옮긴 뒤, 고친 보드를 새로 만들어 줘.
3. SCR-ANNIV-02 직접 기념일 작성·수정 (보드: AnniversaryEdit.dc.html) — PRD D-70, FR-ANNIV-03
   - 이 보드의 안내 문구 "캘린더와 기념일 목록에 표시되고, 당일 오전 9시에 두 사람 모두에게 알림이 가요. 2월 29일은 윤년이 아닌 해에 2월 28일로 표시돼요."는 커플 공간 문구라서 그대로 둬. 고치지 마.
   - 개인 공간 문구는 아래 [새 보드] 17번에 따로 그려.
4. SCR-COUPLE-04 연결 완료 시트 (보드: CalendarLinkedSheet.dc.html, CalendarLinkedSheetDialog.dc.html) — PRD D-76, FR-COUPLE-03 AC5
   - 디자인 변경은 없어. [가져오기]가 미리 선택된 모양이 확정됐어.
   - 보드에 "제안", "사람 확인 필요" 같은 표시가 있으면 지워 줘. 없으면 "변경 없음"이라고 알려 줘.

[새 보드]
5. SCR-SET-01 계정 · 게스트 · 이미 가입된 계정 ① (보드: AccountGuestExisting.dc.html) — PRD D-67, FR-AUTH-03 AC2
   - 계정(게스트) 화면(Account.dc.html) 위에 다이얼로그가 떠 있는 모양으로 그려 줘.
   - 제목 "이미 가입된 계정이에요"
   - 본문 "이 계정은 이미 둘이서에 가입돼 있어요. 그 계정으로 로그인하면 게스트로 쓴 기록은 옮겨지지 않아요."
   - 버튼 [취소] (아웃라인), [그 계정으로 로그인] (채움)
6. SCR-SET-01 계정 · 게스트 · 이미 가입된 계정 ② (보드: AccountGuestExistingConfirm.dc.html) — PRD D-67, FR-AUTH-03 AC3
   - 5번과 같은 배경 위에 다이얼로그가 떠 있는 모양이야.
   - 제목 "그 계정으로 로그인할까요?"
   - 본문 "게스트로 쓴 기록은 모두 삭제돼요. 삭제한 기록은 되돌릴 수 없어요."
   - 버튼 [취소] (아웃라인), [삭제하고 로그인] (`danger-700` 채움)
   - 5번 → 6번 흐름은 V06Flow(20번)에 화살표로 표시해 줘.
7. SCR-SET-01 계정 · 회원 (보드: AccountMember.dc.html) — PRD FR-SET-01, FR-AUTH-05, FR-AUTH-06, D-44, NFR-PRIV-01
   - 계정 화면(Account.dc.html)과 같은 앱바·여백으로, 회원일 때의 모습을 그려 줘.
   - 로그인 방식: Google 또는 카카오 아이콘 + "Google로 로그인 중" 한 줄 (기존 로그인 버튼에 쓴 아이콘을 그대로 써 줘).
   - 닉네임, 가입일 (샘플 값을 넣어 줘).
   - [로그아웃] 버튼.
   - 맨 아래 [회원 탈퇴] (게스트 화면의 탈퇴하기와 같은 위치·모양).
   - 이메일은 받지 않으니 넣지 마. 게스트 안내 배너와 [로그인] 버튼은 없어.
8. SCR-SET-01 로그아웃 확인 (보드: MenuLogoutDialog.dc.html) — PRD FR-AUTH-05 AC1·AC3, D-80
   - 전체 메뉴(Menu.dc.html) 위에 다이얼로그가 떠 있는 모양이야.
   - 제목 "로그아웃할까요?"
   - 본문 "다시 로그인하면 기록을 그대로 볼 수 있어요."
   - 버튼 [취소] (아웃라인), [로그아웃] (채움)
   - 같은 다이얼로그가 SCR-COUPLE-01의 "다른 계정으로 로그인"에서도 떠. 보드는 하나만 만들면 돼.
9. SCR-COUPLE-02 "아직 연결되지 않았어요" (보드: InviteCreateNotYet.dc.html) — PRD D-48, FR-COUPLE-02 AC5
   - 초대코드 만들기(InviteCreate.dc.html)의 대기 상태 화면 아래쪽에 스낵바 "아직 연결되지 않았어요"가 보이는 모양으로 그려 줘. [연결 확인하기]를 누른 뒤의 상태야.
   - 스낵바는 MainSessionReplaced에서 쓴 것과 같은 모양으로.
10. SCR-COUPLE-04 혼자 쓴 기록 없음 (보드: CalendarLinkedSheetNoRecords.dc.html) — PRD FR-COUPLE-03 AC4
   - CalendarLinkedSheet와 같은 시트에서 "혼자 쓴 기록" 영역(제목, 개수 안내, [가져오기]/[가져오지 않기] 카드, "내 기록만 정해요. 상대의 기록은 상대가 정해요." 안내)을 모두 빼 줘.
   - 남는 것: 제목 "[상대 이름]님과 연결됐어요", "처음 만난 날" 날짜 선택 칸과 안내, [나중에 하기], [시작하기].
   - 이 상태는 시트를 닫을 수 있어. 닫기 버튼을 새로 만들지는 말고, 닫을 수 있다는 점이 필요한 모양이 있으면 만들기 전에 먼저 물어봐 줘.
11. SCR-CAL-01 커플 + 처음 만난 날 없음 (보드: CalendarNoStartDate.dc.html) — PRD FR-COUPLE-04 AC2
   - 커플 캘린더 홈(Calendar.dc.html)과 같은 화면에서 앱바의 "함께한 지 D+N ›" 자리를 "처음 만난 날 입력하기 ›"로 바꿔 줘. 나·너 겹침 아바타, "우리 둘", 알림 버튼, 전체 메뉴 버튼은 그대로야.
   - 나머지(달력, 날짜 목록, FAB)는 Calendar와 같게.
   - "처음 만난 날 입력하기 ›"를 누르면 처음 만난 날 선택 시트(12번)가 뜬다는 흐름을 화살표로 표시해 줘.
12. SCR-SET-01 처음 만난 날 선택 시트 (보드: StartDateSheet.dc.html) — PRD FR-COUPLE-04, D-74
   - 하단 시트 모양은 CalendarLinkedSheet와 같게 그리고, 뒤 화면은 11번(CalendarNoStartDate)을 어둡게 보여 줘.
   - 제목 "처음 만난 날"
   - 안내 "D-day와 기념일이 이 날을 1일로 계산돼요."
   - 날짜 선택 칸 (자리표시 "날짜를 골라 주세요")
   - [저장] 버튼
   - 이 시트는 닫을 수 있어. 같은 시트가 SCR-CAL-01 앱바 안내, SCR-ANNIV-01 안내 카드(16번), 전체 메뉴의 [처음 만난 날 수정]에서 떠. 흐름은 V06Flow(20번)에 표시해 줘.
   - 1950-01-01 이전과 오늘 이후 날짜가 비활성인 모습은 시스템 날짜 선택기가 처리하니 따로 그리지 않아도 돼. 필요하면 알려 줘.
13. SCR-CAL-03 내 일정 수정 (보드: AddEventEdit.dc.html) — PRD FR-CAL-02, FR-CAL-03 AC1
   - 일정 작성(AddEvent.dc.html)과 같은 구성에서 이렇게 바꿔 줘.
     · 앱바 제목 "일정 수정" (닫기, 저장은 그대로)
     · 종류 탭 [일정 | 메모] 없음
     · 대상 선택 [나 | 함께]는 있음, 하루 종일 스위치, "시작"·"종료" 행, 내 알림, 일정 메모는 그대로
     · "상대에게 알림 보내기" 스위치 없음
   - 상대가 만든 '함께' 일정을 수정하는 모양은 v0.5의 AddEventPartnerEdit가 이미 있어. 다시 그리지 마.
14. SCR-CAL-03 종료가 시작보다 이른 오류 (보드: AddEventError.dc.html) — PRD FR-CAL-02 AC3
   - 일정 작성(AddEvent.dc.html)에서 종료가 시작보다 이른 값을 넣고 저장을 눌렀을 때의 모양이야. 시작·종료 샘플 값은 종료가 시작보다 이르게 넣어 줘.
   - 종료 행 바로 아래에 `danger-700` 글자로 "종료는 시작보다 뒤여야 해요."
   - 나머지는 AddEvent와 같게.
15. SCR-ANNIV-01 지난 기념일 펼침 (보드: AnniversariesPastOpen.dc.html) — PRD D-71, FR-ANNIV-04 AC3
   - 2번의 Anniversaries 보드에서 "지난 기념일 [N]개" 행을 펼친 모양이야 (화살표가 펼침 방향).
   - 펼친 목록은 지난 1회성 직접 기념일을 최근 순으로 2~3개 보여 줘. 항목 모양은 다가오는 기념일 행과 같게 (날짜 블록, 이름, 사람 색 점).
   - 항목을 누르면 SCR-ANNIV-02(수정)로 간다는 흐름을 화살표로 표시해 줘. 누를 수 있는 건 만든 사람뿐이야.
   - 지난 항목에 연도 표시와 남은 일수 배지가 필요한지는 PRD에 정해진 게 없어. 정하지 말고, 어떻게 그렸는지 알려 줘.
16. SCR-ANNIV-01 커플 + 처음 만난 날 없음 (보드: AnniversariesNoStartDate.dc.html) — PRD FR-ANNIV-04 AC4
   - 2번의 Anniversaries 보드에서 "함께한 지 D+N" 카드 자리에 안내 카드를 넣어 줘.
     · 안내 "처음 만난 날을 정해 주세요"
     · [처음 만난 날 입력] 버튼 → 처음 만난 날 선택 시트(12번)로 간다는 흐름을 화살표로 표시해 줘.
   - 자동 기념일은 없어. 목록에는 직접 기념일만 보여 줘.
   - 안내 카드에 설명 문구를 더 넣지 마. 필요해 보이면 알려 줘.
17. SCR-ANNIV-02 개인 공간 문구 (보드: AnniversaryEditSolo.dc.html) — PRD D-70, FR-ANNIV-03
   - AnniversaryEdit와 같은 화면에서 안내 문구만 바꿔 줘: "캘린더와 기념일 목록에 표시되고, 당일 오전 9시에 알려 드려요. 2월 29일은 윤년이 아닌 해에 2월 28일로 표시돼요."
   - 이름, 날짜, "매년 반복" 스위치, [기념일 삭제] 등 나머지는 그대로야.
18. SCR-ANNIV-02 삭제 확인 (보드: AnniversaryEditDialog.dc.html) — PRD FR-ANNIV-03
   - 기념일 수정 화면(AnniversaryEdit) 위에 다이얼로그가 떠 있는 모양이야.
   - 제목 "기념일을 삭제할까요?"
   - 본문 "[기념일 이름]이 캘린더와 기념일 목록에서 사라져요."
   - 버튼 [취소] (아웃라인), [삭제] (`danger-700` 채움)
19. SCR-SET-03 개인 공간 (보드: ColorSettingsSolo.dc.html) — PRD FR-CAL-04 AC5
   - 우리 색상(ColorSettings.dc.html)과 같은 화면에서 이렇게 바꿔 줘.
     · "바꿀 대상"은 [나]만 보여 (상대·함께 없음)
     · 같은 색 경고 배너 없음
     · 안내 "연결하면 상대와 함께 색도 고를 수 있어요."
   - 미리보기는 나 색 하나로 일정을 보여 줘. 색 고르기 12색, [기본 색으로 되돌리기]는 그대로야.
20. 흐름도 (보드: V06Flow.dc.html) — PRD D-67, D-71, FR-COUPLE-04
   - V05Flow와 같은 방식으로 화살표 흐름도를 그려 줘. 세 줄이야.
     · 게스트 → 기존 계정 로그인: SCR-SET-01 계정(게스트) → 다이얼로그 ①(5번) → [그 계정으로 로그인] → 다이얼로그 ②(6번) → [삭제하고 로그인] → 그 계정의 현재 상태. 두 다이얼로그의 [취소]는 게스트로 계속 쓴다는 화살표.
     · 지난 기념일: SCR-ANNIV-01(접힘) → 펼침(15번) → 항목 → SCR-ANNIV-02(수정) → 삭제 확인(18번)
     · 처음 만난 날 시트: SCR-CAL-01 앱바 "처음 만난 날 입력하기 ›"(11번), SCR-ANNIV-01 안내 카드(16번), 전체 메뉴 [처음 만난 날 수정] → 처음 만난 날 선택 시트(12번)

[확인]
21. SCR-COUPLE-01 게스트 (보드: ConnectGuest.dc.html) — PRD D-80, 5장
   - "다른 계정으로 로그인"은 회원에게만 보이는 걸로 정해졌어. 지금 ConnectGuest 하단에 "다른 계정으로 로그인"이 있는지 확인해서 알려 줘. 고치지는 마.
   - 회원 화면(Connect.dc.html)은 지금 그대로 맞아. 바뀐 게 없으면 "변경 없음"이라고 알려 줘.
22. SCR-CAL-03 상대가 '함께' 일정을 수정할 때 (보드: AddEventPartnerEdit.dc.html) — PRD D-77, FR-CAL-03 AC4
   - 읽기 전용 "누구의 일정 · 함께"와 안내 "함께 일정의 대상은 만든 사람만 바꿀 수 있어요."가 확정됐어. 보드에 "제안", "사람 확인 필요" 같은 표시가 있는지 확인해서 알려 줘. 고치지는 마.
23. 새 토큰·컴포넌트 필요 여부
   - 이번 변경은 새 색, 새 토큰 없이 기존 토큰과 v0.5에서 쓴 조합(하단 시트, 스낵바, 다이얼로그)으로 그리는 것이 원칙이야.
   - 계정 · 회원 화면(7번)의 로그인 방식 아이콘, 지난 기념일의 접힌 행(2번)에 새 색이나 새 컴포넌트가 필요해 보이면 만들기 전에 먼저 물어봐 줘.

다 끝나면 바뀐 화면 ID 목록, 새로 만든 보드 목록, 디자인 시스템(토큰·컴포넌트)에 바뀐 점, 10·15·21·22번에서 알려 달라고 한 항목에 대한 답을 정리해 줘.
```

---

## 이미지 이름

화면 ID + `--<상태>`로 만들어요. 새 보드는 모두 `design/screens/`에 이미지를 만들고, 고친 보드(InviteEnter, Anniversaries, AnniversariesSolo)는 기존 이미지를 다시 만들어요.

| 보드 | 이미지 |
| --- | --- |
| AccountGuestExisting | `SCR-SET-01--account-guest-existing.png` |
| AccountGuestExistingConfirm | `SCR-SET-01--account-guest-existing-confirm.png` |
| AccountMember | `SCR-SET-01--account-member.png` |
| MenuLogoutDialog | `SCR-SET-01--logout-dialog.png` |
| InviteCreateNotYet | `SCR-COUPLE-02--not-yet.png` |
| CalendarLinkedSheetNoRecords | `SCR-COUPLE-04--no-records.png` |
| CalendarNoStartDate | `SCR-CAL-01--no-start-date.png` |
| StartDateSheet | `SCR-SET-01--start-date-sheet.png` |
| AddEventEdit | `SCR-CAL-03--edit.png` |
| AddEventError | `SCR-CAL-03--error.png` |
| AnniversariesPastOpen | `SCR-ANNIV-01--past-open.png` |
| AnniversariesNoStartDate | `SCR-ANNIV-01--no-start-date.png` |
| AnniversaryEditSolo | `SCR-ANNIV-02--solo.png` |
| AnniversaryEditDialog | `SCR-ANNIV-02--delete-dialog.png` |
| ColorSettingsSolo | `SCR-SET-03--solo.png` |
| V06Flow | `flow-prd-v0.6.png` |

---

## 반영 확인 (핸드오프 때 체크)

| # | 화면 | 반영 |
| --- | --- | --- |
| 1 | SCR-COUPLE-03 상대 카드 삭제 (InviteEnter 수정, 이전 버전 줄) | ✅ 보드를 그 자리에서 고침 (이전 모습은 캔버스 버전 35 기록에). 6자리 입력 상태 `SCR-COUPLE-03--filled.png` 추가 |
| 2 | SCR-ANNIV-01 접힌 "지난 기념일" 행, "D-day" 배지 (Anniversaries, AnniversariesSolo 수정, 이전 버전 줄) | ✅ 접힌 행 "지난 기념일 N개" + 펼침 화살표. 오늘 기념일 "D-day" 배지는 예시 데이터에 오늘 기념일이 없어 그림에 없음 (SCREENS 규칙대로) |
| 3 | SCR-ANNIV-02 커플 문구 그대로 (AnniversaryEdit) | ✅ 커플 문구 그대로 |
| 4 | SCR-COUPLE-04 확정 표시만 (CalendarLinkedSheet, CalendarLinkedSheetDialog) | ✅ 변경 없음 (D-76 확정) |
| 5 | SCR-SET-01 이미 가입된 계정 ① (AccountGuestExisting, 새 보드) | ✅ |
| 6 | SCR-SET-01 이미 가입된 계정 ② (AccountGuestExistingConfirm, 새 보드) | ✅ [삭제하고 로그인] `danger-700` |
| 7 | SCR-SET-01 계정 · 회원 (AccountMember, 새 보드) | ✅ "Google로 로그인 중" + 닉네임, 로그인 방식, 가입일, [로그아웃], [탈퇴하기] (버튼 이름을 게스트·PRD와 같게 "탈퇴하기"로) |
| 8 | SCR-SET-01 로그아웃 확인 (MenuLogoutDialog, 새 보드) | ✅ [로그아웃] `brand-500` 채움 |
| 9 | SCR-COUPLE-02 "아직 연결되지 않았어요" (InviteCreateNotYet, 새 보드) | ✅ 스낵바 |
| 10 | SCR-COUPLE-04 혼자 쓴 기록 없음 (CalendarLinkedSheetNoRecords, 새 보드) | ✅ 제목 오른쪽 닫기 버튼 |
| 11 | SCR-CAL-01 커플 + 처음 만난 날 없음 (CalendarNoStartDate, 새 보드) | ✅ |
| 12 | SCR-SET-01 처음 만난 날 선택 시트 (StartDateSheet, 새 보드) | ✅ 시트는 컴포넌트 보드 StartDateSheet, 이미지는 MenuStartDateSheet(전체 메뉴 위)로. 월 달력 + 연·월 선택 제목 + 미래 비활성 안내 |
| 13 | SCR-CAL-03 내 일정 수정 (AddEventEdit, 새 보드) | ✅ |
| 14 | SCR-CAL-03 종료 < 시작 오류 (AddEventError, 새 보드) | ✅ 입력 오류 토큰 `danger-600` 사용 (tokens.json의 "입력 오류 테두리·메시지") |
| 15 | SCR-ANNIV-01 지난 기념일 펼침 (AnniversariesPastOpen, 새 보드) | ✅ 항목: 월/일 블록(연도 없음), 이름, 만든 사람, 내 것만 ›. 일수 배지 없음 |
| 16 | SCR-ANNIV-01 커플 + 처음 만난 날 없음 (AnniversariesNoStartDate, 새 보드) | ✅ `brand-50` 안내 카드 + [처음 만난 날 입력] |
| 17 | SCR-ANNIV-02 개인 공간 문구 (AnniversaryEditSolo, 새 보드) | ✅ |
| 18 | SCR-ANNIV-02 삭제 확인 (AnniversaryEditDialog, 새 보드) | ✅ |
| 19 | SCR-SET-03 개인 공간 (ColorSettingsSolo, 새 보드) | ✅ 대상 [나] 한 줄, 안내 "연결하면 상대와 함께 색도 고를 수 있어요." |
| 20 | 흐름도 (V06Flow, 새 보드) | ✅ `flow-prd-v0.6.png` |
| 21 | SCR-COUPLE-01 게스트 "다른 계정으로 로그인" 확인 | ✅ 게스트 화면에서 "다른 계정으로 로그인"을 뺌. 회원 화면의 링크는 로그아웃 확인으로 |
| 22 | SCR-CAL-03 읽기 전용 표시 확정 표시 확인 | ✅ AddEventPartnerEdit에 "제안" 표시는 없음 (확정 상태 그대로) |
| 23 | 새 토큰·컴포넌트 필요 여부 | ✅ 새 토큰·컴포넌트 없음 |

## 결과 (2026-10-22, 캔버스 버전 37)

- 고친 보드: InviteEnter, Account, Menu, Calendar, AddEvent, Anniversaries, AnniversaryEdit, InviteCreate, Connect, ColorSettings (모두 상태 prop 추가, 기본 모습은 Anniversaries·Account·Connect 게스트만 바뀜)
- 새 보드 18개: 위 표의 새 보드 + InviteEnterFilled, StartDateSheet(컴포넌트), MenuStartDateSheet
- 바뀐 이미지: `SCR-ANNIV-01.png`, `SCR-ANNIV-01--solo.png`(지난 기념일 행), `SCR-COUPLE-01--guest.png`(링크 뺌), `SCR-SET-01--account-guest.png`·`--withdraw-dialog.png`(게스트 안내 문구)
- 게스트 계정 화면 안내 문구를 D-67에 맞게 "이미 둘이서에 가입된 계정이면 그 계정으로 로그인할 수 있어요. 이때 게스트 기록은 옮겨지지 않고 삭제돼요."로 바꿨어요
- 그리지 않은 것: SCR-COUPLE-03 오류 문구, 재연결(유예 기간) 복구 시트 — 이번 요청 범위 밖
