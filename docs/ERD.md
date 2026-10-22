# 둘이서 ERD (MVP v0.1)

> 기준 문서: 둘이서 PRD v0.5 (`docs/PRD.md`)
> 함께 보는 문서: `ERD.png` (한눈에 보기, 원본 `erd/erd.html`), `API.md` (권한 규칙, API, 흐름)
> 작성일: 2026-10-17 (갱신: 2026-10-21)

이 문서는 둘이서 서버의 데이터 모델 단일 기준이다. PRD의 ID(FR, D, NFR, Q)를 그대로 참조하고, 이 문서에서 새로 정한 결정은 `DB-` 접두어를 쓴다. PRD와 충돌하면 PRD가 우선이다.

---

## 1. 설계 원칙

**모든 콘텐츠는 "공간(space)"에 속하고, 사용자는 항상 활성 공간 하나에 속한다.** 혼자 쓰기와 커플 쓰기를 같은 구조로 다루고, 권한 검사는 "요청자가 이 공간의 구성원인가" 하나로 시작한다 (PRD D-29).

| 원칙 | 내용 |
| --- | --- |
| DB | PostgreSQL 16, 마이그레이션은 Flyway (`db/migration/V{n}__{설명}.sql`) |
| 기본 키 | 모든 테이블 UUID (애플리케이션에서 UUIDv7 생성, 시간순 정렬 가능) |
| 시간 | 일시는 `timestamptz`(UTC), 종일 일정·기념일·처음 만난 날·메모 날짜는 `date` (NFR-TIME-01) |
| 사용자 시간대 | `users.time_zone`(IANA, 기본 `Asia/Seoul`)에 저장하고 앱 실행 시 갱신. 오전 9시 알림 계산에 쓴다 |
| 삭제 | 콘텐츠는 물리 삭제(hard delete). 보관이 필요한 것은 공간 단위(`spaces.purge_at`)와 사용자 익명화로만 다룬다 (4장) |
| 열거형 | `varchar` + `CHECK` 제약으로 저장한다 (PostgreSQL enum 타입은 변경이 어려워 쓰지 않음) |
| 공통 컬럼 | 모든 테이블에 `created_at`, 수정 가능한 테이블에 `updated_at` (`timestamptz not null default now()`) |
| 네이밍 | 테이블은 복수형 snake_case, FK는 `{단수}_id` |
| 자동 기념일 | 저장하지 않고 `spaces.start_date`로 그때그때 계산한다 (DB-01) |

---

## 2. 테이블 한눈에 보기

15개 테이블이 세 영역으로 나뉜다 (삭제된 `memo_checklist_items` 제외). 관계도는 `ERD.png`를 본다.

| 영역 | 테이블 | 역할 |
| --- | --- | --- |
| 계정 | users | 사용자 한 명 (게스트·회원) |
| | social_accounts | Google·Kakao 로그인 수단 |
| | auth_sessions | refresh 토큰 |
| | devices | FCM 푸시 토큰 |
| | notification_settings | 알림 종류별 켜기·끄기 |
| | notifications | 받은 알림 목록 (30일 보관) |
| 공간 | spaces | 개인 공간 또는 커플 공간 |
| | space_members | 사용자의 공간 소속 (활성 소속은 1개) |
| | invite_codes | 커플 연결용 초대코드 |
| | invite_code_attempts | 초대코드 오입력 기록 |
| 콘텐츠 | events | 일정 |
| | event_reminders | 사용자별 일정 알림 |
| | anniversaries | 직접 기념일 |
| | memos | 메모 (고정 핀 포함) |
| | memo_checklist_items | 삭제됨 (PRD v0.4) |
| | memo_favorites | 사용자별 즐겨찾기 |

---

## 3. 테이블 정의

표의 "제약"은 그대로 DDL이 되고, "서비스"로 표시된 규칙은 DB가 아니라 애플리케이션에서 검사한다.

### 3.1 계정

**users** — 사용자 한 명 (FR-AUTH)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| account_type | varchar(10) | not null, CHECK in (`GUEST`, `MEMBER`) | 게스트 연동 시 `MEMBER`로 변경 (FR-AUTH-03) |
| nickname | varchar(10) | not null | 게스트 기본값 "게스트", 회원은 소셜 프로필 이름. 소셜 이름이 10자가 넘으면 앞 10자만 쓴다 (FR-AUTH-07, PRD D-56, NFR-LIMIT-01) |
| profile_image_key | varchar(200) | null | 이미지 스토리지 객체 키. null이면 글자 아바타 (NFR-FILE-01) |
| time_zone | varchar(50) | not null, default `Asia/Seoul` | IANA 시간대 |
| deleted_at | timestamptz | null | 탈퇴 시각. 탈퇴하면 행을 지우지 않고 익명화한다 (4.3). 로그인 수단이 모두 지워져 다시 들어올 수 없다 |
| created_at, updated_at | timestamptz | not null | |

