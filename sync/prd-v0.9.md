# PRD v0.9 영향 분석

> 상태: 진행 중
> 이전 버전: v0.8 → 새 버전: v0.9
> 브랜치: sync/prd-v0.9
> PR: (PR 완료 후 링크)

이 파일은 `/prd-sync` 팀원들이 읽는 계약이다. 여기 적힌 이름과 할 일을 그대로 따른다.

배경: Server 단위 3(캘린더) 범위 점검에서 13개(Server `docs/progress/unit-3.md` "확인 필요" 1~13), Android 단위 3(커플) 범위 점검에서 18개(Android `docs/progress/unit-3.md` "확인 필요" 1~18)의 빈 곳이 나왔다. 사용자가 2026-10-31에 **모두 추천안대로** 정했다. PRD에는 제품 결정(D-89~D-103, Q-13)과 AC·화면 목록·알림 문구만 넣었다. 일정 API 응답 모양, 쿼리 규칙, 검사 순서, 상태 코드 같은 API 표기는 PRD에 넣지 않고 이 파일 3장 "이름 확정"대로 API·ERD·SCREENS에 채운다.

추천안이 두 갈래였거나 빈 곳이 남은 부분은 리드가 정했고 줄마다 **리드 결정** 또는 **리드 보충**이라고 적었다. 사람이 정해야 하는 것은 PRD Q-13 하나다 (5장).

## 0. 확인 필요 항목 대응표

### 0.1 Server 단위 3 (캘린더)

| 번호 | 항목 | 반영한 곳 |
| --- | --- | --- |
| 서버 1 | 일정 API 응답 모양·상태 | 3.1 `Event`, 경로 표 (API 3.3). `PUT reminder` 200 `Event`는 리드 결정 |
| 서버 2 | 일정 쓰기 필드 규칙 | PRD D-89, FR-CAL-02 AC1 (제목 공백). 3.1 "쓰기 규칙" (API 3.3, 5장) |
| 서버 3 | `GET /events` 쿼리 규칙 | 3.1 "조회 규칙" (API 3.3, 5장 `VALIDATION_FAILED`에 `GET /events` 추가) |
| 서버 4 | 알림 `option` 값과 일정 종류 | 3.1 "일정 알림 `option`" (API 3.3) |
| 서버 5 | `fire_at` 계산식, 이미 지난 시각 | PRD D-90, FR-CAL-05 AC5. 3.1 "알림 시각 계산" (API 3.3·7장, ERD `event_reminders`) |
| 서버 6 | 일시·종류·시간대 변경 때 알림 | PRD D-91, FR-CAL-05 AC4·AC6. 3.1 "다시 계산" (API 3.3, ERD) |
| 서버 7 | `PARTNER_CREATED` 행 단위, 본문 날짜 서식 | PRD D-92, 8장 서식 문단. 3.1 "상대 일정 추가 알림" (API 7장). 행을 만드는 단위는 6장 (문서 밖) |
| 서버 8 | 일정 SYNC 연결점 | 3.1 "동기화 신호" (API 6장 한 줄). 발행·발송 단위는 6장 (문서 밖) |
| 서버 9 | R-01 표기, 검사 순서 | 3.1 "검사 순서", 경로 표 권한 열 (API 2장·3.3) |
| 서버 10 | R-13 판정 기준 | 3.1 "R-13 문구" (API 2장) |
| 서버 11 | `DELETE reminder` 멱등 | 3.1 경로 표 (알림이 없어도 204) |
| 서버 12 | 지난 일정에 `PUT reminder` | PRD D-90 ("끝난 일정에도 설정할 수 있다"). 3.1 "알림 시각 계산" |
| 서버 13 | `updated_by`, 작성자 닉네임 | 3.1 `Event.updatedBy`·`authorId` (API), ERD `events.updated_by` 설명 |

### 0.2 Android 단위 3 (커플)

| 번호 | 항목 | 반영한 곳 |
| --- | --- | --- |
| Android 1 | 혼자 쓴 기록 개수 | PRD D-93, FR-COUPLE-03 AC1·AC2, Q-13. 3.2 `MeSpace.importCounts` (API, **서버 변경**), 3.4 SCR-COUPLE-04 |
| Android 2 | 연결한 날 | PRD D-94, FR-SET-01 AC1. 3.2 `MeSpace.linkedAt`·`Space.linkedAt`(API), `spaces.linked_at`(ERD, **마이그레이션**), 3.4 SCR-SET-01 |
| Android 3 | SCR-COUPLE-01~03 오류·상태 | PRD D-95, FR-COUPLE-01 AC6, FR-COUPLE-02 AC5와 "초대코드 오류 문구" 표. 3.3 앱 동작, 3.4 SCR-COUPLE-02·03, 3.6 요청서 1·2 |
| Android 4 | SCR-COUPLE-01 뒤로 버튼 | PRD D-96, 5장 SCR-COUPLE-01 비고. 3.4 SCR-COUPLE-01 |
| Android 5 | 연결 정보 · 혼자의 [초대코드 만들기] | PRD D-97, 5장 SCR-COUPLE-02·03 진입. 3.4 SCR-SET-01, 3.6 요청서 6 |
| Android 6 | 연도·월 선택 디자인 없음 | PRD 변경 없음. 3.4 처음 만난 날 선택 시트, 3.6 요청서 3 |
| Android 7 | SCR-COUPLE-04 처음 만난 날 칸 동작 | PRD D-98, FR-COUPLE-04 AC4. 3.3 "[시작하기] 순서"(API 4.4의 9단계), 3.4 SCR-COUPLE-04, 3.6 요청서 4 |
| Android 8 | [내 프로필 수정]·연필 배지 | 문서 밖 (6장, Android 단위 8) |
| Android 9 | 처음 만난 날 없는 커플의 전체 메뉴 | PRD D-99, FR-COUPLE-04 AC5. 3.4 SCR-SET-01, 3.6 요청서 5 |
| Android 10 | SCR-SET-03 저장 시점 | PRD D-100, FR-CAL-04 AC2. 3.4 SCR-SET-03 |
| Android 11 | [기본 색으로 되돌리기] 값 | PRD D-101, FR-CAL-04 AC7. 3.4 SCR-SET-03 |
| Android 12 | 보드에만 있는 문구·샘플 | PRD 변경 없음. 3.4 화면별 "보드 문구" (SCREENS에 보드 그대로) |
| Android 13 | [공유하기]·[코드 복사] | PRD D-102, FR-COUPLE-01 AC1. 3.4 SCR-COUPLE-02 |
| Android 14 | 토큰에 없는 수치 | PRD 변경 없음. 3.5 design-system 보충 (토큰 변경 없음) |
| Android 15 | "재시작"의 뜻, 다른 `NOT_COUPLE` | PRD D-103, FR-COUPLE-05 AC3·AC5. 3.3 (API 4.5·5장) |
| Android 16 | "다음 실행 때 시트" 저장값 갱신 시점 | PRD D-98, FR-COUPLE-03 AC6. 3.3 (API 4.4의 8단계) |
| Android 17 | 게스트의 [연결 정보] 행 | PRD FR-AUTH-04 AC2 문구 (D-07 그대로). 3.4 SCR-SET-01 |
| Android 18 | 모르는 팔레트 키 | PRD 변경 없음. 3.3 (API 3.2 앱 동작), 3.5 design-system |

### 0.3 두 범위 문서 사이의 이름 맞춤

