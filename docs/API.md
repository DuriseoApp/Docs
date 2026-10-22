# 둘이서 API 초안 (MVP v0.1)

> 기준 문서: 둘이서 PRD v0.6 (`docs/PRD.md`)
> 함께 보는 문서: `ERD.md` (테이블 정의), `ERD.png` (한눈에 보기)
> 작성일: 2026-10-17 (갱신: 2026-10-22, 응답 형식 1.1 추가)

이 문서는 둘이서 서버 API의 범위, 권한, 처리 흐름을 정한다. 요청·응답의 상세 스키마는 서버 코드의 OpenAPI(springdoc) 문서를 단일 기준으로 삼는다. PRD의 ID(FR, D, NFR, Q)와 ERD의 `DB-` 결정을 그대로 참조하며, PRD와 충돌하면 PRD가 우선이다.

---

## 1. 공통 규약

**응답은 성공이면 봉투 없이 리소스를 그대로, 실패면 오류 객체를 돌려준다. 성공·실패는 HTTP 상태 코드로 구분한다.** 앱은 오류의 `code`로 분기하고, `message`는 로그용이다. 사용자에게 보이는 문구는 앱이 `code`에 맞춰 디자인 시스템의 말투(해요체)로 쓴다.

- 모든 경로는 `/api/v1` 아래에 있다
- `/auth/guest`, `/auth/social`, `/auth/refresh`를 빼면 access 토큰(`Authorization: Bearer …`)이 필요하다. `POST /auth/switch`도 게스트의 access 토큰이 필요하다
- JSON 필드는 camelCase, 날짜는 `YYYY-MM-DD`, 일시는 ISO 8601 UTC (`2026-10-17T06:30:00Z`)
- **날짜 범위는 1950-01-01 ~ 2050-12-31이다 (PRD D-74, R-15).** 일정, 메모 날짜, 직접 기념일을 만들거나 고칠 때(쓰기) 이 밖의 날짜가 있으면 400 `DATE_OUT_OF_RANGE`다. 날짜 범위 조회(`GET /events`, `/anniversaries`, `/memos/dated`)는 다르다. 월 달력이 앞뒤 달 날짜도 그리므로 1950년 1월이나 2050년 12월에서는 `from`·`to`가 범위 밖으로 나간다. 이때 오류 없이 범위 안으로 잘라서 조회한다(R-15). 처음 만난 날은 1950-01-01보다 앞일 때만 이 코드이고, 오늘보다 뒤(2050년 이후 포함)면 `VALIDATION_FAILED`다. 서비스에서 검사하고 DB CHECK는 두지 않는다 (ERD DB-13)
- access 토큰 1시간, refresh 토큰은 회원 30일·게스트 365일, 사용할 때마다 교체 (PRD D-73, NFR-SEC-01, ERD DB-02). 로그인이 만료된 기기에는 푸시를 보내지 않는다 (R-16, 7장). 교체는 같은 세션 행의 토큰 해시와 만료를 갱신하는 것이라 `sid`는 로그인부터 로그아웃까지 바뀌지 않는다. 이전 refresh 토큰을 다시 보내면 401 `SESSION_INVALID`다
- **한 계정은 한 기기에서만 로그인한다 (PRD D-51).** access 토큰에는 발급한 `auth_sessions.id`가 `sid` 클레임으로 들어 있다. 서버는 서명·만료 검사 뒤 요청마다 그 세션이 무효인지 본다. 무효인 이유가 `REPLACED`(다른 기기 로그인으로 끊김)면 401 `SESSION_REPLACED`, 그 밖의 무효(로그아웃, 탈퇴, 만료)면 401 `SESSION_INVALID`를 돌려준다
- 앱은 401 `SESSION_REPLACED`를 받으면 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여주고 로컬 데이터를 지운 뒤 SCR-START-01로 이동한다 (FR-AUTH-02.AC3). `SESSION_INVALID`는 안내 없이 SCR-START-01로 보낸다. 이전 기기의 access 토큰이 이미 만료됐다면 `POST /auth/refresh`가 같은 기준으로 `SESSION_REPLACED`를 돌려주므로 안내는 그때 뜬다
- 입력 길이 제한은 NFR-LIMIT-01을 따르고, 넘으면 400 `VALIDATION_FAILED`이며 필드 이름은 `details.fields`에 담는다 (1.1)
- 목록은 커서 페이지네이션 (`cursor`, `size`, 응답의 `nextCursor`). 응답 모양은 1.1


### 1.1 응답 형식

`{success, data, error}` 같은 성공 봉투는 두지 않는다. 성공 여부는 HTTP 상태가 이미 알려 주고, 401 `SESSION_REPLACED` 같은 처리를 상태 코드에 걸어 두었기 때문이다. 오류를 200으로 돌려주지 않는다.

| 경우 | 상태 | 본문 |
| --- | --- | --- |
| 단건 조회·생성·수정 | 200 (생성은 201) | 리소스 객체 그대로 `{"id": "…", …}` |
| 페이지가 있는 목록 (`cursor`, `size`를 받는 경로) | 200 | `{"items": [ … ], "nextCursor": "…"}`. 마지막 페이지면 `nextCursor`는 `null`. 개수가 필요한 경로만 `totalCount`를 더한다 (`GET /anniversaries/past`) |
| 페이지가 없는 목록 (`GET /events`, `GET /anniversaries`, `GET /memos/dated`, `GET /memos/pinned`) | 200 | `{"items": [ … ]}` |
| 돌려줄 내용이 없는 성공 (삭제, 고정·즐겨찾기 켜고 끄기, 읽음 처리, 로그아웃 등) | 204 | 없음 |
| 모든 오류 (4xx, 5xx) | 5장의 상태 | 오류 객체 (아래) |

- 최상위는 항상 객체다. 배열을 그대로 돌려주지 않는다 (나중에 필드를 더해도 앱이 깨지지 않게).
- 값이 없는 필드는 빼지 않고 `null`로 보낸다.

**오류 객체**

```json
{
  "code": "VALIDATION_FAILED",
  "message": "nickname: max 10",
  "details": { "fields": [ { "field": "nickname", "reason": "TOO_LONG" } ] },
  "traceId": "8f2c1d…"
}
```

| 필드 | 뜻 |
| --- | --- |
| `code` | 5장의 오류 코드. 앱은 이것으로만 분기한다 |
| `message` | 개발자용 설명. 로그에만 쓰고 화면에 보여주지 않는다. 바뀔 수 있다 |
| `details` | 코드마다 추가 정보. 없으면 `null`. 아래 표에 정한 것만 넣는다 |
| `traceId` | 요청 하나를 가리키는 ID. 서버 로그에서 이 값으로 찾는다. 응답 헤더 `X-Trace-Id`에도 같은 값을 넣는다. |