**social_accounts** — 회원의 소셜 로그인 수단 (FR-AUTH-02, 03)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| provider | varchar(10) | not null, CHECK in (`GOOGLE`, `KAKAO`) | |
| provider_user_id | varchar(100) | not null | 제공자의 고유 사용자 ID |
| created_at | timestamptz | not null | |

- UNIQUE (provider, provider_user_id): 한 소셜 계정은 한 사용자에게만 연결된다. 이미 쓰인 계정의 연동 거부(PRD Q-01)는 이 제약 위반으로 판정한다.
- UNIQUE (user_id, provider): 제공자별 하나씩.

**auth_sessions** — 서버가 발급한 refresh 토큰 (NFR-SEC-01)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| refresh_token_hash | char(64) | not null, UNIQUE | 토큰 원문이 아닌 SHA-256 해시만 저장 |
| expires_at | timestamptz | not null | 회원 30일, 게스트 365일. 토큰을 갱신할 때마다 같은 행의 `refresh_token_hash`, `expires_at`, `last_used_at`만 바꿔 새 토큰으로 교체하고 만료를 연장 (DB-02). 게스트 연동 뒤 첫 갱신부터 회원 만료(30일)를 쓴다 |
| last_used_at | timestamptz | not null | |
| revoked_at | timestamptz | null | 로그아웃, 다른 기기 로그인으로 끊길 때 기록. `revoked_reason`과 함께 기록한다. 토큰 교체는 행을 무효화하지 않으므로 기록하지 않는다 |
| revoked_reason | varchar(10) | null, CHECK in (`LOGOUT`, `REPLACED`, `WITHDRAWN`) | 무효가 된 이유. null이면 무효가 아님 (아래 표) |
| created_at | timestamptz | not null | |

| revoked_reason | 뜻 | 기록하는 시점 |
| --- | --- | --- |
| LOGOUT | 사용자가 로그아웃함 | 로그아웃 (FR-AUTH-05) |
| REPLACED | 다른 기기 로그인으로 끊김 | 로그인 2종 (DB-09, FR-AUTH-02.AC3) |
| WITHDRAWN | 탈퇴로 무효가 됨 | 탈퇴 (4.3) |

- 서비스: `revoked_at`과 `revoked_reason`은 항상 같이 기록한다 (둘 다 null이거나 둘 다 값이 있다). 유효한 세션 = `revoked_at IS NULL AND expires_at > now`
- 서비스: access 토큰의 `sid` 클레임이 이 테이블의 `id`다. 서버는 요청마다 그 세션이 무효인지 보고, `REPLACED`면 401 `SESSION_REPLACED`, 그 밖의 무효는 401 `SESSION_INVALID`로 나눠 답한다 (오류 코드와 검사 시점은 `API.md`). 그래서 `REPLACED` 행은 4.4 정리에서 `expires_at`까지 남겨 둔다 (DB-11)
- 서비스: refresh 토큰을 교체할 때는 새 행을 만들지 않고 같은 행의 `refresh_token_hash`, `expires_at`, `last_used_at`만 바꾼다. 그래서 `sid`(= `id`)는 로그인부터 로그아웃까지 변하지 않는다. 이전 refresh 토큰을 다시 보내면 그 해시를 가진 행이 없어 무효(401 `SESSION_INVALID`)다 (DB-02)
- 한 사용자가 동시에 가질 수 있는 유효한 세션은 하나다. 로그인 2종(게스트 시작, 소셜 로그인)을 하면 다른 유효 세션은 모두 `REPLACED`가 된다 (DB-09, PRD D-51)

**devices** — FCM 푸시 토큰 (NFR-SYNC-01)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| fcm_token | varchar(255) | not null, UNIQUE | 같은 토큰이 다른 사용자로 들어오면 그 사용자로 옮긴다 |
| platform | varchar(10) | not null, default `ANDROID` | iOS 대비 (PRD D-25) |
| updated_at | timestamptz | not null | |

