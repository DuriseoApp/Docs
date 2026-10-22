# 둘이서 API 초안 (MVP v0.1)

> 기준 문서: 둘이서 PRD v0.5 (`docs/PRD.md`)
> 함께 보는 문서: `ERD.md` (테이블 정의), `ERD.png` (한눈에 보기)
> 작성일: 2026-10-17 (갱신: 2026-10-21)

이 문서는 둘이서 서버 API의 범위, 권한, 처리 흐름을 정한다. 요청·응답의 상세 스키마는 서버 코드의 OpenAPI(springdoc) 문서를 단일 기준으로 삼는다. PRD의 ID(FR, D, NFR, Q)와 ERD의 `DB-` 결정을 그대로 참조하며, PRD와 충돌하면 PRD가 우선이다.

---

## 1. 공통 규약

**응답은 성공이면 리소스 JSON을 그대로, 실패면 `{"code": "…", "message": "…"}`를 돌려준다.** 앱은 `code`로 분기하고, `message`는 로그용이다. 사용자에게 보이는 문구는 앱이 `code`에 맞춰 디자인 시스템의 말투(해요체)로 쓴다.

- 모든 경로는 `/api/v1` 아래에 있다
- `/auth/guest`, `/auth/social`, `/auth/refresh`를 빼면 access 토큰(`Authorization: Bearer …`)이 필요하다
- JSON 필드는 camelCase, 날짜는 `YYYY-MM-DD`, 일시는 ISO 8601 UTC (`2026-10-17T06:30:00Z`)
- access 토큰 1시간, refresh 토큰은 회원 30일·게스트 365일, 사용할 때마다 교체 (ERD DB-02). 교체는 같은 세션 행의 토큰 해시와 만료를 갱신하는 것이라 `sid`는 로그인부터 로그아웃까지 바뀌지 않는다. 이전 refresh 토큰을 다시 보내면 401 `SESSION_INVALID`다
- **한 계정은 한 기기에서만 로그인한다 (PRD D-51).** access 토큰에는 발급한 `auth_sessions.id`가 `sid` 클레임으로 들어 있다. 서버는 서명·만료 검사 뒤 요청마다 그 세션이 무효인지 본다. 무효인 이유가 `REPLACED`(다른 기기 로그인으로 끊김)면 401 `SESSION_REPLACED`, 그 밖의 무효(로그아웃, 탈퇴, 만료)면 401 `SESSION_INVALID`를 돌려준다
- 앱은 401 `SESSION_REPLACED`를 받으면 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여주고 로컬 데이터를 지운 뒤 SCR-START-01로 이동한다 (FR-AUTH-02.AC3). `SESSION_INVALID`는 안내 없이 SCR-START-01로 보낸다. 이전 기기의 access 토큰이 이미 만료됐다면 `POST /auth/refresh`가 같은 기준으로 `SESSION_REPLACED`를 돌려주므로 안내는 그때 뜬다
- 입력 길이 제한은 NFR-LIMIT-01을 따르고, 넘으면 400 `VALIDATION_FAILED`와 필드 이름을 돌려준다
- 목록은 커서 페이지네이션 (`cursor`, `size`, 응답의 `nextCursor`)

---

## 2. 서버 권한 검사 규칙

**모든 요청은 먼저 "이 리소스가 요청자의 활성 공간에 있는가"를 검사하고, 아니면 404를 돌려준다.** 403이 아니라 404인 이유는 다른 커플의 리소스가 존재한다는 사실 자체를 알려주지 않기 위해서다 (NFR-SEC-02, ERD DB-05). 이 규칙들은 한 곳(`SpaceAccessPolicy` 같은 단일 컴포넌트)에서 구현하고, 각 규칙마다 허용·거부 테스트를 둔다. **리뷰에서 이 규칙 위반은 항상 Critical이다.**

| ID | 규칙 | 실패 응답 | 근거 |
| --- | --- | --- | --- |
| R-01 | 모든 콘텐츠 조회·변경: 리소스의 `space_id` = 요청자의 활성 공간(`space_members.left_at IS NULL`) | 404 `NOT_FOUND` | NFR-SEC-02 |
| R-02 | 일정 수정·삭제: 요청자 = `author_id`, 또는 `is_together = true` | 403 `NOT_AUTHOR` | D-12, D-34 |
| R-03 | 메모의 제목·본문·메모 날짜 수정, 메모 삭제: 요청자 = `author_id` | 403 `NOT_AUTHOR` | D-17 |
| R-04 | 메모 고정·해제: 공간 구성원이면 허용 | (R-01만) | D-21 |
| R-05 | 직접 기념일 수정·삭제: 요청자 = `author_id` | 403 `NOT_AUTHOR` | FR-ANNIV-03 |
| R-06 | 즐겨찾기: 요청자 본인의 행만 만들고 지운다. 목록 조회 시 다른 사용자의 즐겨찾기는 응답에 넣지 않는다 | — | D-24 |
| R-07 | 일정 알림: 요청자 본인의 행만 만들고 바꾼다. 일정 응답에는 요청자의 알림만 넣는다 | — | D-16 |
| R-08 | 처음 만난 날, 사람 색 변경: 커플 공간의 구성원이면 허용. 개인 공간에서는 자기 색만 | 409 `NOT_COUPLE` | FR-COUPLE-04, FR-CAL-04 |
| R-09 | 초대코드 생성·입력: `account_type = MEMBER`이고 개인 공간에 있을 것 | 403 `GUEST_NOT_ALLOWED` / 409 `ALREADY_COUPLED` | D-07 |
| R-10 | 일정 대상: 요청 본문은 `isTogether`만 받고 대상 사용자는 받지 않는다. 개인 공간에서 `isTogether = true`면 거부 | 400 `INVALID_TARGET` | D-34 |
| R-11 | 프로필 사진 조회: 본인 또는 같은 활성 공간의 구성원만 | 404 `NOT_FOUND` | NFR-FILE-01 |
| R-12 | 알림 조회·읽음 처리: `notifications.user_id` = 요청자. 알림 목록은 공간이 아니라 받은 사람 기준이므로 R-01 대신 이 규칙만 적용한다 | 404 `NOT_FOUND` | FR-NOTI-05.AC4 |
| R-13 | 일정 수정에서 `isTogether` 값을 바꾸는 요청은 요청자 = `author_id`일 때만. '함께' 일정을 상대가 수정할 때는 `isTogether`를 바꿀 수 없다 (R-02는 통과해도 R-13에서 거부). 값을 바꾸지 않는 요청은 R-02만 적용한다 | 403 `NOT_AUTHOR` | D-52, FR-CAL-03.AC4 |

