# PRD v0.6 영향 분석

> 상태: PR 완료 — https://github.com/DuriseoApp/Docs/pull/4 (Android 이슈: https://github.com/DuriseoApp/Android/issues/4)
> 이전 버전: v0.5 → 새 버전: v0.6
> 브랜치: sync/prd-v0.6
> PR: (PR 완료 후 링크)

이 파일은 `/prd-sync` 팀원들이 읽는 계약이다. 여기 적힌 이름과 할 일을 그대로 따른다. 이번 변경은 2026-10-22 2차 문서 점검에서 찾은 빈칸을 사용자가 정한 결과다 (D-67~D-80). 사용자는 지금까지 "디자인 없음"이던 상태 화면도 이번에 모두 그리기로 했다.

## 1. 바뀐 ID

| ID | 변경 | 내용 |
| --- | --- | --- |
| D-67, FR-AUTH-03 (AC2 수정, AC3 추가), Q-01, 4장, 7장 계정 표 | 추가·수정 | 게스트가 이미 가입된 소셜 계정으로 연동하려 하면 "이미 가입된 계정이에요" + [그 계정으로 로그인]. 누르면 "게스트로 쓴 기록은 모두 삭제돼요" 확인 → 게스트 계정·기록을 탈퇴처럼 바로 삭제 → 그 계정으로 로그인. 데이터는 합치지 않음 |
| D-68, FR-AUTH-03 AC1 | 추가·수정 | 연동할 때 닉네임이 아직 "게스트"면 소셜 이름으로(10자, 없으면 "사용자"). 직접 바꾼 닉네임은 유지 |
| D-69, FR-AUTH-07 AC1 | 추가·수정 | 소셜 이름을 못 받으면 기본 닉네임 "사용자" |
| D-79, FR-AUTH-03 AC4, SCR-COUPLE-01 진입 | 추가 (기본값) | 게스트가 [로그인하고 연결하기]로 연동을 시작했으면 연동 뒤 SCR-COUPLE-01(회원 화면)로 |
| D-80, FR-AUTH-05 AC3, SCR-COUPLE-01 | 추가 (기본값) | SCR-COUPLE-01의 "다른 계정으로 로그인"(회원) = 로그아웃 확인 → 로그아웃 → SCR-START-01 |
| FR-AUTH-06 AC3 | 추가 (기본값) | Kakao 회원이 탈퇴하면 서버가 Kakao 앱 연결도 끊음 |
| D-70, FR-NOTI-01 | 추가·수정 | 알림 권한을 직접 기념일 저장 때도 처음 물음 (일정 알림 설정, 커플 연결, 직접 기념일 저장) |
| D-71, FR-ANNIV-04 AC3 | 추가 | 기념일 목록 아래 접힌 "지난 기념일": 날짜가 지난 1회성 직접 기념일, 최근 순, 누르면 작성자는 SCR-ANNIV-02에서 수정·삭제 |
| D-75, FR-ANNIV-04 AC1, SCR-ANNIV-01 비고 | 추가·수정 | 기념일 목록 = 오늘(포함)부터 2050-12-31까지 모든 기념일, 매년 기념일은 해마다 한 줄. 오늘은 "D-day" |
| FR-ANNIV-04 AC4 | 추가 | 처음 만난 날이 없는 커플: 함께한 날 카드 자리에 처음 만난 날 입력 안내, 자동 기념일 없음 |
| D-74, FR-CAL-01 AC6, FR-COUPLE-04 AC3, FR-ANNIV-02 AC1 | 추가·수정 | 캘린더와 모든 날짜 선택 범위 1950-01-01 ~ 2050-12-31 (일정, 메모 날짜, 직접 기념일, 처음 만난 날). 서버도 거부. 매년 N주년은 2050년까지 계산 |
| D-72, SCR-COUPLE-03 비고 | 추가 | 초대코드 입력 화면의 상대 미리보기 카드 삭제. 6자리를 넣으면 바로 [연결하고 시작하기] 활성 |
| D-73, NFR-SEC-01 | 추가·수정 | JWT: access 1시간, refresh 회원 30일·게스트 365일(쓸 때마다 연장, 기존과 같음). 로그인이 만료된 기기에는 푸시를 보내지 않음 |
| D-76, FR-COUPLE-03 (AC4 수정, AC5 추가) | 추가·수정 | 연결 완료 시트의 기록 선택은 [가져오기] 미리 선택 (v0.5 디자인 확정). [시작하기] 전에는 닫기 불가 |
| D-77, FR-CAL-03 AC4 | 추가·수정 | 상대가 '함께' 일정 수정 시 읽기 전용 "누구의 일정 · 함께" + "함께 일정의 대상은 만든 사람만 바꿀 수 있어요." (v0.5 디자인 확정) |
| D-78, FR-COUPLE-05 AC4 | 추가 (기본값) | 기록 가져오기를 정하기 전에 연결이 해제되면 혼자 쓴 기록은 원래 개인 공간으로 그대로 돌아감 |
| 8장 | 수정 | 알림 표 "기본값" 열 → "푸시 설정 기본값" + 설명 한 줄(일정 알림 시각 기본값 "없음"과 다름) |
| 5장 | 수정 | SCR-START-01 진입(로그아웃·탈퇴 후, 다른 기기 로그인), SCR-ANNIV-01·SCR-COUPLE-01·SCR-COUPLE-03 비고 |