- 서비스: 같은 토큰이 다른 사용자로 들어오면 그 사용자로 옮긴다
- 서비스: 로그인 2종(게스트 시작, 소셜 로그인)은 그 사용자의 `devices` 행을 모두 지운다. 새 기기는 로그인 뒤 `PUT /me/devices`로 다시 등록한다. 게스트 연동은 같은 기기라 지우지 않는다 (DB-09, PRD D-51)
- 서비스: 로그아웃은 그 사용자의 `devices` 행을 모두 지운다. 한 기기 규칙이라 사용자 전체 = 그 기기다 (DB-09, PRD D-50). 그래서 로그아웃한 기기에는 푸시가 가지 않는다
- 한 사용자의 유효한 세션이 하나이므로 `devices`도 사실상 한 행이다. 그래도 `user_id`에 UNIQUE를 걸지는 않는다 (등록과 삭제 사이에 잠깐 겹칠 수 있고, 위 서비스 규칙이 정리한다)

**notification_settings** — 알림 종류별 켜고 끄기 (FR-NOTI-02, PRD 8장)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| user_id | uuid | PK, FK users ON DELETE CASCADE | 사용자 생성 시 함께 만든다 |
| event_reminder | boolean | not null, default true | 내 일정 알림 |
| partner_created | boolean | not null, default true | 상대의 일정·메모 추가 알림 (PRD D-35) |
| memo_pinned | boolean | not null, default true | 상대의 메모 고정 알림 |
| anniversary | boolean | not null, default true | 기념일 당일 알림 |
| updated_at | timestamptz | not null | |

연결·해제 알림은 끌 수 없으므로 컬럼이 없다.

**notifications** — 받은 알림 목록 (FR-NOTI-05, PRD D-39, 8장)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | 받는 사람. 알림은 받는 사람 각자의 것이며 상대에게 보이지 않는다 (FR-NOTI-05.AC4) |
| space_id | uuid | null, FK spaces ON DELETE CASCADE | 콘텐츠 알림은 그 공간, 연결·해제 알림은 null (PRD D-45) |
| type | varchar(30) | not null, CHECK in (`EVENT_REMINDER`, `PARTNER_CREATED`, `MEMO_PINNED`, `ANNIVERSARY`, `COUPLE_LINKED`, `COUPLE_UNLINKED`) | PRD 8장 알림 종류 |
| title | varchar(100) | not null | 푸시 제목과 같음 |
| body | varchar(200) | null | 푸시 본문과 같음 |
| target_type | varchar(20) | null, CHECK in (`EVENT`, `MEMO`, `ANNIVERSARY`, `SETTINGS`) | 누르면 이동할 대상 (FR-NOTI-03) |
| target_id | uuid | null | `target_type`이 가리키는 행의 ID |
| read_at | timestamptz | null | 읽은 시각. null이면 안 읽음 (FR-NOTI-05.AC3) |
| created_at | timestamptz | not null | |

- INDEX (user_id, created_at DESC): 알림 목록 조회
- 부분 INDEX (user_id) WHERE read_at IS NULL: 안 읽음 점과 개수 조회 (FR-CAL-01.AC4)
- 서비스: 알림이 생기면 받는 사람마다 이 행을 먼저 만들고, 그 종류의 설정(`notification_settings`)이 켜져 있을 때만 푸시를 보낸다. 연결·해제 알림은 항상 푸시한다. 설정을 꺼도 행은 남는다 (DB-07)
- 서비스: 조회·읽음 처리는 `user_id`가 요청자일 때만. 아니면 404 (DB-05)
- `target_id`는 FK가 아니다. 대상 일정·메모가 삭제돼도 알림 기록은 30일까지 남는다
- `COUPLE_UNLINKED`는 상대가 해제했을 때와 상대가 탈퇴해 해제됐을 때 모두 쓴다. 타입과 컬럼은 같고 제목·본문만 다르다. 탈퇴 해제는 복구 안내가 없는 전용 문구를 쓰고, 문구는 `API.md`가 정한다 (PRD D-53, 8장)

### 3.2 공간

**spaces** — 개인 공간 또는 커플 공간 (PRD D-29)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| type | varchar(10) | not null, CHECK in (`PERSONAL`, `COUPLE`) | |
| status | varchar(10) | not null, default `ACTIVE`, CHECK in (`ACTIVE`, `UNLINKED`) | 개인 공간은 항상 `ACTIVE` |
| start_date | date | null | 처음 만난 날. 커플 공간만 (FR-COUPLE-04) |
| together_color | varchar(20) | null | '함께' 사람 색의 팔레트 키. 커플 공간만 (FR-CAL-04) |
| unlinked_at | timestamptz | null | 연결 해제 시각 |
| purge_at | timestamptz | null | 이 시각이 지나면 정리 작업이 공간을 삭제한다. 연결 해제 시 `unlinked_at` + 30일, 구성원이 탈퇴하면 탈퇴 시각 + 90일로 늦춘다 (PRD D-06, D-36) |
| created_at, updated_at | timestamptz | not null | |

