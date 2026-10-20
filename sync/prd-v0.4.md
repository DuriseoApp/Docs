# PRD v0.4 영향 분석

> 상태: PR 완료
> 이전 버전: v0.3 → 새 버전: v0.4
> 브랜치: sync/prd-v0.4
> PR: https://github.com/DuriseoApp/Docs/pull/2

이 파일은 `/prd-sync` 팀원들이 읽는 계약이다. 여기 적힌 이름과 할 일을 그대로 따른다. 이번 변경은 디자인 핸드오프(PR #1)에서 찾은 "PRD와의 차이" 10건을 사용자가 정한 결과다.

## 1. 바뀐 ID

| ID | 변경 | 내용 |
| --- | --- | --- |
| D-05 | 수정 | 초대코드 6자리(헷갈리는 글자 제외, 대소문자 구분 없음), 10분 유효, 재요청 1분 간격, 재요청 시 이전 코드 즉시 만료 |
| FR-COUPLE-01 | 수정 | AC1 6자리·10분, AC2 10분 만료, AC3 재요청(1분 간격, 이전 코드 만료), AC4 대소문자 구분 없음(추가) |
| D-19 | 수정 | 메모 항목: 제목, 본문, 메모 날짜(선택). 체크리스트 범위 밖 |
| FR-MEMO-04, D-22 | 삭제 | 체크리스트 기능 삭제 (범위 밖) |
| FR-MEMO-01 | 수정 | AC3 목록 항목에 체크리스트 진행 대신 메모 날짜(있으면) |
| FR-MEMO-02 | 수정 | AC1·2 체크리스트 제외, AC3 날짜 추가(기본 없음), AC4 날짜 있는 메모는 캘린더에도 표시 |
| FR-MEMO-03 | 수정 | AC1 수정 대상: 제목, 본문, 메모 날짜 |
| D-38 | 추가 | 메모 날짜(선택), 있으면 캘린더 그 날에 표시 |
| FR-CAL-01 | 수정 | AC2 날짜 있는 메모도 날짜 표시·목록에 포함(순서: 종일 일정·기념일 → 시간 일정 → 메모), AC4 알림 버튼 안 읽음 점(추가) |
| D-39 | 추가 | 알림 목록: 받은 알림 전부(푸시 끈 종류 포함), 30일 보관, 안 읽음 표시 |
| FR-NOTI-05 | 추가 | 알림 목록 (기록, 30일, 읽음 처리, 본인만) |
| SCR-NOTI-01 | 추가 | 알림 목록 화면 |
| Q-09 | 추가 | 연결 해제 시 그 공간의 알림 삭제 (기본값) |
| D-40 | 추가 | 용어 "사귄 날" → "처음 만난 날" (PRD 전체 치환) |
| D-41 | 추가 | 메모 검색, 읽음·NEW 표시, 직접 색 고르기는 범위 밖 |
| 권한 매트릭스 | 수정 | 체크리스트 체크 행 삭제, 메모 수정 행에 날짜 |
| 8장 알림 정책 | 수정 | 모든 알림은 알림 목록에 30일 남음 |
| NFR-SYNC-03, NFR-OFF-02, NFR-LIMIT-01 | 수정 | 체크 표시·체크리스트 제한 제거 |
| Q-06 | 수정 | 해결: 체크리스트 범위 밖 |
| 용어집, 3장, 5장 | 수정 | 위 내용 반영, SCR-COUPLE-02·SCR-MEMO-03·SCR-CAL-01 비고 수정 |

## 2. 문서별 할 일

| 문서 | 담당 | 할 일 |
| --- | --- | --- |
| docs/ERD.md (+ erd.html, ERD.png) | data | invite_codes 변경, memos.memo_date 추가, memo_checklist_items 삭제됨 표시, notifications 신규, notification 정리 작업, 연결 해제·탈퇴 처리에 알림 삭제 추가, "사귄 날" → "처음 만난 날", 추적표(FR-MEMO-04 삭제됨, FR-NOTI-05 추가), 새 DB- ID |
| docs/API.md | api | 초대코드 재요청 규칙·응답·오류, 코드 정규화, 메모 요청에서 checklist 제거·memoDate 추가, 날짜 범위 메모 조회, 체크리스트 API 삭제됨, 알림 목록 API, R-04 수정, R-12 추가, 알림 발송 7장에 목록 기록·정리, SYNC `NOTIFICATION`, 연결 해제 흐름에 알림 삭제, "사귄 날" → "처음 만난 날", 추적표 |
| docs/SCREENS.md | screen | 결정 반영, "PRD와의 차이" 표 정리(해결 표시), SCR-NOTI-01 추가, 디자인 상태 갱신 |
| 디자인 변경 요청서 | screen | 있음: `design/change-requests/prd-v0.4.md` (아래 3.4) |

## 3. 이름 확정

### 3.1 데이터 (ERD)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 컬럼 변경 | invite_codes.code | `char(6)` not null UNIQUE. 문자 집합: A–Z 중 O·I·L 제외 23자 + 숫자 2–9 8자 = 31자. 대문자로 저장 | D-05, FR-COUPLE-01 |
| 컬럼 설명 | invite_codes.expires_at | 생성 + 10분 | D-05 |
| 컬럼 설명 | invite_codes.revoked_at | 재요청으로 만료된 시각 | FR-COUPLE-01.AC3 |
| 규칙 | 재요청 간격 | 같은 `creator_user_id`의 가장 최근 `created_at` + 60초가 지나야 새 코드 발급. 새 컬럼 없음 | FR-COUPLE-01.AC3 |
| 컬럼 추가 | memos.memo_date | `date` null. 메모 날짜 (시간 없음, NFR-TIME-01처럼 시간대 없이 저장) | D-38, FR-MEMO-02 |
| 인덱스 추가 | memos | 부분 INDEX (space_id, memo_date) WHERE memo_date IS NOT NULL: 캘린더 날짜 범위 조회 | FR-CAL-01 |
| 서비스 규칙 | memos | 제목, 본문 중 하나 이상 필수 (체크리스트 제외) | FR-MEMO-02 |
| 테이블 삭제 | memo_checklist_items | "삭제됨 (PRD v0.4)" 표시. 테이블 정의는 지우고 한 줄 설명만 남김. erd.html·ERD.png에서도 카드 제거 | FR-MEMO-04, D-22 |
| 테이블 추가 | notifications | 아래 컬럼 | D-39, FR-NOTI-05 |
| ↳ | notifications.id | uuid PK | |
| ↳ | notifications.user_id | uuid not null, FK users ON DELETE CASCADE (받는 사람) | FR-NOTI-05.AC4 |
| ↳ | notifications.space_id | uuid null, FK spaces ON DELETE CASCADE. 콘텐츠 알림은 그 공간, 연결·해제 알림은 null | Q-09 |
| ↳ | notifications.type | varchar(30) not null. enum: `EVENT_REMINDER`, `PARTNER_CREATED`, `MEMO_PINNED`, `ANNIVERSARY`, `COUPLE_LINKED`, `COUPLE_UNLINKED` | 8장 |
| ↳ | notifications.title | varchar(100) not null (푸시 제목과 같음) | |
| ↳ | notifications.body | varchar(200) null (푸시 본문과 같음) | |
| ↳ | notifications.target_type | varchar(20) null. enum: `EVENT`, `MEMO`, `ANNIVERSARY`, `SETTINGS` (FR-NOTI-03의 이동 대상) | FR-NOTI-03 |
| ↳ | notifications.target_id | uuid null | |
| ↳ | notifications.read_at | timestamptz null. null이면 안 읽음 | FR-NOTI-05.AC3 |
| ↳ | notifications.created_at | timestamptz not null | |
| ↳ | 인덱스 | INDEX (user_id, created_at DESC), 부분 INDEX (user_id) WHERE read_at IS NULL | |
| 정리 작업 | 매일 03:00 KST | `created_at`이 30일 지난 notifications 삭제 | FR-NOTI-05.AC2 |
| 생명주기 | 연결 해제 | 해제한 공간의 `space_id`를 가진 notifications를 두 사람 모두 삭제 (그 뒤에 만드는 `COUPLE_UNLINKED` 알림은 space_id null) | Q-09 |
| 생명주기 | 탈퇴 익명화 | 탈퇴자의 notifications 삭제 (기존 삭제 목록에 추가) | NFR-PRIV-02 |
| 컬럼 설명 | spaces.start_date | 이름 그대로. 설명만 "처음 만난 날" | D-40 |
| 새 결정 ID | DB-07 | 알림 목록은 푸시와 별개로 저장하고 30일 뒤 삭제 | D-39 |
| 새 결정 ID | DB-08 | 초대코드 31자 집합 6자리(약 8.9억 조합) + 10분 만료 + 1시간 10회 오입력 제한으로 무차별 대입 방어 | D-05, NFR-SEC-03 |

### 3.2 API

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| API 변경 | POST /invite-codes | 초대코드 생성·재요청. 응답 `{code, expiresAt, reissueAvailableAt}`. 마지막 발급 후 60초 안이면 거부 | FR-COUPLE-01 |
| API 변경 | GET /invite-codes/current | 응답에 `reissueAvailableAt` 추가 | FR-COUPLE-01.AC3 |
| API 변경 | POST /couple/join | `{code}`는 공백 제거 후 대문자로 정규화해서 비교 | FR-COUPLE-01.AC4 |
| 오류 코드 | INVITE_REISSUE_TOO_SOON | 429. 응답에 `retryAfterSeconds` | FR-COUPLE-01.AC3 |
| 오류 코드 설명 | INVITE_USED | "이미 사용되었거나 재요청으로 만료된 코드" | |
| API 변경 | POST /memos | `{title, body, memoDate, notifyPartner}`. `memoDate`는 `YYYY-MM-DD` 또는 생략·null. `checklist` 제거 | FR-MEMO-02 |
| API 변경 | PATCH /memos/{id} | `{title, body, memoDate}`. `memoDate: null`이면 날짜 제거. 체크리스트 제거 | FR-MEMO-03 |
| API 변경 | GET /memos, GET /memos/pinned, GET /memos/{id} | 응답 항목에 `memoDate`. 체크리스트 진행 필드 제거 | FR-MEMO-01 |
| API 추가 | GET /memos/dated?from=&to= | 날짜 범위(최대 3개월)에 `memoDate`가 있는 메모. 캘린더용 | FR-CAL-01.AC2 |
| API 삭제 | PATCH /memos/{id}/checklist-items/{itemId} | "삭제됨 (PRD v0.4)" 표시 | FR-MEMO-04 |
| API 추가 | GET /notifications?cursor=&size= | 최근 30일 내 알림, 최신순. 항목 `{id, type, title, body, targetType, targetId, read, createdAt}`. 커서는 (created_at, id) | FR-NOTI-05.AC2 |
| API 추가 | GET /notifications/unread-count | `{count}`. 앱바 점 표시용 | FR-CAL-01.AC4 |
| API 추가 | PUT /notifications/{id}/read | 읽음 처리 | FR-NOTI-05.AC3 |
| 권한 규칙 수정 | R-04 | "메모 고정·해제: 공간 구성원이면 허용" (체크리스트 제거, 근거 D-21) | D-22 삭제 |
| 권한 규칙 추가 | R-12 | 알림 조회·읽음 처리: `notifications.user_id` = 요청자. 아니면 404 `NOT_FOUND` | FR-NOTI-05.AC4 |
| 동기화 신호 | SYNC `resource` | `NOTIFICATION` 추가. 알림 목록에 행이 생기면 받는 사람 본인 기기로 보냄(푸시를 끈 종류도). 앱은 안 읽음 개수를 다시 불러온다 | FR-CAL-01.AC4 |
| 알림 발송 | 7장 모든 작업 | 받는 사람마다 notifications 행을 먼저 만들고, 그 종류의 설정이 켜져 있을 때만 푸시. 연결·해제는 항상 푸시 | FR-NOTI-05.AC1 |
| 흐름 | 연결 해제 | 해제 처리 트랜잭션에서 그 공간의 notifications 삭제 | Q-09 |
| 문구 | R-08, /me, /space, SYNC SPACE 설명 | "사귄 날" → "처음 만난 날". 필드명 `startDate`는 그대로 | D-40 |

### 3.3 화면 (SCREENS)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 화면 추가 | SCR-NOTI-01 알림 목록 | 진입: SCR-CAL-01 앱바 알림 버튼. 최근 30일 알림 최신순, 항목: 종류 아이콘, 제목, 본문, 시각, 안 읽음 점. 누르면 읽음 + 관련 화면. 빈 상태 문구 필요 | FR-NOTI-05 |
| 화면 변경 | SCR-CAL-01 | 앱바 알림 버튼 유지(안 읽음 점 추가) → SCR-NOTI-01. 날짜 목록에 날짜 있는 메모(순서 맨 아래, "메모" 표시). 날짜 점에 메모 포함 | FR-CAL-01 |
| 화면 변경 | SCR-COUPLE-02 | 6칸, "10분 동안 유효 · N분 N초 남음", 재요청 버튼 "코드 새로 만들기"(1분 안에는 비활성 + "N초 뒤에 다시 만들 수 있어요") | FR-COUPLE-01 |
| 화면 변경 | SCR-COUPLE-03 | 6칸, 설명 "영문과 숫자 6자리예요", 소문자 입력 허용(대문자로 표시) | FR-COUPLE-01.AC4 |
| 화면 변경 | SCR-MEMO-01, SCR-MEMO-02 | 검색 버튼 제거, 읽음 표시·NEW 제거, 메모 행에 날짜(있으면) | D-41, FR-MEMO-01 |
| 화면 변경 | SCR-MEMO-04 | 날짜 행 기본 없음 → [날짜 추가] 버튼. 추가하면 날짜 행 + 제거 버튼. 체크리스트 없음 | FR-MEMO-02 |
| 화면 디자인 | SCR-MEMO-03 메모 상세 | 제목, 본문, 날짜(있으면), 작성자, 고정·즐겨찾기, 작성자에게만 수정·삭제 | FR-MEMO-03 |
| 화면 디자인 | SCR-CAL-02 일정 상세 | PRD 5장·FR-CAL-03·05 기준 | FR-CAL-03 |
| 화면 디자인 | SCR-SET-02 알림 설정 | 스위치 4개(일정 알림, 상대 일정·메모 추가, 메모 고정, 기념일) + 연결·해제는 끌 수 없다는 안내. 꺼도 알림 목록에는 남는다는 안내 | FR-NOTI-02, FR-NOTI-05 |
| 화면 변경 | SCR-SET-01 프로필 카드 | 게스트·혼자: 내 아바타 + 점선 원 "아직 없음" + [상대와 연결하기] → SCR-COUPLE-01(게스트면 연동 안내). D-day·처음 만난 날 영역과 [처음 만난 날 수정] 숨김 | 사용자 결정 |
| 화면 변경 | SCR-SET-03 | [직접 고르기] 제거 | D-41 |
| 화면 변경 | SCR-COUPLE-04, SCR-ANNIV-01 | "사귄 날" → "처음 만난 날" | D-40 |
| 유지 | SCR-START-01 | "공지사항" 칩 그대로 (사용자 결정) | — |

### 3.4 주요 문구

| 위치 | 문구 |
| --- | --- |
| 메모 작성 날짜 버튼 | 날짜 추가 |
| 초대코드 재요청 대기 | N초 뒤에 다시 만들 수 있어요 |
| 알림 목록 비었을 때 | 최근 30일 동안 받은 알림이 없어요 |
| 알림 설정 안내 | 꺼도 알림 목록에는 남아요 |
| 프로필 카드 연결 버튼 | 상대와 연결하기 |

## 4. 위험 항목

- [x] DB 마이그레이션 필요: `invite_codes.code` char(8)→char(6), `memos.memo_date` 추가, `memo_checklist_items` 삭제, `notifications` 신규. 출시 전이라 운영 데이터는 없음. Server 레포에 이미 마이그레이션 파일이 있으면 새 마이그레이션으로 처리
- [x] 데이터 삭제: 체크리스트 데이터 (출시 전, 실제 데이터 없음)
- [x] 권한 변경: R-04에서 체크리스트 체크 권한 제거, R-12 추가 (알림은 본인만)
- [x] 앱 호환성이 깨지는 API 변경: 메모 요청·응답에서 `checklist` 제거, 체크리스트 API 삭제, 초대코드 길이 변경. 앱 출시 전이라 영향 없음
- [x] 개인정보 처리 변경: 알림 목록에 일정·메모 제목이 30일 보관됨 → 개인정보처리방침(Q-03)에 보관 항목·기간 추가 필요

## 5. 열린 질문

- 없음 (Q-09는 기본값으로 진행)

## 6. 검수 기록

| 회차 | 판정 | Critical | 비고 |
| --- | --- | --- | --- |
| 1 | 수정 필요 | 1 | API: 연결 알림이 한 사람에게만 기록됨 (PRD 8장 위반). Minor 10건 (5건 수정, 6건은 PRD 수정 필요로 PR에 기록) |
| 2 | 통과 | 0 | Minor 1건 (만료·재요청 코드 오류 우선순위) PR에 기록 |
