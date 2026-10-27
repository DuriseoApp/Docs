# 둘이서 ERD (MVP v0.1)

> 기준 문서: 둘이서 PRD v0.8 (`docs/PRD.md`)
> 함께 보는 문서: `ERD.png` (한눈에 보기, 원본 `erd/erd.html`), `API.md` (권한 규칙, API, 흐름)
> 작성일: 2026-10-17 (갱신: 2026-10-27)

이 문서는 둘이서 서버의 데이터 모델 단일 기준이다. PRD의 ID(FR, D, NFR, Q)를 그대로 참조하고, 이 문서에서 새로 정한 결정은 `DB-` 접두어를 쓴다. PRD와 충돌하면 PRD가 우선이다.

---

## 1. 설계 원칙

**모든 콘텐츠는 "공간(space)"에 속하고, 사용자는 항상 활성 공간 하나에 속한다.** 혼자 쓰기와 커플 쓰기를 같은 구조로 다루고, 권한 검사는 "요청자가 이 공간의 구성원인가" 하나로 시작한다 (PRD D-29).

| 원칙 | 내용 |
| --- | --- |
| DB | PostgreSQL 16, 마이그레이션은 Flyway (`db/migration/V{n}__{설명}.sql`) |
| 기본 키 | 모든 테이블 UUID (애플리케이션에서 UUIDv7 생성, 시간순 정렬 가능) |
| 시간 | 일시는 `timestamptz`(UTC), 종일 일정·기념일·처음 만난 날·메모 날짜는 `date` (NFR-TIME-01) |
| 날짜 범위 | 날짜 컬럼은 1950-01-01 ~ 2050-12-31만 허용한다. 서비스에서 검사하고 DB CHECK는 두지 않는다 (DB-13, PRD D-74) |
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
| nickname | varchar(10) | not null | 게스트 기본값 "게스트", 회원은 소셜 프로필 이름. 앞뒤 공백을 지운 값을 저장하고, 글자 수는 유니코드 코드 포인트로 세어 1~10자다. 지운 뒤 빈 값이면 저장하지 않고 거부한다. 소셜 이름이 코드 포인트 10개를 넘으면 앞 10개만 쓰고, 이름이 없거나 공백뿐이면 "사용자"를 쓴다 (FR-AUTH-07, PRD D-56, D-69, D-82, NFR-LIMIT-01). 길이와 공백 검사는 서비스에서 하고, `varchar(10)`은 PostgreSQL이 문자 단위로 세므로 같은 기준이다. 게스트 연동(`/auth/link`) 성공 시 값이 정확히 "게스트"일 때만 위 규칙으로 소셜 프로필 이름으로 바꾸고, 사용자가 직접 바꾼 닉네임은 그대로 둔다 (FR-AUTH-03.AC1, PRD D-68) |
| profile_image_key | varchar(200) | null | 이미지 스토리지 객체 키. null이면 글자 아바타 (NFR-FILE-01) |
| time_zone | varchar(50) | not null, default `Asia/Seoul` | IANA 시간대 |
| deleted_at | timestamptz | null | 탈퇴 시각. 탈퇴하면 행을 지우지 않고 익명화한다 (4.3). 로그인 수단이 모두 지워져 다시 들어올 수 없다 |
| created_at, updated_at | timestamptz | not null | `created_at`은 API `Me.createdAt`(가입일)로 내보낸다. 게스트가 연동한 회원은 계정이 그대로이므로 게스트로 시작한 시각이다 (FR-SET-01) |

**social_accounts** — 회원의 소셜 로그인 수단 (FR-AUTH-02, 03)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| provider | varchar(10) | not null, CHECK in (`GOOGLE`, `KAKAO`) | |
| provider_user_id | varchar(100) | not null | 제공자의 고유 사용자 ID |
| created_at | timestamptz | not null | |

- UNIQUE (provider, provider_user_id): 한 소셜 계정은 한 사용자에게만 연결된다. 이미 쓰인 계정의 연동 거부(PRD Q-01)는 이 제약 위반으로 판정한다. 거부된 게스트는 확인을 거쳐 게스트를 삭제하고 그 계정으로 로그인할 수 있다 (게스트 → 기존 계정 로그인, DB-12, PRD D-67). 데이터는 합치지 않는다.
- UNIQUE (user_id, provider): 제공자별 하나씩.
- 서비스: `provider = KAKAO`인 행은 탈퇴 트랜잭션(4.3)이 커밋된 뒤 Kakao 앱 연결 끊기를 호출한다. 실패해도 되돌리지 않는다 (FR-AUTH-06.AC3). 테이블 변화는 없다.
- 서비스: Kakao 연결 해제 알림(`POST /webhooks/kakao/unlink`)은 (`KAKAO`, `provider_user_id`)로 사용자를 찾아, `KAKAO` 밖의 행이 있으면 `KAKAO` 행만 지우고, 없으면 그 사용자를 4.3과 같이 탈퇴 처리한다. 이때 Kakao 연결 끊기 호출은 하지 않는다 (이미 끊겼다). 못 찾으면 아무것도 하지 않는다 (DB-15, FR-AUTH-06.AC4, PRD D-87).