- CHECK: `type = 'COUPLE'` 이거나 `start_date`, `together_color`, `unlinked_at`, `purge_at`이 모두 null
- CHECK: `(status = 'UNLINKED') = (unlinked_at IS NOT NULL AND purge_at IS NOT NULL)`
- 부분 INDEX (purge_at) WHERE purge_at IS NOT NULL: 정리 작업용
- 탈퇴한 구성원이 있는 UNLINKED 공간은 재연결 복구 대상이 아니다. 운영자만 DB에서 복구할 수 있다 (PRD D-36)

**space_members** — 사용자와 공간의 소속

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| space_id | uuid | not null, FK spaces ON DELETE CASCADE | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| color | varchar(20) | not null | 이 사용자의 사람 색 팔레트 키 (FR-CAL-04) |
| joined_at | timestamptz | not null | |
| left_at | timestamptz | null | 연결 해제나 기록 이동으로 공간을 떠난 시각 |

- UNIQUE (space_id, user_id)
- **부분 UNIQUE (user_id) WHERE left_at IS NULL**: 사용자는 동시에 활성 공간 하나에만 속한다. 이 제약이 "한 사람은 한 커플" 규칙을 DB에서 보장한다.
- 서비스: 커플 공간의 구성원은 정확히 2명, 개인 공간은 1명.
- 팔레트 키는 디자인 시스템의 `pick-*` 12색 토큰 이름을 그대로 쓴다. 기본값은 개인 공간·초대코드를 만든 사람 = 주황, 입력한 사람 = 파랑, 함께 = 보라 (FR-CAL-04.AC3, AC5).

**invite_codes** — 커플 연결용 초대코드 (FR-COUPLE-01, 02)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| code | char(6) | not null, UNIQUE | 문자 집합 31자: 영문 대문자 A–Z 중 O·I·L 제외 23자 + 숫자 2–9 8자. 대문자로 저장한다 (PRD D-05, FR-COUPLE-01) |
| creator_user_id | uuid | not null, FK users ON DELETE CASCADE | |
| expires_at | timestamptz | not null | 생성 + 10분 (PRD D-05) |
| used_at | timestamptz | null | |
| used_by_user_id | uuid | null, FK users ON DELETE SET NULL | |
| revoked_at | timestamptz | null | 재요청으로 만료된 시각 (FR-COUPLE-01.AC3) |
| created_at | timestamptz | not null | |

- 부분 UNIQUE (creator_user_id) WHERE used_at IS NULL AND revoked_at IS NULL: 사용자당 유효한 코드는 하나
- 서비스: 입력한 코드는 공백을 없애고 대문자로 바꾼 뒤 비교한다 (FR-COUPLE-01.AC4). 그래서 DB에는 대문자만 있다
- 서비스(재요청 간격): 같은 `creator_user_id`의 가장 최근 `created_at` + 60초가 지나야 새 코드를 발급한다. 새 컬럼은 없다 (FR-COUPLE-01.AC3)
- 서비스(재요청): 새 코드를 만드는 같은 트랜잭션에서, 그 사용자의 사용되지 않은(`used_at IS NULL`) 이전 코드 전부의 `revoked_at`을 기록한다. 시간이 지나 만료됐어도 `revoked_at`이 null이면 포함한다. 그래야 위 부분 UNIQUE와 충돌하지 않고, 이전 코드는 그 즉시 쓸 수 없다
- 무차별 대입 방어는 DB-08

**invite_code_attempts** — 초대코드 입력 시도 기록 (NFR-SEC-03)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| succeeded | boolean | not null | |
| attempted_at | timestamptz | not null | |

- INDEX (user_id, attempted_at): 최근 1시간 실패 횟수 조회. 7일 지난 기록은 정리 작업에서 삭제

### 3.3 콘텐츠

콘텐츠의 `author_id`, `updated_by`, `pinned_by` 같은 사용자 참조는 **ON DELETE RESTRICT**다. 탈퇴한 사용자는 행을 지우지 않고 익명화하므로(4.3) 참조가 깨지지 않는다. 사용자 행은 그를 참조하는 공간이 모두 삭제된 뒤 정리 작업이 지운다.