| `code` | `details` |
| --- | --- |
| `VALIDATION_FAILED`, `DATE_OUT_OF_RANGE` | `{"fields": [{"field": "<요청 필드 이름>", "reason": "<이유>"}]}`. `reason`은 `REQUIRED`(필수값 없음), `TOO_LONG`(길이 초과), `INVALID`(형식·값이 틀림: 종료가 시작보다 이름, 미래의 처음 만난 날, 조회 범위 3개월 초과 등), `OUT_OF_RANGE`(1950-01-01 ~ 2050-12-31 밖) |
| `INVITE_REISSUE_TOO_SOON`, `INVITE_RATE_LIMITED` | `{"retryAfterSeconds": 18}` |
| 그 밖의 코드 | `null` |

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
| R-14 | 게스트 전용 경로(`POST /auth/link`, `POST /auth/switch`): 요청자 = `account_type = GUEST`. 회원이 부르면 거부하고 아무것도 바꾸지 않는다 | 403 `GUEST_ONLY` | D-67, FR-AUTH-03 |
| R-15 | 날짜 범위: `events`의 시작·종료 날짜(일시는 요청자 `users.time_zone` 기준 날짜), `memos.memoDate`(null이 아닐 때), `anniversaries.date`, `spaces.start_date`는 1950-01-01 ~ 2050-12-31 안이어야 한다. 이 검사와 `DATE_OUT_OF_RANGE`는 쓰기(생성·수정) 요청에만 쓴다. 범위 조회(`GET /events`, `GET /anniversaries`, `GET /memos/dated`)의 `from`·`to`가 이 범위 밖이면 오류 없이 범위 안으로 잘라서 조회한다(`from`은 1950-01-01 이상, `to`는 2050-12-31 이하로). `from` > `to`와 3개월 초과 검사는 요청받은 값 그대로 먼저 하고, 잘라낸 뒤 조회 구간이 비면 빈 목록을 돌려준다. 처음 만난 날(`PATCH /space`)이 오늘보다 뒤면 범위와 관계없이 기존대로 `VALIDATION_FAILED`이고(2050년 이후 포함), `DATE_OUT_OF_RANGE`는 1950-01-01보다 앞일 때 나온다 | 400 `DATE_OUT_OF_RANGE` | D-74, FR-CAL-01.AC6, FR-COUPLE-04.AC3 |
| R-16 | 푸시 전송: 받는 사람에게 유효한 세션(`auth_sessions.revoked_at IS NULL AND expires_at > now`)이 있을 때만 보낸다. 알림 목록 행(`notifications`)은 세션과 관계없이 그대로 만든다. 동기화 신호(6장)는 그대로 보낸다 | (푸시 안 보냄, 오류 아님) | D-73, ERD DB-14, NFR-SEC-01 |
| R-17 | 회원 전용 `POST /auth/logout`: 요청자 = `account_type = MEMBER`. 게스트가 부르면 거부하고 아무것도 바꾸지 않는다. (커플 연결의 회원 전용 검사는 R-09) | 403 `GUEST_NOT_ALLOWED` | FR-AUTH-05, D-07 |

앱 화면에서 버튼을 숨기는 것은 사용성을 위한 것이고, 보안은 위 규칙으로만 보장한다.

---

## 3. API 목록

"권한" 열의 R-번호는 2장의 규칙이다.

### 3.1 인증·내 정보

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| POST | /auth/guest | 게스트 시작. 새 사용자라 끊을 이전 세션·기기는 없다 (4.1) | 없음 | FR-AUTH-01 |
| POST | /auth/social | 소셜 로그인 `{provider, token}`, 응답에 `isNewUser`. 같은 트랜잭션에서 그 사용자의 다른 유효 세션을 `REPLACED`로 끊고 `devices`를 모두 지운다 (4.2). 토큰 검증 실패는 401 `SOCIAL_TOKEN_INVALID` | 없음 | FR-AUTH-02, NFR-SEC-01 |
| POST | /auth/link | 게스트 → 회원 연동 `{provider, token}`. 같은 기기에서 하므로 현재 세션을 그대로 쓰고, 다른 세션을 끊거나 `devices`를 지우지 않으며 응답에 새 토큰도 담지 않는다 (4.3). 닉네임이 정확히 "게스트"면 소셜 프로필 이름으로 바꾼다 (D-68, D-69). 토큰 검증 실패는 401 `SOCIAL_TOKEN_INVALID`, 그 소셜 계정이 이미 다른 회원이면 409 `SOCIAL_ALREADY_USED`(이때 앱은 4.7로 이어간다), 회원이 부르면 403 `GUEST_ONLY` | R-14 (GUEST만) | FR-AUTH-03, NFR-SEC-01 |
| POST | /auth/switch | 게스트 → 기존 회원 계정 로그인 `{provider, token}`. 한 트랜잭션으로 게스트 계정·기록을 탈퇴와 같이 삭제하고 그 소셜 계정의 회원으로 로그인한다 (4.7, ERD DB-12). 응답은 `/auth/social`과 같다(`isNewUser: false`, 새 access·refresh 토큰). 토큰 검증 실패는 401 `SOCIAL_TOKEN_INVALID`, 회원이 부르면 403 `GUEST_ONLY`, 그 소셜 계정으로 가입한 회원이 없으면 404 `SOCIAL_NOT_REGISTERED`(아무것도 바꾸지 않음) | R-14 (GUEST만) | FR-AUTH-03.AC3, D-67, NFR-SEC-01 |
| POST | /auth/refresh | refresh 토큰 교체 발급 (같은 세션 행을 갱신하므로 `sid`는 그대로). 그 세션이 `REPLACED`로 끊겼으면 401 `SESSION_REPLACED`, 이전 refresh 토큰 재사용을 포함한 그 밖의 무효는 401 `SESSION_INVALID` | refresh 토큰 | NFR-SEC-01, FR-AUTH-02.AC3 |
| POST | /auth/logout | 현재 세션 무효화(`LOGOUT`)와 그 사용자의 `devices` 행 삭제. 이후 그 기기에는 푸시가 가지 않는다. 앱의 "다른 계정으로 로그인"(SCR-COUPLE-01, 회원)은 로그아웃 확인 뒤 이 호출을 하고 SCR-START-01로 이동하는 앱 동작이다 (D-80) | R-17 (MEMBER만) | FR-AUTH-05 |
| GET | /me | 내 정보 + 현재 공간 요약 (종류, 공간 ID, 상대, 사람 색, 처음 만난 날, `importPending`). SCR-COUPLE-02의 연결 확인 호출로도 쓴다 (4.4) | 로그인 | FR-SET-01, FR-COUPLE-02.AC5 |
| PATCH | /me | 닉네임(최대 10자, 넘으면 400 `VALIDATION_FAILED`), 시간대 변경 | 로그인 | FR-AUTH-07, NFR-LIMIT-01 |
| PUT | /me/profile-image | 프로필 사진 업로드 (multipart) | 로그인 | FR-AUTH-07.AC3 |
| DELETE | /me/profile-image | 프로필 사진 삭제 | 로그인 | FR-AUTH-07.AC5 |
| GET | /users/{id}/profile-image | 프로필 사진 조회 | R-11 | FR-AUTH-07 |
| DELETE | /me | 탈퇴. Kakao 회원이면 서버가 Kakao 앱 연결도 끊는다 (4.6, FR-AUTH-06.AC3) | 로그인 | FR-AUTH-06 |
| PUT | /me/devices | FCM 토큰 등록·갱신. 알림 권한 요청(Android 13 이상, 일정 알림 설정·커플 연결·직접 기념일 저장 때 처음)은 앱 동작이라 API가 없다 (D-70) | 로그인 | NFR-SYNC-01, FR-NOTI-01 |
| GET, PATCH | /me/notification-settings | 알림 설정 조회·변경. 게스트를 포함한 로그인 사용자 모두 가능 (D-62) | 로그인 (게스트 포함) | FR-NOTI-02 |