**auth_sessions** — 서버가 발급한 refresh 토큰 (NFR-SEC-01)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| refresh_token_hash | char(64) | not null, UNIQUE | refresh 토큰은 보안 난수 32바이트를 base64url(패딩 없음)로 인코딩한 43자 무작위 문자열이다 (JWT 아님). DB에는 원문이 아닌 SHA-256 16진수 64자만 저장하고, 요청에서 받은 토큰을 해시해 이 컬럼으로 조회한다 (PRD D-81, NFR-SEC-01, DB-02) |
| expires_at | timestamptz | not null | 회원 30일, 게스트 365일. 토큰을 갱신할 때마다 같은 행의 `refresh_token_hash`, `expires_at`, `last_used_at`만 바꿔 새 토큰으로 교체하고 만료를 연장 (DB-02). 게스트 연동 뒤 첫 갱신부터 회원 만료(30일)를 쓴다 |
| last_used_at | timestamptz | not null | |
| revoked_at | timestamptz | null | 로그아웃, 다른 기기 로그인으로 끊길 때 기록. `revoked_reason`과 함께 기록한다. 토큰 교체는 행을 무효화하지 않으므로 기록하지 않는다 |
| revoked_reason | varchar(10) | null, CHECK in (`LOGOUT`, `REPLACED`, `WITHDRAWN`) | 무효가 된 이유. null이면 무효가 아님 (아래 표) |
| created_at | timestamptz | not null | |

| revoked_reason | 뜻 | 기록하는 시점 |
| --- | --- | --- |
| LOGOUT | 사용자가 로그아웃함 | 로그아웃 (FR-AUTH-05) |
| REPLACED | 다른 기기 로그인으로 끊김 | 로그인 3종 (DB-09, FR-AUTH-02.AC3) |
| WITHDRAWN | 탈퇴로 무효가 됨 | 탈퇴 (4.3) |

- 서비스: `revoked_at`과 `revoked_reason`은 항상 같이 기록한다 (둘 다 null이거나 둘 다 값이 있다). 유효한 세션 = `revoked_at IS NULL AND expires_at > now`
- 서비스: access 토큰의 `sid` 클레임이 이 테이블의 `id`다. 서버는 요청마다 그 세션이 무효인지 보고, `REPLACED`면 401 `SESSION_REPLACED`, 그 밖의 무효는 401 `SESSION_INVALID`로 나눠 답한다 (오류 코드와 검사 시점은 `API.md`). 그래서 `REPLACED` 행은 4.4 정리에서 `expires_at`까지 남겨 둔다 (DB-11)
- 서비스: refresh 토큰을 교체할 때는 새 행을 만들지 않고 같은 행의 `refresh_token_hash`, `expires_at`, `last_used_at`만 바꾼다. 그래서 `sid`(= `id`)는 로그인부터 로그아웃까지 변하지 않는다. 이전 refresh 토큰을 다시 보내면 그 해시를 가진 행이 없어 무효(401 `SESSION_INVALID`)다 (DB-02)
- 한 사용자가 동시에 가질 수 있는 유효한 세션은 하나다. 로그인 3종(게스트 시작, 소셜 로그인, 게스트 → 기존 계정 로그인)을 하면 다른 유효 세션은 모두 `REPLACED`가 된다 (DB-09, DB-12, PRD D-51, D-67)
- 서비스: 만료 시간은 access 1시간, refresh 회원 30일·게스트 365일이다 (PRD NFR-SEC-01, D-73). access는 JWT이고 DB에 저장하지 않으며, refresh는 무작위 토큰이다 (PRD D-81). 푸시는 받는 사람에게 유효한 세션이 있을 때만 보낸다 (아래 `devices`, DB-14)

**devices** — FCM 푸시 토큰 (NFR-SYNC-01)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| fcm_token | varchar(255) | not null, UNIQUE | 같은 토큰이 다른 사용자로 들어오면 그 사용자로 옮긴다 |
| platform | varchar(10) | not null, default `ANDROID` | 값은 `ANDROID`, `IOS`. iOS 대비 (PRD D-25). 요청의 값은 API에서 검사하고 DB CHECK는 두지 않는다 (1장 열거형 규칙의 예외) |
| updated_at | timestamptz | not null | |

- 서비스: 같은 토큰이 다른 사용자로 들어오면 그 사용자로 옮긴다
- 서비스: 로그인 3종(게스트 시작, 소셜 로그인, 게스트 → 기존 계정 로그인)은 그 사용자의 `devices` 행을 모두 지운다. 새 기기는 로그인 뒤 `PUT /me/devices`로 다시 등록한다. 게스트 연동은 같은 기기라 지우지 않는다 (DB-09, DB-12, PRD D-51, D-67)
- 서비스: 로그아웃은 그 사용자의 `devices` 행을 모두 지운다. 한 기기 규칙이라 사용자 전체 = 그 기기다 (DB-09, PRD D-50). 그래서 로그아웃한 기기에는 푸시가 가지 않는다
- 서비스: 로그인이 만료된 기기에는 푸시를 보내지 않는다. 사용자에게 보이는 푸시는 받는 사람에게 유효한 세션(`revoked_at IS NULL AND expires_at > now`)이 있을 때만 보낸다. 이 조건은 보이는 푸시에만 적용하고, 동기화 신호(SYNC)는 그대로 보낸다(기기 정리로 자연히 멈춘다). 알림 목록(`notifications`) 행은 그대로 만든다. 그리고 매일 정리 작업(4.4)이 유효 세션이 없는 사용자의 `devices` 행을 지운다 (DB-14, PRD D-73, NFR-SEC-01)
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
| target_type | varchar(20) | null, CHECK in (`EVENT`, `MEMO`, `ANNIVERSARY`, `SETTINGS`) | 누르면 이동할 대상 (FR-NOTI-03). `COUPLE_LINKED`, `COUPLE_UNLINKED`(해제·탈퇴 해제 모두)는 `SETTINGS`이고 `target_id`는 null이다 (PRD D-85). 그 밖에 이동 대상이 없으면 `target_type`, `target_id` 모두 null |
| target_id | uuid | null | `target_type`이 가리키는 행의 ID |
| read_at | timestamptz | null | 읽은 시각. null이면 안 읽음 (FR-NOTI-05.AC3) |
| created_at | timestamptz | not null | |