## 2. 문서별 할 일

| 문서 | 담당 | 할 일 |
| --- | --- | --- |
| docs/ERD.md (+ erd.html, ERD.png) | data | 스키마 변화 없음. 서비스 규칙·수명주기만: 게스트 → 기존 계정 로그인(4.1 생성 표·4.6 세션 표에 행 추가, 게스트는 4.3 탈퇴와 같이 처리), 연동 시 닉네임 규칙(users.nickname 설명), 이름 없을 때 "사용자", 날짜 범위(서비스 검증, DB CHECK 없음), 가져오기 전 해제 시 대기 중 개인 공간 되살리기(4.2), 로그인 만료 기기 푸시 금지(devices 서비스 규칙 + 4.4 정리 작업에서 유효 세션 없는 사용자의 devices 삭제), 탈퇴 시 Kakao 연결 끊기(4.3, 테이블 변화 없음), 새 DB 결정 DB-12~DB-14(아래 3.1), 추적표, 헤더 v0.6. ERD.png는 스키마가 같으면 헤더만 바꿔 다시 렌더 |
| docs/API.md | api | `POST /auth/switch` 추가(3.2), `/auth/link` 409 `SOCIAL_ALREADY_USED` 뒤 앱 흐름, 연동 시 닉네임 규칙, 소셜 이름 없을 때 "사용자", 날짜 범위 검증(400 `DATE_OUT_OF_RANGE`), 기념일 목록 API 2개(`/anniversaries/upcoming`, `/anniversaries/past`), 처음 만난 날 없는 커플의 기념일 응답, 가져오기 전 해제(4.5), 푸시 전 유효 세션 확인(7장), 탈퇴 시 Kakao 연결 끊기(4.6), 1장 토큰 수명 근거를 D-73으로, 오류 코드 표, 추적표, 헤더 v0.6 |
| docs/SCREENS.md | screen | 위 결정 반영(아래 3.3), 공통 "알림 권한"에 직접 기념일 저장 추가, 공통에 "날짜 범위 1950~2050", "디자인 없음" 표시를 이번에 그릴 보드 이미지 이름으로(3.4), 연결 완료 시트의 "디자인 제안, 사람 확인 필요" 표시 제거(D-76 확정), SCR-CAL-03 읽기 전용 표시 "사람 확인 필요" 제거(D-77 확정), SCR-ANNIV-02 개인 공간 안내 문구, 헤더 v0.6 |
| 디자인 변경 요청서 | screen | 있음: `design/change-requests/prd-v0.6.md` (아래 3.4) |