### 3.2 공간·커플

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /space | 현재 공간 상세 (구성원, 사람 색, 처음 만난 날) | 로그인 | FR-SET-01 |
| PATCH | /space | 처음 만난 날 변경 `{startDate}`. 요청자의 시간대(`users.time_zone`) 기준 오늘보다 뒤의 날짜는 400 `VALIDATION_FAILED`, 1950-01-01보다 앞의 날짜는 400 `DATE_OUT_OF_RANGE` | R-08, R-15 | FR-COUPLE-04.AC3, D-74 |
| PATCH | /space/colors | 사람 색 변경 `{members: [{userId, color}], together}` | R-08 | FR-CAL-04 |
| POST | /invite-codes | 초대코드 생성·재요청. 응답 `{code, expiresAt, reissueAvailableAt}`. 재요청하면 이전 코드는 즉시 만료. 마지막 발급 후 60초 안이면 429 `INVITE_REISSUE_TOO_SOON` (`details.retryAfterSeconds`) | R-09 | FR-COUPLE-01 |
| GET | /invite-codes/current | 내 유효한 초대코드와 남은 시간. 응답에 `reissueAvailableAt` 포함 (이 시각 전에는 재요청 불가) | R-09 | FR-COUPLE-01 |
| POST | /couple/join | 초대코드로 연결 `{code}`. 서버는 `code`의 공백을 제거하고 대문자로 바꿔서 비교한다. 응답에 `restored`, `importPending`. 커밋 뒤 두 사람 기기에 SYNC `SPACE`/`LINKED`를 보낸다 (4.4, 6장) | R-09 | FR-COUPLE-01.AC4, FR-COUPLE-02, 06 |
| POST | /couple/import | 기록 가져오기 결정 `{import: boolean}`. 결정하기 전에는 `GET /me`의 `importPending`이 계속 true라서 앱은 연결 완료 시트를 닫을 수 없고, 다음 실행 때 시트를 다시 띄운다 (4.4). 가져오기 대기 중인 개인 공간이 없으면(해제와 겹친 경우 포함) 409 `NO_IMPORT_PENDING` | 가져오기 대기 중인 본인 | FR-COUPLE-03 |
| DELETE | /couple | 연결 해제. 가져오기를 정하지 못한 구성원은 원래 개인 공간으로 돌아간다 (4.5의 4단계, D-78) | 커플 구성원 | FR-COUPLE-05 |

### 3.3 일정·기념일

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /events?from=&to= | 날짜 범위의 일정 (최대 3개월). 각 일정에 요청자의 알림만 포함. `from`·`to`가 1950-01-01 ~ 2050-12-31 밖이면 오류 없이 범위 안으로 잘라서 조회한다 | R-01, R-07, R-15 | FR-CAL-01, FR-CAL-01.AC6 |
| POST | /events | 일정 생성 `{title, note, isAllDay, start, end, isTogether, notifyPartner}`. `notifyPartner` 기본 true, 커플 공간에서만 의미 있음. 일정 알림(`event_reminders`)은 만들지 않는다: 기본값은 "없음"이고 `PUT /events/{id}/reminder`로 정한다 (D-59). 시작·종료 날짜가 1950-01-01 ~ 2050-12-31 밖이면 400 `DATE_OUT_OF_RANGE` | R-01, R-10, R-15 | FR-CAL-02, FR-NOTI-04, FR-CAL-01.AC6 |
| GET | /events/{id} | 일정 상세 | R-01 | FR-CAL-03 |
| PATCH | /events/{id} | 일정 수정 (수정 시에는 상대에게 알림 없음). `isTogether`를 바꾸는 요청은 작성자만 (R-13). 일시를 바꾸면 요청자가 누구든('함께' 일정이면 상대도) 그 일정에 알림을 건 모든 사용자의 `event_reminders.fire_at`을 새 일시 기준으로 다시 계산한다. 바뀐 날짜가 1950-01-01 ~ 2050-12-31 밖이면 400 `DATE_OUT_OF_RANGE` | R-02, R-10, R-13, R-15 | FR-CAL-03, FR-CAL-05.AC4, FR-CAL-01.AC6 |
| DELETE | /events/{id} | 일정 삭제 | R-02 | FR-CAL-03 |
| PUT | /events/{id}/reminder | 내 알림 설정 `{option}` | R-01, R-07 | FR-CAL-05 |
| DELETE | /events/{id}/reminder | 내 알림 끄기 | R-01, R-07 | FR-CAL-05 |
| GET | /anniversaries?from=&to= | **캘린더용.** 날짜 범위의 자동 + 직접 기념일을 합쳐 날짜순으로 (`kind: AUTO` 또는 `CUSTOM`). 범위는 최대 3개월이고 넘으면 400 `VALIDATION_FAILED`, `from`·`to`가 1950-01-01 ~ 2050-12-31 밖이면 오류 없이 범위 안으로 잘라서 조회한다. D-N 계산 포함. 개인 공간과 처음 만난 날이 없는 커플 공간에는 `AUTO`가 없고 `CUSTOM`만 나온다 (FR-ANNIV-04.AC2, AC4) | R-01, R-15 | FR-ANNIV-01~04, FR-CAL-01 |
| GET | /anniversaries/upcoming?cursor=&size= | **기념일 목록(SCR-ANNIV-01)용.** 요청자 시간대 기준 오늘(포함)부터 2050-12-31까지의 자동·직접 기념일 발생일을 날짜순으로 돌려준다. 매년 반복하는 기념일은 해마다 한 항목이다. 항목 `{anniversaryId, kind, name, date, daysLeft, repeatsYearly, authorId}`: `kind`는 `AUTO`·`CUSTOM`, `daysLeft`는 오늘이면 0 (앱이 "D-day"로 표시), `anniversaryId`와 `authorId`는 직접 기념일만 값이 있고 자동은 null. 커서는 (date, kind, anniversaryId). 처음 만난 날이 없는 커플과 개인 공간에는 `AUTO` 항목이 없다. 앱이 처음 만난 날 입력 안내를 보여주는 것은 커플이고 처음 만난 날이 없을 때만이고, 개인 공간은 `AUTO`만 없을 뿐 안내도 없다 (FR-ANNIV-04.AC2, AC4) | R-01 | FR-ANNIV-04.AC1·AC4, D-75 |
| GET | /anniversaries/past?cursor=&size= | **"지난 기념일"용.** `repeats_yearly = false`이고 `date`가 오늘(요청자 시간대)보다 앞인 직접 기념일만, 날짜 최근 순. 항목 `{anniversaryId, name, date, authorId}`. 응답에 `totalCount`(조건에 맞는 지난 1회성 직접 기념일 전체 개수, 페이지와 관계없음)도 넣는다. 앱은 접힌 행 "지난 기념일 N개"에 쓰고 0이면 행을 숨긴다 (D-71). 커서는 (date, anniversaryId). 수정·삭제는 기존 `PATCH, DELETE /anniversaries/{id}`(R-05)로 한다 | R-01 | FR-ANNIV-04.AC3, D-71 |
| POST | /anniversaries | 직접 기념일 생성. `date`가 1950-01-01 ~ 2050-12-31 밖이면 400 `DATE_OUT_OF_RANGE` | R-01, R-15 | FR-ANNIV-03, FR-CAL-01.AC6 |
| PATCH, DELETE | /anniversaries/{id} | 직접 기념일 수정·삭제. 수정할 `date`도 같은 범위 검사 | R-05, R-15 | FR-ANNIV-03 |