- INDEX (user_id, created_at DESC): 알림 목록 조회
- 부분 INDEX (user_id) WHERE read_at IS NULL: 안 읽음 점과 개수 조회 (FR-CAL-01.AC4)
- 서비스: 알림이 생기면 받는 사람마다 이 행을 먼저 만들고, 그 종류의 설정(`notification_settings`)이 켜져 있을 때만 푸시를 보낸다. 연결·해제 알림은 항상 푸시한다. 설정을 꺼도 행은 남는다 (DB-07). 받는 사람에게 유효한 세션이 없으면 보이는 푸시는 보내지 않고 행만 만든다 (DB-14)
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
| start_date | date | null | 처음 만난 날. 커플 공간만 (FR-COUPLE-04). 커플 공간에서 한번 정하면 바꿀 수만 있고 null로 되돌리지 않는다 (PRD D-84). 연결 직후에는 null(건너뛰기) |
| together_color | varchar(20) | null | '함께' 사람 색의 팔레트 키. 커플 공간만 (FR-CAL-04) |
| unlinked_at | timestamptz | null | 연결 해제 시각 |
| purge_at | timestamptz | null | 이 시각이 지나면 정리 작업이 공간을 삭제한다. 연결 해제 시 `unlinked_at` + 30일, 구성원이 탈퇴하면 탈퇴 시각 + 90일로 늦춘다 (PRD D-06, D-36) |
| created_at, updated_at | timestamptz | not null | |

- CHECK: `type = 'COUPLE'` 이거나 `start_date`, `together_color`, `unlinked_at`, `purge_at`이 모두 null
- CHECK: `(status = 'UNLINKED') = (unlinked_at IS NOT NULL AND purge_at IS NOT NULL)`
- 부분 INDEX (purge_at) WHERE purge_at IS NOT NULL: 정리 작업용
- 탈퇴한 구성원이 있는 UNLINKED 공간은 재연결 복구 대상이 아니다. 운영자만 DB에서 복구할 수 있다 (PRD D-36)
- 서비스: `start_date`는 1950-01-01 ~ 오늘만 허용한다. 미래 날짜는 기존대로 거부하고, 1950-01-01 이전은 날짜 범위 위반이다. DB CHECK는 두지 않는다 (DB-13, PRD D-74, FR-COUPLE-04.AC3)

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
- 팔레트 키(`space_members.color`, `spaces.together_color`)는 `design/tokens.json`의 `color.pick` 이름 12개 중 하나다. 이 순서가 팔레트 순서다: `pick-orange`, `pick-rose`, `pick-amber`, `pick-mustard`, `pick-green`, `pick-teal`, `pick-blue`, `pick-purple`, `pick-magenta`, `pick-brown`, `pick-gray`, `pick-ink`. 12개 밖의 값은 서비스에서 거부한다 (DB CHECK 없음).
- 기본값은 개인 공간의 나·초대코드를 만든 사람 `pick-orange`(주황), 입력한 사람 `pick-blue`(파랑), 함께 `pick-purple`(보라)이다 (FR-CAL-04.AC3, AC5).

**invite_codes** — 커플 연결용 초대코드 (FR-COUPLE-01, 02)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| code | char(6) | not null, UNIQUE | 문자 집합 31자: 영문 대문자 A–Z 중 O·I·L 제외 23자 + 숫자 2–9 8자. 대문자로 저장한다 (PRD D-05, FR-COUPLE-01) |
| creator_user_id | uuid | not null, FK users ON DELETE CASCADE | |
| expires_at | timestamptz | not null | 생성 + 10분 (PRD D-05) |
| used_at | timestamptz | null | |
| used_by_user_id | uuid | null, FK users ON DELETE SET NULL | |
| revoked_at | timestamptz | null | 재요청으로 만료되거나(FR-COUPLE-01.AC3), 만든 사람이 커플로 연결돼 무효가 된 시각 (DB-16) |
| created_at | timestamptz | not null | |

- 부분 UNIQUE (creator_user_id) WHERE used_at IS NULL AND revoked_at IS NULL: 사용자당 유효한 코드는 하나
- 서비스: 입력한 코드는 공백을 없애고 대문자로 바꾼 뒤 비교한다 (FR-COUPLE-01.AC4). 그래서 DB에는 대문자만 있다
- 서비스(재요청 간격): 같은 `creator_user_id`의 가장 최근 `created_at` + 60초가 지나야 새 코드를 발급한다. 새 컬럼은 없다 (FR-COUPLE-01.AC3)
- 서비스(재요청): 새 코드를 만드는 같은 트랜잭션에서, 그 사용자의 사용되지 않은(`used_at IS NULL`) 이전 코드 전부의 `revoked_at`을 기록한다. 시간이 지나 만료됐어도 `revoked_at`이 null이면 포함한다. 그래야 위 부분 UNIQUE와 충돌하지 않고, 이전 코드는 그 즉시 쓸 수 없다
- 서비스(유효한 코드): `used_at IS NULL AND revoked_at IS NULL AND expires_at > now`. `expires_at <= now`면 만료다
- 서비스(연결 때 무효화, DB-16): `/couple/join` 트랜잭션에서 만든 사람 A와 입력한 사람 B의 **다른** 유효한 코드(`used_at IS NULL AND revoked_at IS NULL`, 만료됐어도 포함)에 `revoked_at` = 지금을 기록한다. 입력한 코드는 기존대로 사용 처리(`used_at`, `used_by_user_id`)한다 (FR-COUPLE-02.AC3)
- 무차별 대입 방어는 DB-08