**events** — 일정 (FR-CAL)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| space_id | uuid | not null, FK spaces ON DELETE CASCADE | |
| author_id | uuid | not null, FK users RESTRICT | 작성자 (PRD D-12) |
| is_together | boolean | not null, default false | 일정 대상. false = 작성자 본인의 일정, true = 함께 (PRD D-34). 상대를 대상으로 지정할 수 없으므로 대상 사용자 컬럼이 없다 (DB-06) |
| title | varchar(50) | not null | |
| note | varchar(1000) | null | 일정 메모 (PRD D-13) |
| is_all_day | boolean | not null | |
| start_at, end_at | timestamptz | null | 시간 일정만 |
| start_date, end_date | date | null | 종일 일정만 |
| updated_by | uuid | null, FK users RESTRICT | 마지막 수정자 ('함께' 일정은 상대도 수정 가능) |
| created_at, updated_at | timestamptz | not null | |

- CHECK: 종일이면 `start_date`, `end_date`만 있고 `end_date >= start_date`, 아니면 `start_at`, `end_at`만 있고 `end_at >= start_at`
- INDEX (space_id, start_at), (space_id, start_date): 월 범위 조회. 여러 날 일정은 `start <= 범위끝 AND end >= 범위시작`으로 찾는다
- 서비스: 개인 공간에서는 `is_together = false`만 허용
- 화면 표시: `is_together = false`인 일정은 보는 사람이 작성자면 '나', 아니면 '상대'로 표시하고 그 사람의 사람 색을 쓴다

**event_reminders** — 사용자별 일정 알림 (PRD D-16, FR-CAL-05)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| event_id | uuid | not null, FK events ON DELETE CASCADE | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | 알림을 받을 사람 |
| option | varchar(20) | not null, CHECK in (`AT_TIME`, `MIN_10`, `HOUR_1`, `DAY_1`, `ALLDAY_9AM`, `ALLDAY_PREV_9AM`) | "없음"은 행이 없는 것 |
| fire_at | timestamptz | not null | 보낼 시각. 일정 일시나 사용자 시간대가 바뀌면 다시 계산 (FR-CAL-05.AC4) |
| sent_at | timestamptz | null | |
| created_at, updated_at | timestamptz | not null | |

- UNIQUE (event_id, user_id): 일정당 사용자별 하나
- 부분 INDEX (fire_at) WHERE sent_at IS NULL: 1분마다 도는 발송 작업용

**anniversaries** — 직접 기념일 (FR-ANNIV-03). 자동 기념일은 저장하지 않는다 (DB-01)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| space_id | uuid | not null, FK spaces ON DELETE CASCADE | |
| author_id | uuid | not null, FK users RESTRICT | |
| name | varchar(30) | not null | |
| date | date | not null | |
| repeats_yearly | boolean | not null, default true | |
| created_at, updated_at | timestamptz | not null | |

- INDEX (space_id)

**memos** — 메모 (FR-MEMO)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| space_id | uuid | not null, FK spaces ON DELETE CASCADE | |
| author_id | uuid | not null, FK users RESTRICT | |
| title | varchar(50) | null | |
| body | varchar(5000) | null | |
| memo_date | date | null | 메모 날짜(선택). 시간 없이 시간대 없는 날짜로 저장 (NFR-TIME-01, PRD D-38). 있으면 캘린더 그 날에도 보인다 (FR-MEMO-02.AC4) |
| pinned_at | timestamptz | null | 고정 시각. null이면 고정 안 됨 (PRD D-18, D-21) |
| pinned_by | uuid | null, FK users RESTRICT | |
| created_at, updated_at | timestamptz | not null | |

- INDEX (space_id, created_at DESC): 최신순·오래된순 목록
- 부분 INDEX (space_id, pinned_at DESC) WHERE pinned_at IS NOT NULL: 고정 영역, 최근 고정순
- 부분 INDEX (space_id, memo_date) WHERE memo_date IS NOT NULL: 캘린더 날짜 범위 조회 (FR-CAL-01)
- 서비스: 제목, 본문 중 하나 이상 필수 (FR-MEMO-02)

**memo_checklist_items** — 삭제됨 (PRD v0.4). 체크리스트가 범위 밖이 됨 (PRD D-19, FR-MEMO-04)

**memo_favorites** — 사용자별 즐겨찾기 (PRD D-24)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| memo_id | uuid | FK memos ON DELETE CASCADE | |
| user_id | uuid | FK users ON DELETE CASCADE | |
| created_at | timestamptz | not null | |

- PK (memo_id, user_id)

---

## 4. 데이터 수명주기

데이터가 바뀌는 시점별로 어떤 행이 생기고 지워지는지 정리한다. 요청 단위의 처리 순서는 `API.md` 4장을 본다.

### 4.1 생성