### 3.4 메모

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /memos?view=&cursor=&size= | 고정되지 않은 메모 목록. `view` = `newest`(기본), `oldest`, `favorites`. 커서는 (created_at, id). 각 항목에 `memoDate`(없으면 null) 포함 | R-01, R-06 | FR-MEMO-01 |
| GET | /memos/pinned | 고정 메모 전체, 최근 고정순. 앱은 3개만 보여주고 4개 이상이면 "더보기". 각 항목에 `memoDate` 포함 | R-01 | FR-MEMO-05 |
| GET | /memos/dated?from=&to= | 날짜 범위(최대 3개월)에 `memoDate`가 있는 메모. 캘린더용. 각 항목에 `memoDate` 포함. `from` > `to`이거나 범위가 3개월을 넘으면 400 `VALIDATION_FAILED`, `from`·`to`가 1950-01-01 ~ 2050-12-31 밖이면 오류 없이 범위 안으로 잘라서 조회한다 | R-01, R-15 | FR-CAL-01.AC2, FR-CAL-01.AC6 |
| POST | /memos | 메모 생성 `{title, body, memoDate, notifyPartner}`. `memoDate`는 `YYYY-MM-DD` 또는 생략·null이고, 날짜가 1950-01-01 ~ 2050-12-31 밖이면 400 `DATE_OUT_OF_RANGE`. 제목, 본문 중 하나 이상 필수 | R-01, R-15 | FR-MEMO-02, FR-NOTI-04, FR-CAL-01.AC6 |
| GET | /memos/{id} | 메모 상세 (요청자의 즐겨찾기 여부, `memoDate` 포함) | R-01, R-06 | FR-MEMO-03 |
| PATCH | /memos/{id} | 제목, 본문, 메모 날짜 수정 `{title, body, memoDate}`. `memoDate: null`이면 날짜 제거. 날짜 범위 검사는 POST와 같다 | R-03, R-15 | FR-MEMO-03, FR-CAL-01.AC6 |
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
4. 로그인 3종(게스트 시작, 소셜 로그인, 게스트 → 기존 계정 로그인)은 모두 4.2의 "이전 세션·기기 정리"를 같은 코드로 처리한다 (ERD DB-12). 게스트 시작은 방금 만든 사용자라 끊을 세션과 지울 기기가 없을 뿐이다. 게스트 → 기존 계정 로그인은 4.7이다. 게스트 연동(4.3)은 이 정리를 하지 않는다.
5. 앱을 지운 게스트의 서버 데이터는 API가 지우지 않는다. 유효한 세션이 없어진 게스트를 정리 작업이 탈퇴와 같이 삭제한다 (PRD Q-11, ERD 4.4 정리 작업).

### 4.2 소셜 로그인 (FR-AUTH-02)

1. 앱이 Google SDK에서 ID 토큰, Kakao SDK에서 액세스 토큰을 받아 `POST /auth/social`로 보낸다.
2. 서버가 제공자에게 검증한다 (NFR-SEC-01). 하나라도 어긋나면 401 `SOCIAL_TOKEN_INVALID`로 거부하고 아무것도 바꾸지 않는다.
   - **Google**: ID 토큰의 서명(구글 공개키), `iss`(`accounts.google.com`), `aud`(둘이서 앱의 클라이언트 ID), `exp`를 확인한다. 통과하면 토큰의 사용자 ID를 `provider_user_id`로 쓴다.
   - **Kakao**: `GET https://kapi.kakao.com/v1/user/access_token_info`로 토큰을 확인하고, 응답의 `app_id`가 서버에 설정된 둘이서 앱 ID와 같은지 본다. 같을 때만 응답의 사용자 ID를 `provider_user_id`로 쓴다. 다른 앱에서 발급된 토큰은 여기서 걸러진다.
3. `social_accounts`에 있으면 그 사용자로 로그인한다. 없으면 MEMBER 사용자와 개인 공간을 만들고 `isNewUser: true`를 돌려준다. 닉네임 기본값은 소셜 프로필 이름이고 10자가 넘으면 앞 10자만 쓴다 (FR-AUTH-07.AC1, D-56). 소셜 계정에서 이름을 받지 못했거나 공백뿐이면 "사용자"를 쓴다 (D-69). 앱은 이때 SCR-COUPLE-01을 띄운다 (PRD D-31).
4. **이전 세션·기기 정리 (D-51)**: (`POST /auth/switch`도 4.7에서 같은 코드를 쓴다.) 3단계와 같은 트랜잭션에서 그 사용자의 다른 유효한 `auth_sessions`를 모두 `revoked_at` = 지금, `revoked_reason = REPLACED`로 바꾸고, 그 사용자의 `devices` 행을 모두 지운다. 새 세션의 access·refresh 토큰을 돌려준다.
5. 앱은 로그인 직후 `PUT /me/devices`로 새 기기의 FCM 토큰을 다시 등록한다. 이전 기기는 푸시를 받지 못하고, 다음 요청에서 401 `SESSION_REPLACED`를 받아 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여준 뒤 SCR-START-01로 이동한다 (1장).

### 4.3 게스트 → 회원 연동 (FR-AUTH-03)

1. 게스트가 `POST /auth/link`로 소셜 토큰을 보낸다. 4.2의 2단계처럼 검증한다. 실패하면 401 `SOCIAL_TOKEN_INVALID`.
2. `social_accounts`에 행을 넣는다. UNIQUE 위반이면 409 `SOCIAL_ALREADY_USED`로 거부하고 아무것도 바꾸지 않는다 (PRD Q-01). 이때 앱은 "이미 가입된 계정이에요" 안내를 보여주고 4.7의 흐름으로 이어간다 (FR-AUTH-03.AC2).
3. `users.account_type`을 MEMBER로 바꾼다. 사용자 ID와 모든 데이터는 그대로다. 다음 토큰 갱신부터 회원 만료 정책(30일)을 쓴다.
4. **닉네임 (D-68, D-69)**: 같은 트랜잭션에서 `users.nickname`이 정확히 "게스트"면 소셜 프로필 이름(앞 10자)으로 바꾼다. 프로필 이름이 없거나 공백뿐이면 "사용자"로 바꾼다. "게스트"가 아닌 닉네임(사용자가 직접 바꾼 것)은 그대로 둔다. 응답에는 새 토큰이 없으므로 앱은 연동 뒤 `GET /me`로 닉네임을 다시 읽는다.
5. 연동은 같은 기기에서 하므로 4.2의 4단계(이전 세션 `REPLACED`, `devices` 삭제)를 하지 않는다. 현재 세션과 `sid`, 등록된 FCM 토큰을 그대로 쓰고 응답에 새 토큰을 담지 않는다. 앱도 토큰을 바꾸거나 `PUT /me/devices`를 다시 부를 필요가 없다.
6. **앱 동작 (D-79)**: 게스트가 커플 연결 메뉴의 [로그인하고 연결하기]로 연동을 시작했으면, 연동이 끝난 뒤 SCR-COUPLE-01(회원 화면)로 이동한다. API는 달라지지 않는다.

### 4.4 커플 연결과 기록 가져오기 (FR-COUPLE-01~03, 06)