| 다르게 부른 것 | 정한 것 |
| --- | --- |
| 작성자 닉네임 출처: Server 13은 `GET /space`의 `Space.members`, Android 결정 3은 `GET /me`의 `MeSpace.partner` | 둘 다 된다. `Event`에는 `authorId`만 두고, 앱은 `MeSpace`(나는 `Me.id`·`Me.nickname`, 상대는 `partner`)나 `Space.members`에서 `authorId`로 찾는다 (3.1) |
| Android 15가 `POST /couple/import`의 `NOT_COUPLE`을 말함 | API R-18대로 `POST /couple/import`는 `NOT_COUPLE`을 주지 않는다. 해제와 겹치면 409 `NO_IMPORT_PENDING`이다. 이때 앱 동작은 3.3 |
| Android "acknowledgedSpaceId", API 4.4 "기기에 저장된 값" | API에서는 "기기에 저장한 확인한 공간 ID"라고 쓰고 앱 내부 이름은 쓰지 않는다 (3.3) |
| 날짜 서식 두 가지 | 화면의 날짜(가입일·연결한 날·"[처음 만난 날]부터 함께하고 있어요")는 "2026년 10월 12일"(연·월·일, 요일 없음, 앞자리 0 없음, 기기 시간대). 상대 일정 추가 알림 본문은 "10월 17일 (토)"(D-92, 받는 사람의 `users.time_zone`). 섞지 않는다 |

## 1. 바뀐 ID

| ID | 변경 | 내용 |
| --- | --- | --- |
| FR-AUTH-04 | 수정 (AC2) | 게스트가 누르는 "커플 연결 메뉴"에 전체 메뉴의 [상대와 연결하기]와 연결 정보 행을 포함 (Android 17) |
| FR-COUPLE-01 | 수정 (AC1), 추가 (AC6) | AC1: 공유·복사는 코드 6자리만, "복사됨" (D-102). AC6: 코드를 받기 전 빈 칸, 오프라인 안내 (D-95) |
| FR-COUPLE-02 | 수정 (AC2~AC5), 표 추가 | 오류 문구 표 6줄(D-95). AC5: 오프라인이면 5초 확인은 조용히 건너뛰고 [연결 확인하기]는 오프라인 안내 |
| FR-COUPLE-03 | 수정 (AC1, AC2), 추가 (AC6) | 혼자 쓴 기록 종류별 개수 문구와 다이얼로그 본문 (D-93, Q-13). AC6: 기록이 없어도 닫기 전 앱을 끄면 다음 실행 때 시트 (D-98) |
| FR-COUPLE-04 | 추가 (AC4, AC5) | AC4: 시트의 처음 만난 날 칸 동작 (D-98). AC5: 처음 만난 날 없는 커플의 전체 메뉴 (D-99) |
| FR-COUPLE-05 | 수정 (AC3), 추가 (AC5) | AC3: "재시작"의 뜻 (D-103). AC5: 처음 만난 날·우리 색상 저장의 `NOT_COUPLE`도 초기화 (D-103) |
| FR-CAL-02 | 수정 (AC1) | 제목 앞뒤 공백 제거, 공백만이면 제목 없음 (D-89) |
| FR-CAL-04 | 수정 (AC2), 추가 (AC7) | AC2: [완료]에서 바뀐 색만 저장, 뒤로 가면 버림 (D-100). AC7: 기본 색으로 되돌리기 값 (D-101) |
| FR-CAL-05 | 수정 (AC4), 추가 (AC5, AC6) | AC4: 다시 보내기, 종일↔시간 전환 시 "없음" (D-91). AC5: 알림 시각 계산과 지난 시각 (D-90). AC6: 시간대 변경 (D-91) |
| FR-SET-01 | 수정 (AC1) | 커플 항목에 "연결한 날(D-94)" |
| SCR-COUPLE-01 | 수정 (5장 비고) | 앞 화면이 없는 진입에서는 뒤로 버튼 없음 (D-96) |
| SCR-COUPLE-02, SCR-COUPLE-03 | 수정 (5장 진입) | 진입에 "SCR-SET-01 연결 정보(혼자 사용 중)" (D-97). SCR-COUPLE-03 비고에 D-95 |
| SCR-COUPLE-04 | 수정 (5장 비고) | 기록 가져오기 선택과 종류별 개수 (D-93) |
| (8장 알림 문구) | 추가 (문단) | 상대 일정 추가의 [날짜] 서식 (D-92) |
| D-89 ~ D-103 | 추가 | 10장. 내용은 PRD 그대로. D-102만 "기본값", 나머지는 "확정" |
| Q-13 | 추가 | 0개인 종류도 보여주나. 기본값: 세 종류 모두 보여줌 |
| (11장 머리 문장) | 수정 | "Q-11, Q-12, Q-13은 기본값으로 구현한다" |

## 2. 문서별 할 일

| 문서 | 담당 | 할 일 |
| --- | --- | --- |
| docs/ERD.md (+ ERD.png) | data | 헤더 PRD v0.9. **`spaces.linked_at` 컬럼 추가**(3.2: 정의, CHECK 2개, 기존 행 채우기), 4.1 "커플 연결"과 4.2 "복구" 줄에 `linked_at` = 지금. 새 결정 **DB-17**(3.2). `events.updated_by` 설명(3.1 "Event" 아래), `event_reminders.fire_at`·`sent_at` 설명(3.1 "알림 시각 계산"·"다시 계산"), 4.1 "커플 연결 때 개인 공간 처리"에 `importCounts`는 대기 공간의 행 수를 세며 저장하지 않는다는 한 줄. 6장 추적표에 D-90·D-91·D-94 줄. ERD.png는 `spaces`에 칸이 늘었으므로 `docs/erd/erd.html`을 고치고 `npm run render:erd`로 다시 만든다 |
| docs/API.md | api | 헤더 PRD v0.9 (작성일 줄에 갱신 2026-10-31). 3장 "이름 확정"의 API 몫을 모두 반영: 1장 머리말 7행(3.3 일정도 이 문서에서 정한다), 2장 R-13 문구(3.1), 3.1 `MeSpace`에 `importCounts`·`linkedAt`(3.2), 3.2 `Space.linkedAt`과 팔레트 키 아래 앱 동작(3.3), **3.3을 "일정" 표(새 "요청 → 성공" 형식)와 "기념일" 표(기존 그대로)로 나누고** `Event`·`EventReminder` 정의, 조회 규칙, 쓰기 규칙, 검사 순서, `option`, 알림 시각 계산·다시 계산(3.1), 4.4의 6·8·9·10단계(3.2, 3.3), 4.5의 1·6단계(3.3), 5장 `VALIDATION_FAILED`·`DATE_OUT_OF_RANGE`·`NOT_COUPLE`·`NO_IMPORT_PENDING`·`ALREADY_COUPLED`·`GUEST_NOT_ALLOWED` "언제" 열(3.1, 3.3), 6장 한 줄(3.1), 7장 일정 알림·상대 활동 알림 줄(3.1), 9장 추적표 줄 |
| docs/SCREENS.md | screen | 헤더 PRD v0.9 (갱신 줄). 3.4의 화면별 항목 반영: SCR-CAL-02·03, SCR-COUPLE-01~04, 처음 만난 날 선택 시트, SCR-NOTI-01, SCR-SET-01(프로필 카드·연결 정보·게스트 행), SCR-SET-03. 요청서로 그릴 상태는 "디자인: 변경 요청됨 (PRD v0.9)"과 `이미지 예정 <이름>`(3.6)으로 표시 |
| design/design-system.md | screen | 갱신 줄 추가. 3.5의 컴포넌트 수치를 v0.8 3.10처럼 보드 행 번호를 붙여 표로 적는다. **토큰 값은 바꾸지 않는다.** "Android 매핑"에 모르는 팔레트 키 처리 한 줄(3.3) |
| 디자인 변경 요청서 | screen | 있음: `design/change-requests/prd-v0.9.md` (3.6). 새 상태 6개를 그리고 보드 1개를 정리한다. 새 토큰·새 화면 ID 없음 |