**invite_code_attempts** — 초대코드 입력 시도 기록 (NFR-SEC-03)

| 컬럼 | 타입 | 제약 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK | |
| user_id | uuid | not null, FK users ON DELETE CASCADE | |
| succeeded | boolean | not null | |
| attempted_at | timestamptz | not null | |

- INDEX (user_id, attempted_at): 최근 1시간 실패 횟수 조회. 7일 지난 기록은 정리 작업에서 삭제
- 서비스(미끄러지는 창, D-83): 요청자의 `succeeded = false`이고 `attempted_at > now − 1시간`인 행이 10개 이상이면 입력을 막는다. 1시간은 지금부터 거꾸로 센다. 그중 가장 오래된 실패가 1시간을 지나면 풀린다 (풀리는 시각 계산은 `API.md` 4.4). 고정 시간 구간이나 별도 잠금 컬럼은 없다
- 서비스(무엇을 남기나): 연결에 쓸 수 없는 코드는 형식이 틀린 코드를 포함해 모두 `succeeded = false` 한 행이다 (`INVITE_NOT_FOUND`, `INVITE_SELF`, `INVITE_USED`, `INVITE_UNAVAILABLE`, `INVITE_EXPIRED`). 실패 행은 연결 트랜잭션과 별도로 커밋해 응답이 오류여도 남긴다. 성공은 연결 트랜잭션 안에서 `succeeded = true`로 남긴다. **남기지 않는 것**: 게스트·이미 커플 거부(R-09), 요청 형식 오류(`VALIDATION_FAILED`), 입력 제한(`INVITE_RATE_LIMITED`) 자체 (PRD D-83, NFR-SEC-03)

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
- 서비스: `start_date`, `end_date`, 그리고 `start_at`, `end_at`을 요청자 `time_zone` 기준 날짜로 바꾼 값은 1950-01-01 ~ 2050-12-31이어야 한다. DB CHECK는 두지 않는다 (DB-13, PRD D-74, FR-CAL-01.AC6)
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
- 서비스: `date`는 1950-01-01 ~ 2050-12-31이어야 한다. DB CHECK는 두지 않는다 (DB-13, PRD D-74, FR-CAL-01.AC6). 매년 반복 기념일과 자동 N주년의 발생일은 2050-12-31까지만 계산한다 (FR-ANNIV-02.AC1, FR-ANNIV-04.AC1)
- 서비스: "지난 기념일"은 `repeats_yearly = false`이고 `date`가 오늘(요청자 시간대)보다 이른 행이다. 저장하는 값이 아니라 조회 조건이다 (FR-ANNIV-04.AC3, PRD D-71)

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
- 서비스: `memo_date`는 1950-01-01 ~ 2050-12-31이어야 한다. DB CHECK는 두지 않는다 (DB-13, PRD D-74)

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
| 로그인 3종 (게스트 시작, 소셜 로그인, 게스트 → 기존 계정 로그인) | 새 auth_sessions. 같은 트랜잭션에서 다른 유효 세션과 devices를 정리한다 (4.6). 게스트 연동은 현재 세션을 그대로 쓰므로 새 행이 없다 |
| 게스트 → 기존 계정 로그인 (D-67) | 새 auth_sessions 한 행(그 계정의 회원 세션). 같은 트랜잭션에서 게스트 사용자를 4.3 탈퇴와 같이 처리한다 (DB-12). 새 users, spaces는 만들지 않는다 |
| 커플 연결 (복구 아님) | spaces(COUPLE, 함께 = 보라), space_members 2개(만든 사람 주황, 입력한 사람 파랑). 같은 트랜잭션에서 두 사람 각자의 개인 공간을 정한다: 혼자 쓴 기록이 없으면 그 개인 공간을 바로 지운다 (아래 "커플 연결 때 개인 공간 처리"). 또 두 사람의 다른 유효한 invite_codes에 `revoked_at`을 기록해 무효로 만든다 (DB-16) |
| 연결 해제 | 두 사람 각자 spaces(PERSONAL), space_members(주황). 단, 가져오기 대기 중인 개인 공간(기록이 있어 남아 있는 공간)이 있는 사람은 새로 만들지 않고 그 공간을 되살린다 (4.2) |
| 알림이 생길 때 (PRD 8장) | 받는 사람마다 notifications. 푸시 설정을 꺼도 만든다 (DB-07) |

**커플 연결 때 개인 공간 처리** (`/couple/join`, PRD D-78, FR-COUPLE-03): 연결하는 두 사람 A(코드를 만든 쪽)와 B(코드를 입력한 쪽) 각자의 개인 공간을 같은 트랜잭션에서 다음처럼 정한다 (`API.md` 4.4 5단계와 같다).