1. A가 `POST /invite-codes`를 호출한다. 서버는 A의 가장 최근 코드 `created_at` + 60초가 지났는지 먼저 본다. 안 지났으면 429 `INVITE_REISSUE_TOO_SOON`과 `details.retryAfterSeconds`를 돌려준다. 지났으면 같은 트랜잭션에서 A의 사용되지 않은 이전 코드 모두(만료됐어도 `used_at`과 `revoked_at`이 null인 것 포함)에 `revoked_at`을 기록하고(부분 UNIQUE `creator_user_id` WHERE `used_at IS NULL AND revoked_at IS NULL`을 지키기 위해), 6자리 새 코드(`expires_at` = 지금 + 10분)를 만들어 `{code, expiresAt, reissueAvailableAt}`(= 생성 + 60초)을 돌려준다. 앱은 `GET /invite-codes/current`로 남은 시간과 `reissueAvailableAt`을 다시 읽을 수 있다 (FR-COUPLE-01). 코드가 만료되면 앱이 SCR-COUPLE-02를 보고 있는 동안(또는 다시 들어왔을 때) 같은 `POST /invite-codes`를 호출해 새 코드를 받는다. 만료 시점에는 마지막 발급 후 10분이 지났으므로 429가 나지 않는다. 서버에 따로 자동 발급 작업은 두지 않는다 (FR-COUPLE-01.AC5, D-42).
2. B가 `POST /couple/join`으로 코드를 보낸다. 서버는 `code`의 공백을 제거하고 대문자로 바꾼 뒤 비교한다 (FR-COUPLE-01.AC4). 먼저 최근 1시간 실패가 10회 이상인지 본다 (NFR-SEC-03). 시도는 성공·실패 모두 `invite_code_attempts`에 남긴다.
3. 코드 행을 잠그고 검사한다: 존재, 미만료, 미사용, 미무효, 만든 사람이 B가 아님, A와 B 모두 MEMBER이고 개인 공간에 있음. 실패마다 다른 오류 코드를 돌려준다 (FR-COUPLE-02.AC2, 5장). 재요청·자동 재발급으로 무효가 된 코드(`revoked_at` 있음)는 만료와 같은 `INVITE_EXPIRED`로 응답한다 (PRD D-47).
4. **복구 확인**: `purge_at`이 지나지 않았고 이전 구성원이 정확히 A와 B인 UNLINKED 커플 공간이 있으면, 그 공간을 다시 ACTIVE로 바꾸고 두 사람의 `space_members.left_at`과 공간의 `unlinked_at`, `purge_at`을 비운다 (FR-COUPLE-06). 없으면 새 커플 공간과 구성원(A 주황, B 파랑, 함께 보라)을 만든다.
5. 코드를 사용 처리하고, A와 B 각자의 개인 공간을 정한다 (D-78).
   - 혼자 쓴 기록(`events`, `anniversaries`, `memos`)이 있으면 소속에 `left_at`을 기록하고 공간은 지우지 않는다 (가져오기 대기).
   - 혼자 쓴 기록이 없으면 그 개인 공간을 같은 트랜잭션에서 바로 지운다. 그래서 가져오기 대기 중인 개인 공간은 기록이 있는 공간뿐이다.
6. 응답에 `restored`와 `importPending`을 넣는다. `importPending`은 요청자에게 가져오기 대기 중인 개인 공간(5단계에서 남긴 공간)이 있을 때만 true다. A와 B 두 사람 각자에게 `notifications`(`COUPLE_LINKED`, `space_id` null) 행을 만들고, 두 사람 모두에게 푸시를 보낸다 (PRD 8장, 7장).
7. **커밋이 끝난 뒤** 두 사람의 기기 모두에 동기화 신호 `{"type":"SYNC","resource":"SPACE","action":"LINKED"}`를 보낸다 (6장). 보통의 신호는 다른 구성원에게만 가지만 이 신호는 입력한 B에게도 간다 (D-48).
8. **앱 동작** (D-48, FR-COUPLE-02.AC1·AC5): 두 사람 모두 SCR-CAL-01로 이동하고 그 위에 연결 완료 시트(SCR-COUPLE-04)가 뜬다.
   - B: `POST /couple/join` 응답을 받으면 바로 이동한다.
   - A(코드를 만든 쪽): 신호를 받으면 `GET /me`로 확인하고, 공간 종류가 COUPLE이면 이동한다. 신호가 늦거나 오지 않을 때를 대비해 SCR-COUPLE-02가 열려 있는 동안 5초마다 `GET /me`를 부른다. [연결 확인하기]도 같은 `GET /me`다. 아직 개인 공간이면 "아직 연결되지 않았어요"를 보여준다. 서버에 따로 대기 상태나 폴링 전용 경로는 없다.
   - 앱이 꺼져 있었으면 다음 실행 때 `GET /me`의 활성 공간 ID가 기기에 저장된 값과 다른 것을 보고(4.5의 6단계와 같은 방식) SCR-CAL-01과 시트를 띄운다. 서버는 시트를 봤는지를 저장하지 않는다.
9. 시트에서 두 사람은 각자 `POST /couple/import`로 고른다. 가져오기 대기 중인 개인 공간이 없으면(이미 정했거나 연결 해제와 겹친 경우 포함) 409 `NO_IMPORT_PENDING`이고 아무것도 바꾸지 않는다. `import: true`면 자기 개인 공간의 `events`, `anniversaries`, `memos`의 `space_id`를 커플 공간으로 바꾼 뒤 개인 공간을 지운다. `false`면 개인 공간을 지운다 (FR-COUPLE-03). 처음 만난 날은 같은 시트에서 `PATCH /space`로 정하며, 건너뛰어도 된다. 오늘보다 뒤의 날짜는 400 `VALIDATION_FAILED`, 1950-01-01보다 앞의 날짜는 400 `DATE_OUT_OF_RANGE`로 거부한다 (FR-COUPLE-04.AC3, D-74, R-15). 앱은 기록 선택을 [가져오기]로 미리 선택해 보여주고, [시작하기] 전에는 시트를 닫지 못하게 한다 (D-76, 앱 동작).
10. `importPending`은 6단계와 같은 정의다: 가져오기 대기 중인 개인 공간(소속에 `left_at`이 있는 PERSONAL 공간, 곧 기록이 있는 공간)이 남아 있을 때만 true다. true인 사람은 고르기 전에는 시트를 닫을 수 없다(혼자 쓴 기록이 없는 사람은 대기 공간이 없어 false이고 바로 닫을 수 있다). 고르지 않고 앱을 껐다가 다시 열었을 때 대기 공간이 남아 있으면 `GET /me`의 `importPending`이 계속 true이므로 앱이 시트를 다시 띄워 묻는다 (FR-COUPLE-03.AC4). 고르기 전에 연결이 해제되면 4.5의 4단계가 이 공간을 되살린다 (D-78).
11. 알림 권한: 커플 연결도 앱이 알림 권한을 처음 묻는 시점 중 하나다 (D-70, 앱 동작, API 없음).

### 4.5 연결 해제 (FR-COUPLE-05)

1. 둘 중 한 명이 `DELETE /couple`을 호출한다.
2. 커플 공간을 UNLINKED로 바꾸고 `unlinked_at` = 지금, `purge_at` = 지금 + 30일로 기록한다. 두 구성원의 소속에 `left_at`을 기록한다.
3. 그 공간의 `event_reminders`를 삭제한다 (더 이상 볼 수 없는 일정의 알림이 가지 않도록). 같은 트랜잭션에서 그 공간의 `notifications`(`space_id` = 해제한 공간)도 두 사람 모두 삭제한다 (PRD D-45). 이 뒤에 만드는 `COUPLE_UNLINKED` 알림은 `space_id`가 null이라 남는다.
4. 두 사람 각자의 개인 공간을 정한다 (D-78).
   - **가져오기 대기 중인 개인 공간이 남아 있는 구성원**(소속에 `left_at`이 있는 PERSONAL 공간. 4.4의 5단계에서 기록이 있어 남겨 둔 공간뿐이다. ERD 4.2와 같은 조건): 새 개인 공간을 만들지 않고 그 공간의 `space_members.left_at`을 비워 다시 활성 공간으로 쓴다. 혼자 쓴 기록이 그대로 돌아오고, 사람 색도 소속 행이 그대로라 이전 값이다. 그 사람의 `GET /me`의 `importPending`은 false가 된다.
   - **그 밖의 구성원**(그런 개인 공간이 남아 있지 않은 경우): 새 빈 개인 공간을 만든다. 사람 색은 기본값(주황)으로 시작한다.