## 3. 이름 확정

### 3.1 일정 API (API.md 3.3, 서버 1~13)

모든 경로는 `/api/v1` 아래. "요청 → 성공" 형식은 3.1·3.2와 같다. `?`는 선택 필드다.

| 메서드 | 경로 | 요청 → 성공 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /events?from=&to= | → 200 `{items: Event[]}` (페이지 없음, 1.1) | R-01, R-07, R-15 | FR-CAL-01, FR-CAL-01.AC6 |
| POST | /events | `{title, note?, isAllDay, start, end, isTogether?, notifyPartner?}` → 201 `Event` (`reminder`는 항상 null, D-59) | R-01, R-10, R-15 | FR-CAL-02, FR-NOTI-04, FR-CAL-01.AC6 |
| GET | /events/{id} | → 200 `Event` | R-01, R-07 | FR-CAL-03 |
| PATCH | /events/{id} | `{title?, note?, isAllDay?, start?, end?, isTogether?}` → 200 `Event` | R-01, R-02, R-13, R-10, R-15 | FR-CAL-03, FR-CAL-05.AC4, FR-CAL-01.AC6 |
| DELETE | /events/{id} | 본문 없음 → 204 | R-01, R-02 | FR-CAL-03 |
| PUT | /events/{id}/reminder | `{option}` → 200 `Event` (바뀐 `reminder` 포함) | R-01, R-07 | FR-CAL-05 |
| DELETE | /events/{id}/reminder | 본문 없음 → 204. **알림이 없어도 204** (멱등, 서버 11) | R-01, R-07 | FR-CAL-05 |

- **리드 결정**: 서버 1 추천안은 `PUT reminder`를 "200 `Event`(앱이 다시 그릴 수 있게) 또는 204"로 적었다. 이유가 붙은 앞쪽인 200 `Event`로 정한다.
- 기존 3.3의 `PATCH`·`DELETE` 권한 칸에 R-01을 더한다 (서버 9). `GET /events/{id}`에는 R-07을 더한다.

`Event` (응답 본문. 1.1대로 값이 없으면 `null`)

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `id` | uuid | |
| `title` | string | 앞뒤 공백을 지운 값 (D-89) |
| `note` | string \| null | 일정 메모 |
| `isAllDay` | boolean | |
| `start` | 날짜 \| 일시 | 종일이면 `YYYY-MM-DD`(`start_date`), 아니면 ISO 8601 UTC 일시(`start_at`) |
| `end` | 날짜 \| 일시 | `start`와 같은 규칙(`end_date` / `end_at`) |
| `isTogether` | boolean | |
| `authorId` | uuid | 작성자. 닉네임은 응답에 넣지 않는다. 앱이 `GET /me`의 `MeSpace`나 `GET /space`의 `members`에서 이 ID로 찾는다 (FR-CAL-03.AC3, 0.3). 활성 공간 일정의 작성자는 늘 그 공간의 구성원이다(구성원이 탈퇴하면 공간이 해제돼 활성 공간이 아니게 된다) |
| `updatedBy` | uuid \| null | 마지막 수정자. 만든 뒤 수정한 적이 없으면 `null` (서버 13) |
| `reminder` | `EventReminder` \| null | **요청자 자신의** 알림만 (R-07). 없으면 `null` |
| `createdAt`, `updatedAt` | 일시 | |

`EventReminder`: `option`(string, 아래 6개 중 하나), `fireAt`(일시. 이미 지난 시각일 수 있다, D-90). `sent_at`은 내보내지 않는다.

**조회 규칙** (`GET /events`, 서버 3)

| 항목 | 규칙 |
| --- | --- |
| 쿼리 | `from`, `to` 모두 필수, `YYYY-MM-DD`. `to`는 포함한다 |
| 오류 | 없으면 400 `VALIDATION_FAILED`(`from`/`to`, `REQUIRED`), 날짜 형식이 아니면 (`from`/`to`, `INVALID`), `from` > `to`이면 (`to`, `INVALID`), `to` > `from` + 3개월(달력 월로 더함, `from.plusMonths(3)`)이면 (`to`, `INVALID`) |
| 검사와 잘라내기 | 위 검사는 요청받은 값 그대로 먼저 하고, 그 뒤 1950-01-01 ~ 2050-12-31로 잘라낸다. 잘라낸 구간이 비면 `{items: []}` (R-15 기존) |
| 걸치는 일정 | 범위에 하루라도 걸치는 일정. 종일: `start_date <= to AND end_date >= from`. 시간 일정: 요청자 `users.time_zone` 기준 `from` 00:00 ~ `to` 다음 날 00:00을 UTC로 바꿔 `start_at < 끝 AND end_at >= 시작` |
| 정렬 | 시작 날짜(종일은 `start_date`, 시간 일정은 요청자 시간대로 바꾼 `start_at`의 날짜) 오름차순 → 같은 날이면 종일 먼저 → 시간 일정은 `start_at` → `id`. 화면의 날짜 목록 순서(FR-CAL-01 AC2)는 앱이 맞춘다 |
| 5장 | `VALIDATION_FAILED` "언제" 열의 "날짜 범위 조회에서 `from` > `to`이거나 범위가 3개월 초과 (`GET /memos/dated`)"에 `GET /events`를 더하고, `from`·`to` 없음·형식 오류(`REQUIRED`·`INVALID`)도 적는다 |

**쓰기 규칙** (`POST`·`PATCH /events`, 서버 2)

| 항목 | 규칙 |
| --- | --- |
| `POST` 필수 | `title`, `isAllDay`, `start`, `end`. 없거나 `null`이면 400 `VALIDATION_FAILED`(해당 필드, `REQUIRED`) |
| `POST` 선택 | `note` 생략·`null` → null. `isTogether` 생략 → false. `notifyPartner` 생략 → true. **리드 보충**: `isTogether`·`notifyPartner`에 `null`을 보내면 `REQUIRED` (`PATCH /me`의 `null` 규칙과 같게) |
| `PATCH` | 부분 수정: 없는 필드는 바꾸지 않는다. `note: null`이면 일정 메모를 지운다. 그 밖의 필드에 `null`을 보내면 `REQUIRED`. `notifyPartner`는 받지 않는다(무시, 수정은 알리지 않음) |
| 제목 (D-89) | 앞뒤 공백을 지운 값으로 저장. 지운 뒤 빈 값이면 (`title`, `REQUIRED`), 코드 포인트 50개 초과면 (`title`, `TOO_LONG`) — 길이는 지운 뒤 센다 |
| 일정 메모 | 코드 포인트 1000개 초과면 (`note`, `TOO_LONG`) |
| 종일·시간 짝 | `isAllDay = true`면 `start`·`end`가 `YYYY-MM-DD`, `false`면 1장의 UTC 일시. 맞지 않으면 (`start` 또는 `end`, `INVALID`). `PATCH`에서 `isAllDay`를 바꾸면 `start`·`end`를 같은 요청에 함께 보내야 하고 빠지면 (빠진 필드, `REQUIRED`). `isAllDay`가 없는 `PATCH`의 `start`·`end`는 저장된 종류에 맞아야 한다 |
| 순서 | 종료가 시작보다 이르면 (`end`, `INVALID`). 같으면 저장한다 |
| 날짜 범위 (R-15) | `start`·`end` 각각 400 `DATE_OUT_OF_RANGE`(`start`/`end`, `OUT_OF_RANGE`). 둘 다 밖이면 둘 다 담는다. **리드 보충**: `VALIDATION_FAILED`가 하나라도 있으면 그것만 응답하고 `DATE_OUT_OF_RANGE`는 그 뒤에 본다 (한 응답에 두 코드를 섞지 않음) |
| 모르는 필드 | 무시한다. 대상 사용자 필드(`targetUserId` 등)도 무시라 효과가 없다 (R-10, DB-06) |
| `details.fields` | 틀린 필드를 모두 담는다 |