앱 화면에서 버튼을 숨기는 것은 사용성을 위한 것이고, 보안은 위 규칙으로만 보장한다.

---

## 3. API 목록

"권한" 열의 R-번호는 2장의 규칙이다.

### 3.1 인증·내 정보

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| POST | /auth/guest | 게스트 시작. 새 사용자라 끊을 이전 세션·기기는 없다 (4.1) | 없음 | FR-AUTH-01 |
| POST | /auth/social | 소셜 로그인 `{provider, token}`, 응답에 `isNewUser`. 같은 트랜잭션에서 그 사용자의 다른 유효 세션을 `REPLACED`로 끊고 `devices`를 모두 지운다 (4.2). 토큰 검증 실패는 401 `SOCIAL_TOKEN_INVALID` | 없음 | FR-AUTH-02, NFR-SEC-01 |
| POST | /auth/link | 게스트 → 회원 연동 `{provider, token}`. 같은 기기에서 하므로 현재 세션을 그대로 쓰고, 다른 세션을 끊거나 `devices`를 지우지 않으며 응답에 새 토큰도 담지 않는다 (4.3). 토큰 검증 실패는 401 `SOCIAL_TOKEN_INVALID` | GUEST만 | FR-AUTH-03, NFR-SEC-01 |
| POST | /auth/refresh | refresh 토큰 교체 발급 (같은 세션 행을 갱신하므로 `sid`는 그대로). 그 세션이 `REPLACED`로 끊겼으면 401 `SESSION_REPLACED`, 이전 refresh 토큰 재사용을 포함한 그 밖의 무효는 401 `SESSION_INVALID` | refresh 토큰 | NFR-SEC-01, FR-AUTH-02.AC3 |
| POST | /auth/logout | 현재 세션 무효화(`LOGOUT`)와 그 사용자의 `devices` 행 삭제. 이후 그 기기에는 푸시가 가지 않는다 | MEMBER만 | FR-AUTH-05 |
| GET | /me | 내 정보 + 현재 공간 요약 (종류, 공간 ID, 상대, 사람 색, 처음 만난 날, `importPending`). SCR-COUPLE-02의 연결 확인 호출로도 쓴다 (4.4) | 로그인 | FR-SET-01, FR-COUPLE-02.AC5 |
| PATCH | /me | 닉네임(최대 10자, 넘으면 400 `VALIDATION_FAILED`), 시간대 변경 | 로그인 | FR-AUTH-07, NFR-LIMIT-01 |
| PUT | /me/profile-image | 프로필 사진 업로드 (multipart) | 로그인 | FR-AUTH-07.AC3 |
| DELETE | /me/profile-image | 프로필 사진 삭제 | 로그인 | FR-AUTH-07.AC5 |
| GET | /users/{id}/profile-image | 프로필 사진 조회 | R-11 | FR-AUTH-07 |
| DELETE | /me | 탈퇴 | 로그인 | FR-AUTH-06 |
| PUT | /me/devices | FCM 토큰 등록·갱신 | 로그인 | NFR-SYNC-01 |
| GET, PATCH | /me/notification-settings | 알림 설정 조회·변경. 게스트를 포함한 로그인 사용자 모두 가능 (D-62) | 로그인 (게스트 포함) | FR-NOTI-02 |

### 3.2 공간·커플

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /space | 현재 공간 상세 (구성원, 사람 색, 처음 만난 날) | 로그인 | FR-SET-01 |
| PATCH | /space | 처음 만난 날 변경 `{startDate}`. 요청자의 시간대(`users.time_zone`) 기준 오늘보다 뒤의 날짜는 400 `VALIDATION_FAILED` | R-08 | FR-COUPLE-04.AC3 |
| PATCH | /space/colors | 사람 색 변경 `{members: [{userId, color}], together}` | R-08 | FR-CAL-04 |
| POST | /invite-codes | 초대코드 생성·재요청. 응답 `{code, expiresAt, reissueAvailableAt}`. 재요청하면 이전 코드는 즉시 만료. 마지막 발급 후 60초 안이면 429 `INVITE_REISSUE_TOO_SOON` (응답에 `retryAfterSeconds`) | R-09 | FR-COUPLE-01 |
| GET | /invite-codes/current | 내 유효한 초대코드와 남은 시간. 응답에 `reissueAvailableAt` 포함 (이 시각 전에는 재요청 불가) | R-09 | FR-COUPLE-01 |
| POST | /couple/join | 초대코드로 연결 `{code}`. 서버는 `code`의 공백을 제거하고 대문자로 바꿔서 비교한다. 응답에 `restored`, `importPending`. 커밋 뒤 두 사람 기기에 SYNC `SPACE`/`LINKED`를 보낸다 (4.4, 6장) | R-09 | FR-COUPLE-01.AC4, FR-COUPLE-02, 06 |
| POST | /couple/import | 기록 가져오기 결정 `{import: boolean}`. 결정하기 전에는 `GET /me`의 `importPending`이 계속 true라서 앱은 연결 완료 시트를 닫을 수 없고, 다음 실행 때 시트를 다시 띄운다 (4.4) | 가져오기 대기 중인 본인 | FR-COUPLE-03 |
| DELETE | /couple | 연결 해제 | 커플 구성원 | FR-COUPLE-05 |