## 3. 이름 확정

### 3.1 데이터 (ERD)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 스키마 | 변화 없음 | 새 테이블·컬럼·enum 없음. 마이그레이션 없음 | — |
| 서비스 규칙 | 게스트 → 기존 계정 로그인 (`POST /auth/switch`) | 한 트랜잭션: ① 게스트 사용자를 4.3 탈퇴와 같이 처리(세션 `WITHDRAWN` 후 삭제, 개인 공간 삭제, 익명화) ② 그 소셜 계정의 회원으로 로그인(로그인 2종과 같은 이전 세션·기기 정리: 다른 유효 세션 `REPLACED`, `devices` 모두 삭제) ③ 새 세션 생성. 이제 "로그인"은 3종(게스트 시작, 소셜 로그인, 게스트 → 기존 계정 로그인)이고 이전 세션·기기 정리는 셋 모두 같은 코드 | D-67 |
| 서비스 규칙 | 연동 시 닉네임 | `/auth/link` 성공 시 `users.nickname = '게스트'`(값이 정확히 같을 때)면 소셜 프로필 이름(앞 10자, 없으면 "사용자")으로 바꾼다. 다르면 그대로 | D-68, D-69 |
| 서비스 규칙 | 기본 닉네임 | 소셜 이름이 없거나 공백뿐이면 "사용자" | D-69 |
| 서비스 규칙 | 날짜 범위 | `events.start_date/end_date`, `events.start_at/end_at`(요청자 `time_zone` 기준 날짜), `memos.memo_date`, `anniversaries.date`, `spaces.start_date`는 1950-01-01 ~ 2050-12-31. 서비스에서 검사하고 DB CHECK는 두지 않는다 (리드 결정) | D-74 |
| 서비스 규칙 | 가져오기 전 해제 | 연결 해제 시 구성원에게 가져오기 대기 중인 개인 공간(소속에 `left_at`이 있는 PERSONAL)이 있으면 새 개인 공간을 만들지 않고 그 공간의 `space_members.left_at`을 비워 다시 활성 공간으로 쓴다. 그 사람의 `importPending`은 false가 된다 | D-78 |
| 서비스 규칙 | 로그인 만료 기기 | 푸시는 받는 사람에게 유효한 세션(`revoked_at IS NULL AND expires_at > now`)이 있을 때만 보낸다(알림 목록 행은 그대로 만든다). 매일 정리 작업은 만료 세션을 지운 뒤 유효 세션이 없는 사용자의 `devices`를 지운다 | D-73 |
| 서비스 규칙 | 탈퇴 시 Kakao 연결 끊기 | `social_accounts.provider = KAKAO`면 행을 지우기 전에 Kakao 연결 끊기 API를 서버의 Kakao 어드민 키로 호출한다(키는 설정값, 문서에 쓰지 않음). 실패해도 탈퇴는 진행하고 로그만 남긴다 | FR-AUTH-06.AC3 |
| DB 결정 | DB-12 | 게스트 → 기존 계정 로그인은 게스트 탈퇴 + 소셜 로그인을 한 트랜잭션으로 처리 | D-67 |
| DB 결정 | DB-13 | 날짜 범위(1950~2050)는 서비스에서 검사하고 DB CHECK는 두지 않는다 | D-74 |
| DB 결정 | DB-14 | 푸시는 유효 세션이 있는 사용자에게만, 정리 작업이 세션 없는 사용자의 devices를 지운다 | D-73 |