**검사 순서** (서버 9, 단위 2의 R-08 → 400 순서와 같음)

`PATCH /events/{id}`: R-01(404 `NOT_FOUND`) → R-02(403 `NOT_AUTHOR`) → R-13(403 `NOT_AUTHOR`) → R-10(400 `INVALID_TARGET`) → 값 검사(400 `VALIDATION_FAILED`) → 날짜 범위(400 `DATE_OUT_OF_RANGE`). `DELETE`: R-01 → R-02. `POST`: R-10 → 값 검사 → 날짜 범위. `PUT`·`DELETE reminder`: R-01 → 값 검사. 권한 없는 사용자에게 필드 오류를 보여주지 않는다. **리드 보충**: `isTogether`가 boolean이 아니면 R-13·R-10은 건너뛰고 값 검사에서 (`isTogether`, `INVALID`).

**R-13 문구** (API 2장, 서버 10): 규칙 끝에 "바꾸는 요청인지는 요청의 `isTogether`를 저장된 값과 비교해 정한다. 같은 값을 보내면 바꾸지 않는 요청이라 R-02만 적용한다"를 더한다.

**일정 알림 `option`** (서버 4)

| 일정 종류 | 값 (ERD `ck_event_reminders_option` 그대로) | 화면 |
| --- | --- | --- |
| 시간 일정 | `AT_TIME`, `MIN_10`, `HOUR_1`, `DAY_1` | 정시, 10분 전, 1시간 전, 1일 전 |
| 종일 일정 | `ALLDAY_9AM`, `ALLDAY_PREV_9AM` | 당일 오전 9시, 1일 전 오전 9시 |

- 일정 종류와 맞지 않거나 모르는 값: 400 `VALIDATION_FAILED`(`option`, `INVALID`). 없거나 `null`: (`option`, `REQUIRED`).
- "없음"은 `DELETE /events/{id}/reminder`뿐이다. `NONE` 같은 값은 없다.
- `PUT`은 멱등 upsert다(같은 사용자·일정에 행 하나, `uq_event_reminders_event_user`).

**알림 시각 계산** (D-90, 서버 5·12)

| `option` | `fire_at` |
| --- | --- |
| `AT_TIME` | `start_at` |
| `MIN_10` | `start_at` − 10분 |
| `HOUR_1` | `start_at` − 1시간 |
| `DAY_1` | `start_at` − 24시간 (서머타임이 있는 날도 24시간) |
| `ALLDAY_9AM` | `start_date` 09:00, **알림 주인**(`event_reminders.user_id`)의 `users.time_zone` 기준 → UTC |
| `ALLDAY_PREV_9AM` | (`start_date` − 1일) 09:00, 같은 시간대 기준 → UTC |

- 저장할 때(`PUT`, 아래 다시 계산 모두) 계산한 `fire_at` <= 지금이면 행은 저장하고 `sent_at` = 지금으로 기록해 보내지 않는다. 미래면 `sent_at` = null. 끝난 일정에도 `PUT`은 된다 (서버 12).
- ERD `event_reminders.fire_at` 설명에 위 계산 규칙(또는 "`API.md` 3.3")을, `sent_at` 설명에 "보냈거나, 저장할 때 이미 지난 시각이라 보내지 않기로 한 시각 (PRD D-90)"을 적는다.

**다시 계산** (D-91, 서버 6. 모두 같은 트랜잭션)

| 언제 | 처리 |
| --- | --- |
| `PATCH`로 `isAllDay`가 바뀜 | 그 일정의 `event_reminders`를 **모든 사용자 것** 삭제한다. 응답의 `reminder`는 null |
| `PATCH`로 `start`가 바뀜 (종류는 그대로) | 그 일정의 모든 행의 `fire_at`을 새 `start`로 다시 계산하고, `sent_at`은 위 규칙(지났으면 지금, 미래면 null)으로 다시 정한다. 이미 보낸 알림도 새 시각이 미래면 다시 보낸다 |
| `end`·제목·메모·대상만 바뀜 | 알림은 그대로 (`fire_at`은 시작 기준) |
| 사용자의 `time_zone`이 바뀜 (`PATCH /me`, 단위 1의 `UserTimeZoneChanged`) | 그 사용자의 행 중 `option`이 `ALLDAY_9AM`·`ALLDAY_PREV_9AM`이고 `sent_at IS NULL`인 것만 새 시간대로 다시 계산한다 (지났으면 `sent_at` = 지금). 시간 일정 알림은 그대로 |

**상대 일정 추가 알림** (API 7장 "상대 활동 알림" 줄, D-92, 서버 7)

- 제목 "[작성자 닉네임]님이 일정을 추가했어요", 본문 "[날짜] · [일정 제목]" (PRD 8장).
- [날짜]: 종일은 `start_date`, 시간 일정은 받는 사람(상대)의 `users.time_zone`으로 바꾼 `start_at`의 날짜. 서식 "M월 d일 (E)", 요일은 한국어 한 글자(월~일), 연도 없음, 앞자리 0 없음. 예: "10월 17일 (토) · 1박 2일 여행". 여러 날 일정도 시작 날짜만.
- 행: `type = PARTNER_CREATED`, `target_type = EVENT`, `target_id` = 일정 ID, `space_id` = 커플 공간 (기존). 개인 공간이거나 `notifyPartner = false`면 만들지 않는다.

**동기화 신호** (API 6장에 한 줄, 서버 8): "일정 알림(`PUT`·`DELETE /events/{id}/reminder`)은 요청자 본인의 값이라 동기화 신호를 보내지 않는다. `PATCH /events/{id}`가 다른 사용자의 알림을 지우거나 다시 계산해도 신호는 `EVENT`/`UPDATED` 하나다."

**ERD `events.updated_by`** (서버 13): 설명에 "생성 때 null, 수정할 때 수정자로 기록 (API `Event.updatedBy`)".