### 3.3 일정·기념일

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /events?from=&to= | 날짜 범위의 일정 (최대 3개월). 각 일정에 요청자의 알림만 포함 | R-01, R-07 | FR-CAL-01 |
| POST | /events | 일정 생성 `{title, note, isAllDay, start, end, isTogether, notifyPartner}`. `notifyPartner` 기본 true, 커플 공간에서만 의미 있음. 일정 알림(`event_reminders`)은 만들지 않는다: 기본값은 "없음"이고 `PUT /events/{id}/reminder`로 정한다 (D-59) | R-01, R-10 | FR-CAL-02, FR-NOTI-04 |
| GET | /events/{id} | 일정 상세 | R-01 | FR-CAL-03 |
| PATCH | /events/{id} | 일정 수정 (수정 시에는 상대에게 알림 없음). `isTogether`를 바꾸는 요청은 작성자만 (R-13). 일시를 바꾸면 요청자가 누구든('함께' 일정이면 상대도) 그 일정에 알림을 건 모든 사용자의 `event_reminders.fire_at`을 새 일시 기준으로 다시 계산한다 | R-02, R-10, R-13 | FR-CAL-03, FR-CAL-05.AC4 |
| DELETE | /events/{id} | 일정 삭제 | R-02 | FR-CAL-03 |
| PUT | /events/{id}/reminder | 내 알림 설정 `{option}` | R-01, R-07 | FR-CAL-05 |
| DELETE | /events/{id}/reminder | 내 알림 끄기 | R-01, R-07 | FR-CAL-05 |
| GET | /anniversaries?from=&to= | 자동 + 직접 기념일을 합쳐 날짜순으로 (`kind: AUTO` 또는 `CUSTOM`). D-N 계산 포함. 개인 공간은 처음 만난 날이 없어 `CUSTOM`만 나온다 (FR-ANNIV-04.AC2) | R-01 | FR-ANNIV-01~04 |
| POST | /anniversaries | 직접 기념일 생성 | R-01 | FR-ANNIV-03 |
| PATCH, DELETE | /anniversaries/{id} | 직접 기념일 수정·삭제 | R-05 | FR-ANNIV-03 |

### 3.4 메모

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /memos?view=&cursor=&size= | 고정되지 않은 메모 목록. `view` = `newest`(기본), `oldest`, `favorites`. 커서는 (created_at, id). 각 항목에 `memoDate`(없으면 null) 포함 | R-01, R-06 | FR-MEMO-01 |
| GET | /memos/pinned | 고정 메모 전체, 최근 고정순. 앱은 3개만 보여주고 4개 이상이면 "더보기". 각 항목에 `memoDate` 포함 | R-01 | FR-MEMO-05 |
| GET | /memos/dated?from=&to= | 날짜 범위(최대 3개월)에 `memoDate`가 있는 메모. 캘린더용. 각 항목에 `memoDate` 포함. `from` > `to`이거나 범위가 3개월을 넘으면 400 `VALIDATION_FAILED` | R-01 | FR-CAL-01.AC2 |
| POST | /memos | 메모 생성 `{title, body, memoDate, notifyPartner}`. `memoDate`는 `YYYY-MM-DD` 또는 생략·null. 제목, 본문 중 하나 이상 필수 | R-01 | FR-MEMO-02, FR-NOTI-04 |
| GET | /memos/{id} | 메모 상세 (요청자의 즐겨찾기 여부, `memoDate` 포함) | R-01, R-06 | FR-MEMO-03 |
| PATCH | /memos/{id} | 제목, 본문, 메모 날짜 수정 `{title, body, memoDate}`. `memoDate: null`이면 날짜 제거 | R-03 | FR-MEMO-03 |
| DELETE | /memos/{id} | 메모 삭제 | R-03 | FR-MEMO-03 |
| PATCH | /memos/{id}/checklist-items/{itemId} | 삭제됨 (PRD v0.4). 체크리스트가 범위 밖이 됨 | — | FR-MEMO-04 |
| PUT, DELETE | /memos/{id}/pin | 고정·해제 | R-04 | FR-MEMO-05 |
| PUT, DELETE | /memos/{id}/favorite | 즐겨찾기·해제 | R-06 | FR-MEMO-06 |

### 3.5 알림 목록