### 3.2 API

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 경로 | `POST /auth/switch` | 게스트 → 기존 회원 계정 로그인 `{provider, token}`. 권한: GUEST만(게스트 access 토큰). 4.2의 2단계처럼 소셜 토큰 검증(실패 401 `SOCIAL_TOKEN_INVALID`). 그 소셜 계정이 가입돼 있지 않으면 404 `SOCIAL_NOT_REGISTERED`(앱은 `/auth/link`로 연동하면 됨, 아무것도 바꾸지 않음). 성공하면 3.1 규칙대로 게스트 삭제 + 로그인, 응답은 `/auth/social`과 같음(`isNewUser: false`, 새 access·refresh 토큰). 앱은 `PUT /me/devices`를 다시 부르고 그 계정의 현재 상태로 이동 | D-67, FR-AUTH-03.AC3 |
| 오류 코드 | SOCIAL_NOT_REGISTERED | 404. `/auth/switch`에서 그 소셜 계정으로 가입한 회원이 없음 | D-67 |
| 오류 코드 (리드 결정) | GUEST_ONLY | 403. 게스트만 부를 수 있는 경로(`/auth/link`, `/auth/switch`)를 회원이 부름 | D-67, FR-AUTH-03 |
| 규칙 (리드 결정) | 푸시 조건의 범위 | 유효 세션 조건(DB-14, API R-16)은 사용자에게 보이는 푸시에만 적용한다. 동기화 신호(SYNC)는 그대로 보낸다(기기 정리로 자연히 멈춤) | D-73 |
| 규칙 (리드 결정) | D-78 되살리기 조건 | 해제할 때 그 사람의 가져오기 대기 중인 개인 공간(소속에 `left_at`이 있는 PERSONAL)이 남아 있으면 새로 만들지 않고 그 공간을 되살린다(ERD 4.2). 남아 있지 않으면 지금처럼 새 빈 개인 공간을 만든다 | D-78 |
| 규칙 (리드 결정, 검수 1차) | 빈 개인 공간 | `/couple/join`에서 개인 공간에 혼자 쓴 기록이 없으면 그 개인 공간을 같은 트랜잭션에서 바로 지운다. 그래서 가져오기 대기 중인 개인 공간 = 기록이 있는 공간뿐이고, `importPending` = 그런 공간이 남아 있음 | D-78, FR-COUPLE-03 |
| 응답 필드 (리드 결정, 검수 1차) | `GET /anniversaries/past`의 `totalCount` | 지난 1회성 직접 기념일의 전체 개수. 앱은 접힌 행 "지난 기념일 N개"에 쓰고, 0이면 행을 숨긴다 | D-71 |
| 규칙 (리드 결정, 검수 1차) | `/auth/switch` 트랜잭션 | 트랜잭션 안에서 `social_accounts`를 다시 조회하고 대상 회원 행을 잠근다. 없거나 탈퇴한 회원이면 롤백하고 404 `SOCIAL_NOT_REGISTERED` (게스트는 그대로) | D-67 |
| 오류 코드 (리드 결정, 검수 1차) | NO_IMPORT_PENDING | 409. 가져오기 대기 중인 개인 공간이 없는데 `POST /couple/import`를 부름 (해제와 겹친 경우 포함) | FR-COUPLE-03, D-78 |
| 오류 코드 (리드 결정, 검수 1차) | GUEST_NOT_ALLOWED 뜻 넓힘 | 403. 게스트가 회원 전용 기능(커플 연결, `/auth/logout`)을 부름 | D-07, FR-AUTH-05 |
| 권한 규칙 | R-17 | `/auth/logout`은 회원만. 게스트면 403 `GUEST_NOT_ALLOWED` (API 2장) | FR-AUTH-05 |
| 규칙 (리드 결정, 검수 2차) | 날짜 범위 조회 | 조회의 `from`·`to`가 1950-01-01 ~ 2050-12-31 밖이면 오류 없이 범위 안으로 잘라 조회한다(월 달력의 앞뒤 달 날짜 때문). `DATE_OUT_OF_RANGE`는 쓰기 요청에만 (검수 1차 결정을 바꿈) | D-74 |
| 규칙 (리드 결정, 검수 1차) | Kakao 연결 끊기 시점 | 탈퇴(또는 게스트 삭제와 무관, 회원 탈퇴만) 트랜잭션이 커밋된 뒤 호출한다. 실패해도 되돌리지 않고 로그만 남긴다 | FR-AUTH-06.AC3 |
| 앱 흐름 | `/auth/link` 409 `SOCIAL_ALREADY_USED` | 앱은 "이미 가입된 계정이에요" 다이얼로그와 [그 계정으로 로그인]을 보여주고, 확인 다이얼로그 뒤 같은 소셜 토큰으로 `POST /auth/switch` (소셜 SDK 토큰을 다시 받아도 됨) | D-67 |
| 오류 코드 | DATE_OUT_OF_RANGE | 400. 날짜가 1950-01-01 ~ 2050-12-31 밖. `POST/PATCH /events`, `POST/PATCH /memos`(memoDate), `POST/PATCH /anniversaries`, `PATCH /space`(startDate). 미래의 처음 만난 날은 기존대로 `VALIDATION_FAILED` | D-74 |
| 경로 | `GET /anniversaries/upcoming?cursor=&size=` | 기념일 목록용. 요청자 시간대 기준 오늘(포함)부터 2050-12-31까지의 자동·직접 기념일 발생일을 날짜순으로. 매년 반복은 해마다 한 항목. 항목 `{anniversaryId(직접만, 자동은 null), kind(AUTO·CUSTOM), name, date, daysLeft(오늘 = 0), repeatsYearly, authorId(직접만)}`. 커서는 (date, kind, anniversaryId). 처음 만난 날이 없으면 AUTO 없음 | D-75, FR-ANNIV-04.AC1·AC4 |
| 경로 | `GET /anniversaries/past?cursor=&size=` | "지난 기념일"용. `repeats_yearly = false`이고 `date` < 오늘(요청자 시간대)인 직접 기념일, 날짜 최근 순. 항목 `{anniversaryId, name, date, authorId}` | D-71, FR-ANNIV-04.AC3 |
| 경로 유지 | `GET /anniversaries?from=&to=` | 캘린더용 그대로 (범위 최대 3개월로 명시, 넘으면 `VALIDATION_FAILED`) | FR-CAL-01 |
| 앱 흐름 | 알림 권한 | API 없음. 앱이 직접 기념일 저장 성공 직후 처음 한 번 요청 | D-70 |
| 앱 흐름 | "다른 계정으로 로그인" | `POST /auth/logout` 뒤 SCR-START-01 | D-80 |