### 3.2 공간 응답에 더하는 필드 (서버 변경, Android 1·2)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 응답 필드 | `MeSpace.importCounts` | `ImportCounts` \| null. 가져오기 대기 중인 개인 공간(4.4의 5단계에서 남긴 공간)의 기록 개수. `importPending`이 false면 `null`. `MeSpace` 표에서 `importPending` 바로 다음 | FR-COUPLE-03.AC1·AC2, D-93 |
| 응답 모양 | `ImportCounts` | `events`(integer), `anniversaries`(integer, 직접 기념일 행 수. 자동 기념일은 저장하지 않으므로 세지 않음), `memos`(integer). 각각 0 이상이고 합은 1 이상(대기 공간은 기록이 있는 공간뿐) | D-93, Q-13 |
| 응답 필드 | `MeSpace.linkedAt` | 일시 \| null. 커플 공간이 연결된 시각. 유예 기간 안에 복구했으면 다시 연결한 시각. 개인 공간이면 `null`. `MeSpace` 표에서 `startDate` 바로 다음 | FR-SET-01.AC1, D-94 |
| 응답 필드 | `Space.linkedAt` | `MeSpace.linkedAt`과 같은 정의. `Space` 표에서 `startDate` 바로 다음 | D-94 |
| 변경 없음 | `MeSpace.importPending`, `CoupleJoinResult` | `importPending`은 boolean 그대로 둔다(객체로 바꾸지 않음, 앱 호환). `CoupleJoinResult`에는 개수를 넣지 않는다(앱은 연결 뒤 `GET /me`로 읽음) | |
| 테이블.컬럼 (새) | `spaces.linked_at` | `timestamptz` null. 설명 "커플 공간이 연결된 시각. 복구(FR-COUPLE-06)하면 다시 연결한 시각으로 바꾼다. API `MeSpace.linkedAt`·`Space.linkedAt`(연결한 날, PRD D-94)" | D-94 |
| CHECK | `spaces` | 기존 "`type = 'COUPLE'` 이거나 `start_date`, `together_color`, `unlinked_at`, `purge_at`이 모두 null"에 `linked_at`을 더한다. 새 CHECK: `type = 'PERSONAL' OR linked_at IS NOT NULL` (커플 공간은 늘 값이 있음) | D-94 |
| 수명주기 | ERD 4.1 "커플 연결 (복구 아님)", 4.2 복구 줄 | 연결: `linked_at` = 지금. 복구: `left_at`·`unlinked_at`·`purge_at`을 비울 때 `linked_at` = 지금. 해제·탈퇴 때는 그대로 둔다 | D-94 |
| ERD 결정 (새) | DB-17 | 결정: "연결한 날은 `spaces.linked_at`에 둔다. `space_members.joined_at`을 쓰지 않는다". 이유: "`joined_at`은 소속 행이 생긴 시각이라 복구 때 바뀌지 않고, 연결 시각은 공간 하나에 값 하나라 공간에 두는 것이 맞다 (PRD D-94)" (**리드 결정**: 저장 위치) | D-94 |
| 마이그레이션 | Server 새 Flyway 버전 | ① 컬럼 추가(null 허용) ② 기존 COUPLE 행을 `linked_at = created_at`으로 채움(출시 전, 개발 데이터만 있음. 복구된 개발 데이터는 처음 연결 시각이 됨) ③ 위 CHECK 2개 추가. 이미 머지된 V1·V2 파일은 고치지 않는다 | |
| ERD 4.1 한 줄 | 개수 | "`MeSpace.importCounts`는 대기 공간의 `events`, `anniversaries`, `memos` 행 수를 요청 때 센다. 저장하지 않는다" | D-93 |
| API 4.4 6·10단계 | 개수 | `importPending`이 true일 때 `GET /me`의 `importCounts`가 같은 공간의 개수라고 한 줄씩 | D-93 |

### 3.3 커플 쪽 앱 동작 (API.md 3.2·4.4·4.5·5장)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| API 3.2 팔레트 키 아래 (앱 동작) | 모르는 팔레트 키 | 앱은 12개 밖의 키를 받아도 오류로 보지 않는다. 값은 그대로 저장하고, 그릴 때 그 자리를 기본 사람 색 토큰(나 `person-me`, 상대 `person-partner`, 함께 `person-together`)으로 그리며 디버그 로그만 남긴다 (Android 18) | FR-CAL-04 |
| API 4.4 8단계 (앱 동작) | 다음 실행 때 시트 | "기기에 저장된 값"을 "기기에 저장한 확인한 공간 ID"로 고치고, 이 값은 사용자가 시트를 닫거나 [시작하기]를 마쳤을 때만 바꾼다고 적는다. 그래서 시트를 닫기 전에 앱을 끄면 기록이 없어도 다음 실행 때 다시 뜬다. 처음 로그인한 기기(값 없음)는 변화로 보지 않고 `importPending`만 본다 (Android 16, 결정 5) | FR-COUPLE-02.AC5, FR-COUPLE-03.AC6, D-98 |
| API 4.4 9단계 (앱 동작) | [시작하기] 순서 | ① 처음 만난 날을 골랐으면 `PATCH /space` ② 기록 선택이 있으면 `POST /couple/import` ③ 시트를 닫고 확인한 공간 ID를 저장. 되돌릴 수 없는 삭제를 마지막에 한다. 중간에 실패하면 거기서 멈추고 공통 오류(D-88), 시트는 그대로(다시 누르면 처음부터, 같은 날짜 `PATCH`는 무해). 처음 만난 날 칸의 [저장]은 서버를 부르지 않는다 (Android 7, 결정 2) | FR-COUPLE-04.AC4, D-98 |
| API 4.4 9단계 (앱 동작) | `NO_IMPORT_PENDING` | 이미 정한 것으로 보고 ③으로 간 뒤 `GET /me`를 다시 읽는다. 해제와 겹친 경우면 이 읽기에서 공간이 바뀐 것을 알고 4.5의 6단계 초기화로 이어진다 (**리드 보충**, 0.3) | FR-COUPLE-03, D-103 |
| API 4.5 1단계·5장 `NOT_COUPLE` | 다른 `NOT_COUPLE` | `DELETE /couple`뿐 아니라 `PATCH /space`, `PATCH /space/colors`의 409 `NOT_COUPLE`도 앱은 해제를 안 것으로 보고 6단계 초기화를 한다 (Android 15) | FR-COUPLE-05.AC5, D-103 |
| API 4.5 6단계 | "재시작"의 뜻 | "재시작"은 앱 프로세스를 끄지 않고, 토큰·소셜 SDK 상태는 두고 Room·설정을 지운 뒤 화면 이동 기록을 SCR-COUPLE-01 하나로 다시 만드는 것이다. 그 뒤 `GET /me`로 새 개인 공간을 채운다 | FR-COUPLE-05.AC3, D-103 |
| API 4.4 앱 동작 / 5장 `ALREADY_COUPLED`·`GUEST_NOT_ALLOWED` | 낡은 로컬 상태 | `POST /invite-codes`·`GET /invite-codes/current`·`POST /couple/join`이 409 `ALREADY_COUPLED`나 403 `GUEST_NOT_ALLOWED`를 주면 공통 오류를 보여준 뒤 `GET /me`를 다시 읽는다 (로컬이 낡은 경우. 공간이 바뀌었으면 시트·초기화로 이어짐). `VALIDATION_FAILED`(`code`)는 공통 오류 (**리드 보충**: 추천안은 "공통 오류 재사용"까지, `GET /me` 다시 읽기는 v0.8 `GUEST_ONLY` 선례) | D-95 |
| API 4.4 1단계 (앱 동작) | 읽기의 오프라인 | 첫 `GET /invite-codes/current`·`POST /invite-codes`가 오프라인이면 "인터넷 연결이 필요해요". 5초 `GET /me` 확인은 오프라인이면 안내 없이 건너뛴다. [연결 확인하기]는 "인터넷 연결이 필요해요" | FR-COUPLE-01.AC6, FR-COUPLE-02.AC5, D-95 |

### 3.4 화면 (SCREENS.md)

보드에만 있던 문구는 보드 그대로 옮긴다 (Android 12, v0.8 3.10과 같은 방식). 문구는 아래 따옴표 그대로. 줄바꿈은 `\n`으로 적은 곳만.