알림 목록은 푸시 설정(`/me/notification-settings`)과 별개로, 받은 알림을 받은 사람마다 30일 동안 보관한 기록이다 (D-39, ERD DB-07). 본인 것만 보인다 (R-12).

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /notifications?cursor=&size= | 최근 30일 내 알림, 최신순. 항목 `{id, type, title, body, targetType, targetId, read, createdAt}`. 커서는 (created_at, id) | R-12 | FR-NOTI-05.AC2 |
| GET | /notifications/unread-count | `{count}`. 캘린더 앱바 알림 버튼의 점 표시용 | R-12 | FR-CAL-01.AC4 |
| PUT | /notifications/{id}/read | 읽음 처리 | R-12 | FR-NOTI-05.AC3 |

- `type`: `EVENT_REMINDER`, `PARTNER_CREATED`, `MEMO_PINNED`, `ANNIVERSARY`, `COUPLE_LINKED`, `COUPLE_UNLINKED`
- `targetType`: `EVENT`, `MEMO`, `ANNIVERSARY`, `SETTINGS` (FR-NOTI-03의 이동 대상). 이동 대상이 없으면 `targetType`, `targetId`는 null
- 다른 사람의 알림 ID나 없는 ID는 404 `NOT_FOUND`로 같게 응답한다 (R-12)
- `title`, `body`는 알림을 만들 때 서버가 PRD 8장 "알림 문구" 표대로 채워 저장한다. 푸시에도 같은 값을 보낸다 (D-46). 이름·제목이 나중에 바뀌어도 이미 만든 알림은 그대로다
- 대상 일정·메모가 지워져도 알림은 지우지 않는다. 앱은 알림을 누르면 먼저 `PUT /notifications/{id}/read`를 부르고, 대상 조회(`GET /events/{id}`, `GET /memos/{id}`)가 404면 "삭제된 일정이에요"·"삭제된 메모예요"를 보여주고 목록에 머문다 (FR-NOTI-05.AC5, D-43)

---

## 4. 핵심 흐름

여러 테이블을 함께 바꾸는 흐름은 모두 한 트랜잭션에서 처리한다. 커플 연결처럼 두 사람이 동시에 움직일 수 있는 흐름은 행 잠금(`SELECT … FOR UPDATE`)으로 순서를 보장한다.

### 4.1 게스트로 시작 (FR-AUTH-01)

1. 앱이 `POST /auth/guest`를 호출한다.
2. 서버가 `users`(GUEST, 닉네임 "게스트"), `notification_settings`, `spaces`(PERSONAL), `space_members`(색 주황)를 만든다.
3. access 토큰(`sid` = 새 세션 ID)과 refresh 토큰(365일)을 돌려준다. 앱은 refresh 토큰을 암호화해 저장한다.
4. 로그인 2종(게스트 시작, 소셜 로그인)은 모두 4.2의 "이전 세션·기기 정리"를 같은 코드로 처리한다. 게스트 시작은 방금 만든 사용자라 끊을 세션과 지울 기기가 없을 뿐이다. 게스트 연동(4.3)은 이 정리를 하지 않는다.
5. 앱을 지운 게스트의 서버 데이터는 API가 지우지 않는다. 유효한 세션이 없어진 게스트를 정리 작업이 탈퇴와 같이 삭제한다 (PRD Q-11, ERD 4.4 정리 작업).

### 4.2 소셜 로그인 (FR-AUTH-02)

1. 앱이 Google SDK에서 ID 토큰, Kakao SDK에서 액세스 토큰을 받아 `POST /auth/social`로 보낸다.
2. 서버가 제공자에게 검증한다 (NFR-SEC-01). 하나라도 어긋나면 401 `SOCIAL_TOKEN_INVALID`로 거부하고 아무것도 바꾸지 않는다.
   - **Google**: ID 토큰의 서명(구글 공개키), `iss`(`accounts.google.com`), `aud`(둘이서 앱의 클라이언트 ID), `exp`를 확인한다. 통과하면 토큰의 사용자 ID를 `provider_user_id`로 쓴다.
   - **Kakao**: `GET https://kapi.kakao.com/v1/user/access_token_info`로 토큰을 확인하고, 응답의 `app_id`가 서버에 설정된 둘이서 앱 ID와 같은지 본다. 같을 때만 응답의 사용자 ID를 `provider_user_id`로 쓴다. 다른 앱에서 발급된 토큰은 여기서 걸러진다.
3. `social_accounts`에 있으면 그 사용자로 로그인한다. 없으면 MEMBER 사용자와 개인 공간을 만들고 `isNewUser: true`를 돌려준다. 닉네임 기본값은 소셜 프로필 이름이고 10자가 넘으면 앞 10자만 쓴다 (FR-AUTH-07.AC1, D-56). 앱은 이때 SCR-COUPLE-01을 띄운다 (PRD D-31).
4. **이전 세션·기기 정리 (D-51)**: 3단계와 같은 트랜잭션에서 그 사용자의 다른 유효한 `auth_sessions`를 모두 `revoked_at` = 지금, `revoked_reason = REPLACED`로 바꾸고, 그 사용자의 `devices` 행을 모두 지운다. 새 세션의 access·refresh 토큰을 돌려준다.
5. 앱은 로그인 직후 `PUT /me/devices`로 새 기기의 FCM 토큰을 다시 등록한다. 이전 기기는 푸시를 받지 못하고, 다음 요청에서 401 `SESSION_REPLACED`를 받아 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여준 뒤 SCR-START-01로 이동한다 (1장).

### 4.3 게스트 → 회원 연동 (FR-AUTH-03)