- 혼자 쓴 기록(`events`, `anniversaries`, `memos`)이 있으면 그 개인 공간 소속에 `space_members.left_at`을 기록하고 공간은 지우지 않는다. 이것이 **가져오기 대기 중인 개인 공간**이다. 활성 소속이 하나뿐이라는 부분 UNIQUE는 이 `left_at` 기록 뒤에 커플 공간 소속이 생기므로 지켜진다.
- 혼자 쓴 기록이 없으면 그 개인 공간을 같은 트랜잭션에서 바로 지운다. 소속과 알림(`notifications.space_id` CASCADE, 4.5)도 함께 지워진다.
- 그래서 가져오기 대기 중인 개인 공간은 기록이 있는 공간뿐이고, `importPending`은 요청자에게 그런 공간이 남아 있을 때만 true다.
- 대기 공간은 `POST /couple/import`로 가져오거나 가져오지 않기를 고르면 지워진다. 고르기 전에 연결이 해제되면 4.2가 그 공간을 되살린다.

### 4.2 연결 해제와 보관

- 커플 공간은 `status = UNLINKED`, `unlinked_at` = 해제 시각, `purge_at` = 해제 시각 + 30일 (PRD D-06)
- 두 구성원의 `space_members.left_at`을 기록하고, 그 공간의 `event_reminders`를 삭제한다
- 해제한 공간의 `space_id`를 가진 `notifications`를 두 사람 모두 삭제한다 (PRD D-45). 이 처리 뒤에 만드는 `COUPLE_UNLINKED` 알림은 `space_id`가 null이라 지워지지 않는다
- `purge_at` 전에 같은 두 사람이 다시 연결하면 공간을 ACTIVE로 되돌리고 `left_at`, `unlinked_at`, `purge_at`을 비운다 (FR-COUPLE-06)
- 커플 연결 때의 개인 공간 처리(빈 개인 공간 즉시 삭제, 가져오기 대기)는 4.1의 "커플 연결 때 개인 공간 처리"에 있다. 아래 되살리기는 그 결과로 남은 대기 공간을 대상으로 한다
- **가져오기 전 해제** (D-78): 구성원에게 가져오기 대기 중인 개인 공간(기록이 있어 남아 있고 소속에 `left_at`이 있는 PERSONAL)이 있으면 그 사람에게는 새 개인 공간을 만들지 않는다. 대신 그 공간의 `space_members.left_at`을 비워 다시 활성 공간으로 쓴다. 혼자 쓴 기록이 원래 개인 공간에 그대로 돌아가고, 그 사람의 `importPending`은 false가 된다 (FR-COUPLE-05.AC4). 활성 소속이 하나뿐이라는 부분 UNIQUE는 해제 처리에서 커플 공간 소속의 `left_at`을 먼저 기록한 뒤 되살리므로 지켜진다. 남아 있는 대기 중인 개인 공간이 없는 구성원(기록이 없어 연결 때 지워졌거나, 이미 가져오기·가져오지 않기를 정한 사람)은 기존대로 새 빈 개인 공간을 만든다

### 4.3 탈퇴 (익명화)

게스트 → 기존 계정 로그인(D-67)에서 게스트를 지울 때도 같은 순서를 쓴다. 게스트는 커플이 될 수 없으므로 1~2단계는 건너뛴다.

1. 커플 공간에 있으면 4.2로 연결 해제한다.
2. 이 사용자가 속했던 UNLINKED 커플 공간의 `purge_at`을 탈퇴 시각 + 90일로 늦춘다. 이미 그보다 늦으면 그대로 둔다 (PRD D-36).
3. 개인 공간과 가져오기 대기 중인 개인 공간을 지운다. 콘텐츠는 CASCADE로 함께 지워진다.
4. 사용자를 익명화한다: `deleted_at` 기록, 닉네임 "탈퇴한 사용자", 프로필 사진 파일과 `profile_image_key` 삭제, `social_accounts`, `auth_sessions`, `devices`, `notification_settings`, `notifications`, `memo_favorites`, `event_reminders`, 유효한 `invite_codes` 삭제. `users` 행 자체는 남겨 보관 중인 커플 공간의 작성자 참조를 유지한다.
   - `auth_sessions`는 먼저 `revoked_reason = WITHDRAWN`으로 무효화한 뒤 같은 트랜잭션에서 지운다. 그래서 탈퇴 뒤에 남는 세션 행은 없다.

**Kakao 연결 끊기** (FR-AUTH-06.AC3, 회원 탈퇴만): `social_accounts.provider = KAKAO`인 회원이면 탈퇴 트랜잭션이 **커밋된 뒤에** Kakao 연결 끊기 API를 서버의 Kakao 어드민 키로 호출한다 (키는 서버 설정값이며 이 문서에 쓰지 않는다). 행은 트랜잭션 안에서 지워지므로 호출에 필요한 `provider_user_id`는 지우기 전에 읽어 둔다. 호출이 실패해도 탈퇴를 되돌리지 않고 로그만 남긴다. 게스트 삭제(게스트 → 기존 계정 로그인, 게스트 정리)에는 소셜 계정이 없어 해당 없다. 테이블 변화는 없다.