| 시점 | 만드는 행 |
| --- | --- |
| 게스트 시작, 신규 소셜 로그인 | users, notification_settings, spaces(PERSONAL), space_members(주황), auth_sessions |
| 로그인 2종 (게스트 시작, 소셜 로그인) | 새 auth_sessions. 같은 트랜잭션에서 다른 유효 세션과 devices를 정리한다 (4.6). 게스트 연동은 현재 세션을 그대로 쓰므로 새 행이 없다 |
| 커플 연결 (복구 아님) | spaces(COUPLE, 함께 = 보라), space_members 2개(만든 사람 주황, 입력한 사람 파랑) |
| 연결 해제 | 두 사람 각자 spaces(PERSONAL), space_members(주황) |
| 알림이 생길 때 (PRD 8장) | 받는 사람마다 notifications. 푸시 설정을 꺼도 만든다 (DB-07) |

### 4.2 연결 해제와 보관

- 커플 공간은 `status = UNLINKED`, `unlinked_at` = 해제 시각, `purge_at` = 해제 시각 + 30일 (PRD D-06)
- 두 구성원의 `space_members.left_at`을 기록하고, 그 공간의 `event_reminders`를 삭제한다
- 해제한 공간의 `space_id`를 가진 `notifications`를 두 사람 모두 삭제한다 (PRD D-45). 이 처리 뒤에 만드는 `COUPLE_UNLINKED` 알림은 `space_id`가 null이라 지워지지 않는다
- `purge_at` 전에 같은 두 사람이 다시 연결하면 공간을 ACTIVE로 되돌리고 `left_at`, `unlinked_at`, `purge_at`을 비운다 (FR-COUPLE-06)

### 4.3 탈퇴 (익명화)

1. 커플 공간에 있으면 4.2로 연결 해제한다.
2. 이 사용자가 속했던 UNLINKED 커플 공간의 `purge_at`을 탈퇴 시각 + 90일로 늦춘다. 이미 그보다 늦으면 그대로 둔다 (PRD D-36).
3. 개인 공간과 가져오기 대기 중인 개인 공간을 지운다. 콘텐츠는 CASCADE로 함께 지워진다.
4. 사용자를 익명화한다: `deleted_at` 기록, 닉네임 "탈퇴한 사용자", 프로필 사진 파일과 `profile_image_key` 삭제, `social_accounts`, `auth_sessions`, `devices`, `notification_settings`, `notifications`, `memo_favorites`, `event_reminders`, 유효한 `invite_codes` 삭제. `users` 행 자체는 남겨 보관 중인 커플 공간의 작성자 참조를 유지한다.
   - `auth_sessions`는 먼저 `revoked_reason = WITHDRAWN`으로 무효화한 뒤 같은 트랜잭션에서 지운다. 그래서 탈퇴 뒤에 남는 세션 행은 없다.

탈퇴로 해제될 때 상대에게는 탈퇴 전용 `COUPLE_UNLINKED` 알림이 간다 (PRD D-53). 이 알림은 `space_id`가 null이라 4.2의 알림 삭제에 지워지지 않는다. 문구는 `API.md`가 정한다.

### 4.4 매일 정리 작업 (03:00 KST)

- **게스트 정리** (PRD Q-11): `account_type = GUEST`, `deleted_at IS NULL`이고 유효한(`revoked_at IS NULL AND expires_at > now`) `auth_sessions`가 하나도 없는 사용자를 4.3 탈퇴와 같이 처리한다. 게스트는 커플이 될 수 없으므로 개인 공간만 지우면 된다. 마지막 사용 뒤 365일(DB-02)이 지나면 대상이 되고, 아래 세션 정리보다 먼저 돈다 (DB-10)
- `purge_at`이 지난 공간 삭제
- `deleted_at`이 있고 더 이상 어떤 공간에서도 참조되지 않는 사용자 행 삭제
- 7일 지난 `invite_code_attempts`, 30일 지난 사용·만료·무효 초대코드 삭제
- 만료된 `auth_sessions` 삭제. 무효화된 세션도 지우되 `REPLACED`는 `expires_at`이 지날 때까지 남긴다 (DB-11)
- `created_at`이 30일 지난 `notifications` 삭제 (FR-NOTI-05.AC2)

### 4.5 공간이 지워질 때 알림 (notifications.space_id CASCADE)

`notifications.space_id`는 `ON DELETE CASCADE`이므로 공간이 지워지면 그 공간의 알림도 30일이 되기 전에 함께 지워진다. 사라진 공간을 가리키는 알림을 남기지 않으려는 의도한 동작이고, 연결 해제 때 알림을 지우는 이유(PRD D-45)와 같다. 대상 일정·메모가 지워져도 알림 행은 지우지 않는다(`target_id`는 FK가 아님, PRD D-43).