5. 상대에게 `COUPLE_UNLINKED` 알림을 만들고, 상대 기기에 동기화 신호(`SPACE`, `UNLINKED`)와 해제 푸시를 보낸다 (7장). 탈퇴(4.6)로 인한 해제면 같은 `COUPLE_UNLINKED` 타입에 탈퇴 전용 문구를 쓴다: 제목 "[상대 이름]님이 탈퇴해 연결이 해제됐어요", 본문 "함께 쓴 기록은 더 이상 볼 수 없어요" (PRD 8장, D-53). 복구 안내("30일 안에 다시 연결하면…")는 넣지 않는다.
6. **앱 초기화** (PRD D-37): 해제한 사람은 응답을 받은 직후, 상대는 신호를 받거나 다음 실행 시 `GET /me`의 활성 공간 ID가 기기에 저장된 값과 다른 것을 확인하면, 로그인 정보를 뺀 로컬 데이터를 지우고 재시작해 자동 로그인한 뒤 SCR-COUPLE-01(연결 방법 선택)로 이동한다.

### 4.6 탈퇴 (FR-AUTH-06)

`DELETE /me`는 한 트랜잭션에서 ERD 4.3의 순서로 처리한다: 연결 해제 → 속했던 커플 공간 `purge_at`을 +90일로 연장 → 개인 공간 삭제 → 사용자 익명화. **Kakao 연결 끊기 (FR-AUTH-06.AC3)**: 탈퇴 트랜잭션이 **커밋된 뒤에** 호출한다. `social_accounts.provider`가 `KAKAO`면 트랜잭션 안에서 행을 지우기 전에 `provider_user_id`를 읽어 두고, 커밋 뒤 Kakao 연결 끊기 API(`POST https://kapi.kakao.com/v1/user/unlink`, `target_id_type=user_id`, `target_id` = 읽어 둔 `provider_user_id`)를 서버의 Kakao 어드민 키로 호출한다. 어드민 키는 서버 설정값이며 문서와 로그에 쓰지 않는다. 호출이 실패하거나 시간이 초과돼도 이미 끝난 탈퇴를 되돌리지 않고 실패했다는 사실만 로그에 남긴다(키·토큰 제외). 외부 호출은 트랜잭션 밖이라 응답이 길어지지 않도록 짧은 제한 시간을 둔다. Google 회원과 게스트(4.7 포함)는 이 단계가 없다. 커플 공간에 있던 사용자가 탈퇴하면 연결 해제 단계에서 상대에게 4.5의 5단계처럼 `COUPLE_UNLINKED` 알림·푸시·동기화 신호(`SPACE`, `UNLINKED`)를 보내되 문구는 탈퇴 전용(탈퇴해 연결이 해제됐어요, 복구 안내 없음)을 쓴다 (D-53). 문구의 [상대 이름]은 받는 사람 기준의 상대, 곧 탈퇴하는 사용자의 익명화 전 닉네임이다. 응답 후 앱은 로컬 데이터를 모두 지우고 SCR-START-01로 이동한다.

### 4.7 게스트 → 기존 계정 로그인 (FR-AUTH-03.AC2~AC3, D-67)

게스트가 연동하려는 소셜 계정이 이미 회원이면, 게스트로 쓴 기록을 지우고 그 계정으로 로그인한다. 데이터는 합치지 않는다 (PRD Q-01). 게스트는 로그아웃이 없어 원래 계정으로 돌아갈 길이 이것뿐이다.

1. **앱 흐름**: `POST /auth/link`가 409 `SOCIAL_ALREADY_USED`를 돌려주면 앱은 "이미 가입된 계정이에요" 다이얼로그와 [그 계정으로 로그인]을 보여준다. 누르면 "게스트로 쓴 기록은 모두 삭제돼요" 확인 다이얼로그를 한 번 더 보여주고, 확인하면 같은 소셜 토큰으로 `POST /auth/switch`를 호출한다(소셜 SDK 토큰을 다시 받아도 된다). 두 다이얼로그 어디서든 취소하면 아무것도 호출하지 않고 게스트로 계속 쓴다.
2. 서버가 게스트의 access 토큰을 확인한다(R-14, 회원이면 403 `GUEST_ONLY`). 4.2의 2단계처럼 소셜 토큰을 검증한다. 실패하면 401 `SOCIAL_TOKEN_INVALID`로 거부하고 아무것도 바꾸지 않는다.
3. `social_accounts`에서 그 소셜 계정을 찾는다. 없으면 404 `SOCIAL_NOT_REGISTERED`로 거부하고 아무것도 바꾸지 않는다. 앱은 이때 `POST /auth/link`로 연동하면 된다.
4. **한 트랜잭션으로 처리한다 (ERD DB-12)**. 트랜잭션 안에서 먼저 `social_accounts`를 다시 조회하고 대상 회원 행을 잠근다(`SELECT … FOR UPDATE`). 3단계 조회와 트랜잭션 사이에 그 회원이 탈퇴했을 수 있기 때문이다. 행이 없거나 탈퇴한 회원이면 롤백하고 404 `SOCIAL_NOT_REGISTERED`를 돌려준다. 이때 게스트 계정은 그대로 남는다. 확인이 끝나면 다음을 처리한다:
   1. 게스트 사용자를 4.6의 탈퇴와 같이 처리한다: 게스트의 세션을 `WITHDRAWN`으로 끊은 뒤 삭제하고, 개인 공간과 기록을 삭제하고, 사용자를 익명화한다. 게스트는 커플 공간에 들어갈 수 없으므로 연결 해제 단계와 Kakao 연결 끊기는 없다.
   2. 4.2의 "이전 세션·기기 정리"를 같은 코드로 처리한다: 그 회원의 다른 유효한 세션은 `REPLACED`, `devices`는 모두 삭제.
   3. 그 회원의 새 세션을 만든다.
5. 응답은 `/auth/social`과 같다(`isNewUser: false`, 새 access·refresh 토큰). 트랜잭션이 실패하면 게스트 계정도 그대로 남는다.
6. **앱 동작**: 앱은 게스트의 토큰과 로컬 데이터를 지우고 새 토큰을 저장한 뒤 `PUT /me/devices`로 FCM 토큰을 다시 등록하고, `GET /me`로 그 계정의 현재 상태(개인 공간·커플 공간, `importPending`)로 이동한다. 이전 게스트 access 토큰으로 다시 요청하면 401 `SESSION_INVALID`다 (1장).
7. 다른 기기에서 그 회원 계정에 로그인해 있었다면 그 기기는 4단계의 2번(이전 세션 정리) 때문에 다음 요청에서 401 `SESSION_REPLACED`를 받는다 (1장).

---

## 5. 오류 코드