### 3.3 화면 (SCREENS)

| 화면 | 바뀌는 것 | 관련 ID |
| --- | --- | --- |
| 공통 | 알림 권한 요청 시점에 "직접 기념일 저장" 추가. 날짜 범위: 달력과 모든 날짜 선택은 1950년 1월 ~ 2050년 12월, 범위 밖은 비활성 | D-70, D-74 |
| SCR-SET-01 (계정 · 게스트) | 연동 시 이미 가입된 계정이면 다이얼로그 ① "이미 가입된 계정이에요" / "이 계정은 이미 둘이서에 가입돼 있어요. 그 계정으로 로그인하면 게스트로 쓴 기록은 옮겨지지 않아요." [취소] [그 계정으로 로그인] → 다이얼로그 ② "그 계정으로 로그인할까요?" / "게스트로 쓴 기록은 모두 삭제돼요. 삭제한 기록은 되돌릴 수 없어요." [취소] [삭제하고 로그인](`danger-700`). 확인하면 그 계정의 현재 상태로 이동. 연동 성공 시 닉네임 규칙 안내는 없음 | D-67, D-68 |
| SCR-SET-01 (계정 · 회원) | 새로 그림: 로그인 방식(Google·카카오 아이콘 + "Google로 로그인 중"), 닉네임, 가입일, [로그아웃], 맨 아래 [회원 탈퇴]. 이메일은 받지 않으므로 보여주지 않음(NFR-PRIV-01) | FR-SET-01, D-44 |
| SCR-SET-01 (로그아웃 확인) | "로그아웃할까요?" / "다시 로그인하면 기록을 그대로 볼 수 있어요." [취소] [로그아웃] | FR-AUTH-05 |
| SCR-COUPLE-01 | 진입에 "게스트가 [로그인하고 연결하기]로 연동을 마친 뒤" 추가. 하단 "다른 계정으로 로그인"(회원만) = 로그아웃 확인 → SCR-START-01 | D-79, D-80 |
| SCR-COUPLE-02 | "아직 연결되지 않았어요" 상태를 그림 (스낵바) | D-48 |
| SCR-COUPLE-03 | 연결할 상대 카드 삭제. 6자리가 다 차면 [연결하고 시작하기] 활성 | D-72 |
| SCR-COUPLE-04 | [가져오기] 미리 선택 확정(사람 확인 표시 제거). 혼자 쓴 기록이 없는 상태를 그림(기록 영역 없음, 닫기 가능). 처음 만난 날 선택 범위 1950-01-01 ~ 오늘 | D-76, D-74 |
| SCR-CAL-01 | 커플 + 처음 만난 날 없음: 앱바 "처음 만난 날 입력하기 ›" → 처음 만난 날 선택 시트. 이 상태를 그림 | FR-COUPLE-04.AC2 |
| 처음 만난 날 선택 시트 (SCR-SET-01 소속) | 새로 그림: 제목 "처음 만난 날", 안내 "D-day와 기념일이 이 날을 1일로 계산돼요.", 날짜 선택(1950-01-01 ~ 오늘), [저장]. SCR-CAL-01 앱바 안내, SCR-ANNIV-01 안내 카드, 전체 메뉴 [처음 만난 날 수정]에서 같은 시트가 뜸 | FR-COUPLE-04, D-74 |
| SCR-CAL-03 | 내 일정 수정 상태를 그림(앱바 "일정 수정", 종류 탭 없음, 대상 선택 있음, 알림 스위치 없음). 종료가 시작보다 이를 때 저장하면 종료 행 아래 `danger-600`(입력 오류 토큰) 오류 "종료는 시작보다 뒤여야 해요." 상태를 그림. 상대 '함께' 일정 수정의 읽기 전용 표시 확정(사람 확인 표시 제거) | FR-CAL-02.AC3, D-77 |
| SCR-ANNIV-01 | 목록 범위 오늘 ~ 2050-12-31(오늘은 "D-day"), 목록 아래 접힌 "지난 기념일 N개" 행 → 펼치면 지난 1회성 직접 기념일 최근 순, 누르면 SCR-ANNIV-02(작성자). 커플 + 처음 만난 날 없음: 함께한 날 카드 자리에 "처음 만난 날을 정해 주세요" 안내 카드 + [처음 만난 날 입력] → 처음 만난 날 선택 시트 | D-75, D-71, FR-ANNIV-04.AC4 |
| SCR-ANNIV-02 | 개인 공간 안내 문구 "캘린더와 기념일 목록에 표시되고, 당일 오전 9시에 알려 드려요. 2월 29일은 윤년이 아닌 해에 2월 28일로 표시돼요." (커플은 기존 "두 사람 모두에게" 그대로). 삭제 확인 다이얼로그를 그림: "기념일을 삭제할까요?" / "[기념일 이름]이 캘린더와 기념일 목록에서 사라져요." [취소] [삭제](`danger-700`). 저장 성공 뒤 처음이면 알림 권한 요청 | D-70 |
| SCR-SET-03 | 개인 공간 상태를 그림: 바꿀 대상은 [나]만, 같은 색 경고 없음, 안내 "연결하면 상대와 함께 색도 고를 수 있어요." | FR-CAL-04.AC5 |