| 화면 | 항목 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| SCR-CAL-02 | 일정 알림 | 명세 설명 한 줄(화면 문구 아님, 새 안내 문구 없음): 알림 시각이 이미 지났으면 설정은 저장되지만 푸시는 오지 않는다 (D-90). 내 설정은 응답의 `reminder`로 보여준다 | FR-CAL-05, D-90 |
| SCR-CAL-03 | 제목·알림 | 제목은 앞뒤 공백을 지운 값이고 공백만 있으면 제목이 없는 것이다 (D-89). 수정에서 하루 종일을 바꿔 저장하면 내 알림(과 상대 알림)은 "없음"으로 돌아간다 (D-91) | FR-CAL-02.AC1, FR-CAL-05.AC4 |
| SCR-NOTI-01 | 상대 일정 추가 문구 | 본문 [날짜] 서식 D-92 (예 "10월 17일 (토) · 1박 2일 여행"은 그대로) | D-92 |
| SCR-COUPLE-01 | 뒤로 버튼 (D-96) | 앞 화면(전체 메뉴, 연결 정보, 프로필 카드)이 있으면 보이고 그 화면으로. 앞 화면이 없는 진입(회원 첫 로그인 직후, 해제 뒤 초기화 등)은 버튼 없음, 기기 뒤로 가기는 앱 닫기. 보드의 뒤로 링크(`Connect.dc.html` 20행 → `Main.dc.html`)는 따르지 않는다 | D-96 |
| SCR-COUPLE-01 | 보드 문구 | 설명 "둘 중 한 명이 초대코드를 만들고,\n다른 한 명이 입력하면 연결돼요.", 카드 부제 "코드를 만들어 상대에게 보내요"(만들기)·"상대에게 받은 코드를 입력해요"(입력하기), 게스트 안내 본문 "게스트는 상대와 연결할 수 없어요. Google이나 카카오로 로그인하면 지금까지 쓴 기록을 그대로 두고 연결할 수 있어요." | |
| SCR-COUPLE-02 | 진입 | SCR-COUPLE-01, SCR-SET-01 연결 정보(혼자 사용 중)의 [초대코드 만들기] (D-97) | D-97 |
| SCR-COUPLE-02 | 코드 받는 중 (D-95) | 코드를 받기 전에는 코드 칸 6개를 빈 칸으로 두고 문구·스피너는 없다. 코드가 없는 동안 [코드 복사]·[공유하기]는 비활성 (**리드 보충**). 오프라인이면 "인터넷 연결이 필요해요". 다시 들어오면 다시 받는다 (FR-COUPLE-01 AC5) — `이미지 예정 SCR-COUPLE-02--loading.png` | FR-COUPLE-01.AC6 |
| SCR-COUPLE-02 | 공유·복사 (D-102) | [공유하기]: 기기 공유 창(Android `ACTION_SEND`, `text/plain`)에 코드 6자리만. [코드 복사]: 클립보드에 코드, 버튼 이름 "복사됨"(`InviteCreate.dc.html` 96행)으로 바뀌고 새 코드를 받거나 화면을 떠나면 "코드 복사"로 돌아온다 | FR-COUPLE-01.AC1 |
| SCR-COUPLE-02 | 오프라인·오류 | 5초 확인은 오프라인이면 조용히 건너뜀, [연결 확인하기] 오프라인은 "인터넷 연결이 필요해요". `ALREADY_COUPLED`·`GUEST_NOT_ALLOWED`는 3.3 "낡은 로컬 상태" | D-95 |
| SCR-COUPLE-02 | 보드 문구 | 부제 "상대가 이 코드를 입력하면 바로 연결돼요.", 접근성 "내 초대코드"(코드 패널), "초대코드 [코드]"(코드 칸 묶음, 예 "초대코드 K7Q29X"), "연결 상태"(대기 카드) | |
| SCR-COUPLE-03 | 진입 | SCR-COUPLE-01, SCR-SET-01 연결 정보(혼자 사용 중)의 [받은 초대코드 입력하기] (D-97) | D-97 |
| SCR-COUPLE-03 | 오류 (D-95) | "오류 (각각 다른 문구, 디자인 없음)" 줄을 PRD FR-COUPLE-02 "초대코드 오류 문구" 표 6줄과 같은 문구로 바꾼다. 위치: 코드 칸 아래 한 줄, `danger-600` 글자 (SCR-CAL-03 오류와 같은 색 규칙, 크기·간격은 요청서로 그림). **리드 보충**: 코드 오류 문구는 코드를 고치면 사라진다. 입력 제한 문구의 [N]은 안내를 띄울 때 `retryAfterSeconds`를 분으로 올림(최소 1), 풀릴 때까지 [연결하고 시작하기] 비활성. 그 밖의 오류는 공통 오류, 오프라인은 "인터넷 연결이 필요해요"(스낵바) — `이미지 예정 SCR-COUPLE-03--error.png`, `SCR-COUPLE-03--rate-limited.png` | FR-COUPLE-02.AC2~AC4 |
| SCR-COUPLE-03 | 보드 문구 | 코드 칸 라벨 "초대코드" | |
| SCR-COUPLE-04 | 개수 (D-93) | "개수 안내"를 "일정 [N]개, 기념일 [N]개, 메모 [N]개가 있어요."(`Calendar.dc.html` 160행)로, [N]은 `MeSpace.importCounts`의 `events`·`anniversaries`·`memos`. 0개인 종류도 보여준다 (Q-13 기본값) | FR-COUPLE-03.AC1, Q-13 |
| SCR-COUPLE-04 | 다이얼로그 본문 (D-93) | "혼자 쓴 기록을 삭제할까요?" 다이얼로그 본문 "가져오지 않으면 혼자 쓴 일정 [N]개, 기념일 [N]개, 메모 [N]개가 삭제되고 되돌릴 수 없어요."(`Calendar.dc.html` 176행) | FR-COUPLE-03.AC2 |
| SCR-COUPLE-04 | 처음 만난 날 칸 (D-98) | 칸을 누르면 처음 만난 날 선택 시트가 위에 한 겹 더 뜨고 [저장]은 칸만 채운다. 서버 저장은 [시작하기](3.3 순서). [나중에 하기]는 고른 날짜를 비운다. `MeSpace.startDate`가 있으면 칸에 보여주고 [나중에 하기]는 숨긴다 — `이미지 예정 SCR-COUPLE-04--date-set.png` | FR-COUPLE-04.AC4 |
| SCR-COUPLE-04 | 다시 뜨는 조건 (D-98) | 진입 문장에 "기록이 없어도 시트를 닫기 전에 앱을 끄면 다음 실행 때 다시 떠요. 닫거나 [시작하기]를 누른 뒤에는 그 연결에 대해 다시 뜨지 않아요" | FR-COUPLE-03.AC6 |
| SCR-COUPLE-04 | 복구·요청 중 | 복구(`restored: true`)도 같은 시트·같은 문구(해제 뒤 새로 쓴 기록만 셈). 요청 중은 공통 "요청 중" 규칙([시작하기] 비활성) | FR-COUPLE-06.AC2 |
| SCR-COUPLE-04 | 보드 문구 | 카드 부제 "함께 쓰는 캘린더와 메모로 옮겨요"(가져오기)·"혼자 쓴 기록은 삭제돼요"(가져오지 않기), 접근성 "혼자 쓴 기록 가져오기"(선택 묶음), "닫기"(기록 없음 상태의 닫기 버튼) | |
| 처음 만난 날 선택 시트 | 연도·월 선택 | SCR-SET-01 소속 시트의 "연·월 제목을 누르면 연도·월 선택"은 보드에 없다(`StartDateSheet.dc.html` 27행은 ⌄ 버튼만). 요청서 3으로 그린다 — `이미지 예정 SCR-SET-01--start-date-sheet-year-month.png`. 그때까지 구현은 Android가 정한다(문서 밖) | Android 6 |
| SCR-SET-01 프로필 카드 | 문구·형식 | "[처음 만난 날]부터 함께하고 있어요"의 날짜는 "2026년 10월 12일" 형식(0.3). 혼자·게스트 "아직 없음" | FR-SET-01 |
| SCR-SET-01 프로필 카드 | 처음 만난 날 없는 커플 (D-99) | D+N과 "[처음 만난 날]부터 함께하고 있어요" 줄을 숨기고 [처음 만난 날 수정]은 그대로 — `이미지 예정 SCR-SET-01--no-start-date.png` | FR-COUPLE-04.AC5 |
| SCR-SET-01 연결 정보 | 연결한 날 (D-94) | 값은 `MeSpace.linkedAt`을 기기 시간대 날짜로 "2026년 10월 12일" 형식. 복구된 공간은 다시 연결한 날 | FR-SET-01.AC1 |
| SCR-SET-01 연결 정보 | 처음 만난 날 없음 (D-99) | 처음 만난 날·함께한 지 값을 보여주지 않는다. 행을 숨기는지 라벨만 남기는지는 요청서 5의 그림대로 — `이미지 예정 SCR-SET-01--couple-no-start-date.png` | FR-COUPLE-04.AC5 |
| SCR-SET-01 연결 정보 · 혼자 사용 중 (D-97) | 버튼 이동 | [초대코드 만들기] → SCR-COUPLE-02, [받은 초대코드 입력하기] → SCR-COUPLE-03. 보드(`ConnectionInfo.dc.html` 96~111행)의 화면 안 코드 패널("24시간 동안 유효 …", v0.3 값)과 `justDisconnected` 안내("연결을 해제했어요. 이제 혼자 사용하고 있어요.", 29행)는 쓰지 않는다 ("차이"로 기록, 요청서 6) | D-97, D-37 |
| SCR-SET-01 연결 정보 | 보드 문구 | 카드 제목 "연결 상태", 행 "함께 쓰는 것" 값 "캘린더 · 메모", 혼자 사용 중 소개문 "상대를 초대하면 캘린더와 메모를 함께 쓸 수 있어요.\n혼자 쓴 기록은 연결할 때 가져올지 고를 수 있어요." | |
| SCR-SET-01 | 게스트의 연결 정보 행 | 게스트가 누르면 SCR-COUPLE-01(게스트 모양, `SCR-COUPLE-01--guest.png`)으로 간다. [상대와 연결하기]와 같다 | FR-AUTH-04.AC2, D-07 |
| SCR-SET-01 | 접근성 문구 | "함께한 지 D+[N]"(프로필 카드 D-day), "현재 색상: 나, 상대, 함께"(우리 색상 행의 색 점) | |
| SCR-SET-03 | 저장 시점 (D-100) | 색을 누르면 미리보기만 바뀐다. [완료]에서 바뀐 필드만 `PATCH /space/colors` 한 번, 성공하면 닫는다. 바뀐 것이 없으면 요청하지 않고 닫는다. 실패면 공통 오류, 오프라인이면 "인터넷 연결이 필요해요", 둘 다 화면 그대로. 뒤로 가기는 저장하지 않고 닫는다(확인 없음). `NOT_COUPLE`은 3.3 초기화 | FR-CAL-04.AC2, D-103 |
| SCR-SET-03 | 되돌리기 (D-101) | [기본 색으로 되돌리기]는 화면에서 나 `pick-orange`, 상대 `pick-blue`, 함께 `pick-purple`(개인 공간은 나 `pick-orange`)로 바꾸고 저장은 [완료]에서 | FR-CAL-04.AC7 |
| SCR-SET-03 | 보드 문구·샘플 | 미리보기 제목 "미리보기", 샘플 일정 "치과 예약"(14:00)·"저녁 데이트"(19:30)·"선물 리스트 정리"("메모") — 문구는 보드 그대로, 한 주는 고정된 11~17일이 아니라 **오늘이 든 주**로 그린다 | |
| SCR-SET-03 | 같은 색 경고 | 이미지 없음, 보드 `hasDup` 상태(`ColorSettings.dc.html` 72~74행)를 가리킨다 (기존 문구 그대로) | FR-CAL-04.AC4 |