1. 게스트가 `POST /auth/link`로 소셜 토큰을 보낸다. 4.2의 2단계처럼 검증한다. 실패하면 401 `SOCIAL_TOKEN_INVALID`.
2. `social_accounts`에 행을 넣는다. UNIQUE 위반이면 409 `SOCIAL_ALREADY_USED`로 거부하고 아무것도 바꾸지 않는다 (PRD Q-01).
3. `users.account_type`을 MEMBER로 바꾼다. 사용자 ID와 모든 데이터는 그대로다. 다음 토큰 갱신부터 회원 만료 정책(30일)을 쓴다.
4. 연동은 같은 기기에서 하므로 4.2의 4단계(이전 세션 `REPLACED`, `devices` 삭제)를 하지 않는다. 현재 세션과 `sid`, 등록된 FCM 토큰을 그대로 쓰고 응답에 새 토큰을 담지 않는다. 앱도 토큰을 바꾸거나 `PUT /me/devices`를 다시 부를 필요가 없다.

### 4.4 커플 연결과 기록 가져오기 (FR-COUPLE-01~03, 06)

1. A가 `POST /invite-codes`를 호출한다. 서버는 A의 가장 최근 코드 `created_at` + 60초가 지났는지 먼저 본다. 안 지났으면 429 `INVITE_REISSUE_TOO_SOON`과 `retryAfterSeconds`를 돌려준다. 지났으면 같은 트랜잭션에서 A의 사용되지 않은 이전 코드 모두(만료됐어도 `used_at`과 `revoked_at`이 null인 것 포함)에 `revoked_at`을 기록하고(부분 UNIQUE `creator_user_id` WHERE `used_at IS NULL AND revoked_at IS NULL`을 지키기 위해), 6자리 새 코드(`expires_at` = 지금 + 10분)를 만들어 `{code, expiresAt, reissueAvailableAt}`(= 생성 + 60초)을 돌려준다. 앱은 `GET /invite-codes/current`로 남은 시간과 `reissueAvailableAt`을 다시 읽을 수 있다 (FR-COUPLE-01). 코드가 만료되면 앱이 SCR-COUPLE-02를 보고 있는 동안(또는 다시 들어왔을 때) 같은 `POST /invite-codes`를 호출해 새 코드를 받는다. 만료 시점에는 마지막 발급 후 10분이 지났으므로 429가 나지 않는다. 서버에 따로 자동 발급 작업은 두지 않는다 (FR-COUPLE-01.AC5, D-42).
2. B가 `POST /couple/join`으로 코드를 보낸다. 서버는 `code`의 공백을 제거하고 대문자로 바꾼 뒤 비교한다 (FR-COUPLE-01.AC4). 먼저 최근 1시간 실패가 10회 이상인지 본다 (NFR-SEC-03). 시도는 성공·실패 모두 `invite_code_attempts`에 남긴다.
3. 코드 행을 잠그고 검사한다: 존재, 미만료, 미사용, 미무효, 만든 사람이 B가 아님, A와 B 모두 MEMBER이고 개인 공간에 있음. 실패마다 다른 오류 코드를 돌려준다 (FR-COUPLE-02.AC2, 5장). 재요청·자동 재발급으로 무효가 된 코드(`revoked_at` 있음)는 만료와 같은 `INVITE_EXPIRED`로 응답한다 (PRD D-47).
4. **복구 확인**: `purge_at`이 지나지 않았고 이전 구성원이 정확히 A와 B인 UNLINKED 커플 공간이 있으면, 그 공간을 다시 ACTIVE로 바꾸고 두 사람의 `space_members.left_at`과 공간의 `unlinked_at`, `purge_at`을 비운다 (FR-COUPLE-06). 없으면 새 커플 공간과 구성원(A 주황, B 파랑, 함께 보라)을 만든다.
5. A와 B의 개인 공간 소속에 `left_at`을 기록하고 코드를 사용 처리한다. 개인 공간 자체는 아직 지우지 않는다 (가져오기 대기).
6. 응답에 `restored`와, 개인 공간에 데이터가 있으면 `importPending: true`를 넣는다. A와 B 두 사람 각자에게 `notifications`(`COUPLE_LINKED`, `space_id` null) 행을 만들고, 두 사람 모두에게 푸시를 보낸다 (PRD 8장, 7장).
7. **커밋이 끝난 뒤** 두 사람의 기기 모두에 동기화 신호 `{"type":"SYNC","resource":"SPACE","action":"LINKED"}`를 보낸다 (6장). 보통의 신호는 다른 구성원에게만 가지만 이 신호는 입력한 B에게도 간다 (D-48).
8. **앱 동작** (D-48, FR-COUPLE-02.AC1·AC5): 두 사람 모두 SCR-CAL-01로 이동하고 그 위에 연결 완료 시트(SCR-COUPLE-04)가 뜬다.
   - B: `POST /couple/join` 응답을 받으면 바로 이동한다.
   - A(코드를 만든 쪽): 신호를 받으면 `GET /me`로 확인하고, 공간 종류가 COUPLE이면 이동한다. 신호가 늦거나 오지 않을 때를 대비해 SCR-COUPLE-02가 열려 있는 동안 5초마다 `GET /me`를 부른다. [연결 확인하기]도 같은 `GET /me`다. 아직 개인 공간이면 "아직 연결되지 않았어요"를 보여준다. 서버에 따로 대기 상태나 폴링 전용 경로는 없다.
   - 앱이 꺼져 있었으면 다음 실행 때 `GET /me`의 활성 공간 ID가 기기에 저장된 값과 다른 것을 보고(4.5의 6단계와 같은 방식) SCR-CAL-01과 시트를 띄운다. 서버는 시트를 봤는지를 저장하지 않는다.