### 3.4 디자인 변경 요청서 (`design/change-requests/prd-v0.6.md`)

[수정] InviteEnter(상대 카드 삭제), Anniversaries·AnniversariesSolo(접힌 "지난 기념일" 행), AnniversaryEdit(커플 문구 그대로, 개인 공간 문구는 새 보드), CalendarLinkedSheet(변경 없음, 확정 표시만).
[새 보드] AccountGuestExisting(다이얼로그 ①), AccountGuestExistingConfirm(다이얼로그 ②), AccountMember(계정 · 회원), MenuLogoutDialog(로그아웃 확인), InviteCreateNotYet("아직 연결되지 않았어요"), CalendarLinkedSheetNoRecords(기록 없음 시트), CalendarNoStartDate(커플 + 처음 만난 날 없음), StartDateSheet(처음 만난 날 선택 시트), AddEventEdit(내 일정 수정), AddEventError(종료 < 시작 오류), AnniversariesPastOpen(지난 기념일 펼친 상태), AnniversariesNoStartDate(커플 + 처음 만난 날 없음), AnniversaryEditSolo(개인 공간 문구), AnniversaryEditDialog(삭제 확인), ColorSettingsSolo(개인 공간), V06Flow(흐름도: 게스트 → 기존 계정 로그인, 지난 기념일, 처음 만난 날 시트).
이미지 이름: 화면 ID + `--<상태>` (예: `SCR-SET-01--account-guest-existing.png`, `SCR-SET-01--account-member.png`, `SCR-SET-01--logout-dialog.png`, `SCR-COUPLE-02--not-yet.png`, `SCR-COUPLE-04--no-records.png`, `SCR-CAL-01--no-start-date.png`, `SCR-SET-01--start-date-sheet.png`, `SCR-CAL-03--edit.png`, `SCR-CAL-03--error.png`, `SCR-ANNIV-01--past-open.png`, `SCR-ANNIV-01--no-start-date.png`, `SCR-ANNIV-02--solo.png`, `SCR-ANNIV-02--delete-dialog.png`, `SCR-SET-03--solo.png`, `flow-prd-v0.6.png`). 새 토큰 없이 기존 토큰·컴포넌트로.