| HTTP | code | 언제 | 관련 |
| --- | --- | --- | --- |
| 400 | VALIDATION_FAILED | 필수값 누락, 길이 초과(닉네임은 10자), 종료가 시작보다 이름, 날짜 범위 조회에서 `from` > `to`이거나 범위가 3개월 초과 (`GET /memos/dated`), 범위가 3개월 초과 (`GET /anniversaries`), 처음 만난 날이 오늘보다 뒤 (`PATCH /space`, 2050년 이후 날짜도 이 코드) | FR-CAL-02.AC3, NFR-LIMIT-01, FR-CAL-01.AC2, FR-COUPLE-04.AC3 |
| 400 | DATE_OUT_OF_RANGE | 날짜가 1950-01-01 ~ 2050-12-31 밖: `POST/PATCH /events`, `POST/PATCH /memos`(`memoDate`), `POST/PATCH /anniversaries`(`date`), `PATCH /space`(`startDate`가 1950-01-01보다 앞일 때). 미래의 처음 만난 날은 `VALIDATION_FAILED`. 쓰기(생성·수정) 요청에만 쓴다. 범위 조회(`GET /events`, `/anniversaries`, `/memos/dated`)의 `from`·`to`가 밖이면 이 오류 없이 범위 안으로 잘라서 조회한다 | R-15, D-74, FR-CAL-01.AC6 |
| 400 | INVALID_TARGET | 개인 공간에서 '함께' 일정을 만들려 함 | R-10 |
| 401 | TOKEN_EXPIRED | access 토큰 만료 (앱이 refresh 후 재시도) | |
| 401 | SESSION_INVALID | 세션이 무효: refresh 토큰 만료·무효(이미 교체된 이전 refresh 토큰 재사용 포함), 로그아웃·탈퇴로 끊긴 세션의 토큰 (시작 화면으로). 다른 기기 로그인으로 끊긴 경우는 `SESSION_REPLACED` | 1장 |
| 401 | SESSION_REPLACED | 다른 기기 로그인으로 이 기기의 세션이 끊김. 앱은 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여주고 로컬 데이터를 지운 뒤 SCR-START-01로 이동 | D-51, FR-AUTH-02.AC3 |
| 401 | SOCIAL_TOKEN_INVALID | 소셜 토큰 검증 실패: Google은 서명·`iss`·`aud`·`exp`, Kakao는 `app_id`가 맞지 않음 (`/auth/social`, `/auth/link`, `/auth/switch`) | NFR-SEC-01 |
| 403 | NOT_AUTHOR | 작성자가 아닌 수정·삭제, 작성자가 아닌 사용자의 일정 대상(`isTogether`) 변경 | R-02, R-03, R-05, R-13 |
| 403 | GUEST_NOT_ALLOWED | 게스트가 회원 전용 기능(커플 연결, `/auth/logout`)을 부름 | R-09, R-17, D-07, FR-AUTH-05 |
| 403 | GUEST_ONLY | 게스트만 부를 수 있는 경로(`/auth/link`, `/auth/switch`)를 회원이 부름. `GUEST_NOT_ALLOWED`와 반대 경우다 | R-14, D-67, FR-AUTH-03 |
| 404 | NOT_FOUND | 없거나 다른 공간의 리소스 | R-01 |
| 404 | INVITE_NOT_FOUND | 존재하지 않는 초대코드 | FR-COUPLE-02.AC2 |
| 404 | SOCIAL_NOT_REGISTERED | `/auth/switch`에서 그 소셜 계정으로 가입한 회원이 없음. 아무것도 바꾸지 않으며 앱은 `/auth/link`로 연동하면 된다 | D-67, FR-AUTH-03.AC3 |
| 409 | NO_IMPORT_PENDING | `POST /couple/import`를 불렀는데 가져오기 대기 중인 개인 공간이 없음(이미 정했거나, 연결 해제와 겹침). 아무것도 바꾸지 않는다 | FR-COUPLE-03, D-78 |
| 409 | INVITE_EXPIRED | 만료된 코드, 또는 재요청·자동 재발급으로 바뀐 이전 코드 | FR-COUPLE-01.AC2, FR-COUPLE-02.AC2 (D-47) |
| 409 | INVITE_USED | 이미 사용된 코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_SELF | 자신이 만든 코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_UNAVAILABLE | 코드를 만든 사람이 이미 다른 사람과 연결됨 | FR-COUPLE-02.AC3 |
| 409 | ALREADY_COUPLED | 요청자가 이미 커플 공간에 있음 | R-09 |
| 409 | NOT_COUPLE | 커플 공간이 필요한 요청을 개인 공간에서 보냄 | R-08 |
| 409 | SOCIAL_ALREADY_USED | 연동하려는 소셜 계정이 이미 다른 회원 (`/auth/link`). 앱은 "이미 가입된 계정이에요"와 [그 계정으로 로그인]을 보여주고 확인 뒤 `/auth/switch`를 호출한다 (4.7) | FR-AUTH-03.AC2, AC3, D-67 |
| 413 | IMAGE_TOO_LARGE | 프로필 사진 10MB 초과 | NFR-FILE-01 |
| 415 | IMAGE_TYPE_NOT_ALLOWED | JPEG·PNG가 아님 | NFR-FILE-01 |
| 429 | INVITE_RATE_LIMITED | 1시간 내 초대코드 오입력 10회. `details.retryAfterSeconds`에 다시 입력할 수 있을 때까지 남은 초 | NFR-SEC-03 |
| 429 | INVITE_REISSUE_TOO_SOON | 초대코드를 마지막 발급 후 60초 안에 재요청. `details.retryAfterSeconds` | FR-COUPLE-01.AC3 |
| 500 | INTERNAL_ERROR | 서버 내부 오류. `details`는 `null`이고 `traceId`로 서버 로그를 찾는다. 앱은 공통 오류 안내를 보여준다 | 1.1 |

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

**모든 알림 작업은 받는 사람마다 `notifications` 행을 먼저 만들고, 푸시는 아래 두 조건을 모두 채울 때만 보낸다.** ① 받는 사람에게 유효한 세션이 있다(`auth_sessions.revoked_at IS NULL AND expires_at > now`, R-16, D-73, ERD DB-14). 로그인이 만료된 기기에는 푸시를 보내지 않는다. ② 그 종류의 푸시 설정이 켜져 있다. 연결·해제 알림만 ②를 보지 않고 설정과 관계없이 항상 푸시한다(①은 똑같이 본다). 푸시를 끈 종류나 유효 세션이 없는 사람의 알림도 알림 목록에는 남는다 (FR-NOTI-05.AC1, D-39). `notifications` 행을 만들 때 받는 사람 본인 기기로 동기화 신호 `NOTIFICATION`도 보낸다 (6장). 동기화 신호는 사용자에게 보이는 푸시가 아니라서 ①의 대상이 아니다.

알림 권한(Android 13 이상)은 앱이 일정 알림 설정, 커플 연결, 직접 기념일 저장 때 처음 한 번 요청한다. API는 없다 (D-70).