9. 시트에서 두 사람은 각자 `POST /couple/import`로 고른다. `import: true`면 자기 개인 공간의 `events`, `anniversaries`, `memos`의 `space_id`를 커플 공간으로 바꾼 뒤 개인 공간을 지운다. `false`면 개인 공간을 지운다 (FR-COUPLE-03). 처음 만난 날은 같은 시트에서 `PATCH /space`로 정하며, 건너뛰어도 된다. 오늘보다 뒤의 날짜는 400 `VALIDATION_FAILED`로 거부한다 (FR-COUPLE-04.AC3).
10. 혼자 쓴 기록이 있어 `importPending`이 true인 사람은 고르기 전에는 시트를 닫을 수 없다. 고르지 않고 앱을 껐다가 다시 열었을 때 가져오기 대기 중인 개인 공간(소속에 `left_at`이 있는 PERSONAL 공간)이 남아 있으면 `GET /me`의 `importPending`이 계속 true이므로 앱이 시트를 다시 띄워 묻는다 (FR-COUPLE-03.AC4).

### 4.5 연결 해제 (FR-COUPLE-05)

1. 둘 중 한 명이 `DELETE /couple`을 호출한다.
2. 커플 공간을 UNLINKED로 바꾸고 `unlinked_at` = 지금, `purge_at` = 지금 + 30일로 기록한다. 두 구성원의 소속에 `left_at`을 기록한다.
3. 그 공간의 `event_reminders`를 삭제한다 (더 이상 볼 수 없는 일정의 알림이 가지 않도록). 같은 트랜잭션에서 그 공간의 `notifications`(`space_id` = 해제한 공간)도 두 사람 모두 삭제한다 (PRD D-45). 이 뒤에 만드는 `COUPLE_UNLINKED` 알림은 `space_id`가 null이라 남는다.
4. 두 사람 각자에게 새 개인 공간을 만든다. 사람 색은 기본값(주황)으로 시작한다.
5. 상대에게 `COUPLE_UNLINKED` 알림을 만들고, 상대 기기에 동기화 신호(`SPACE`, `UNLINKED`)와 해제 푸시를 보낸다 (7장). 탈퇴(4.6)로 인한 해제면 같은 `COUPLE_UNLINKED` 타입에 탈퇴 전용 문구를 쓴다: 제목 "[상대 이름]님이 탈퇴해 연결이 해제됐어요", 본문 "함께 쓴 기록은 더 이상 볼 수 없어요" (PRD 8장, D-53). 복구 안내("30일 안에 다시 연결하면…")는 넣지 않는다.
6. **앱 초기화** (PRD D-37): 해제한 사람은 응답을 받은 직후, 상대는 신호를 받거나 다음 실행 시 `GET /me`의 활성 공간 ID가 기기에 저장된 값과 다른 것을 확인하면, 로그인 정보를 뺀 로컬 데이터를 지우고 재시작해 자동 로그인한 뒤 SCR-COUPLE-01(연결 방법 선택)로 이동한다.

### 4.6 탈퇴 (FR-AUTH-06)

`DELETE /me`는 한 트랜잭션에서 ERD 4.3의 순서로 처리한다: 연결 해제 → 속했던 커플 공간 `purge_at`을 +90일로 연장 → 개인 공간 삭제 → 사용자 익명화. 커플 공간에 있던 사용자가 탈퇴하면 연결 해제 단계에서 상대에게 4.5의 5단계처럼 `COUPLE_UNLINKED` 알림·푸시·동기화 신호(`SPACE`, `UNLINKED`)를 보내되 문구는 탈퇴 전용(탈퇴해 연결이 해제됐어요, 복구 안내 없음)을 쓴다 (D-53). 문구의 [상대 이름]은 받는 사람 기준의 상대, 곧 탈퇴하는 사용자의 익명화 전 닉네임이다. 응답 후 앱은 로컬 데이터를 모두 지우고 SCR-START-01로 이동한다.

---

## 5. 오류 코드