## 4. 위험 항목

- [ ] DB 마이그레이션 필요: 없음 (스키마 변화 없음)
- [x] 데이터 삭제: 게스트 → 기존 계정 로그인 시 게스트 계정과 기록을 바로 삭제(사용자 확인 후, D-67). 정리 작업이 유효 세션 없는 사용자의 devices 삭제
- [x] 권한 변경: `POST /auth/switch`(GUEST만) 추가
- [x] 앱 호환성이 깨지는 API 변경: 새 경로 3개(`/auth/switch`, `/anniversaries/upcoming`, `/anniversaries/past`), 새 오류 `SOCIAL_NOT_REGISTERED`, `DATE_OUT_OF_RANGE`, 범위 밖 날짜 거부 (출시 전이라 실제 영향 없음)
- [x] 개인정보 처리 변경: 탈퇴 시 Kakao 연결 끊기, 로그인 만료 기기로 푸시 안 감, 게스트 → 기존 계정 로그인 시 게스트 데이터 즉시 삭제 → 개인정보처리방침(Q-03)에 반영

## 5. 열린 질문

- 없음. Q-10(문의 메일 주소), Q-03(약관·개인정보처리방침)은 그대로 열려 있지만 문서 작업은 막지 않는다.

## 6. 검수 기록

| 회차 | 판정 | Critical | 비고 |
| --- | --- | --- | --- |
| 1 | 수정 필요 | 0 | Major 3(지난 기념일 개수, 빈 대기 공간과 importPending, /auth/switch 트랜잭션 재조회), Minor 12 → 리드 결정(위 3.2 "검수 1차" 행)으로 api·data·screen이 수정. SCR-COUPLE-03 오류 화면과 재연결 복구 시트는 이번 그리기 범위 밖(사용자 목록에 없음) |
| 2 | 수정 필요 | 0 | Major 1(ERD의 빈 개인 공간 삭제 대상이 B만) → data가 A·B 모두로, 위치를 4.1로. Minor: 범위 조회는 자르기로(리드 결정 변경, api), 로그아웃 확인 버튼을 `danger-700` 채움으로(토큰 규칙, 캔버스 버전 38), 오류 색 표기 `danger-600`, 기록 없음 시트의 닫기 버튼은 기존 닫기 아이콘 버튼 모양이라 새 컴포넌트 아님 |