**Kakao 연결 해제 알림으로 인한 탈퇴** (FR-AUTH-06.AC4, PRD D-87, DB-15): 사용자가 Kakao 계정 설정에서 둘이서 연결을 끊으면 Kakao가 `POST /webhooks/kakao/unlink`를 부른다. 서버는 (`KAKAO`, `provider_user_id`)로 `social_accounts`를 찾고, 그 사용자 행을 잠근 뒤(탈퇴와 같은 잠금) 다음처럼 처리한다. 못 찾거나 이미 `deleted_at`이 있으면 아무것도 하지 않는다(같은 알림이 두 번 와도 결과가 같다).
- 그 사용자에게 `KAKAO` 밖의 `social_accounts`(곧 `GOOGLE`)가 있으면 `KAKAO` 행만 지운다. 세션, 기기, 데이터는 그대로다.
- 없으면 위 1~4단계와 같이 탈퇴 처리한다. 커플이면 연결 해제와 상대에게 탈퇴 전용 `COUPLE_UNLINKED` 알림, 속했던 커플 공간 `purge_at` +90일, 개인 공간 삭제, 익명화, 세션 `WITHDRAWN` 무효화 뒤 삭제까지 같다. **커밋 뒤 Kakao 연결 끊기 호출은 하지 않는다** (Kakao 쪽이 이미 끊었다). 테이블 변화는 없다.

탈퇴로 해제될 때 상대에게는 탈퇴 전용 `COUPLE_UNLINKED` 알림이 간다 (PRD D-53). 이 알림은 `space_id`가 null이라 4.2의 알림 삭제에 지워지지 않는다. 문구는 `API.md`가 정한다.

### 4.4 매일 정리 작업 (03:00 KST)

- **게스트 정리** (PRD Q-11): `account_type = GUEST`, `deleted_at IS NULL`이고 유효한(`revoked_at IS NULL AND expires_at > now`) `auth_sessions`가 하나도 없는 사용자를 4.3 탈퇴와 같이 처리한다. 게스트는 커플이 될 수 없으므로 개인 공간만 지우면 된다. 마지막 사용 뒤 365일(DB-02)이 지나면 대상이 되고, 아래 세션 정리보다 먼저 돈다 (DB-10)
- `purge_at`이 지난 공간 삭제
- `deleted_at`이 있고 더 이상 어떤 공간에서도 참조되지 않는 사용자 행 삭제
- 7일 지난 `invite_code_attempts`, 30일 지난 사용·만료·무효 초대코드 삭제
- 만료된 `auth_sessions` 삭제. 무효화된 세션도 지우되 `REPLACED`는 `expires_at`이 지날 때까지 남긴다 (DB-11)
- **세션 없는 사용자의 `devices` 삭제** (DB-14, PRD D-73): 바로 위 세션 정리가 끝난 뒤, 유효한(`revoked_at IS NULL AND expires_at > now`) `auth_sessions`가 하나도 없는 사용자의 `devices` 행을 모두 지운다. 이 순서여야 방금 만료돼 지워진 세션의 기기가 같은 실행에서 정리된다. 로그인이 만료된 기기에 푸시가 가지 않게 하는 안전망이다 (푸시를 보낼 때도 유효 세션을 확인한다, 3.1 `devices`)
- `created_at`이 30일 지난 `notifications` 삭제 (FR-NOTI-05.AC2)
- 어떤 사용자도 참조하지 않는 프로필 사진 파일 삭제

### 4.5 공간이 지워질 때 알림 (notifications.space_id CASCADE)

`notifications.space_id`는 `ON DELETE CASCADE`이므로 공간이 지워지면 그 공간의 알림도 30일이 되기 전에 함께 지워진다. 사라진 공간을 가리키는 알림을 남기지 않으려는 의도한 동작이고, 연결 해제 때 알림을 지우는 이유(PRD D-45)와 같다. 대상 일정·메모가 지워져도 알림 행은 지우지 않는다(`target_id`는 FK가 아님, PRD D-43).

- 커플 연결 때 기록이 없는 개인 공간이 바로 지워질 때(4.1, A와 B 모두), 그리고 커플 연결 뒤 개인 공간이 지워질 때(가져오지 않기를 고른 경우 포함): 그 개인 공간의 `space_id`를 가진 알림도 함께 지워진다.
- 탈퇴로 개인 공간이 지워질 때(4.3의 3단계): 그 개인 공간의 알림도 함께 지워진다. 사용자 본인의 알림은 4.3의 4단계에서도 지운다.
- `purge_at` 이후 정리 작업이 커플 공간을 지울 때도 같다 (4.4). 해제 시점에 이미 지웠으므로 남은 알림은 없다.
- 게스트 → 기존 계정 로그인으로 게스트 개인 공간이 지워질 때도 탈퇴와 같다 (4.3). 그 공간의 알림은 함께 지워진다.

### 4.6 로그인·로그아웃 시 세션과 기기 (한 기기 로그인)

한 계정은 한 기기에서만 로그인한다 (PRD D-51). 요청 단위의 처리 순서와 오류 응답은 `API.md`를 본다.