| HTTP | code | 언제 | 관련 |
| --- | --- | --- | --- |
| 400 | VALIDATION_FAILED | 필수값 누락, 길이 초과(닉네임은 10자), 종료가 시작보다 이름, 날짜 범위 조회에서 `from` > `to`이거나 범위가 3개월 초과 (`GET /memos/dated`), 처음 만난 날이 오늘보다 뒤 (`PATCH /space`) | FR-CAL-02.AC3, NFR-LIMIT-01, FR-CAL-01.AC2, FR-COUPLE-04.AC3 |
| 400 | INVALID_TARGET | 개인 공간에서 '함께' 일정을 만들려 함 | R-10 |
| 401 | TOKEN_EXPIRED | access 토큰 만료 (앱이 refresh 후 재시도) | |
| 401 | SESSION_INVALID | 세션이 무효: refresh 토큰 만료·무효(이미 교체된 이전 refresh 토큰 재사용 포함), 로그아웃·탈퇴로 끊긴 세션의 토큰 (시작 화면으로). 다른 기기 로그인으로 끊긴 경우는 `SESSION_REPLACED` | 1장 |
| 401 | SESSION_REPLACED | 다른 기기 로그인으로 이 기기의 세션이 끊김. 앱은 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여주고 로컬 데이터를 지운 뒤 SCR-START-01로 이동 | D-51, FR-AUTH-02.AC3 |
| 401 | SOCIAL_TOKEN_INVALID | 소셜 토큰 검증 실패: Google은 서명·`iss`·`aud`·`exp`, Kakao는 `app_id`가 맞지 않음 (`/auth/social`, `/auth/link`) | NFR-SEC-01 |
| 403 | NOT_AUTHOR | 작성자가 아닌 수정·삭제, 작성자가 아닌 사용자의 일정 대상(`isTogether`) 변경 | R-02, R-03, R-05, R-13 |
| 403 | GUEST_NOT_ALLOWED | 게스트의 커플 연결 시도 | R-09, D-07 |
| 404 | NOT_FOUND | 없거나 다른 공간의 리소스 | R-01 |
| 404 | INVITE_NOT_FOUND | 존재하지 않는 초대코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_EXPIRED | 만료된 코드, 또는 재요청·자동 재발급으로 바뀐 이전 코드 | FR-COUPLE-01.AC2, FR-COUPLE-02.AC2 (D-47) |
| 409 | INVITE_USED | 이미 사용된 코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_SELF | 자신이 만든 코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_UNAVAILABLE | 코드를 만든 사람이 이미 다른 사람과 연결됨 | FR-COUPLE-02.AC3 |
| 409 | ALREADY_COUPLED | 요청자가 이미 커플 공간에 있음 | R-09 |
| 409 | NOT_COUPLE | 커플 공간이 필요한 요청을 개인 공간에서 보냄 | R-08 |
| 409 | SOCIAL_ALREADY_USED | 연동하려는 소셜 계정이 이미 다른 회원 | FR-AUTH-03.AC2 |
| 413 | IMAGE_TOO_LARGE | 프로필 사진 10MB 초과 | NFR-FILE-01 |
| 415 | IMAGE_TYPE_NOT_ALLOWED | JPEG·PNG가 아님 | NFR-FILE-01 |
| 429 | INVITE_RATE_LIMITED | 1시간 내 초대코드 오입력 10회 | NFR-SEC-03 |
| 429 | INVITE_REISSUE_TOO_SOON | 초대코드를 마지막 발급 후 60초 안에 재요청. 응답에 `retryAfterSeconds` | FR-COUPLE-01.AC3 |

---

## 6. 동기화 신호 (NFR-SYNC-01)

공간의 데이터가 바뀌면 서버는 그 공간의 **다른** 구성원 기기에 FCM 데이터 메시지를 보낸다. 사용자에게 보이는 알림이 아니며, 앱은 받은 즉시 해당 데이터를 다시 불러온다.

```json
{"type": "SYNC", "resource": "EVENT", "id": "0192…", "action": "UPDATED"}
```

- `resource`: `EVENT`, `ANNIVERSARY`, `MEMO`, `SPACE`(처음 만난 날, 사람 색, 구성원 변경), `NOTIFICATION`
- `action`: `CREATED`, `UPDATED`, `DELETED`, `UNLINKED`(`SPACE`만, 앱 초기화 신호), `LINKED`(`SPACE`만, 커플 연결 완료 신호)
- `LINKED`는 위 원칙(다른 구성원에게)의 예외다. 커플 연결 커밋 뒤 **두 사람의 기기 모두**에 `{"type": "SYNC", "resource": "SPACE", "action": "LINKED"}`를 보낸다 (`id` 없음). 앱은 받으면 `GET /me`로 확인하고 SCR-CAL-01과 연결 완료 시트로 이동한다 (4.4, D-48)
- `NOTIFICATION`은 위 원칙(공간의 다른 구성원에게)의 예외다. 알림 목록에 행이 생기면 **받는 사람 본인 기기**로 `{"type": "SYNC", "resource": "NOTIFICATION", "id": "<알림 ID>", "action": "CREATED"}`를 보낸다. 푸시를 끈 종류도 보낸다. 앱은 `GET /notifications/unread-count`를 다시 불러온다
- 커밋이 끝난 뒤에 보낸다 (트랜잭션이 실패하면 보내지 않음). 전송 실패는 재시도하지 않는다: 앱이 화면 진입 시 다시 불러오므로 (NFR-SYNC-02)

---

## 7. 알림 발송

**모든 알림 작업은 받는 사람마다 `notifications` 행을 먼저 만들고, 그 종류의 푸시 설정이 켜져 있을 때만 푸시를 보낸다.** 푸시를 끈 종류도 알림 목록에는 남는다 (FR-NOTI-05.AC1, D-39). 연결·해제 알림만 설정과 관계없이 항상 푸시한다. `notifications` 행을 만들 때 받는 사람 본인 기기로 동기화 신호 `NOTIFICATION`도 보낸다 (6장).