- 커플 연결 뒤 개인 공간이 지워질 때(가져오지 않기를 고른 경우 포함): 그 개인 공간의 `space_id`를 가진 알림도 함께 지워진다.
- 탈퇴로 개인 공간이 지워질 때(4.3의 3단계): 그 개인 공간의 알림도 함께 지워진다. 사용자 본인의 알림은 4.3의 4단계에서도 지운다.
- `purge_at` 이후 정리 작업이 커플 공간을 지울 때도 같다 (4.4). 해제 시점에 이미 지웠으므로 남은 알림은 없다.
- 어떤 사용자도 참조하지 않는 프로필 사진 파일 삭제

### 4.6 로그인·로그아웃 시 세션과 기기 (한 기기 로그인)

한 계정은 한 기기에서만 로그인한다 (PRD D-51). 요청 단위의 처리 순서와 오류 응답은 `API.md`를 본다.

| 시점 | auth_sessions | devices |
| --- | --- | --- |
| 로그인 2종 (게스트 시작, 소셜 로그인) | 같은 트랜잭션에서 그 사용자의 다른 유효 세션을 모두 `revoked_at` = 지금, `revoked_reason = REPLACED`로 바꾸고 새 세션을 만든다 | 그 사용자의 행을 모두 지운다. 새 기기는 로그인 뒤 `PUT /me/devices`로 다시 등록한다 |
| 게스트 연동 (`/auth/link`) | 같은 기기라 현재 세션을 그대로 쓴다. 다른 세션을 끊지 않는다. 다음 토큰 갱신부터 회원 만료(30일) | 변화 없음 |
| 로그아웃 | 현재 세션을 `revoked_reason = LOGOUT`으로 바꾼다 | 그 사용자의 행을 모두 지운다 (PRD D-50) |
| refresh 토큰 갱신 | 새 행을 만들지 않고 같은 행의 `refresh_token_hash`, `expires_at`, `last_used_at`만 바꾼다. `sid`는 그대로다 (DB-02) | 변화 없음 |
| 탈퇴 | `WITHDRAWN`으로 무효화한 뒤 삭제 (4.3) | 삭제 (4.3) |

- 이전 기기는 `devices`가 지워져 푸시를 받지 않고, 다음 요청에서 세션이 `REPLACED`임을 알게 된다.
- 위 동작은 모두 한 트랜잭션 안에서 처리한다. 새 세션이 생겼는데 이전 기기의 푸시가 계속 가는 순간이 없어야 한다.

---

## 5. 설계 결정