| 시점 | auth_sessions | devices |
| --- | --- | --- |
| 로그인 3종 (게스트 시작, 소셜 로그인, 게스트 → 기존 계정 로그인) | 같은 트랜잭션에서 그 사용자의 다른 유효 세션을 모두 `revoked_at` = 지금, `revoked_reason = REPLACED`로 바꾸고 새 세션을 만든다. 이전 세션·기기 정리는 셋 모두 같은 코드다 | 그 사용자의 행을 모두 지운다. 새 기기는 로그인 뒤 `PUT /me/devices`로 다시 등록한다 |
| 게스트 → 기존 계정 로그인 (`POST /auth/switch`) | 한 트랜잭션: 먼저 `social_accounts`를 다시 조회하고 대상 회원 행을 잠근다. 없거나 탈퇴한 회원이면 롤백하고(404 `SOCIAL_NOT_REGISTERED`) 게스트는 그대로 남는다. 있으면 ① 게스트 사용자의 세션을 `WITHDRAWN`으로 무효화한 뒤 삭제하고 게스트를 4.3 탈퇴와 같이 처리 ② 그 소셜 계정의 회원으로 위 로그인 3종의 정리(다른 유효 세션 `REPLACED`) ③ 새 세션 생성 (DB-12) | 게스트의 행은 4.3으로 삭제, 그 회원의 행은 모두 지운다. 앱은 `PUT /me/devices`를 다시 부른다 |
| 게스트 연동 (`/auth/link`) | 같은 기기라 현재 세션을 그대로 쓴다. 다른 세션을 끊지 않는다. 다음 토큰 갱신부터 회원 만료(30일) | 변화 없음 |
| 로그아웃 | 현재 세션을 `revoked_reason = LOGOUT`으로 바꾼다 | 그 사용자의 행을 모두 지운다 (PRD D-50) |
| refresh 토큰 갱신 | 새 행을 만들지 않고 같은 행의 `refresh_token_hash`, `expires_at`, `last_used_at`만 바꾼다. `sid`는 그대로다 (DB-02) | 변화 없음 |
| 탈퇴 | `WITHDRAWN`으로 무효화한 뒤 삭제 (4.3) | 삭제 (4.3) |

- 이전 기기는 `devices`가 지워져 푸시를 받지 않고, 다음 요청에서 세션이 `REPLACED`임을 알게 된다.
- 로그인이 만료된 기기(유효 세션 없음)에는 푸시를 보내지 않는다. 정리 작업이 그런 사용자의 `devices`를 지운다 (4.4, DB-14).
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
| DB-09 | 한 기기 로그인: 로그인 3종(게스트 시작, 소셜 로그인, 게스트 → 기존 계정 로그인)은 같은 트랜잭션에서 그 사용자의 다른 유효 세션을 `REPLACED`로 무효화하고 `devices`를 모두 지운다. 로그아웃은 현재 세션을 `LOGOUT`으로 바꾸고 `devices`를 모두 지운다. 무효가 된 이유는 `auth_sessions.revoked_reason`에 둔다 | 이전 기기와 로그아웃한 기기에 푸시가 가지 않게 하고(PRD D-50, D-51), 이전 기기가 "다른 기기에서 로그인해서 로그아웃됐어요"(`REPLACED`)와 그냥 무효를 구분하게 하려고 |
| DB-10 | 게스트 정리: 유효한 세션이 없는 게스트(`deleted_at IS NULL`)를 매일 정리 작업이 탈퇴와 같이 처리하고, 세션 정리보다 먼저 돈다 | 앱을 지운 게스트는 계정을 되찾을 수 없어 서버에 데이터만 남는다. 기본값은 마지막 사용 후 365일(PRD Q-11, DB-02). 같은 실행 안에서 세션 정리보다 먼저 돌도록 순서를 고정 |
| DB-11 | `REPLACED` 세션 행은 `expires_at`까지 남기고, 그 밖의 무효·만료 세션은 정리 작업이 지운다 | 이전 기기가 며칠 뒤에 접속해도 `SESSION_REPLACED` 안내를 받게 하려고. 지우면 일반 무효(`SESSION_INVALID`)로 보인다 |
| DB-12 | 게스트 → 기존 계정 로그인(`POST /auth/switch`)은 게스트 탈퇴(4.3)와 소셜 로그인을 한 트랜잭션으로 처리한다 (v0.6) | 게스트는 로그아웃이 없어 원래 계정으로 돌아갈 길이 없었다(PRD D-67). 데이터는 합치지 않고 게스트를 지운다. 한 트랜잭션이라 게스트만 지워지고 로그인이 실패하는 중간 상태가 없다. 트랜잭션 안에서 `social_accounts`를 다시 조회하고 대상 회원 행을 잠가, 그 사이에 회원이 탈퇴해도 안전하다. 없거나 탈퇴한 회원이면 롤백하고 게스트는 그대로 남는다. 이전 세션·기기 정리는 다른 로그인과 같은 코드를 쓴다 |
| DB-13 | 날짜 범위(1950-01-01 ~ 2050-12-31)는 서비스에서 검사하고 DB CHECK는 두지 않는다 (v0.6) | 범위가 PRD D-74로 바뀔 수 있고, 바뀔 때마다 마이그레이션을 하지 않게 하려고. 서비스가 모든 입력 경로에서 막는다 (리드 결정) |
| DB-14 | 사용자에게 보이는 푸시는 받는 사람에게 유효한 세션이 있을 때만 보내고(동기화 신호 SYNC는 그대로 보낸다), 매일 정리 작업이 유효 세션 없는 사용자의 `devices`를 지운다 (v0.6) | 로그인이 만료된 기기에 푸시가 가지 않게(PRD D-73, D-50과 같은 이유). 동기화 신호는 사용자에게 보이지 않으므로 막지 않고, 기기 정리로 자연히 멈춘다. 알림 목록 행은 그대로 만들어 다시 로그인하면 볼 수 있다. 푸시 전 확인과 정리 작업 두 겹으로 막는다 |
| DB-15 | Kakao 연결 해제 알림은 `social_accounts`의 (`KAKAO`, `provider_user_id`)로 사용자를 찾아, Kakao가 유일한 로그인 수단이면 4.3 탈퇴로, 다른 수단이 있으면 `KAKAO` 행 삭제로 처리한다. 못 찾으면 아무것도 하지 않는다 (v0.8) | Kakao로만 들어오던 회원은 다시 들어올 방법이 없어 데이터를 남기지 않음 (PRD D-87). 같은 알림이 여러 번 와도 결과가 같다(멱등). 지금은 회원이 로그인 수단을 둘 가질 API가 없지만 UNIQUE (user_id, provider)가 허용하므로 정의해 둔다 |
| DB-16 | 커플 연결 트랜잭션에서 두 사람의 다른 유효한 초대코드에 `revoked_at`을 기록한다 (v0.8) | 연결 뒤 남은 코드가 해제 직후 다시 쓸 수 있는 코드가 되지 않게. 연결 중인 사람의 코드를 넣으면 `INVITE_UNAVAILABLE`(`API.md` 오류 우선순위) (FR-COUPLE-02.AC3) |