### 3.5 design-system.md 컴포넌트 수치 (Android 14)

토큰을 바꾸지 않고 보드 값을 컴포넌트 명세에 적는다. 아래 값은 Android가 보드에서 읽은 것이다. screen이 보드에서 다시 읽고 행 번호를 붙인다. **보드와 다르면 보드가 맞다.**

| 컴포넌트 (새 절) | 보드 | 값 |
| --- | --- | --- |
| 연결 방법 카드 (SCR-COUPLE-01) | `Connect.dc.html` | 두 원 그림 164×56(원 지름 52, 점선), 카드 최소 높이 136, 안쪽 20/22, 모서리 24, 카드 제목 20/700, 부제 14. 혼자 시작하기 행 높이 72, 모서리 20 |
| 초대코드 패널 (SCR-COUPLE-02) | `InviteCreate.dc.html` | 코드 칸 42×56, 글자 `code-lg`(26). 패널 안쪽 24/20/20, 모서리 24, 안쪽 간격 14. 상태 카드 안쪽 16/18, 모서리 18. 하단 버튼 높이 56(`size-button-lg`와 같음), 모서리 16 — **`radius-md`(14)와 다르다고 적고 토큰을 바꾸지 않는다**. 바닥 스낵바 위치 바닥에서 112 |
| 초대코드 입력 칸 (SCR-COUPLE-03) | `InviteEnter.dc.html` | 칸 높이 58, 폭은 나눠 채움(flex 1), 글자 `code-md`(24), 현재 칸 테두리 2px `brand-500` |
| 연결 완료 시트 (SCR-COUPLE-04) | `Calendar.dc.html` `linkedSheet` | 안쪽 위 10·좌우 24·아래 28, 위 모서리 24, 손잡이 36×4, 제목 22/700, 날짜 칸 높이 52·모서리 14, 선택 카드 테두리 2px `ink-900` |
| 처음 만난 날 선택 시트 (공용) | `StartDateSheet.dc.html` | 달력 행 높이 40, 날짜 원 36, 요일 머리 28 |
| 우리 색상 (SCR-SET-03) | `ColorSettings.dc.html` | 미리보기 패널 안쪽 16·모서리 20, 대상 카드 높이 112(개인 공간 64), 색 원 44, 선택 링 3 + 2, 아바타 28 |
| 프로필 카드·연결 상태 카드 (SCR-SET-01) | `Menu.dc.html`, `ConnectionInfo.dc.html` | 프로필 카드 안쪽 22/16/16·모서리 24·아바타 72·연필 배지 28. 연결 상태 카드 안쪽 24/16/20·아바타 56 |

- "Android 매핑"(또는 "사람 색" 절)에 한 줄: 모르는 팔레트 키는 기본 사람 색 토큰(`person-me`·`person-partner`·`person-together`)으로 그린다 (3.3).

### 3.6 디자인 변경 요청서 (`design/change-requests/prd-v0.9.md`)

이전 요청서 형식을 따른다. 상태 "요청됨". **새 토큰·새 화면 ID 없음.** 새 상태 보드를 만들 때 기존 컴포넌트와 토큰만 쓰고, 새 컴포넌트가 필요하면 먼저 묻게 한다. v0.8 요청서(`prd-v0.8.md`)가 아직 "요청됨"이므로, v0.9 요청서에 "v0.8 요청서를 먼저(또는 함께) 반영"이라고 적는다.