| 작업 | 주기 | 내용 | 관련 |
| --- | --- | --- | --- |
| 일정 알림 | 1분마다 | `fire_at <= now`이고 `sent_at`이 없는 `event_reminders`마다 `notifications`(`EVENT_REMINDER`) 행을 만들고 `sent_at` 기록. 사용자의 `event_reminder` 설정이 켜져 있고 유효 세션이 있을 때만 푸시. 일정 일시가 바뀌면 `PATCH /events/{id}`가 `fire_at`을 다시 계산해 둔다 | FR-CAL-05 |
| 기념일 알림 | 매시 정각 | 각 사용자의 시간대로 지금이 오전 9시인 사용자에게, 오늘이 기념일(자동·직접)이면 `notifications`(`ANNIVERSARY`) 행을 만들고 설정이 켜져 있고 유효 세션이 있을 때만 푸시. 처음 만난 날이 없는 커플과 개인 공간에는 자동 기념일이 없다 (FR-ANNIV-04.AC4). 제목은 둘 다 "오늘은 [기념일 이름]이에요". 본문은 자동 기념일이면 "함께한 지 D+[N]" (N = 그날의 D+ 값, 처음 만난 날 = D+1). 직접 기념일이면 `repeats_yearly`이고 올해가 등록한 `date`의 해보다 뒤일 때 "[N]번째 맞는 날이에요" (N = 올해 − 등록 연도 + 1), 그 밖에는 "오늘이에요" | D-32, D-55 |
| 상대 활동 알림 | 즉시 | 커플 공간에서 `notifyPartner = true`로 일정·메모를 만들었을 때(`PARTNER_CREATED`), 메모를 고정했을 때(`MEMO_PINNED`) 상대의 `notifications` 행을 만들고, 상대의 `partner_created`, `memo_pinned` 설정이 켜져 있고 유효 세션이 있을 때만 푸시 | D-27, D-35 |
| 연결·해제·탈퇴 알림 | 즉시 | 연결 완료: 두 사람 각자에게 `notifications`(`COUPLE_LINKED`, `space_id` null) 행을 만들고 두 사람 모두에게 푸시. 해제: 상대에게만 `notifications`(`COUPLE_UNLINKED`, `space_id` null) 행을 만들고 푸시. 탈퇴로 인한 해제: 상대에게만 같은 `COUPLE_UNLINKED` 타입으로 만들되 제목 "[상대 이름]님이 탈퇴해 연결이 해제됐어요", 본문 "함께 쓴 기록은 더 이상 볼 수 없어요" (복구 안내 없음). 모두 설정과 관계없이 항상 푸시(받는 사람에게 유효 세션이 있을 때) | PRD 8장, D-53, FR-AUTH-06.AC2 |
| 알림 목록 정리 | 매일 03:00 KST | `created_at`이 30일 지난 `notifications` 삭제. ERD의 정리 작업이 하며 API는 별도로 지우지 않는다 | FR-NOTI-05.AC2, ERD DB-07 |
| 로그인 만료 기기 정리 | 매일 | 만료된 세션을 지운 뒤 유효 세션이 없는 사용자의 `devices`를 지운다. ERD 4.4의 정리 작업이 하며 API는 별도로 지우지 않는다. 정리 전에도 푸시는 R-16으로 막힌다 | D-73, ERD DB-14 |

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
| FR-AUTH-02.AC3 한 기기 로그인 (D-51) | /auth/guest, /auth/social, /auth/switch, /auth/refresh (/auth/link는 정리 안 함) | 1장, 4.1, 4.2, 4.3, 4.7, 401 `SESSION_REPLACED` |
| FR-AUTH-03 게스트 → 회원 연동 (D-67, D-68, D-79) | POST /auth/link, POST /auth/switch | 4.3 (닉네임, 연동 뒤 SCR-COUPLE-01), 4.7, R-14 (403 `GUEST_ONLY`), 409 `SOCIAL_ALREADY_USED`, 404 `SOCIAL_NOT_REGISTERED`, ERD DB-12 |
| FR-AUTH-05 로그아웃 (D-50, D-80) | POST /auth/logout | R-17 (게스트는 403 `GUEST_NOT_ALLOWED`), `devices` 삭제, "다른 계정으로 로그인"은 같은 호출 (앱 동작) |
| FR-AUTH-06 탈퇴 | DELETE /me | 4.6 (AC3 Kakao 연결 끊기), 7장 (탈퇴 전용 해제 알림) |
| FR-AUTH-07 프로필 | /me, /me/profile-image, /users/{id}/profile-image | R-11, 8장, 닉네임 10자, 이름 없으면 "사용자" (D-69, 4.2, 4.3) |
| FR-AUTH-08 이용 동의, FR-AUTH-09 앱 밖 계정 삭제 요청 | API 없음(앱·웹) | |
| Q-11 게스트 정리 | API 없음 (정리 작업) | 4.1의 5단계, ERD 4.4 |
| FR-COUPLE-01~02, 06 | /invite-codes, /invite-codes/current, /couple/join, GET /me | 4.4, 6장(`LINKED`), R-09 |
| FR-COUPLE-03 | /couple/import | 4.4의 5·6·9·10단계 (빈 개인 공간은 바로 삭제, `importPending` 정의), 409 `NO_IMPORT_PENDING` (D-76은 앱 동작) |
| FR-COUPLE-04 | PATCH /space | R-08, R-15, 4.4의 9단계(미래 날짜 거부, 1950년 이전 `DATE_OUT_OF_RANGE`) |
| FR-COUPLE-05 | DELETE /couple | 4.5 (알림 삭제 포함, 4단계의 가져오기 대기 중 개인 공간 되살리기 D-78) |
| FR-CAL-01~03 | /events, GET /memos/dated, GET /notifications/unread-count | R-01, R-02, R-10, R-12, R-13 |
| FR-CAL-01.AC6 날짜 범위 1950~2050 (D-74) | POST/PATCH /events, /memos, /anniversaries, PATCH /space | R-15, 1장, 쓰기는 400 `DATE_OUT_OF_RANGE`, 범위 조회(GET /events, /anniversaries, /memos/dated)는 `from`·`to`를 범위 안으로 잘라서 조회, ERD DB-13 |
| FR-CAL-04 사람 색 | PATCH /space/colors | R-08 |
| FR-CAL-05 일정 알림 | /events/{id}/reminder, PATCH /events/{id} | R-07, 7장 |
| FR-ANNIV-01~04 | /anniversaries | R-05, 7장 (기념일 알림 문구) |
| FR-ANNIV-04 기념일 목록 (D-71, D-75) | GET /anniversaries/upcoming, GET /anniversaries/past, GET /anniversaries?from=&to= (캘린더용, 3개월) | R-01, R-05, `GET /anniversaries/past`의 `totalCount`, FR-ANNIV-04.AC4 처음 만난 날이 없으면 `AUTO` 없음 |
| FR-MEMO-01~03 | /memos | R-03 |
| FR-MEMO-04 | 삭제됨 (PRD v0.4). PATCH /memos/{id}/checklist-items/{itemId} 삭제됨 | |
| FR-MEMO-05 | /memos/pinned, /memos/{id}/pin | R-04 |
| FR-MEMO-06 | /memos/{id}/favorite, ?view=favorites | R-06 |
| FR-NOTI-01~04 | /me/devices, /me/notification-settings (게스트 포함, D-62), notifyPartner | 6장, 7장, R-16 (유효 세션이 있을 때만 푸시, D-73), 알림 권한은 앱 동작 (D-70) |
| NFR-SEC-01 토큰·세션 (D-73) | /auth/*, 푸시 전송 | 1장 토큰 수명, R-16, 7장, ERD DB-14 |
| FR-NOTI-05 알림 목록 | /notifications, /notifications/unread-count, /notifications/{id}/read | R-12, 3.5, 6장, 7장 |
| FR-SET-01 | GET /me, GET /space | |
| D-57 메모 작성자 닉네임 | API 변경 없음 | 앱이 `GET /space`의 구성원 닉네임을 메모의 `author_id`와 맞춰 채운다 |
| FR-SET-02 정보 | API 없음(앱·웹) | |