---

## 6. PRD 추적표 (테이블)

| FR 영역 | 테이블 |
| --- | --- |
| FR-AUTH-01~05 | users, social_accounts, auth_sessions (revoked_reason, refresh_token_hash는 D-81), devices, notification_settings |
| FR-AUTH-03 연동 (AC1 닉네임, AC3 기존 계정 로그인) | users.nickname, social_accounts, auth_sessions, devices (4.6, DB-12) |
| FR-AUTH-05 로그아웃 (AC3 다른 계정으로 로그인) | auth_sessions (LOGOUT), devices (4.6) |
| FR-AUTH-06 탈퇴 | 모든 사용자 관련 테이블 (4.3). AC3 Kakao 연결 끊기는 social_accounts.provider (테이블 변화 없음). AC4 Kakao 연결 해제 알림은 social_accounts (KAKAO 행만 삭제 또는 탈퇴, 연결 끊기 호출 없음, D-87, DB-15, 테이블 변화 없음) |
| FR-SET-01 계정 | users.created_at (가입일, API `Me.createdAt`), users.account_type (테이블 변화 없음) |
| FR-AUTH-07 프로필 | users.nickname (앞뒤 공백 제거, 코드 포인트 1~10자, 이름 없으면 "사용자", D-82), users.profile_image_key |
| FR-AUTH-08 이용 동의 | 테이블 없음 (앱) |
| FR-AUTH-09 앱 밖 계정 삭제 요청 | 테이블 없음 (웹 페이지와 메일 요청, 처리는 FR-AUTH-06과 같음) |
| FR-SET-02 정보 | 테이블 없음 (앱·웹) |
| FR-COUPLE-01~02, 06 | invite_codes (code, expires_at, revoked_at; 연결 때 다른 유효 코드 무효화 DB-16), invite_code_attempts (AC4 최근 1시간 실패 10번, 미끄러지는 창, D-83), spaces, space_members |
| FR-COUPLE-03 | events, anniversaries, memos (space_id 이동) |
| FR-COUPLE-04 | spaces.start_date (1950-01-01 ~ 오늘, 서비스 검사, DB-13. 바꿀 수만 있고 null로 되돌리지 않음, D-84) |
| FR-COUPLE-05 | spaces.status, unlinked_at, purge_at, space_members.left_at. AC4 가져오기 전 해제는 space_members.left_at을 비워 개인 공간을 되살림 (4.2) |
| FR-CAL-01~03 | events |
| FR-CAL-01.AC6 날짜 범위 | events, memos.memo_date, anniversaries.date, spaces.start_date (서비스 검사, DB-13) |
| FR-CAL-01 날짜 있는 메모 | memos.memo_date |
| FR-CAL-01.AC4 안 읽음 점 | notifications.read_at |
| FR-CAL-04 사람 색 | space_members.color, spaces.together_color |
| FR-CAL-05 일정 알림 | event_reminders |
| FR-ANNIV-01~04 | spaces.start_date(자동), anniversaries(직접). AC3 지난 기념일은 `repeats_yearly = false`이고 `date` < 오늘인 조회, AC4 처음 만난 날이 없으면 자동 기념일 없음 (`start_date` null) |
| FR-MEMO-01~03 | memos |
| FR-MEMO-02 메모 날짜 | memos.memo_date |
| FR-MEMO-04 | 삭제됨 (PRD v0.4) |
| FR-MEMO-05 | memos.pinned_at, pinned_by |
| FR-MEMO-06 | memo_favorites |
| FR-NOTI-01~03 | devices, notification_settings. 로그인 만료 기기 푸시 금지는 auth_sessions 확인 + 정리 작업 (NFR-SEC-01, DB-14) |
| FR-NOTI-03 알림 이동 | notifications.target_type (연결·해제 알림은 `SETTINGS`, D-85) |
| FR-NOTI-05 알림 목록 | notifications |

---

## 7. 확인 사항 (모두 해결)

| ID | 질문 | 결과 |
| --- | --- | --- |
| Q-D1 | 탈퇴 시 커플 공간 데이터 처리 | 90일 보관 후 삭제 (PRD D-36, DB-04) |
| Q-D2 | 운영 서버 위치 | AWS 서울 리전 EC2 1대에 Docker Compose로 개발·운영 앱과 PostgreSQL 16을 함께 둔다. DB와 DB 사용자는 개발(`duriseo_dev`)과 운영(`duriseo_prod`)으로 나눈다. 운영 DB는 매일 S3에 백업해 30일 보관한다. 운영 프로필 이미지는 S3에 둔다 (`API.md` 8장). 구성은 Server 레포 `deploy/`와 `docs/DEPLOY.md` (2026-10 변경, 비용 때문에 RDS 대신) |
| Q-D3 | 게스트 refresh 토큰 365일 만료 | 365일 유지 (게스트는 원래 복구 불가) |