| 작업 | 주기 | 내용 | 관련 |
| --- | --- | --- | --- |
| 일정 알림 | 1분마다 | `fire_at <= now`이고 `sent_at`이 없는 `event_reminders`마다 `notifications`(`EVENT_REMINDER`) 행을 만들고 `sent_at` 기록. 사용자의 `event_reminder` 설정이 켜져 있을 때만 푸시. 일정 일시가 바뀌면 `PATCH /events/{id}`가 `fire_at`을 다시 계산해 둔다 | FR-CAL-05 |
| 기념일 알림 | 매시 정각 | 각 사용자의 시간대로 지금이 오전 9시인 사용자에게, 오늘이 기념일(자동·직접)이면 `notifications`(`ANNIVERSARY`) 행을 만들고 설정이 켜져 있을 때만 푸시. 제목은 둘 다 "오늘은 [기념일 이름]이에요". 본문은 자동 기념일이면 "함께한 지 D+[N]" (N = 그날의 D+ 값, 처음 만난 날 = D+1). 직접 기념일이면 `repeats_yearly`이고 올해가 등록한 `date`의 해보다 뒤일 때 "[N]번째 맞는 날이에요" (N = 올해 − 등록 연도 + 1), 그 밖에는 "오늘이에요" | D-32, D-55 |
| 상대 활동 알림 | 즉시 | 커플 공간에서 `notifyPartner = true`로 일정·메모를 만들었을 때(`PARTNER_CREATED`), 메모를 고정했을 때(`MEMO_PINNED`) 상대의 `notifications` 행을 만들고, 상대의 `partner_created`, `memo_pinned` 설정이 켜져 있을 때만 푸시 | D-27, D-35 |
| 연결·해제·탈퇴 알림 | 즉시 | 연결 완료: 두 사람 각자에게 `notifications`(`COUPLE_LINKED`, `space_id` null) 행을 만들고 두 사람 모두에게 푸시. 해제: 상대에게만 `notifications`(`COUPLE_UNLINKED`, `space_id` null) 행을 만들고 푸시. 탈퇴로 인한 해제: 상대에게만 같은 `COUPLE_UNLINKED` 타입으로 만들되 제목 "[상대 이름]님이 탈퇴해 연결이 해제됐어요", 본문 "함께 쓴 기록은 더 이상 볼 수 없어요" (복구 안내 없음). 모두 설정과 관계없이 항상 푸시 | PRD 8장, D-53, FR-AUTH-06.AC2 |
| 알림 목록 정리 | 매일 03:00 KST | `created_at`이 30일 지난 `notifications` 삭제. ERD의 정리 작업이 하며 API는 별도로 지우지 않는다 | FR-NOTI-05.AC2, ERD DB-07 |

단일 서버 인스턴스를 가정한다 (ERD DB-03). 서버를 여러 대로 늘리면 스케줄러 중복 실행 방지(예: ShedLock)가 필요하다.

---

## 8. 프로필 사진 저장

- 업로드된 이미지는 서버에서 긴 변 512px JPEG로 다시 인코딩하고, 원본과 EXIF(촬영 위치 포함)는 버린다 (NFR-FILE-01)
- 저장소는 인터페이스로 감싸 개발 환경은 로컬 디스크, 운영 환경은 Amazon S3(서울 리전 ap-northeast-2)를 쓴다
- 객체 키는 `profile/{userId}/{uuid}.jpg`로 매번 새로 만들어 캐시 문제를 피하고, 교체 시 이전 파일을 지운다

---

## 9. PRD 추적표 (API)

| FR 영역 | API | 흐름·규칙 |
| --- | --- | --- |
| FR-AUTH-01~05 | /auth/*, /me | 1장(`sid`, 세션 검사), 4.1~4.3, 5장 |
| FR-AUTH-02.AC3 한 기기 로그인 (D-51) | /auth/guest, /auth/social, /auth/refresh (/auth/link는 정리 안 함) | 1장, 4.2, 4.3, 401 `SESSION_REPLACED` |
| FR-AUTH-05 로그아웃 (D-50) | POST /auth/logout | `devices` 삭제 |
| FR-AUTH-06 탈퇴 | DELETE /me | 4.6, 7장 (탈퇴 전용 해제 알림) |
| FR-AUTH-07 프로필 | /me, /me/profile-image, /users/{id}/profile-image | R-11, 8장, 닉네임 10자 |
| FR-AUTH-08 이용 동의, FR-AUTH-09 앱 밖 계정 삭제 요청 | API 없음(앱·웹) | |
| Q-11 게스트 정리 | API 없음 (정리 작업) | 4.1의 5단계, ERD 4.4 |
| FR-COUPLE-01~02, 06 | /invite-codes, /invite-codes/current, /couple/join, GET /me | 4.4, 6장(`LINKED`), R-09 |
| FR-COUPLE-03 | /couple/import | 4.4의 9~10단계 |
| FR-COUPLE-04 | PATCH /space | R-08, 4.4의 9단계(미래 날짜 거부) |
| FR-COUPLE-05 | DELETE /couple | 4.5 (알림 삭제 포함) |
| FR-CAL-01~03 | /events, GET /memos/dated, GET /notifications/unread-count | R-01, R-02, R-10, R-12, R-13 |
| FR-CAL-04 사람 색 | PATCH /space/colors | R-08 |
| FR-CAL-05 일정 알림 | /events/{id}/reminder, PATCH /events/{id} | R-07, 7장 |
| FR-ANNIV-01~04 | /anniversaries | R-05, 7장 (기념일 알림 문구) |
| FR-MEMO-01~03 | /memos | R-03 |
| FR-MEMO-04 | 삭제됨 (PRD v0.4). PATCH /memos/{id}/checklist-items/{itemId} 삭제됨 | |
| FR-MEMO-05 | /memos/pinned, /memos/{id}/pin | R-04 |
| FR-MEMO-06 | /memos/{id}/favorite, ?view=favorites | R-06 |
| FR-NOTI-01~04 | /me/devices, /me/notification-settings (게스트 포함, D-62), notifyPartner | 6장, 7장 |
| FR-NOTI-05 알림 목록 | /notifications, /notifications/unread-count, /notifications/{id}/read | R-12, 3.5, 6장, 7장 |
| FR-SET-01 | GET /me, GET /space | |
| D-57 메모 작성자 닉네임 | API 변경 없음 | 앱이 `GET /space`의 구성원 닉네임을 메모의 `author_id`와 맞춰 채운다 |
| FR-SET-02 정보 | API 없음(앱·웹) | |