| # | 화면 (보드) | 할 일 | 이미지 |
| --- | --- | --- | --- |
| 1 | SCR-COUPLE-03 (`InviteEnter.dc.html` → 새 `InviteEnterError`, `InviteEnterRateLimited`) | 오류 문구를 코드 칸 아래 한 줄, `danger-600` 글자로(`AddEventError.dc.html`의 오류 표시 규칙). 예시는 "없는 코드예요. 코드를 다시 확인해 주세요."(6자리 입력, 버튼 활성). 입력 제한은 "코드를 너무 많이 틀렸어요. 12분 뒤에 다시 입력해 주세요."(샘플 12, 버튼 비활성). 칸 테두리를 오류 색으로 바꿀지 디자이너가 정해 알려 줌 | `SCR-COUPLE-03--error.png`, `SCR-COUPLE-03--rate-limited.png` |
| 2 | SCR-COUPLE-02 (`InviteCreate.dc.html` → 새 `InviteCreateLoading`) | 코드를 받기 전: 코드 칸 6개 빈 칸, 남은 시간 줄 없음 또는 그대로(디자이너가 정해 알려 줌), [코드 복사]·[공유하기] 비활성. 문구·스피너 없음 | `SCR-COUPLE-02--loading.png` |
| 3 | 처음 만난 날 선택 시트 (`StartDateSheet.dc.html` → 새 `StartDateSheetYearMonth`) | 연·월 제목(⌄)을 누른 뒤의 연도·월 선택 상태. 1950년 ~ 올해만, 미래 월 비활성(D-74, FR-COUPLE-04 AC3) | `SCR-SET-01--start-date-sheet-year-month.png` |
| 4 | SCR-COUPLE-04 (`CalendarLinkedSheet.dc.html` → 새 `CalendarLinkedSheetDate`) | 처음 만난 날 칸에 날짜가 들어간 상태("2026년 3월 14일" 같은 샘플), [나중에 하기] 없음 (D-98) | `SCR-COUPLE-04--date-set.png` |
| 5 | SCR-SET-01 (`Menu.dc.html` → 새 `MenuNoStartDate`, `ConnectionInfo.dc.html` → 새 `ConnectionInfoNoStartDate`) | 처음 만난 날이 없는 커플: 프로필 카드에 D+N·"…부터 함께하고 있어요" 줄 없음, [처음 만난 날 수정] 그대로. 연결 정보의 처음 만난 날·함께한 지 값 없음 — 행을 숨겼는지 라벨만 남겼는지 알려 줌 (D-99) | `SCR-SET-01--no-start-date.png`, `SCR-SET-01--couple-no-start-date.png` |
| 6 | SCR-SET-01 연결 정보 (`ConnectionInfo.dc.html`) | 혼자 사용 중의 화면 안 코드 패널("24시간 동안 유효 · 23시간 59분 남음", 96~111행)과 `justDisconnected` 안내(29행)를 보드에서 뺀다. 버튼 두 개만 남긴다 (D-97, D-37). 이전 모습은 "이전 버전" 줄로 | `SCR-SET-01--couple-solo.png` (바뀌었으면 다시) |

## 4. 위험 항목

- [x] DB 마이그레이션 필요: **있음.** `spaces.linked_at` 추가 + 기존 COUPLE 행 채우기 + CHECK 2개 (3.2). Server 새 Flyway 버전. 일정 쪽은 없음 (V1에 `events`, `event_reminders`, CHECK·인덱스가 모두 있다)
- [x] 데이터 삭제: `PATCH /events/{id}`로 종일 ↔ 시간을 바꾸면 그 일정의 **모든 사용자의** 일정 알림이 지워진다(상대의 설정도 상대 모르게 "없음"이 됨, D-91). [가져오지 않기] 다이얼로그에 지워질 개수가 나온다(D-93, 삭제 자체는 기존)
- [x] 권한 변경: 동작 변화는 없고 표기만 바뀐다. 일정 `PATCH`·`DELETE`에 R-01을 먼저 적용(404), R-13은 저장값과 비교해 판정, 검사 순서 R-01 → R-02 → R-13 → R-10 → 값 → 날짜 범위 (3.1)
- [x] 앱 호환성이 깨지는 API 변경: 깨지지 않는다(필드 추가만). 다만 **Server 단위 2가 이미 머지돼** `MeSpace.importCounts`·`linkedAt`, `Space.linkedAt`은 서버 후속 PR이 필요하고, Android 단위 3의 막힘 1·2는 그 PR까지 기다린다. Android Room `me` 스키마 버전이 오른다. 일정 API는 처음 정한다(Server·Android 구현 전). `PUT /events/{id}/reminder` 200 `Event`(리드 결정)
- [ ] 개인정보 처리 변경: 없음 (새로 받는 값 없음. 연결 시각은 서버가 정함)

## 5. 열린 질문

- **Q-13 (PRD)**: 혼자 쓴 기록 개수에서 0개인 종류도 보여주나. 기본값 "세 종류 모두 보여준다"(디자인 문구 그대로)로 진행한다. 바꾸려면 사용자가 알려 준다.
- **리드 결정·보충 확인** (추천안이 두 갈래였거나 빈 곳을 메운 것. 기본으로 진행하고 다르면 알려 주세요):
  1. `PUT /events/{id}/reminder` 성공은 200 `Event` (204 아님, 서버 1)
  2. 연결한 날 저장 위치는 새 컬럼 `spaces.linked_at` (DB-17), 개수는 `importPending`을 그대로 두고 `importCounts`를 더함 (Android 1·2)
  3. 일정 쓰기에서 `isTogether`·`notifyPartner`의 `null`은 `REQUIRED`, `VALIDATION_FAILED`를 `DATE_OUT_OF_RANGE`보다 먼저, `isTogether`가 boolean이 아니면 값 검사로 (서버 2·9)
  4. 초대코드 오류 문구는 코드를 고치면 사라짐, 입력 제한 [N]분은 올림·풀릴 때까지 버튼 비활성, 코드를 받기 전 [코드 복사]·[공유하기] 비활성 (Android 3)
  5. `ALREADY_COUPLED`·`GUEST_NOT_ALLOWED`는 공통 오류 + `GET /me` 다시 읽기, `NO_IMPORT_PENDING` 뒤에도 `GET /me` (Android 3·15)
- **참고 (이번 범위 밖, Server·Android 단위 6·7 전에 정할 것)**: PRD 8장 일정 알림 본문 "[알림 시점] · [시작 시각]"은 "1시간 뒤"와 종일 "오늘 · 하루 종일" 예시만 있다. 정시(`AT_TIME`), 1일 전(`DAY_1`), 1일 전 오전 9시(`ALLDAY_PREV_9AM`)의 [알림 시점] 문구가 없다. 이번에는 PRD를 바꾸지 않았다.

## 6. 문서 밖 결정 (참고, Docs를 고치지 않음)

| 출처 | 항목 | 정한 것 | 할 곳 |
| --- | --- | --- | --- |
| 서버 7 | `PARTNER_CREATED` 행을 만드는 단위 | Server 단위 3이 일정 생성 트랜잭션에서 행을 만들고 `EventCreated`에 알림 ID를 담는다. 푸시·SYNC·설정 확인은 단위 6 | Server 단위 3, `docs/PLAN.md` |
| 서버 8 | 일정 도메인 이벤트 | 단위 3은 `EventCreated`·`EventUpdated`·`EventDeleted` 발행(커밋 뒤 전달 테스트 포함)까지, 발송은 단위 6. reminder 변경은 이벤트 없음 | Server 단위 3 |
| 서버 결정 후보 | 패키지, `@RequestBody Map`, 잠금 순서, 테스트 픽스처 | Server 단위 3 "결정"대로 (규칙은 3.1이 기준) | Server 단위 3 |
| Android 1·2 | 서버 후속 PR | `importCounts`·`linkedAt`·`spaces.linked_at` 마이그레이션을 Server에서 만든다 (단위 3에 넣을지 별도 PR일지는 Server가 정함). Android는 그 전까지 개수 자리·연결한 날 행을 비워 둘 수 있다 | Server `docs/PLAN.md`, Android 단위 3 |
| Android 6 | 연도·월 선택 구현 시점 | 요청서 3이 그려질 때까지 연·월 제목 버튼의 동작은 Android가 정함 | Android 단위 3 |
| Android 8 | [내 프로필 수정]·연필 배지 | 단위 3은 그리지 않고 단위 8에서 더함 | Android 단위 3·8 |
| Android 결정 1~14 | 모듈·패키지·DataStore·시트 호스트 등 | Android 단위 3 "결정"대로 | Android 단위 3 |

## 7. 검수 기록

| 회차 | 판정 | Critical | 비고 |
| --- | --- | --- | --- |