| ID | 결정 | 이유 |
| --- | --- | --- |
| DB-01 | 자동 기념일은 저장하지 않고 처음 만난 날로 계산 | 처음 만난 날이 바뀌면 다시 계산만 하면 되고, 저장된 값과 어긋날 일이 없음 |
| DB-02 | refresh 토큰은 사용할 때마다 교체하되, 새 행을 만들지 않고 같은 `auth_sessions` 행의 `refresh_token_hash`, `expires_at`, `last_used_at`만 바꾼다 (v0.5 보완). 회원 30일, 게스트 365일 만료 | 게스트는 토큰을 잃으면 계정을 영영 잃으므로 길게 둠 (PRD D-02). 행이 같으면 `sid`가 변하지 않아 갱신과 겹친 요청이 끊기지 않고, 이전 토큰은 해시가 없어 무효가 됨 |
| DB-03 | MVP는 서버 인스턴스 1대를 가정 (스케줄러, 오입력 횟수 제한이 DB 기반) | 운영 단순화. 확장 시 분산 잠금 필요 |
| DB-04 | 탈퇴한 사용자는 익명화(soft delete)하고, 속했던 커플 공간은 90일 보관 후 삭제 | 버그로 인한 손실이 생겨도 운영자가 복구할 수 있도록 (PRD D-36). 익명화로 작성자 참조도 유지됨 |
| DB-05 | 다른 공간의 리소스 요청은 403이 아니라 404 | 리소스 존재 여부를 노출하지 않음 |
| DB-06 | 일정 대상은 `is_together` 불리언 하나로 저장 | 상대를 대상으로 지정할 수 없어(PRD D-34) 대상은 '작성자 본인' 또는 '함께' 둘뿐 |
| DB-07 | 알림 목록은 푸시와 별개로 저장하고 30일 뒤 삭제 | 푸시를 끈 종류도 목록에는 남기고(PRD D-39), 개인정보(일정·메모 제목) 보관을 30일로 제한 (NFR-PRIV-02, Q-03) |
| DB-08 | 초대코드는 31자 집합 6자리(약 8.9억 조합) + 10분 만료 + 1시간 10회 오입력 제한으로 무차별 대입을 막음 | 코드가 짧아진 만큼 유효 시간과 시도 횟수로 보완 (PRD D-05, NFR-SEC-03) |
| DB-09 | 한 기기 로그인: 로그인 2종(게스트 시작, 소셜 로그인)은 같은 트랜잭션에서 그 사용자의 다른 유효 세션을 `REPLACED`로 무효화하고 `devices`를 모두 지운다. 로그아웃은 현재 세션을 `LOGOUT`으로 바꾸고 `devices`를 모두 지운다. 무효가 된 이유는 `auth_sessions.revoked_reason`에 둔다 | 이전 기기와 로그아웃한 기기에 푸시가 가지 않게 하고(PRD D-50, D-51), 이전 기기가 "다른 기기에서 로그인해서 로그아웃됐어요"(`REPLACED`)와 그냥 무효를 구분하게 하려고 |
| DB-10 | 게스트 정리: 유효한 세션이 없는 게스트(`deleted_at IS NULL`)를 매일 정리 작업이 탈퇴와 같이 처리하고, 세션 정리보다 먼저 돈다 | 앱을 지운 게스트는 계정을 되찾을 수 없어 서버에 데이터만 남는다. 기본값은 마지막 사용 후 365일(PRD Q-11, DB-02). 같은 실행 안에서 세션 정리보다 먼저 돌도록 순서를 고정 |
| DB-11 | `REPLACED` 세션 행은 `expires_at`까지 남기고, 그 밖의 무효·만료 세션은 정리 작업이 지운다 | 이전 기기가 며칠 뒤에 접속해도 `SESSION_REPLACED` 안내를 받게 하려고. 지우면 일반 무효(`SESSION_INVALID`)로 보인다 |

---

## 6. PRD 추적표 (테이블)

| FR 영역 | 테이블 |
| --- | --- |
| FR-AUTH-01~05 | users, social_accounts, auth_sessions (revoked_reason), devices, notification_settings |
| FR-AUTH-06 탈퇴 | 모든 사용자 관련 테이블 (4.3) |
| FR-AUTH-07 프로필 | users.nickname (최대 10자), users.profile_image_key |
| FR-AUTH-08 이용 동의 | 테이블 없음 (앱) |
| FR-AUTH-09 앱 밖 계정 삭제 요청 | 테이블 없음 (웹 페이지와 메일 요청, 처리는 FR-AUTH-06과 같음) |
| FR-SET-02 정보 | 테이블 없음 (앱·웹) |
| FR-COUPLE-01~02, 06 | invite_codes (code, expires_at, revoked_at), invite_code_attempts, spaces, space_members |
| FR-COUPLE-03 | events, anniversaries, memos (space_id 이동) |
| FR-COUPLE-04 | spaces.start_date |
| FR-COUPLE-05 | spaces.status, unlinked_at, purge_at, space_members.left_at |
| FR-CAL-01~03 | events |
| FR-CAL-01 날짜 있는 메모 | memos.memo_date |
| FR-CAL-01.AC4 안 읽음 점 | notifications.read_at |
| FR-CAL-04 사람 색 | space_members.color, spaces.together_color |
| FR-CAL-05 일정 알림 | event_reminders |
| FR-ANNIV-01~04 | spaces.start_date(자동), anniversaries(직접) |
| FR-MEMO-01~03 | memos |
| FR-MEMO-02 메모 날짜 | memos.memo_date |
| FR-MEMO-04 | 삭제됨 (PRD v0.4) |
| FR-MEMO-05 | memos.pinned_at, pinned_by |
| FR-MEMO-06 | memo_favorites |
| FR-NOTI-01~03 | devices, notification_settings |
| FR-NOTI-05 알림 목록 | notifications |

---

## 7. 확인 사항 (모두 해결)

| ID | 질문 | 결과 |
| --- | --- | --- |
| Q-D1 | 탈퇴 시 커플 공간 데이터 처리 | 90일 보관 후 삭제 (PRD D-36, DB-04) |
| Q-D2 | 운영 서버 위치 | AWS 서울 리전. RDS for PostgreSQL + S3. 컴퓨트는 배포 단계에서 결정. 개발은 로컬 Docker PostgreSQL |
| Q-D3 | 게스트 refresh 토큰 365일 만료 | 365일 유지 (게스트는 원래 복구 불가) |
