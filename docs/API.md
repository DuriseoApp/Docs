# 둘이서 API 초안 (MVP v0.1)

> 기준 문서: 둘이서 PRD v0.9 (`docs/PRD.md`)
> 함께 보는 문서: `ERD.md` (테이블 정의), `ERD.png` (한눈에 보기)
> 작성일: 2026-10-17 (갱신: 2026-10-27, 공간·커플 응답 모양, 연결 오류 우선순위, Kakao 연결 해제 알림 웹훅 추가) (갱신: 2026-10-31, PRD v0.9: 일정 API 응답·쓰기·조회 규칙, 일정 알림 시각 계산, `MeSpace.importCounts`·`linkedAt`, `Space.linkedAt`)

이 문서는 둘이서 서버 API의 범위, 권한, 처리 흐름을 정한다. 인증·내 정보 API와 공간·커플 API, 일정 API의 요청·응답 모양은 3.1, 3.2, 3.3에 정했고, 그 밖의 요청·응답 상세 스키마는 서버 코드의 OpenAPI(springdoc) 문서를 단일 기준으로 삼는다. PRD의 ID(FR, D, NFR, Q)와 ERD의 `DB-` 결정을 그대로 참조하며, PRD와 충돌하면 PRD가 우선이다.

---

## 1. 공통 규약

**응답은 성공이면 봉투 없이 리소스를 그대로, 실패면 오류 객체를 돌려준다. 성공·실패는 HTTP 상태 코드로 구분한다.** 앱은 오류의 `code`로 분기하고, `message`는 로그용이다. 사용자에게 보이는 문구는 앱이 `code`에 맞춰 디자인 시스템의 말투(해요체)로 쓴다.

- 모든 경로는 `/api/v1` 아래에 있다
- access 토큰이 필요 없는 경로는 `/auth/guest`, `/auth/social`, `/auth/refresh`, `/webhooks/kakao/unlink`(Kakao 서버만 부르는 웹훅, 3.6) 넷뿐이고, 나머지는 access 토큰(`Authorization: Bearer …`)이 필요하다. `POST /auth/switch`도 게스트의 access 토큰이 필요하다
- JSON 필드는 camelCase, 날짜는 `YYYY-MM-DD`, 일시는 ISO 8601 UTC (`2026-10-17T06:30:00Z`)
- **날짜 범위는 1950-01-01 ~ 2050-12-31이다 (PRD D-74, R-15).** 일정, 메모 날짜, 직접 기념일을 만들거나 고칠 때(쓰기) 이 밖의 날짜가 있으면 400 `DATE_OUT_OF_RANGE`다. 날짜 범위 조회(`GET /events`, `/anniversaries`, `/memos/dated`)는 다르다. 월 달력이 앞뒤 달 날짜도 그리므로 1950년 1월이나 2050년 12월에서는 `from`·`to`가 범위 밖으로 나간다. 이때 오류 없이 범위 안으로 잘라서 조회한다(R-15). 처음 만난 날은 1950-01-01보다 앞일 때만 이 코드이고, 오늘보다 뒤(2050년 이후 포함)면 `VALIDATION_FAILED`다. 서비스에서 검사하고 DB CHECK는 두지 않는다 (ERD DB-13)
- access 토큰 1시간, refresh 토큰은 회원 30일·게스트 365일, 사용할 때마다 교체 (PRD D-73, NFR-SEC-01, ERD DB-02). 로그인이 만료된 기기에는 푸시를 보내지 않는다 (R-16, 7장). 교체는 같은 세션 행의 토큰 해시와 만료를 갱신하는 것이라 `sid`는 로그인부터 로그아웃까지 바뀌지 않는다. 이전 refresh 토큰을 다시 보내면 401 `SESSION_INVALID`다
- **토큰 형식 (PRD D-81, NFR-SEC-01).**
  - **access 토큰**은 JWT다. HS256으로 서버 비밀 키로 서명하고, 클레임은 `sub`(사용자 ID, uuid 문자열), `sid`(세션 ID = `auth_sessions.id`), `iat`, `exp`(발급 + 1시간)다. **계정 종류(GUEST·MEMBER)는 토큰에 넣지 않는다.** 연동(`POST /auth/link`) 직후 같은 토큰으로 판단이 바뀌어야 하므로 서버가 요청마다 DB에서 읽는다 (R-14, R-17).
  - **refresh 토큰**은 JWT가 아니라 보안 난수 32바이트를 base64url(패딩 없음)로 인코딩한 43자 무작위 문자열이다. 서버는 원문을 저장하지 않고 SHA-256 16진수 64자 해시만 `auth_sessions.refresh_token_hash`에 저장한다 (ERD DB-02). refresh 토큰은 세션 행으로 확인한다.
  - 요청 헤더는 `Authorization: Bearer <access>`다. `POST /auth/refresh`는 access 토큰 없이 본문 `{refreshToken}`만 보낸다
- **인증 실패 규칙과 검사 순서 (NFR-SEC-01).** access 토큰이 필요한 경로는 아래 순서로 검사하고 처음 걸린 것으로 응답한다.
  1. **형식·서명**: `Authorization` 헤더가 없음, `Bearer <토큰>` 형식이 아님, JWT 형식이 아님, 서명이 틀림, 필요한 클레임(`sub`, `sid`, `iat`, `exp`)이 없거나 값이 틀림 → 401 `SESSION_INVALID`
  2. **만료**: 서명은 맞고 `exp`가 지났음 → 401 `TOKEN_EXPIRED` (앱이 `POST /auth/refresh` 후 재시도)
  3. **세션**: `sid`의 세션이 무효이면 `REPLACED`는 401 `SESSION_REPLACED`, 그 밖의 무효(로그아웃, 탈퇴, 만료)는 401 `SESSION_INVALID` (아래 "한 계정은 한 기기에서만" 항목)
- **한 계정은 한 기기에서만 로그인한다 (PRD D-51).** access 토큰에는 발급한 `auth_sessions.id`가 `sid` 클레임으로 들어 있다. 서버는 서명·만료 검사 뒤(위 검사 순서) 요청마다 그 세션이 무효인지 본다. 무효인 이유가 `REPLACED`(다른 기기 로그인으로 끊김)면 401 `SESSION_REPLACED`, 그 밖의 무효(로그아웃, 탈퇴, 만료)면 401 `SESSION_INVALID`를 돌려준다
- 앱은 401 `SESSION_REPLACED`를 받으면 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여주고 로컬 데이터를 지운 뒤 SCR-START-01로 이동한다 (FR-AUTH-02.AC3). `SESSION_INVALID`는 안내 없이 SCR-START-01로 보낸다. 이전 기기의 access 토큰이 이미 만료됐다면 `POST /auth/refresh`가 같은 기준으로 `SESSION_REPLACED`를 돌려주므로 안내는 그때 뜬다
- **세션이 끝날 때 앱의 소셜 SDK 정리 (앱 동작, 서버 API 없음, FR-AUTH-05, FR-AUTH-06).** 로그아웃(204 뒤), 탈퇴(204 뒤), 세션 끊김(401 `SESSION_REPLACED`·`SESSION_INVALID`)이면 앱은 기기의 소셜 SDK 로그인 상태도 지운다: Kakao SDK 로그아웃(기기의 Kakao 토큰 삭제), Google Credential Manager 자격 증명 상태 지우기. 실패는 무시한다. Kakao 앱 연결 끊기는 서버가 한다 (4.6). 로그아웃·탈퇴 요청이 실패했을 때의 앱 동작은 3.1의 `POST /auth/logout`·`DELETE /me`
- 입력 길이 제한은 NFR-LIMIT-01을 따르고 글자 수는 유니코드 코드 포인트로 센다 (PRD D-82). 넘으면 400 `VALIDATION_FAILED`이며 필드 이름은 `details.fields`에 담는다 (1.1)
- 목록은 커서 페이지네이션 (`cursor`, `size`, 응답의 `nextCursor`). 응답 모양은 1.1


### 1.1 응답 형식

`{success, data, error}` 같은 성공 봉투는 두지 않는다. 성공 여부는 HTTP 상태가 이미 알려 주고, 401 `SESSION_REPLACED` 같은 처리를 상태 코드에 걸어 두었기 때문이다. 오류를 200으로 돌려주지 않는다.

| 경우 | 상태 | 본문 |
| --- | --- | --- |
| 단건 조회·생성·수정 | 200 (생성은 201) | 리소스 객체 그대로 `{"id": "…", …}` |
| 페이지가 있는 목록 (`cursor`, `size`를 받는 경로) | 200 | `{"items": [ … ], "nextCursor": "…"}`. 마지막 페이지면 `nextCursor`는 `null`. 개수가 필요한 경로만 `totalCount`를 더한다 (`GET /anniversaries/past`) |
| 페이지가 없는 목록 (`GET /events`, `GET /anniversaries`, `GET /memos/dated`, `GET /memos/pinned`) | 200 | `{"items": [ … ]}` |
| 돌려줄 내용이 없는 성공 (삭제, 고정·즐겨찾기 켜고 끄기, 읽음 처리, 로그아웃 등) | 204 | 없음 |
| Kakao 연결 해제 알림 웹훅 (`/webhooks/kakao/unlink`) | 200 | 없음. 위 "204" 규칙의 예외다. Kakao가 3초 안에 `200 OK`를 요구하고 처리 결과·서버 오류와 관계없이 200을 기대한다. 인증 실패만 401 (3.6) |
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
| R-08 | 처음 만난 날(`PATCH /space`)은 커플 공간의 구성원일 때만 허용한다. 사람 색(`PATCH /space/colors`)은 커플 공간의 구성원이면 허용하고, 개인 공간에서는 자기 색만 바꿀 수 있다 (`together`나 자기 밖 `userId`가 있으면 거부) | 409 `NOT_COUPLE` | FR-COUPLE-04, FR-CAL-04 |
| R-09 | 초대코드 생성·입력: `account_type = MEMBER`이고 개인 공간에 있을 것 | 403 `GUEST_NOT_ALLOWED` / 409 `ALREADY_COUPLED` | D-07 |
| R-10 | 일정 대상: 요청 본문은 `isTogether`만 받고 대상 사용자는 받지 않는다. 개인 공간에서 `isTogether = true`면 거부 | 400 `INVALID_TARGET` | D-34 |
| R-11 | 프로필 사진 조회: 본인 또는 같은 활성 공간의 구성원만 | 404 `NOT_FOUND` | NFR-FILE-01 |
| R-12 | 알림 조회·읽음 처리: `notifications.user_id` = 요청자. 알림 목록은 공간이 아니라 받은 사람 기준이므로 R-01 대신 이 규칙만 적용한다 | 404 `NOT_FOUND` | FR-NOTI-05.AC4 |
| R-13 | 일정 수정에서 `isTogether` 값을 바꾸는 요청은 요청자 = `author_id`일 때만. '함께' 일정을 상대가 수정할 때는 `isTogether`를 바꿀 수 없다 (R-02는 통과해도 R-13에서 거부). 값을 바꾸지 않는 요청은 R-02만 적용한다. 바꾸는 요청인지는 요청의 `isTogether`를 저장된 값과 비교해 정한다. 같은 값을 보내면 바꾸지 않는 요청이라 R-02만 적용한다 | 403 `NOT_AUTHOR` | D-52, FR-CAL-03.AC4 |
| R-14 | 게스트 전용 경로(`POST /auth/link`, `POST /auth/switch`): 요청자 = `account_type = GUEST`. 회원이 부르면 거부하고 아무것도 바꾸지 않는다 | 403 `GUEST_ONLY` | D-67, FR-AUTH-03 |
| R-15 | 날짜 범위: `events`의 시작·종료 날짜(일시는 요청자 `users.time_zone` 기준 날짜), `memos.memoDate`(null이 아닐 때), `anniversaries.date`, `spaces.start_date`는 1950-01-01 ~ 2050-12-31 안이어야 한다. 이 검사와 `DATE_OUT_OF_RANGE`는 쓰기(생성·수정) 요청에만 쓴다. 범위 조회(`GET /events`, `GET /anniversaries`, `GET /memos/dated`)의 `from`·`to`가 이 범위 밖이면 오류 없이 범위 안으로 잘라서 조회한다(`from`은 1950-01-01 이상, `to`는 2050-12-31 이하로). `from` > `to`와 3개월 초과 검사는 요청받은 값 그대로 먼저 하고, 잘라낸 뒤 조회 구간이 비면 빈 목록을 돌려준다. 처음 만난 날(`PATCH /space`)이 오늘보다 뒤면 범위와 관계없이 기존대로 `VALIDATION_FAILED`이고(2050년 이후 포함), `DATE_OUT_OF_RANGE`는 1950-01-01보다 앞일 때 나온다 | 400 `DATE_OUT_OF_RANGE` | D-74, FR-CAL-01.AC6, FR-COUPLE-04.AC3 |
| R-16 | 푸시 전송: 받는 사람에게 유효한 세션(`auth_sessions.revoked_at IS NULL AND expires_at > now`)이 있을 때만 보낸다. 알림 목록 행(`notifications`)은 세션과 관계없이 그대로 만든다. 동기화 신호(6장)는 그대로 보낸다 | (푸시 안 보냄, 오류 아님) | D-73, ERD DB-14, NFR-SEC-01 |
| R-17 | 회원 전용 `POST /auth/logout`: 요청자 = `account_type = MEMBER`. 게스트가 부르면 거부하고 아무것도 바꾸지 않는다. (커플 연결의 회원 전용 검사는 R-09) | 403 `GUEST_NOT_ALLOWED` | FR-AUTH-05, D-07 |
| R-18 | 커플 연결 해제(`DELETE /couple`): 요청자의 활성 공간이 `COUPLE`일 것. 기록 가져오기(`POST /couple/import`): 요청자에게 가져오기 대기 중인 개인 공간이 있을 것(그런 공간은 커플 공간에 있는 동안만 있다, D-78). 게스트·회원 구분 없이 이 조건만 본다. 둘이 동시에 해제하면 두 번째 요청은 잠금 뒤 개인 공간을 보고 `NOT_COUPLE`이다 | 409 `NOT_COUPLE` (`DELETE /couple`) / 409 `NO_IMPORT_PENDING` (`POST /couple/import`) | FR-COUPLE-05, FR-COUPLE-03, D-78 |

앱 화면에서 버튼을 숨기는 것은 사용성을 위한 것이고, 보안은 위 규칙으로만 보장한다.

---

## 3. API 목록

"권한" 열의 R-번호는 2장의 규칙이다.

### 3.1 인증·내 정보

"요청 → 성공" 열은 요청 본문과 성공 상태·응답 본문이다. `AuthTokens`, `Me`는 표 아래에 한 번 정의한다. 오류 응답은 1.1과 5장을 따른다.

| 메서드 | 경로 | 요청 → 성공 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- | --- |
| POST | /auth/guest | 본문 없음 → 201 `AuthTokens` (`isNewUser: true`) | 게스트 시작. 새 사용자라 끊을 이전 세션·기기는 없다 (4.1) | 없음 | FR-AUTH-01 |
| POST | /auth/social | `{provider: "GOOGLE" \| "KAKAO", token: string}` → 200 `AuthTokens` (신규 가입이면 `isNewUser: true`) | 소셜 로그인. 같은 트랜잭션에서 그 사용자의 다른 유효 세션을 `REPLACED`로 끊고 `devices`를 모두 지운다 (4.2). 토큰 검증 실패는 401 `SOCIAL_TOKEN_INVALID` | 없음 | FR-AUTH-02, NFR-SEC-01 |
| POST | /auth/link | `{provider, token}` → 204 (새 토큰 없음, 앱은 `GET /me`로 다시 읽음) | 게스트 → 회원 연동. 같은 기기에서 하므로 현재 세션을 그대로 쓰고, 다른 세션을 끊거나 `devices`를 지우지 않으며 응답에 새 토큰도 담지 않는다 (4.3). 닉네임이 정확히 "게스트"면 소셜 프로필 이름으로 바꾼다 (D-68, D-69). 토큰 검증 실패는 401 `SOCIAL_TOKEN_INVALID`, 그 소셜 계정이 이미 다른 회원이면 409 `SOCIAL_ALREADY_USED`(이때 앱은 4.7로 이어간다), 회원이 부르면 403 `GUEST_ONLY` | R-14 (GUEST만) | FR-AUTH-03, NFR-SEC-01 |
| POST | /auth/switch | `{provider, token}` → 200 `AuthTokens` (`isNewUser: false`) | 게스트 → 기존 회원 계정 로그인. 한 트랜잭션으로 게스트 계정·기록을 탈퇴와 같이 삭제하고 그 소셜 계정의 회원으로 로그인한다 (4.7, ERD DB-12). 새 access·refresh 토큰을 돌려준다. 토큰 검증 실패는 401 `SOCIAL_TOKEN_INVALID`, 회원이 부르면 403 `GUEST_ONLY`, 그 소셜 계정으로 가입한 회원이 없으면 404 `SOCIAL_NOT_REGISTERED`(아무것도 바꾸지 않음) | R-14 (GUEST만) | FR-AUTH-03.AC3, D-67, NFR-SEC-01 |
| POST | /auth/refresh | `{refreshToken: string}` (access 토큰 불필요) → 200 `AuthTokens` (`isNewUser: false`, 새 refresh 토큰) | refresh 토큰 교체 발급 (같은 세션 행을 갱신하므로 `sid`는 그대로). 그 세션이 `REPLACED`로 끊겼으면 401 `SESSION_REPLACED`, 이전 refresh 토큰 재사용을 포함한 그 밖의 무효는 401 `SESSION_INVALID` | refresh 토큰 | NFR-SEC-01, FR-AUTH-02.AC3 |
| POST | /auth/logout | 본문 없음 → 204 | 현재 세션 무효화(`LOGOUT`)와 그 사용자의 `devices` 행 삭제. 이후 그 기기에는 푸시가 가지 않는다. 앱의 "다른 계정으로 로그인"(SCR-COUPLE-01, 회원)은 로그아웃 확인 뒤 이 호출을 하고 SCR-START-01로 이동하는 앱 동작이다 (D-80). **앱 동작 (D-86)**: 쓰기와 같이 온라인에서만 부른다. 오프라인이면 부르지 않고 "인터넷 연결이 필요해요"를 보여준다. 응답이 401 `SESSION_REPLACED`·`SESSION_INVALID`면 이미 끊긴 세션이므로 1장 규칙대로 로컬을 지우고 SCR-START-01로 간다. 그 밖의 오류(5xx 포함)는 공통 오류 안내(D-88)를 보여주고 로그인 상태 그대로 둔다(기기 데이터와 토큰을 지우지 않는다). 204를 받으면 소셜 SDK 상태도 지운다 (1장) | R-17 (MEMBER만) | FR-AUTH-05.AC4, D-86, D-50 |
| GET | /me | → 200 `Me` | 내 정보 + 현재 공간 요약 (종류, 공간 ID, 상대, 사람 색, 처음 만난 날, 연결한 날 `linkedAt`, `importPending`, 가져오기 대기 기록 개수 `importCounts`). SCR-COUPLE-02의 연결 확인 호출로도 쓴다 (4.4) | 로그인 | FR-SET-01, FR-COUPLE-02.AC5 |
| PATCH | /me | `{nickname?: string, timeZone?: string}` → 200 `Me`. 없는 필드는 바꾸지 않는다. `null`을 보내면 400 `VALIDATION_FAILED`(`REQUIRED`) | 닉네임·시간대 변경. 닉네임은 앞뒤 공백을 지운 값으로 저장하고 코드 포인트 1~10개다: 지운 뒤 빈 값이면 400 `VALIDATION_FAILED`(`nickname`, `REQUIRED`), 10개 초과면 `TOO_LONG` (D-82). 시간대는 Java `ZoneId`로 해석되는 IANA 이름만이고 아니면 `VALIDATION_FAILED`(`timeZone`, `INVALID`). 새 사용자는 `Asia/Seoul`로 시작하고 앱이 실행 때 이 경로로 갱신한다 | 로그인 | FR-AUTH-07, NFR-LIMIT-01, NFR-TIME-01 |
| PUT | /me/profile-image | multipart (요청·응답 모양은 OpenAPI 기준) | 프로필 사진 업로드 | 로그인 | FR-AUTH-07.AC3 |
| DELETE | /me/profile-image | (OpenAPI 기준) | 프로필 사진 삭제 | 로그인 | FR-AUTH-07.AC5 |
| GET | /users/{id}/profile-image | (OpenAPI 기준) | 프로필 사진 조회 | R-11 | FR-AUTH-07 |
| DELETE | /me | 본문 없음 → 204 | 탈퇴. Kakao 회원이면 서버가 Kakao 앱 연결도 끊는다 (4.6, FR-AUTH-06.AC3). **앱 동작 (D-86)**: `POST /auth/logout`과 같다. 오프라인이면 부르지 않고 "인터넷 연결이 필요해요", `SESSION_REPLACED`·`SESSION_INVALID`면 로컬을 지우고 SCR-START-01, 그 밖의 오류는 공통 오류 안내(D-88)를 보여주고 로그인 상태 그대로 둔다. 204를 받으면 로컬 데이터와 소셜 SDK 상태를 지우고 SCR-START-01로 이동한다 | 로그인 | FR-AUTH-06, FR-AUTH-06.AC5, D-86 |
| PUT | /me/devices | `{fcmToken: string(최대 255), platform?: "ANDROID" \| "IOS"}` (`platform` 기본 `ANDROID`) → 204 | FCM 토큰 등록·갱신. `fcmToken`이 비었으면 400 `VALIDATION_FAILED`(`fcmToken`, `REQUIRED`), 255자를 넘으면 `TOO_LONG`, `platform`이 두 값이 아니면 `INVALID`. 알림 권한 요청(Android 13 이상, 일정 알림 설정·커플 연결·직접 기념일 저장 때 처음)은 앱 동작이라 API가 없다 (D-70) | 로그인 | NFR-SYNC-01, FR-NOTI-01 |
| GET, PATCH | /me/notification-settings | (OpenAPI 기준) | 알림 설정 조회·변경. 게스트를 포함한 로그인 사용자 모두 가능 (D-62) | 로그인 (게스트 포함) | FR-NOTI-02 |

**공통 응답 모양** (JSON 필드는 camelCase, 일시는 ISO 8601 UTC. 값이 없는 필드는 빼지 않고 `null`로 보낸다, 1.1)

`AuthTokens` (토큰을 주는 `/auth/guest`, `/auth/social`, `/auth/switch`, `/auth/refresh`의 응답 본문)

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `accessToken` | string | access JWT (1장) |
| `accessTokenExpiresAt` | 일시 | access 만료 시각 (발급 + 1시간) |
| `refreshToken` | string | refresh 토큰 원문 (43자). 앱은 암호화해 저장한다 |
| `refreshTokenExpiresAt` | 일시 | refresh 만료 시각 (회원 30일, 게스트 365일) |
| `isNewUser` | boolean | 이번 요청으로 사용자가 새로 만들어졌는지. `/auth/guest`는 `true`, `/auth/switch`·`/auth/refresh`는 `false`, `/auth/social`은 신규 가입이면 `true` |

`Me` (`GET /me`, `PATCH /me`의 응답 본문)

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `id` | uuid | 사용자 ID |
| `accountType` | `GUEST` \| `MEMBER` | `users.account_type` |
| `nickname` | string | |
| `timeZone` | string | IANA 시간대 (`users.time_zone`) |
| `providers` | (`GOOGLE` \| `KAKAO`)[] | 연결된 로그인 수단. 게스트는 `[]` (FR-SET-01) |
| `hasProfileImage` | boolean | 프로필 사진이 있는지. 이미지는 `GET /users/{id}/profile-image` |
| `createdAt` | 일시 | 가입일 (`users.created_at` 그대로, not null). 게스트가 연동한 회원은 게스트로 시작한 시각이다(계정이 그대로이므로). 앱은 기기 시간대 날짜로 바꿔 SCR-SET-01 회원 화면에 보여준다 (FR-SET-01) |
| `space` | `MeSpace` | 현재 활성 공간 요약 |

`MeSpace`

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `id` | uuid | 활성 공간 ID |
| `type` | `PERSONAL` \| `COUPLE` | |
| `myColor` | string | 내 사람 색 팔레트 키 (`pick-*`) |
| `partner` | `MePartner` \| null | 커플 공간의 상대. 개인 공간이면 `null` |
| `togetherColor` | string \| null | '함께' 색. 개인 공간이면 `null` |
| `startDate` | 날짜 \| null | 처음 만난 날. 개인 공간이거나 정하지 않았으면 `null` |
| `linkedAt` | 일시 \| null | 커플 공간이 연결된 시각 (`spaces.linked_at`). 유예 기간 안에 복구했으면 다시 연결한 시각이다. 개인 공간이면 `null`. 앱은 기기 시간대 날짜로 바꿔 SCR-SET-01 연결 정보의 "연결한 날"에 보여준다 (FR-SET-01.AC1, D-94) |
| `importPending` | boolean | 가져오기 대기 중인 개인 공간이 있는지 (FR-COUPLE-03, 4.4의 10단계). boolean 그대로 둔다(객체로 바꾸지 않음, 앱 호환) |
| `importCounts` | `ImportCounts` \| null | 가져오기 대기 중인 개인 공간(4.4의 5단계에서 남긴 공간)의 기록 개수. `importPending`이 `false`면 `null` (FR-COUPLE-03.AC1·AC2, D-93) |

`ImportCounts`: `events`(integer), `anniversaries`(integer, 직접 기념일 행 수. 자동 기념일은 저장하지 않으므로 세지 않는다), `memos`(integer). 각각 0 이상이고 합은 1 이상이다(대기 공간은 기록이 있는 공간뿐이다, 4.4의 5단계). 서버는 요청 때 대기 공간의 `events`, `anniversaries`, `memos` 행 수를 세고 따로 저장하지 않는다. 앱은 0개인 종류도 보여준다 (PRD Q-13 기본값).

`MePartner`: `id`(uuid), `nickname`(string), `color`(팔레트 키), `hasProfileImage`(boolean)

### 3.2 공간·커플

"요청 → 성공" 열은 3.1과 같은 형식이다. `InviteCode`, `CoupleJoinResult`, `Space`는 표 아래에 한 번 정의한다. 오류 응답은 1.1과 5장을 따른다.

| 메서드 | 경로 | 요청 → 성공 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- | --- |
| GET | /space | → 200 `Space` | 현재 공간 상세 (구성원, 사람 색, 처음 만난 날). SCR-SET-01·SCR-SET-03·메모 작성자 닉네임용 | 로그인 | FR-SET-01 |
| PATCH | /space | `{startDate: 날짜}` → 200 `Space` | 처음 만난 날 변경. 지우기는 없다(D-84). 검사 순서는 아래 "공간 변경 규칙" | R-08, R-15 | FR-COUPLE-04.AC1·AC3, D-74, D-84 |
| PATCH | /space/colors | `{members?: [{userId: uuid, color: string}], together?: string}` → 200 `Space` | 사람 색·'함께' 색 변경. 모든 필드 선택, 없는 필드는 바꾸지 않는다. 검사 순서는 아래 "공간 변경 규칙" | R-08 | FR-CAL-04 |
| POST | /invite-codes | 본문 없음 → 201 `InviteCode` | 초대코드 생성·재요청. 재요청하면 이전 코드는 즉시 만료. 마지막 발급 후 60초 안이면 429 `INVITE_REISSUE_TOO_SOON` (`details.retryAfterSeconds`, 계산은 4.4의 1단계) | R-09 | FR-COUPLE-01 |
| GET | /invite-codes/current | → 200 `InviteCode`. 유효한 코드가 없으면 404 `NOT_FOUND` | 내 유효한 초대코드와 남은 시간. `reissueAvailableAt` 전에는 재요청 불가. 유효한 코드가 없으면(만든 적 없음, 만료됨, 무효됨, 사용됨 모두) 404이고 앱은 `POST /invite-codes`를 부른다 (4.4의 1단계) | R-09 | FR-COUPLE-01.AC5, D-42 |
| POST | /couple/join | `{code: string}` → 200 `CoupleJoinResult` | 초대코드로 연결. 서버는 `code`의 공백을 제거하고 대문자로 바꿔서 비교한다. 오류 우선순위와 오입력 제한은 4.4의 2단계. 커밋 뒤 두 사람 기기에 SYNC `SPACE`/`LINKED`를 보낸다 (4.4, 6장) | R-09 | FR-COUPLE-01.AC4, FR-COUPLE-02, FR-COUPLE-06 |
| POST | /couple/import | `{import: boolean}` → 204 | 기록 가져오기 결정. 결정하기 전에는 `GET /me`의 `importPending`이 계속 true라서 앱은 연결 완료 시트를 닫을 수 없고, 다음 실행 때 시트를 다시 띄운다 (4.4). 가져오기 대기 중인 개인 공간이 없으면(해제와 겹친 경우 포함) 409 `NO_IMPORT_PENDING` | R-18 | FR-COUPLE-03 |
| DELETE | /couple | 본문 없음 → 204 | 연결 해제. 가져오기를 정하지 못한 구성원은 원래 개인 공간으로 돌아간다 (4.5의 4단계, D-78). 개인 공간이면 409 `NOT_COUPLE` | R-18 | FR-COUPLE-05 |

**공통 응답 모양** (JSON 필드는 camelCase, 일시는 ISO 8601 UTC. 값이 없는 필드는 빼지 않고 `null`로 보낸다, 1.1)

`InviteCode`

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `code` | string | 6자리 대문자 코드 |
| `expiresAt` | 일시 | 만료 시각 (생성 + 10분) |
| `reissueAvailableAt` | 일시 | 이 시각부터 재요청할 수 있음 (이 코드의 생성 + 60초) |

`CoupleJoinResult`

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `spaceId` | uuid | 연결된(또는 복구된) 커플 공간 ID |
| `restored` | boolean | 유예 기간 안의 이전 커플 공간을 복구했는지 (FR-COUPLE-06) |
| `importPending` | boolean | 요청자에게 가져오기 대기 중인 개인 공간이 있는지 (4.4의 6단계와 같은 정의) |

`Space`

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `id` | uuid | 활성 공간 ID |
| `type` | `PERSONAL` \| `COUPLE` | |
| `togetherColor` | string \| null | '함께' 색 팔레트 키. 개인 공간이면 `null` |
| `startDate` | 날짜 \| null | 처음 만난 날. 개인 공간이거나 정하지 않았으면 `null` |
| `linkedAt` | 일시 \| null | `MeSpace.linkedAt`과 같은 정의 (3.1). 커플 공간이 연결된 시각이고 복구하면 다시 연결한 시각, 개인 공간이면 `null` (D-94) |
| `members` | `SpaceMember`[] | 활성 구성원(`left_at IS NULL`). 개인 공간 1개, 커플 공간 2개. 순서는 뜻이 없고 앱은 `userId`로 나를 찾는다 |

`SpaceMember`: `userId`(uuid), `nickname`(string), `color`(팔레트 키), `hasProfileImage`(boolean)

- **팔레트 키 12개** (`design/tokens.json`의 `color.pick` 이름 그대로, 이 순서가 팔레트 순서): `pick-orange`, `pick-rose`, `pick-amber`, `pick-mustard`, `pick-green`, `pick-teal`, `pick-blue`, `pick-purple`, `pick-magenta`, `pick-brown`, `pick-gray`, `pick-ink`. 기본값: 나·만든 사람 `pick-orange`, 입력한 사람 `pick-blue`, 함께 `pick-purple` (FR-CAL-04, D-15)
- **앱 동작: 모르는 팔레트 키.** 앱은 위 12개 밖의 키를 받아도 오류로 보지 않는다. 값은 그대로 저장하고, 그릴 때 그 자리를 기본 사람 색 토큰(나 `person-me`, 상대 `person-partner`, 함께 `person-together`)으로 그리며 디버그 로그만 남긴다 (FR-CAL-04). 서버는 12개 밖의 키를 쓰지 않는다
- `Space`는 `MeSpace`를 대신하지 않는다. `GET /me`의 `MeSpace`는 요약이고 `Space`는 상세다.
- `PATCH /space`, `PATCH /space/colors`의 응답은 바뀐 뒤의 `Space` 전체다.

**공간 변경 규칙**

- `PATCH /space` (D-84) 검사 순서: ① R-08, 개인 공간이면 409 `NOT_COUPLE` → ② `startDate`가 없거나 `null`이면 400 `VALIDATION_FAILED`(`startDate`, `REQUIRED`), 날짜 형식이 아니면 `INVALID` → ③ 요청자의 시간대(`users.time_zone`) 기준 오늘보다 뒤면 400 `VALIDATION_FAILED`(`startDate`, `INVALID`) → ④ 1950-01-01보다 앞이면 400 `DATE_OUT_OF_RANGE`(`startDate`, `OUT_OF_RANGE`). 지우기(`null`)는 없다.
- `PATCH /space/colors` 필드는 모두 선택이다. 같은 색은 허용한다(경고는 앱, FR-CAL-04.AC4). 검사 순서:
  1. `members`와 `together`가 둘 다 없거나 `members`가 빈 배열이고 `together`도 없으면 400 `VALIDATION_FAILED`(`members`, `REQUIRED`). `members`나 `together`, `members[i].userId`, `members[i].color`가 `null`이면 400 `VALIDATION_FAILED`(해당 필드, `REQUIRED`)
  2. 개인 공간인데 `together`가 있거나 `members`에 자기 밖 `userId`가 있으면 409 `NOT_COUPLE` (R-08)
  3. 값 검사, 400 `VALIDATION_FAILED`(`INVALID`): 팔레트 키 12개 밖의 `color`·`together`(필드 `members[i].color`, `together`), 활성 공간 구성원이 아닌 `userId`(다른 공간 사용자도 같은 응답이라 존재를 드러내지 않는다, 필드 `members[i].userId`), 같은 `userId`가 두 번(필드 `members[i].userId`, 두 번째 것)
- `details.fields`의 `field`에서 배열 원소는 `members[0].color`처럼 0부터 센 인덱스로 쓴다 (1.1).
- `POST /couple/import`: R-18이 먼저다. 그다음 `import`가 없거나 `null`이면 400 `VALIDATION_FAILED`(`import`, `REQUIRED`).

### 3.3 일정·기념일

#### 일정

"요청 → 성공" 열은 3.1과 같은 형식이다(`?`는 선택 필드). `Event`, `EventReminder`는 표 아래에 한 번 정의한다. 오류 응답은 1.1과 5장을 따른다.

| 메서드 | 경로 | 요청 → 성공 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- | --- |
| GET | /events?from=&to= | → 200 `{items: Event[]}` (페이지 없음, 1.1) | 날짜 범위의 일정 (최대 3개월). 각 일정에 요청자의 알림만 포함. `from`·`to`가 1950-01-01 ~ 2050-12-31 밖이면 오류 없이 범위 안으로 잘라서 조회한다. 쿼리와 오류는 아래 "조회 규칙" | R-01, R-07, R-15 | FR-CAL-01, FR-CAL-01.AC6 |
| POST | /events | `{title, note?, isAllDay, start, end, isTogether?, notifyPartner?}` → 201 `Event` (`reminder`는 항상 `null`) | 일정 생성. `notifyPartner` 기본 true, 커플 공간에서만 의미 있음. 일정 알림(`event_reminders`)은 만들지 않는다: 기본값은 "없음"이고 `PUT /events/{id}/reminder`로 정한다 (D-59). 시작·종료 날짜가 1950-01-01 ~ 2050-12-31 밖이면 400 `DATE_OUT_OF_RANGE`. 규칙은 아래 "쓰기 규칙" | R-01, R-10, R-15 | FR-CAL-02, FR-NOTI-04, FR-CAL-01.AC6 |
| GET | /events/{id} | → 200 `Event` | 일정 상세 | R-01, R-07 | FR-CAL-03 |
| PATCH | /events/{id} | `{title?, note?, isAllDay?, start?, end?, isTogether?}` → 200 `Event` | 일정 수정 (수정 시에는 상대에게 알림 없음). `isTogether`를 바꾸는 요청은 작성자만 (R-13). 일시를 바꾸면 요청자가 누구든('함께' 일정이면 상대도) 그 일정에 알림을 건 모든 사용자의 알림을 아래 "다시 계산"대로 처리한다. 바뀐 날짜가 1950-01-01 ~ 2050-12-31 밖이면 400 `DATE_OUT_OF_RANGE`. 검사 순서는 아래 "검사 순서" | R-01, R-02, R-13, R-10, R-15 | FR-CAL-03, FR-CAL-05.AC4, FR-CAL-01.AC6 |
| DELETE | /events/{id} | 본문 없음 → 204 | 일정 삭제 | R-01, R-02 | FR-CAL-03 |
| PUT | /events/{id}/reminder | `{option}` → 200 `Event` (바뀐 `reminder` 포함) | 내 알림 설정. 같은 사용자·일정에 행 하나인 upsert라 같은 요청을 다시 보내도 같은 결과다. `option` 값은 아래 "일정 알림 `option`", 시각은 "알림 시각 계산". 끝난 일정에도 설정할 수 있다 (D-90) | R-01, R-07 | FR-CAL-05 |
| DELETE | /events/{id}/reminder | 본문 없음 → 204 | 내 알림 끄기. **알림이 없어도 204다**(멱등) | R-01, R-07 | FR-CAL-05 |

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
| `authorId` | uuid | 작성자. 닉네임은 응답에 넣지 않는다. 앱이 `GET /me`의 `MeSpace`(나는 `Me.id`·`Me.nickname`, 상대는 `partner`)나 `GET /space`의 `members`에서 이 ID로 찾는다 (FR-CAL-03.AC3). 활성 공간 일정의 작성자는 늘 그 공간의 구성원이다(구성원이 탈퇴하면 공간이 해제돼 활성 공간이 아니게 된다) |
| `updatedBy` | uuid \| null | 마지막 수정자. 만든 뒤 수정한 적이 없으면 `null` (`events.updated_by`) |
| `reminder` | `EventReminder` \| null | **요청자 자신의** 알림만 (R-07). 없으면 `null` |
| `createdAt`, `updatedAt` | 일시 | |

`EventReminder`: `option`(string, 아래 "일정 알림 `option`" 6개 중 하나), `fireAt`(일시. 이미 지난 시각일 수 있다, D-90). `sent_at`은 내보내지 않는다.

**조회 규칙** (`GET /events`)

| 항목 | 규칙 |
| --- | --- |
| 쿼리 | `from`, `to` 모두 필수, `YYYY-MM-DD`. `to`는 포함한다 |
| 오류 | 없으면 400 `VALIDATION_FAILED`(`from`/`to`, `REQUIRED`), 날짜 형식이 아니면 (`from`/`to`, `INVALID`), `from` > `to`이면 (`to`, `INVALID`), `to` > `from` + 3개월(달력 월로 더함, `from.plusMonths(3)`)이면 (`to`, `INVALID`) |
| 검사와 잘라내기 | 위 검사는 요청받은 값 그대로 먼저 하고, 그 뒤 1950-01-01 ~ 2050-12-31로 잘라낸다. 잘라낸 구간이 비면 `{items: []}` (R-15) |
| 걸치는 일정 | 범위에 하루라도 걸치는 일정. 종일: `start_date <= to AND end_date >= from`. 시간 일정: 요청자 `users.time_zone` 기준 `from` 00:00 ~ `to` 다음 날 00:00을 UTC로 바꿔 `start_at < 끝 AND end_at >= 시작` |
| 정렬 | 시작 날짜(종일은 `start_date`, 시간 일정은 요청자 시간대로 바꾼 `start_at`의 날짜) 오름차순 → 같은 날이면 종일 먼저 → 시간 일정은 `start_at` → `id`. 화면의 날짜 목록 순서(FR-CAL-01 AC2)는 앱이 맞춘다 |

**쓰기 규칙** (`POST`·`PATCH /events`)

| 항목 | 규칙 |
| --- | --- |
| `POST` 필수 | `title`, `isAllDay`, `start`, `end`. 없거나 `null`이면 400 `VALIDATION_FAILED`(해당 필드, `REQUIRED`) |
| `POST` 선택 | `note` 생략·`null` → null. `isTogether` 생략 → false. `notifyPartner` 생략 → true. `isTogether`·`notifyPartner`에 `null`을 보내면 `REQUIRED` (`PATCH /me`의 `null` 규칙과 같다) |
| `PATCH` | 부분 수정: 없는 필드는 바꾸지 않는다. `note: null`이면 일정 메모를 지운다. 그 밖의 필드에 `null`을 보내면 `REQUIRED`. `notifyPartner`는 받지 않는다(무시, 수정은 알리지 않음) |
| 제목 (D-89) | 앞뒤 공백을 지운 값으로 저장. 지운 뒤 빈 값이면 (`title`, `REQUIRED`), 코드 포인트 50개 초과면 (`title`, `TOO_LONG`) — 길이는 지운 뒤 센다 |
| 일정 메모 | 코드 포인트 1000개 초과면 (`note`, `TOO_LONG`) |
| 종일·시간 짝 | `isAllDay = true`면 `start`·`end`가 `YYYY-MM-DD`, `false`면 1장의 UTC 일시. 맞지 않으면 (`start` 또는 `end`, `INVALID`). `PATCH`에서 `isAllDay`를 바꾸면 `start`·`end`를 같은 요청에 함께 보내야 하고 빠지면 (빠진 필드, `REQUIRED`). `isAllDay`가 없는 `PATCH`의 `start`·`end`는 저장된 종류에 맞아야 한다 |
| 순서 | 종료가 시작보다 이르면 (`end`, `INVALID`). 같으면 저장한다 |
| 날짜 범위 (R-15) | `start`·`end` 각각 400 `DATE_OUT_OF_RANGE`(`start`/`end`, `OUT_OF_RANGE`). 둘 다 밖이면 둘 다 담는다. `VALIDATION_FAILED`가 하나라도 있으면 그것만 응답하고 `DATE_OUT_OF_RANGE`는 그 뒤에 본다(한 응답에 두 코드를 섞지 않는다) |
| 모르는 필드 | 무시한다. 대상 사용자 필드(`targetUserId` 등)도 무시라 효과가 없다 (R-10, ERD DB-06) |
| `details.fields` | 틀린 필드를 모두 담는다 |

**검사 순서** (단위 2의 R-08 → 400 순서와 같은 방식)

- `PATCH /events/{id}`: R-01(404 `NOT_FOUND`) → R-02(403 `NOT_AUTHOR`) → R-13(403 `NOT_AUTHOR`) → R-10(400 `INVALID_TARGET`) → 값 검사(400 `VALIDATION_FAILED`) → 날짜 범위(400 `DATE_OUT_OF_RANGE`)
- `DELETE /events/{id}`: R-01 → R-02
- `POST /events`: R-10 → 값 검사 → 날짜 범위
- `PUT`·`DELETE /events/{id}/reminder`: R-01 → 값 검사
- 권한 없는 사용자에게 필드 오류를 보여주지 않는다. `isTogether`가 boolean이 아니면 R-13·R-10은 건너뛰고 값 검사에서 (`isTogether`, `INVALID`)로 응답한다.

**일정 알림 `option`**

| 일정 종류 | 값 (ERD `ck_event_reminders_option` 그대로) | 화면 |
| --- | --- | --- |
| 시간 일정 | `AT_TIME`, `MIN_10`, `HOUR_1`, `DAY_1` | 정시, 10분 전, 1시간 전, 1일 전 |
| 종일 일정 | `ALLDAY_9AM`, `ALLDAY_PREV_9AM` | 당일 오전 9시, 1일 전 오전 9시 |

- 일정 종류와 맞지 않거나 모르는 값: 400 `VALIDATION_FAILED`(`option`, `INVALID`). 없거나 `null`: (`option`, `REQUIRED`).
- "없음"은 `DELETE /events/{id}/reminder`뿐이다. `NONE` 같은 값은 없다.
- `PUT`은 멱등 upsert다 (같은 사용자·일정에 행 하나, ERD `uq_event_reminders_event_user`).

**알림 시각 계산** (D-90, FR-CAL-05.AC5)

| `option` | `fire_at` |
| --- | --- |
| `AT_TIME` | `start_at` |
| `MIN_10` | `start_at` − 10분 |
| `HOUR_1` | `start_at` − 1시간 |
| `DAY_1` | `start_at` − 24시간 (서머타임이 있는 날도 24시간) |
| `ALLDAY_9AM` | `start_date` 09:00, **알림 주인**(`event_reminders.user_id`)의 `users.time_zone` 기준 → UTC |
| `ALLDAY_PREV_9AM` | (`start_date` − 1일) 09:00, 같은 시간대 기준 → UTC |

- 저장할 때(`PUT`, 아래 "다시 계산" 모두) 계산한 `fire_at` <= 지금이면 행은 저장하고 `sent_at` = 지금으로 기록해 보내지 않는다. 미래면 `sent_at` = null. 끝난 일정에도 `PUT`은 된다.

**다시 계산** (D-91, FR-CAL-05.AC4·AC6. 모두 같은 트랜잭션)

| 언제 | 처리 |
| --- | --- |
| `PATCH`로 `isAllDay`가 바뀜 | 그 일정의 `event_reminders`를 **모든 사용자 것** 삭제한다. 응답의 `reminder`는 `null` |
| `PATCH`로 `start`가 바뀜 (종류는 그대로) | 그 일정의 모든 행의 `fire_at`을 새 `start`로 다시 계산하고, `sent_at`은 위 규칙(지났으면 지금, 미래면 null)으로 다시 정한다. 이미 보낸 알림도 새 시각이 미래면 다시 보낸다 |
| `end`·제목·메모·대상만 바뀜 | 알림은 그대로 (`fire_at`은 시작 기준) |
| 사용자의 `time_zone`이 바뀜 (`PATCH /me`, 단위 1의 `UserTimeZoneChanged`) | 그 사용자의 행 중 `option`이 `ALLDAY_9AM`·`ALLDAY_PREV_9AM`이고 `sent_at IS NULL`인 것만 새 시간대로 다시 계산한다(지났으면 `sent_at` = 지금). 시간 일정 알림은 그대로 |

**상대 일정 추가 알림** (7장 "상대 활동 알림" 줄, D-92)

- 제목 "[작성자 닉네임]님이 일정을 추가했어요", 본문 "[날짜] · [일정 제목]" (PRD 8장).
- [날짜]: 종일은 `start_date`, 시간 일정은 받는 사람(상대)의 `users.time_zone`으로 바꾼 `start_at`의 날짜. 서식 "M월 d일 (E)", 요일은 한국어 한 글자(월~일), 연도 없음, 앞자리 0 없음. 예: "10월 17일 (토) · 1박 2일 여행". 여러 날 일정도 시작 날짜만 쓴다.
- 행: `type = PARTNER_CREATED`, `target_type = EVENT`, `target_id` = 일정 ID, `space_id` = 커플 공간. 개인 공간이거나 `notifyPartner = false`면 만들지 않는다.

#### 기념일

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
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
- `targetType`: `EVENT`, `MEMO`, `ANNIVERSARY`, `SETTINGS` (FR-NOTI-03의 이동 대상). `COUPLE_LINKED`, `COUPLE_UNLINKED`(해제·탈퇴로 인한 해제 모두)는 `SETTINGS`이고 `targetId`는 null이다. 앱은 누르면 설정(SCR-SET-01)으로 이동한다. 푸시를 눌러도 같다 (D-85). 그 밖에 이동 대상이 없으면 `targetType`, `targetId`는 둘 다 null
- 다른 사람의 알림 ID나 없는 ID는 404 `NOT_FOUND`로 같게 응답한다 (R-12)
- `title`, `body`는 알림을 만들 때 서버가 PRD 8장 "알림 문구" 표대로 채워 저장한다. 푸시에도 같은 값을 보낸다 (D-46). 이름·제목이 나중에 바뀌어도 이미 만든 알림은 그대로다
- 대상 일정·메모가 지워져도 알림은 지우지 않는다. 앱은 알림을 누르면 먼저 `PUT /notifications/{id}/read`를 부르고, 대상 조회(`GET /events/{id}`, `GET /memos/{id}`)가 404면 "삭제된 일정이에요"·"삭제된 메모예요"를 보여주고 목록에 머문다 (FR-NOTI-05.AC5, D-43)

### 3.6 웹훅

앱이 아니라 외부 서비스가 부르는 경로다.

| 메서드 | 경로 | 요청 → 성공 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- | --- |
| GET, POST | /webhooks/kakao/unlink | Kakao가 보내는 값(아래) → 200, 본문 없음 | Kakao 연결 해제 알림. 사용자가 Kakao 계정 설정에서 둘이서와의 연결을 끊으면 Kakao가 서버를 부른다. 탈퇴처럼 처리한다 (4.8). 전체 주소는 `https://<서버 주소>/api/v1/webhooks/kakao/unlink`다. **access 토큰이 필요 없는 경로**다 (1장) | Kakao 어드민 키 (아래 인증) | FR-AUTH-06.AC4, D-87 |

- **요청 (Kakao 문서 "연결 해제 웹훅" 기준, 2026-10-27 확인)**: 헤더 `Authorization: KakaoAK <대표 어드민 키>`. 값 `app_id`(필수), `user_id`(필수, Kakao 회원번호), `referrer_type`(필수: `ACCOUNT_DELETE`, `FORCED_ACCOUNT_DELETE`, `UNLINK_FROM_ADMIN`, `UNLINK_FROM_APPS`, `INCOMPLETE_SIGN_UP`), `group_user_token`(그룹 앱일 때만, 쓰지 않음). Kakao는 GET(쿼리 문자열)이나 POST(`application/x-www-form-urlencoded`)로 보낼 수 있어 같은 경로에서 둘 다 받는다. `referrer_type` 값으로 동작을 나누지 않는다(모든 값을 같게 처리). 서버가 `DELETE /me`에서 Kakao 연결 끊기 API로 끊은 경우에는 Kakao가 보내지 않는다.
- **인증 (NFR-SEC-01)**: ① `Authorization` 헤더가 정확히 `KakaoAK ` + 서버 설정의 Kakao 어드민 키와 같은지 상수 시간으로 비교한다. ② `app_id`가 서버 설정의 Kakao 앱 ID(4.2에서 `access_token_info`의 `app_id`와 비교하는 값과 같다)와 같은지 본다. 하나라도 틀리면 401 `WEBHOOK_UNAUTHORIZED`이고 아무것도 바꾸지 않는다. 헤더 값과 키는 로그에 쓰지 않는다. 새 비밀값은 없다(기존 Kakao 앱 ID·어드민 키 설정을 쓴다).
- **응답**: 성공은 200, 본문 없음, 3초 안에. 1.1의 "204" 규칙의 예외다. Kakao가 사용자가 없거나 오류가 나도 200으로 답하라고 요구하므로, 4.8의 모든 결과(아무것도 안 함, 서버 오류 포함)가 200이다. **200이 아닌 것은 인증 실패(401 `WEBHOOK_UNAUTHORIZED`)뿐이다.** 이 경로는 1.1의 오류 형식 중 이 401만 쓴다.
- 앱은 이 경로를 부르지 않고 `WEBHOOK_UNAUTHORIZED`를 받을 일도 없다.

---

## 4. 핵심 흐름

여러 테이블을 함께 바꾸는 흐름은 모두 한 트랜잭션에서 처리한다. 커플 연결처럼 두 사람이 동시에 움직일 수 있는 흐름은 행 잠금(`SELECT … FOR UPDATE`)으로 순서를 보장한다.

### 4.1 게스트로 시작 (FR-AUTH-01)

1. 앱이 `POST /auth/guest`를 호출한다.
2. 서버가 `users`(GUEST, 닉네임 "게스트"), `notification_settings`, `spaces`(PERSONAL), `space_members`(색 주황)를 만든다.
3. 201과 `AuthTokens`(3.1)를 돌려준다. access 토큰(`sid` = 새 세션 ID)과 refresh 토큰(365일), `isNewUser: true`가 들어 있다. refresh 토큰은 무작위 문자열이고 서버는 해시만 저장한다 (1장, D-81). 앱은 refresh 토큰을 암호화해 저장한다.
4. 로그인 3종(게스트 시작, 소셜 로그인, 게스트 → 기존 계정 로그인)은 모두 4.2의 "이전 세션·기기 정리"를 같은 코드로 처리한다 (ERD DB-12). 게스트 시작은 방금 만든 사용자라 끊을 세션과 지울 기기가 없을 뿐이다. 게스트 → 기존 계정 로그인은 4.7이다. 게스트 연동(4.3)은 이 정리를 하지 않는다.
5. 앱을 지운 게스트의 서버 데이터는 API가 지우지 않는다. 유효한 세션이 없어진 게스트를 정리 작업이 탈퇴와 같이 삭제한다 (PRD Q-11, ERD 4.4 정리 작업).

### 4.2 소셜 로그인 (FR-AUTH-02)

1. 앱이 Google SDK에서 ID 토큰, Kakao SDK에서 액세스 토큰을 받아 `POST /auth/social`로 보낸다.
2. 서버가 제공자에게 검증한다 (NFR-SEC-01). 토큰이 어긋나면 401 `SOCIAL_TOKEN_INVALID`로 거부하고 아무것도 바꾸지 않는다.
   - **Google**: ID 토큰의 서명(구글 공개키), `iss`, `aud`(둘이서 앱의 클라이언트 ID), `exp`를 확인한다. `iss`는 `accounts.google.com`과 `https://accounts.google.com` 두 값 모두 허용한다. 통과하면 토큰의 사용자 ID를 `provider_user_id`로 쓰고, 프로필 이름은 같은 ID 토큰의 `name` 클레임에서 읽는다.
   - **Kakao**: `GET https://kapi.kakao.com/v1/user/access_token_info`로 토큰을 확인하고, 응답의 `app_id`가 서버에 설정된 둘이서 앱 ID와 같은지 본다. 같을 때만 응답의 사용자 ID를 `provider_user_id`로 쓴다. 다른 앱에서 발급된 토큰은 여기서 걸러진다. 프로필 이름이 필요한 경우에만(아래 3단계의 신규 가입, 4.3의 "게스트" 닉네임 교체) 토큰 확인 다음에 `GET https://kapi.kakao.com/v2/user/me`를 호출해 `kakao_account.profile.nickname`**만** 받는다. 기존 회원의 로그인에서는 이 호출을 하지 않고 `access_token_info` 확인만 한다. 이메일 등 다른 값은 받거나 저장하지 않는다 (NFR-PRIV-01). Kakao Developers에서 동의항목 "닉네임"이 켜져 있어야 한다 (사람이 할 일).
   - **제공자 장애와 거부**: Google 공개키를 받지 못함, Kakao가 5xx를 돌려주거나 시간이 초과됨(`access_token_info`와 `v2/user/me` 둘 다)은 사용자의 토큰이 틀린 것이 아니므로 500 `INTERNAL_ERROR`로 응답하고 아무것도 바꾸지 않는다. `access_token_info`가 토큰을 거부(4xx)하면 401 `SOCIAL_TOKEN_INVALID`다. `SOCIAL_TOKEN_INVALID`는 이 `access_token_info` 단계의 거부에만 쓴다. 토큰 확인을 이미 통과한 뒤 `v2/user/me`가 4xx를 돌려주면(동의항목 "닉네임"이 꺼진 경우 등) 로그인을 거부하지 않고 "이름을 받지 못함"으로 보아 "사용자"를 쓴다 (D-69).
3. `social_accounts`에 있으면 그 사용자로 로그인한다. 없으면 MEMBER 사용자와 개인 공간을 만들고 `isNewUser: true`를 돌려준다. 닉네임 기본값은 소셜 프로필 이름(Google `name`, Kakao `kakao_account.profile.nickname`)에서 앞뒤 공백을 지운 값이고, 코드 포인트 10개를 넘으면 앞 10개만 쓴다 (FR-AUTH-07.AC1, D-56, D-82). 소셜 계정에서 이름을 받지 못했거나 공백뿐이면 "사용자"를 쓴다 (D-69). 앱은 이때 SCR-COUPLE-01을 띄운다 (PRD D-31).
4. **이전 세션·기기 정리 (D-51)**: (`POST /auth/switch`도 4.7에서 같은 코드를 쓴다.) 3단계와 같은 트랜잭션에서 그 사용자의 다른 유효한 `auth_sessions`를 모두 `revoked_at` = 지금, `revoked_reason = REPLACED`로 바꾸고, 그 사용자의 `devices` 행을 모두 지운다. 새 세션의 `AuthTokens`(3.1)를 200으로 돌려준다.
5. 앱은 로그인 직후 `PUT /me/devices`로 새 기기의 FCM 토큰을 다시 등록한다. 이전 기기는 푸시를 받지 못하고, 다음 요청에서 401 `SESSION_REPLACED`를 받아 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여준 뒤 SCR-START-01로 이동한다 (1장).

### 4.3 게스트 → 회원 연동 (FR-AUTH-03)

1. 게스트가 `POST /auth/link`로 소셜 토큰을 보낸다. 4.2의 2단계처럼 검증한다. Kakao `GET /v2/user/me`는 4단계에서 닉네임이 정확히 "게스트"라 소셜 프로필 이름으로 바꿔야 할 때만 부른다. 이 호출이 4xx를 주면 연동을 거부하지 않고 이름을 받지 못한 것으로 보아 "사용자"를 쓰고(D-69), 5xx·시간 초과면 500 `INTERNAL_ERROR`로 거부하고 아무것도 바꾸지 않는다. 토큰이 틀리면 401 `SOCIAL_TOKEN_INVALID`, 제공자 장애면 500 `INTERNAL_ERROR`이고 아무것도 바꾸지 않는다.
2. `social_accounts`에 행을 넣는다. UNIQUE 위반이면 409 `SOCIAL_ALREADY_USED`로 거부하고 아무것도 바꾸지 않는다 (PRD Q-01). 이때 앱은 "이미 가입된 계정이에요" 안내를 보여주고 4.7의 흐름으로 이어간다 (FR-AUTH-03.AC2).
3. `users.account_type`을 MEMBER로 바꾼다. 사용자 ID와 모든 데이터는 그대로다. 계정 종류는 access 토큰에 들어 있지 않고 서버가 DB에서 읽으므로 같은 access 토큰으로 바로 회원으로 판단한다 (1장). 다음 토큰 갱신부터 회원 만료 정책(30일)을 쓴다.
4. **닉네임 (D-68, D-69, D-82)**: 같은 트랜잭션에서 `users.nickname`이 정확히 "게스트"면 소셜 프로필 이름(앞뒤 공백을 지우고 코드 포인트 앞 10개)으로 바꾼다. 프로필 이름이 없거나 공백뿐이면 "사용자"로 바꾼다. "게스트"가 아닌 닉네임(사용자가 직접 바꾼 것)은 그대로 둔다. 응답은 204이고 새 토큰이 없으므로 앱은 연동 뒤 `GET /me`로 닉네임을 다시 읽는다.
5. 연동은 같은 기기에서 하므로 4.2의 4단계(이전 세션 `REPLACED`, `devices` 삭제)를 하지 않는다. 현재 세션과 `sid`, 등록된 FCM 토큰을 그대로 쓰고 응답에 새 토큰을 담지 않는다. 앱도 토큰을 바꾸거나 `PUT /me/devices`를 다시 부를 필요가 없다.
6. **앱 동작 (D-79)**: 게스트가 커플 연결 메뉴의 [로그인하고 연결하기]로 연동을 시작했으면, 연동이 끝난 뒤 SCR-COUPLE-01(회원 화면)로 이동한다. API는 달라지지 않는다.

### 4.4 커플 연결과 기록 가져오기 (FR-COUPLE-01~03, 06)

1. A가 `POST /invite-codes`를 호출한다. 서버는 A의 가장 최근 코드 `created_at` + 60초가 `<= now`인지 먼저 본다(R-09 검사 뒤). 아니면 429 `INVITE_REISSUE_TOO_SOON`과 `details.retryAfterSeconds`를 돌려준다. `retryAfterSeconds` = (가장 최근 `created_at` + 60초 − 지금)을 초 단위로 올림한 값이고 최소 1이다. 지났으면 같은 트랜잭션에서 A의 사용되지 않은 이전 코드 모두(만료됐어도 `used_at`과 `revoked_at`이 null인 것 포함)에 `revoked_at`을 기록하고(부분 UNIQUE `creator_user_id` WHERE `used_at IS NULL AND revoked_at IS NULL`을 지키기 위해), 6자리 새 코드(`expires_at` = 지금 + 10분)를 만들어 201과 `InviteCode`(`code`, `expiresAt`, `reissueAvailableAt` = 생성 + 60초, 3.2)를 돌려준다. **유효한 코드**는 `used_at IS NULL AND revoked_at IS NULL AND expires_at > now`다(`expires_at <= now`면 만료). 앱은 `GET /invite-codes/current`로 남은 시간과 `reissueAvailableAt`을 다시 읽을 수 있다. 요청자의 유효한 코드가 있으면 200 `InviteCode`이고, 없으면(만든 적 없음, 만료됨, 무효됨, 사용됨 모두) 404 `NOT_FOUND`다 (FR-COUPLE-01). 코드가 만료되면 앱이 SCR-COUPLE-02를 보고 있는 동안(또는 다시 들어왔을 때) `current`가 404이므로 `POST /invite-codes`를 호출해 새 코드를 받는다. 만료 시점에는 마지막 발급 후 10분이 지났으므로 429가 나지 않는다. 서버에 따로 자동 발급 작업은 두지 않는다 (FR-COUPLE-01.AC5, D-42). **앱 동작 (D-95, 오프라인)**: 첫 `GET /invite-codes/current`·`POST /invite-codes`가 오프라인이면 코드 칸을 빈 칸으로 두고 "인터넷 연결이 필요해요"를 보여준다 (FR-COUPLE-01.AC6). 8단계의 5초 `GET /me` 확인은 오프라인이면 안내 없이 건너뛰고, [연결 확인하기]는 "인터넷 연결이 필요해요"를 보여준다 (FR-COUPLE-02.AC5).
2. B가 `POST /couple/join`으로 코드를 보낸다. 서버는 `code`의 공백을 제거하고 대문자로 바꾼 뒤 비교한다 (FR-COUPLE-01.AC4). 아래 표의 순서대로 검사하고 처음 걸린 것으로 응답한다.

   | 순서 | 조건 | 응답 | 실패로 셈 |
   | --- | --- | --- | --- |
   | 1 | R-09: 게스트 | 403 `GUEST_NOT_ALLOWED` | 아니오 |
   | 2 | R-09: 요청자가 이미 커플 공간 | 409 `ALREADY_COUPLED` | 아니오 |
   | 3 | `code`가 없음·null·공백만 있음 | 400 `VALIDATION_FAILED` (`code`, `REQUIRED`) | 아니오 |
   | 4 | 오입력 제한 (아래) | 429 `INVITE_RATE_LIMITED` | 아니오 |
   | 5 | 공백 제거·대문자 변환 뒤 6자리가 아니거나 코드에 쓰는 31자 집합 밖의 글자가 있음 | 404 `INVITE_NOT_FOUND` | 예 |
   | 6 | 그 코드가 없음 | 404 `INVITE_NOT_FOUND` | 예 |
   | 7 | 만든 사람 = 요청자 (만료·사용 여부와 관계없이) | 409 `INVITE_SELF` | 예 |
   | 8 | 사용된 코드 | 409 `INVITE_USED` | 예 |
   | 9 | 만든 사람이 지금 커플 공간에 있음 (탈퇴한 사람의 코드는 탈퇴 때 지워져 6번의 404 `INVITE_NOT_FOUND`, ERD 4.3) | 409 `INVITE_UNAVAILABLE` | 예 |
   | 10 | 만료됨 또는 무효 (`revoked_at` 있음) | 409 `INVITE_EXPIRED` | 예 |

   - **오입력 제한 (NFR-SEC-03, D-83)**: 최근 1시간을 지금부터 거꾸로 센다(미끄러지는 창). 요청자의 `invite_code_attempts` 중 `succeeded = false`이고 `attempted_at > now − 1시간`인 행이 10개 이상이면 429 `INVITE_RATE_LIMITED`다. `details.retryAfterSeconds` = (그 실패 중 **10번째로 최근** 실패의 `attempted_at` + 1시간 − 지금)을 초 단위로 올림한 값이고 최소 1이다.
   - **시도로 남기는 것**: 실패는 위 표의 5~10번(형식이 틀린 코드를 포함해 연결에 쓸 수 없는 모든 코드)이다. 실패 기록은 연결 트랜잭션과 별도로 커밋된다(응답이 오류여도 남는다). 성공은 연결 트랜잭션 안에서 `succeeded = true`로 남긴다. **남기지 않는 것**: 1~3번(R-09 거부, `VALIDATION_FAILED`)과 4번(429 `INVITE_RATE_LIMITED` 자체).
   - 7~10번은 코드 행을 잠근 뒤(`SELECT … FOR UPDATE`) 검사한다. 9번을 10번보다 먼저 보는 이유: 4.4의 5단계 "다른 코드 무효화" 때문에 만든 사람이 다른 사람과 연결되면 그 코드에 `revoked_at`이 생겨 10번이 나오게 되는데, 그러면 FR-COUPLE-02.AC3의 "사용할 수 없는 코드"가 깨진다. 만든 사람이 연결을 해제해 다시 개인 공간이면 9번에 걸리지 않고 10번(만료된 코드)이 된다.
3. 위 표를 통과하면 A와 B가 MEMBER이고 둘 다 개인 공간에 있는 것이다. 실패마다 다른 오류 코드를 돌려준다 (FR-COUPLE-02.AC2, 5장). 재요청이나 연결로 무효가 된 코드(`revoked_at` 있음)는 만료와 같은 `INVITE_EXPIRED`로 응답한다 (PRD D-47).
4. **복구 확인**: `purge_at`이 지나지 않았고 이전 구성원이 정확히 A와 B인 UNLINKED 커플 공간이 있으면, 그 공간을 다시 ACTIVE로 바꾸고 두 사람의 `space_members.left_at`과 공간의 `unlinked_at`, `purge_at`을 비운다 (FR-COUPLE-06). 없으면 새 커플 공간과 구성원(A 주황, B 파랑, 함께 보라)을 만든다.
5. 입력한 코드를 사용 처리하고(`used_at`, `used_by_user_id`), **A와 B의 다른 유효한 코드(`used_at IS NULL AND revoked_at IS NULL`, 만료됐어도 포함)에 `revoked_at` = 지금을 기록한다** (ERD DB-16: 연결 뒤 남은 코드가 해제 직후 다시 쓸 수 있는 코드가 되지 않게. 연결 중인 사람의 코드를 넣으면 `INVITE_UNAVAILABLE`). A와 B 각자의 개인 공간을 정한다 (D-78).
   - 혼자 쓴 기록(`events`, `anniversaries`, `memos`)이 있으면 소속에 `left_at`을 기록하고 공간은 지우지 않는다 (가져오기 대기).
   - 혼자 쓴 기록이 없으면 그 개인 공간을 같은 트랜잭션에서 바로 지운다. 그래서 가져오기 대기 중인 개인 공간은 기록이 있는 공간뿐이다.
6. 200과 `CoupleJoinResult`(`spaceId`, `restored`, `importPending`, 3.2)를 돌려준다. `importPending`은 요청자에게 가져오기 대기 중인 개인 공간(5단계에서 남긴 공간)이 있을 때만 true다. `importPending`이 true일 때 앱이 읽는 `GET /me`의 `MeSpace.importCounts`는 같은 공간의 `events`, `anniversaries`, `memos` 개수다 (3.1, D-93). `CoupleJoinResult`에는 개수를 넣지 않고, 앱은 연결 뒤 `GET /me`로 읽는다. A와 B 두 사람 각자에게 `notifications`(`COUPLE_LINKED`, `space_id` null, `target_type` `SETTINGS`, `target_id` null) 행을 만들고, 두 사람 모두에게 푸시를 보낸다 (PRD 8장, 7장, D-85).
7. **커밋이 끝난 뒤** 두 사람의 기기 모두에 동기화 신호 `{"type":"SYNC","resource":"SPACE","action":"LINKED"}`를 보낸다 (6장). 보통의 신호는 다른 구성원에게만 가지만 이 신호는 입력한 B에게도 간다 (D-48).
8. **앱 동작** (D-48, FR-COUPLE-02.AC1·AC5): 두 사람 모두 SCR-CAL-01로 이동하고 그 위에 연결 완료 시트(SCR-COUPLE-04)가 뜬다.
   - B: `POST /couple/join` 응답을 받으면 바로 이동한다.
   - A(코드를 만든 쪽): 신호를 받으면 `GET /me`로 확인하고, 공간 종류가 COUPLE이면 이동한다. 신호가 늦거나 오지 않을 때를 대비해 SCR-COUPLE-02가 열려 있는 동안 5초마다 `GET /me`를 부른다. [연결 확인하기]도 같은 `GET /me`다. 아직 개인 공간이면 "아직 연결되지 않았어요"를 보여준다. 서버에 따로 대기 상태나 폴링 전용 경로는 없다.
   - 앱이 꺼져 있었으면 다음 실행 때 `GET /me`의 활성 공간 ID가 기기에 저장한 확인한 공간 ID와 다른 것을 보고(4.5의 6단계와 같은 방식) SCR-CAL-01과 시트를 띄운다. 서버는 시트를 봤는지를 저장하지 않는다.
   - **기기에 저장한 확인한 공간 ID (D-98, FR-COUPLE-03.AC6)**: 이 값은 사용자가 시트를 닫거나 [시작하기]를 마쳤을 때만 바꾼다. 그래서 시트를 닫기 전에 앱을 끄면 혼자 쓴 기록이 없어도 다음 실행 때 시트가 다시 뜬다. 처음 로그인한 기기(값 없음)는 공간이 바뀐 것으로 보지 않고 `importPending`만 본다.
9. 시트에서 두 사람은 각자 `POST /couple/import`로 고른다. 가져오기 대기 중인 개인 공간이 없으면(이미 정했거나 연결 해제와 겹친 경우 포함) 409 `NO_IMPORT_PENDING`이고 아무것도 바꾸지 않는다 (R-18). `import`가 없거나 `null`이면 400 `VALIDATION_FAILED`(`import`, `REQUIRED`)이고 R-18이 먼저다. 성공은 204다. `import: true`면 자기 개인 공간의 `events`, `anniversaries`, `memos`의 `space_id`를 커플 공간으로 바꾼 뒤 개인 공간을 지운다. `false`면 개인 공간을 지운다 (FR-COUPLE-03). 처음 만난 날은 같은 시트에서 정하며, 건너뛰어도 된다. 서버 저장은 `PATCH /space`이고, 칸을 채우는 시트의 [저장]은 서버를 부르지 않는다 (아래 [시작하기] 순서). 오늘보다 뒤의 날짜는 400 `VALIDATION_FAILED`, 1950-01-01보다 앞의 날짜는 400 `DATE_OUT_OF_RANGE`로 거부한다 (FR-COUPLE-04.AC3, D-74, R-15). 정한 뒤에는 다른 날로 바꿀 수만 있고 지울 수 없다(`null`은 400 `VALIDATION_FAILED`, D-84). 앱은 기록 선택을 [가져오기]로 미리 선택해 보여주고, [시작하기] 전에는 시트를 닫지 못하게 한다 (D-76, 앱 동작).
   - **[시작하기] 순서 (앱 동작, D-98, FR-COUPLE-04.AC4)**: ① 처음 만난 날을 골랐으면 `PATCH /space` ② 기록 선택이 있으면 `POST /couple/import` ③ 시트를 닫고 확인한 공간 ID를 저장한다. 되돌릴 수 없는 삭제를 마지막에 하려는 순서다. 중간에 실패하면 거기서 멈추고 공통 오류(D-88)를 보여주며 시트는 그대로 둔다(다시 누르면 처음부터 하고, 같은 날짜의 `PATCH /space`는 무해하다).
   - **`NO_IMPORT_PENDING` (앱 동작, D-103)**: ②에서 409 `NO_IMPORT_PENDING`을 받으면 이미 정한 것으로 보고 ③으로 간 뒤 `GET /me`를 다시 읽는다. 해제와 겹친 경우면 이 읽기에서 공간이 바뀐 것을 알고 4.5의 6단계 초기화로 이어진다.
10. `importPending`은 6단계와 같은 정의다: 가져오기 대기 중인 개인 공간(소속에 `left_at`이 있는 PERSONAL 공간, 곧 기록이 있는 공간)이 남아 있을 때만 true다. true인 사람은 고르기 전에는 시트를 닫을 수 없다(혼자 쓴 기록이 없는 사람은 대기 공간이 없어 false이고 바로 닫을 수 있다). `importPending`이 true인 동안 `GET /me`의 `importCounts`는 그 대기 공간의 개수를 계속 돌려주고(`false`면 `null`), 앱은 시트와 "혼자 쓴 기록을 삭제할까요?" 다이얼로그의 [N]에 쓴다 (D-93). 고르지 않고 앱을 껐다가 다시 열었을 때 대기 공간이 남아 있으면 `GET /me`의 `importPending`이 계속 true이므로 앱이 시트를 다시 띄워 묻는다 (FR-COUPLE-03.AC4). 고르기 전에 연결이 해제되면 4.5의 4단계가 이 공간을 되살린다 (D-78).
11. 알림 권한: 커플 연결도 앱이 알림 권한을 처음 묻는 시점 중 하나다 (D-70, 앱 동작, API 없음).
12. **낡은 로컬 상태 (앱 동작, D-95)**: `POST /invite-codes`·`GET /invite-codes/current`·`POST /couple/join`이 409 `ALREADY_COUPLED`나 403 `GUEST_NOT_ALLOWED`를 주면 앱은 공통 오류(D-88)를 보여준 뒤 `GET /me`를 다시 읽는다(로컬 정보가 낡은 경우. 공간이 바뀌었으면 시트나 4.5의 6단계 초기화로 이어진다). `POST /couple/join`의 `VALIDATION_FAILED`(`code`)는 공통 오류다. 그 밖의 초대코드 오류 코드의 문구는 PRD FR-COUPLE-02 "초대코드 오류 문구" 표를 따른다.

### 4.5 연결 해제 (FR-COUPLE-05)

1. 둘 중 한 명이 `DELETE /couple`을 호출한다. 요청자의 활성 공간이 `COUPLE`이 아니면 409 `NOT_COUPLE`이다 (R-18). 둘이 동시에 해제하면 두 번째 요청은 잠금 뒤 개인 공간을 보고 `NOT_COUPLE`이다. 앱은 `NOT_COUPLE`을 이미 해제된 것으로 보고 6단계의 앱 초기화를 한다 (D-37, FR-COUPLE-05.AC3). `DELETE /couple`뿐 아니라 `PATCH /space`, `PATCH /space/colors`의 409 `NOT_COUPLE`도 앱은 상대가 먼저 해제한 것으로 보고 같은 초기화를 한다 (FR-COUPLE-05.AC5, D-103). 성공은 204다.
2. 커플 공간을 UNLINKED로 바꾸고 `unlinked_at` = 지금, `purge_at` = 지금 + 30일로 기록한다. 두 구성원의 소속에 `left_at`을 기록한다.
3. 그 공간의 `event_reminders`를 삭제한다 (더 이상 볼 수 없는 일정의 알림이 가지 않도록). 같은 트랜잭션에서 그 공간의 `notifications`(`space_id` = 해제한 공간)도 두 사람 모두 삭제한다 (PRD D-45). 이 뒤에 만드는 `COUPLE_UNLINKED` 알림은 `space_id`가 null이라 남는다.
4. 두 사람 각자의 개인 공간을 정한다 (D-78).
   - **가져오기 대기 중인 개인 공간이 남아 있는 구성원**(소속에 `left_at`이 있는 PERSONAL 공간. 4.4의 5단계에서 기록이 있어 남겨 둔 공간뿐이다. ERD 4.2와 같은 조건): 새 개인 공간을 만들지 않고 그 공간의 `space_members.left_at`을 비워 다시 활성 공간으로 쓴다. 혼자 쓴 기록이 그대로 돌아오고, 사람 색도 소속 행이 그대로라 이전 값이다. 그 사람의 `GET /me`의 `importPending`은 false가 된다.
   - **그 밖의 구성원**(그런 개인 공간이 남아 있지 않은 경우): 새 빈 개인 공간을 만든다. 사람 색은 기본값(주황)으로 시작한다.
5. 상대에게 `COUPLE_UNLINKED` 알림(`space_id` null, `target_type` `SETTINGS`, `target_id` null, D-85)을 만들고, 상대 기기에 동기화 신호(`SPACE`, `UNLINKED`)와 해제 푸시를 보낸다 (7장). 탈퇴(4.6)로 인한 해제면 같은 `COUPLE_UNLINKED` 타입에 탈퇴 전용 문구를 쓴다: 제목 "[상대 이름]님이 탈퇴해 연결이 해제됐어요", 본문 "함께 쓴 기록은 더 이상 볼 수 없어요" (PRD 8장, D-53). 복구 안내("30일 안에 다시 연결하면…")는 넣지 않는다.
6. **앱 초기화** (PRD D-37): 해제한 사람은 응답을 받은 직후, 상대는 신호를 받거나 다음 실행 시 `GET /me`의 활성 공간 ID가 기기에 저장한 확인한 공간 ID와 다른 것을 확인하면, 로그인 정보를 뺀 로컬 데이터를 지우고 재시작해 자동 로그인한 뒤 SCR-COUPLE-01(연결 방법 선택)로 이동한다. **"재시작"의 뜻 (D-103, FR-COUPLE-05.AC3)**: 앱 프로세스를 끄지 않고, 토큰·소셜 SDK 상태는 두고 Room·설정을 지운 뒤 화면 이동 기록을 SCR-COUPLE-01 하나로 다시 만드는 것이다. 그 뒤 `GET /me`로 새 개인 공간을 채운다.

### 4.6 탈퇴 (FR-AUTH-06)

`DELETE /me`는 한 트랜잭션에서 ERD 4.3의 순서로 처리한다: 연결 해제 → 속했던 커플 공간 `purge_at`을 +90일로 연장 → 개인 공간 삭제 → 사용자 익명화. **Kakao 연결 끊기 (FR-AUTH-06.AC3)**: 탈퇴 트랜잭션이 **커밋된 뒤에** 호출한다. `social_accounts.provider`가 `KAKAO`면 트랜잭션 안에서 행을 지우기 전에 `provider_user_id`를 읽어 두고, 커밋 뒤 Kakao 연결 끊기 API(`POST https://kapi.kakao.com/v1/user/unlink`, `target_id_type=user_id`, `target_id` = 읽어 둔 `provider_user_id`)를 서버의 Kakao 어드민 키로 호출한다. 어드민 키는 서버 설정값이며 문서와 로그에 쓰지 않는다. 호출이 실패하거나 시간이 초과돼도 이미 끝난 탈퇴를 되돌리지 않고 실패했다는 사실만 로그에 남긴다(키·토큰 제외). 외부 호출은 트랜잭션 밖이라 응답이 길어지지 않도록 짧은 제한 시간을 둔다. Google 회원과 게스트(4.7 포함)는 이 단계가 없다. 커플 공간에 있던 사용자가 탈퇴하면 연결 해제 단계에서 상대에게 4.5의 5단계처럼 `COUPLE_UNLINKED` 알림·푸시·동기화 신호(`SPACE`, `UNLINKED`)를 보내되 문구는 탈퇴 전용(탈퇴해 연결이 해제됐어요, 복구 안내 없음)을 쓴다 (D-53). 문구의 [상대 이름]은 받는 사람 기준의 상대, 곧 탈퇴하는 사용자의 익명화 전 닉네임이다. 성공하면 204(본문 없음)를 돌려주고, 앱은 응답 후 로컬 데이터를 모두 지우고 소셜 SDK 로그인 상태도 지운 뒤(1장) SCR-START-01로 이동한다. 요청이 실패했을 때의 앱 동작은 3.1의 `DELETE /me`다 (D-86). **Kakao 연결 해제 알림(4.8)으로 일어난 탈퇴**는 이 절의 순서를 그대로 쓰되 Kakao가 이미 연결을 끊은 뒤이므로 **Kakao 연결 끊기 API를 부르지 않는다**.

### 4.7 게스트 → 기존 계정 로그인 (FR-AUTH-03.AC2~AC3, D-67)

게스트가 연동하려는 소셜 계정이 이미 회원이면, 게스트로 쓴 기록을 지우고 그 계정으로 로그인한다. 데이터는 합치지 않는다 (PRD Q-01). 게스트는 로그아웃이 없어 원래 계정으로 돌아갈 길이 이것뿐이다.

1. **앱 흐름**: `POST /auth/link`가 409 `SOCIAL_ALREADY_USED`를 돌려주면 앱은 "이미 가입된 계정이에요" 다이얼로그와 [그 계정으로 로그인]을 보여준다. 누르면 "게스트로 쓴 기록은 모두 삭제돼요" 확인 다이얼로그를 한 번 더 보여주고, 확인하면 같은 소셜 토큰으로 `POST /auth/switch`를 호출한다(소셜 SDK 토큰을 다시 받아도 된다). 두 다이얼로그 어디서든 취소하면 아무것도 호출하지 않고 게스트로 계속 쓴다.
2. 서버가 게스트의 access 토큰을 확인한다(R-14, 회원이면 403 `GUEST_ONLY`). 4.2의 2단계처럼 소셜 토큰을 검증한다. 토큰이 틀리면 401 `SOCIAL_TOKEN_INVALID`, 제공자 장애면 500 `INTERNAL_ERROR`로 거부하고 아무것도 바꾸지 않는다. 이 경로는 닉네임이 필요 없으므로 Kakao는 `access_token_info` 확인만 하고 `GET /v2/user/me`는 부르지 않는다.
3. `social_accounts`에서 그 소셜 계정을 찾는다. 없으면 404 `SOCIAL_NOT_REGISTERED`로 거부하고 아무것도 바꾸지 않는다. 앱은 이때 `POST /auth/link`로 연동하면 된다.
4. **한 트랜잭션으로 처리한다 (ERD DB-12)**. 트랜잭션 안에서 먼저 `social_accounts`를 다시 조회하고 대상 회원 행을 잠근다(`SELECT … FOR UPDATE`). 3단계 조회와 트랜잭션 사이에 그 회원이 탈퇴했을 수 있기 때문이다. 행이 없거나 탈퇴한 회원이면 롤백하고 404 `SOCIAL_NOT_REGISTERED`를 돌려준다. 이때 게스트 계정은 그대로 남는다. 확인이 끝나면 다음을 처리한다:
   1. 게스트 사용자를 4.6의 탈퇴와 같이 처리한다: 게스트의 세션을 `WITHDRAWN`으로 끊은 뒤 삭제하고, 개인 공간과 기록을 삭제하고, 사용자를 익명화한다. 게스트는 커플 공간에 들어갈 수 없으므로 연결 해제 단계와 Kakao 연결 끊기는 없다.
   2. 4.2의 "이전 세션·기기 정리"를 같은 코드로 처리한다: 그 회원의 다른 유효한 세션은 `REPLACED`, `devices`는 모두 삭제.
   3. 그 회원의 새 세션을 만든다.
5. 200과 `AuthTokens`(3.1)를 돌려준다(`isNewUser: false`, 새 access·refresh 토큰). 트랜잭션이 실패하면 게스트 계정도 그대로 남는다.
6. **앱 동작**: 앱은 게스트의 토큰과 로컬 데이터를 지우고 새 토큰을 저장한 뒤 `PUT /me/devices`로 FCM 토큰을 다시 등록하고, `GET /me`로 그 계정의 현재 상태(개인 공간·커플 공간, `importPending`)로 이동한다. 이전 게스트 access 토큰으로 다시 요청하면 401 `SESSION_INVALID`다 (1장).
7. 다른 기기에서 그 회원 계정에 로그인해 있었다면 그 기기는 4단계의 2번(이전 세션 정리) 때문에 다음 요청에서 401 `SESSION_REPLACED`를 받는다 (1장).

### 4.8 Kakao 연결 해제 알림 (FR-AUTH-06.AC4, D-87)

사용자가 Kakao 계정 설정에서 둘이서와의 연결을 끊으면 Kakao가 `GET`·`POST /webhooks/kakao/unlink`를 부른다 (3.6). 아래를 모두 한 트랜잭션에서 처리한다. 요청 형식과 인증은 3.6이다.

1. **인증**: 3.6의 ①②(어드민 키 헤더, `app_id`) 중 하나라도 틀리면 아무것도 바꾸지 않고 401 `WEBHOOK_UNAUTHORIZED`다. 통과한 뒤에는 어떤 결과든 200(본문 없음)이다.
2. **입력 검사**: `user_id`가 없거나 비었으면 아무것도 바꾸지 않고 200이다. 경고 로그만 남긴다.
3. **사용자 찾기**: `social_accounts`에서 `provider = KAKAO`, `provider_user_id = user_id`인 행을 찾는다. 없으면 200이고 아무것도 하지 않는다(모르는 사용자, 이미 탈퇴함, 같은 알림을 두 번 받음, 서버가 `DELETE /me`에서 연결 끊기를 불러 온 알림).
4. **잠금**: 그 사용자 행을 잠근다(`SELECT … FOR UPDATE`, 탈퇴와 같은 잠금). 잠근 뒤 행이 없어졌거나 `deleted_at`이 있으면 200이다.
5. **Google도 쓰는 회원** (`KAKAO` 밖의 `social_accounts`, 곧 `GOOGLE`이 있음): **`KAKAO` 행만 지우고** 200이다. 세션·기기·데이터는 그대로이고 `Me.providers`에서 `KAKAO`가 빠진다 (ERD DB-15).
6. **Kakao만 쓰는 회원**: **`DELETE /me`와 같은 탈퇴(4.6, ERD 4.3)**를 한다. 커플이면 연결 해제와 상대에게 탈퇴 전용 `COUPLE_UNLINKED` 알림·푸시·동기화 신호, 속했던 커플 공간 `purge_at` +90일, 개인 공간 삭제, 익명화, 세션 `WITHDRAWN` 무효화 뒤 삭제 순이다. **커밋 뒤 Kakao 연결 끊기 API는 부르지 않는다**(이미 끊김). 200을 돌려준다.
7. **서버 오류**: 처리 중 오류가 나면 트랜잭션을 롤백하고 **그래도 200**으로 답한다(200이 아니면 Kakao가 웹훅을 끌 수 있다). 처리하지 못한 알림은 ERROR 로그에 Kakao `user_id`, `referrer_type`, `traceId`를 남기고 운영자가 처리한다(`docs/DEPLOY.md`). 키·헤더 값은 로그에 쓰지 않는다.
8. **앱 동작**: 탈퇴된 사용자의 기기는 세션이 지워져 다음 요청에서 401 `SESSION_INVALID`를 받고 안내 없이 SCR-START-01로 이동한다 (1장). 기기의 소셜 SDK 정리도 1장을 따른다.

같은 알림이 여러 번 와도 결과가 같다(멱등, 3단계). Kakao Developers의 앱 › 웹훅 › 연결 해제 웹훅에 서버 주소를 등록하는 것은 사람이 할 일이다(서버 배포 뒤).

---

## 5. 오류 코드

| HTTP | code | 언제 | 관련 |
| --- | --- | --- | --- |
| 400 | VALIDATION_FAILED | 필수값 누락, 길이 초과(닉네임은 앞뒤 공백을 지운 뒤 코드 포인트 10개, D-82), 닉네임이 지운 뒤 빈 값 (`PATCH /me`, `nickname`, `REQUIRED`), `PATCH /me`에 `null`을 보냄 (`REQUIRED`), 시간대가 IANA 이름이 아님 (`PATCH /me`, `timeZone`, `INVALID`), `fcmToken`이 비었음 (`PUT /me/devices`, `fcmToken`, `REQUIRED`), 255자 초과 (`TOO_LONG`), `platform`이 `ANDROID`·`IOS`가 아님 (`INVALID`), 종료가 시작보다 이름 (`POST/PATCH /events`, `end`, `INVALID`), 날짜 범위 조회에서 `from` > `to`이거나 범위가 3개월 초과 (`GET /memos/dated`, `GET /events`), `GET /events`의 `from`·`to`가 없음 (`REQUIRED`)이거나 날짜 형식이 아님 (`INVALID`), 범위가 3개월 초과 (`GET /anniversaries`), 일정 쓰기의 제목이 지운 뒤 빈 값 (`title`, `REQUIRED`)·50자 초과 (`TOO_LONG`)·메모 1000자 초과 (`note`, `TOO_LONG`), `isAllDay`와 `start`·`end` 형식이 맞지 않음 (`INVALID`), 일정 필수 필드 없음·`null` (`REQUIRED`), 일정 알림 `option`이 없음·`null` (`REQUIRED`)이거나 일정 종류와 맞지 않음·모르는 값 (`PUT /events/{id}/reminder`, `option`, `INVALID`, 3.3), 처음 만난 날이 오늘보다 뒤 (`PATCH /space`, 2050년 이후 날짜도 이 코드), `startDate`가 없거나 `null`(`PATCH /space`, `startDate`, `REQUIRED`, 지우기 없음 D-84)이거나 날짜 형식이 아님 (`INVALID`), `code`가 없음·null·공백만 있음 (`POST /couple/join`, `code`, `REQUIRED`), `import`가 없거나 `null` (`POST /couple/import`, `import`, `REQUIRED`), `PATCH /space/colors`의 `members`·`together`가 둘 다 없음·`members`가 빈 배열(`members`, `REQUIRED`)이거나 `null` 필드(`REQUIRED`), 팔레트 키 12개 밖의 색, 활성 공간 구성원이 아닌 `userId`, 같은 `userId`가 두 번 (`INVALID`, 필드 이름은 `members[0].color`처럼 0부터 센 인덱스, 3.2) | FR-CAL-02.AC3, NFR-LIMIT-01, D-82, NFR-TIME-01, NFR-SYNC-01, FR-CAL-01.AC2, FR-COUPLE-04.AC1·AC3, D-84, FR-COUPLE-02, FR-COUPLE-03, FR-CAL-04 |
| 400 | DATE_OUT_OF_RANGE | 날짜가 1950-01-01 ~ 2050-12-31 밖: `POST/PATCH /events`(`start`/`end` 각각, 둘 다 밖이면 둘 다 담는다), `POST/PATCH /memos`(`memoDate`), `POST/PATCH /anniversaries`(`date`), `PATCH /space`(`startDate`가 1950-01-01보다 앞일 때). 일정 쓰기는 `VALIDATION_FAILED`가 하나라도 있으면 그것만 응답하고 이 코드는 그 뒤에 본다(3.3 검사 순서). 미래의 처음 만난 날은 `VALIDATION_FAILED`. 쓰기(생성·수정) 요청에만 쓴다. 범위 조회(`GET /events`, `/anniversaries`, `/memos/dated`)의 `from`·`to`가 밖이면 이 오류 없이 범위 안으로 잘라서 조회한다 | R-15, D-74, FR-CAL-01.AC6 |
| 400 | INVALID_TARGET | 개인 공간에서 '함께' 일정을 만들려 함 | R-10 |
| 401 | TOKEN_EXPIRED | access 토큰의 서명은 맞고 `exp`가 지남 (앱이 refresh 후 재시도). 검사 순서는 형식·서명 → 만료 → 세션이라, 서명이나 형식이 틀린 토큰은 만료 여부와 관계없이 `SESSION_INVALID`다 | 1장, NFR-SEC-01 |
| 401 | SESSION_INVALID | `Authorization` 헤더가 없음, `Bearer` 형식이 아님, access 토큰의 서명이 틀림, 클레임이 없거나 틀림. 또는 세션이 무효: refresh 토큰 만료·무효(이미 교체된 이전 refresh 토큰 재사용 포함), 로그아웃·탈퇴(Kakao 연결 해제 알림으로 인한 탈퇴 포함, 4.8)로 끊긴 세션의 토큰 (시작 화면으로). 다른 기기 로그인으로 끊긴 경우는 `SESSION_REPLACED` | 1장, NFR-SEC-01 |
| 401 | SESSION_REPLACED | 다른 기기 로그인으로 이 기기의 세션이 끊김. 앱은 "다른 기기에서 로그인해서 로그아웃됐어요"를 보여주고 로컬 데이터를 지운 뒤 SCR-START-01로 이동 | D-51, FR-AUTH-02.AC3 |
| 401 | WEBHOOK_UNAUTHORIZED | 웹훅 요청의 인증 실패: `Authorization`이 `KakaoAK <어드민 키>`가 아니거나 `app_id`가 둘이서 앱 ID가 아님 (`POST /webhooks/kakao/unlink`). 아무것도 바꾸지 않는다. 앱은 이 코드를 받을 일이 없다 | D-87, NFR-SEC-01 |
| 401 | SOCIAL_TOKEN_INVALID | 소셜 토큰 검증 실패: Google은 서명·`iss`(허용값 `accounts.google.com`, `https://accounts.google.com` 두 가지가 아님)·`aud`·`exp`, Kakao는 `app_id`가 맞지 않거나 `access_token_info`가 토큰을 거부(4xx)함 (`/auth/social`, `/auth/link`, `/auth/switch`). 이 코드는 `access_token_info` 단계의 거부에만 쓴다: 확인 뒤 `v2/user/me`가 4xx를 주면 거부하지 않고 닉네임을 "사용자"로 쓴다 (D-69). 제공자 장애는 이 코드가 아니라 500 `INTERNAL_ERROR` | NFR-SEC-01 |
| 403 | NOT_AUTHOR | 작성자가 아닌 수정·삭제, 작성자가 아닌 사용자의 일정 대상(`isTogether`) 변경 (저장된 값과 다른 값을 보낼 때만. 같은 값은 R-02만 적용, R-13) | R-02, R-03, R-05, R-13 |
| 403 | GUEST_NOT_ALLOWED | 게스트가 회원 전용 기능(커플 연결, `/auth/logout`)을 부름 | R-09, R-17, D-07, FR-AUTH-05 |
| 403 | GUEST_ONLY | 게스트만 부를 수 있는 경로(`/auth/link`, `/auth/switch`)를 회원이 부름. `GUEST_NOT_ALLOWED`와 반대 경우다 | R-14, D-67, FR-AUTH-03 |
| 404 | NOT_FOUND | 없거나 다른 공간의 리소스. 요청자의 유효한 초대코드가 없을 때의 `GET /invite-codes/current`도 이 코드다(앱은 `POST /invite-codes`를 부른다) | R-01, FR-COUPLE-01.AC5 |
| 404 | INVITE_NOT_FOUND | 존재하지 않는 초대코드. 공백 제거·대문자 변환 뒤 6자리가 아니거나 코드에 쓰는 31자 집합 밖의 글자가 있는 입력도 이 코드이고 오입력으로 센다 (`POST /couple/join`) | FR-COUPLE-02.AC2, D-83 |
| 404 | SOCIAL_NOT_REGISTERED | `/auth/switch`에서 그 소셜 계정으로 가입한 회원이 없음. 아무것도 바꾸지 않으며 앱은 `/auth/link`로 연동하면 된다 | D-67, FR-AUTH-03.AC3 |
| 409 | NO_IMPORT_PENDING | `POST /couple/import`를 불렀는데 가져오기 대기 중인 개인 공간이 없음(이미 정했거나, 연결 해제와 겹침). 아무것도 바꾸지 않는다 | R-18, FR-COUPLE-03, D-78 |
| 409 | INVITE_EXPIRED | 만료된 코드(`expires_at <= now`), 또는 재요청으로 바뀐 이전 코드·연결로 무효가 된 코드(`revoked_at` 있음). 만든 사람이 연결 중이면 이 코드가 아니라 `INVITE_UNAVAILABLE`이 먼저다 (4.4의 2단계 순서) | FR-COUPLE-01.AC2, FR-COUPLE-02.AC2 (D-47) |
| 409 | INVITE_USED | 이미 사용된 코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_SELF | 자신이 만든 코드 (만료·사용 여부와 관계없이) | FR-COUPLE-02.AC2 |
| 409 | INVITE_UNAVAILABLE | 코드를 만든 사람이 지금 커플 공간에 있음 (탈퇴한 사람의 코드는 지워져 `INVITE_NOT_FOUND`). 만든 사람이 연결을 해제해 다시 개인 공간이면 이 코드가 아니라 `INVITE_EXPIRED`다 | FR-COUPLE-02.AC3, DB-16 |
| 409 | ALREADY_COUPLED | 요청자가 이미 커플 공간에 있음 (`POST /invite-codes`, `GET /invite-codes/current`, `POST /couple/join`) | R-09 |
| 409 | NOT_COUPLE | 커플 공간이 필요한 요청을 개인 공간에서 보냄: `PATCH /space`, 개인 공간에서 `together`나 자기 밖 `userId`가 있는 `PATCH /space/colors`, `DELETE /couple`. `DELETE /couple`이면 앱은 이미 해제된 것으로 보고 앱 초기화를 한다 (4.5) | R-08, R-18, FR-COUPLE-05.AC3 |
| 409 | SOCIAL_ALREADY_USED | 연동하려는 소셜 계정이 이미 다른 회원 (`/auth/link`). 앱은 "이미 가입된 계정이에요"와 [그 계정으로 로그인]을 보여주고 확인 뒤 `/auth/switch`를 호출한다 (4.7) | FR-AUTH-03.AC2, AC3, D-67 |
| 413 | IMAGE_TOO_LARGE | 프로필 사진 10MB 초과 | NFR-FILE-01 |
| 415 | IMAGE_TYPE_NOT_ALLOWED | JPEG·PNG가 아님 | NFR-FILE-01 |
| 429 | INVITE_RATE_LIMITED | 최근 1시간(지금부터 거꾸로) 초대코드 오입력 실패 10번 (`POST /couple/join`). `details.retryAfterSeconds` = 10번째로 최근 실패의 시각 + 1시간까지 남은 초(올림, 최소 1). 이 429 자체는 실패로 세지 않는다 (4.4의 2단계) | NFR-SEC-03, FR-COUPLE-02.AC4, D-83 |
| 429 | INVITE_REISSUE_TOO_SOON | 초대코드를 마지막 발급 후 60초 안에 재요청 (`POST /invite-codes`). `details.retryAfterSeconds` = 최근 `created_at` + 60초까지 남은 초(올림, 최소 1) | FR-COUPLE-01.AC3 |
| 500 | INTERNAL_ERROR | 서버 내부 오류. 소셜 제공자 장애도 포함한다: Google 공개키를 받지 못함, Kakao(`access_token_info`, `v2/user/me`)가 5xx를 돌려주거나 시간이 초과됨 (`/auth/social`, `/auth/link`, `/auth/switch`, 아무것도 바꾸지 않음). `details`는 `null`이고 `traceId`로 서버 로그를 찾는다. 앱은 공통 오류 안내를 보여준다(D-88). 단 `POST /webhooks/kakao/unlink`는 처리 중 서버 오류여도 이 코드 대신 200을 돌려준다 (3.6, 4.8) | 1.1, NFR-SEC-01, D-88 |

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
| 연결·해제·탈퇴 알림 | 즉시 | 연결 완료: 두 사람 각자에게 `notifications`(`COUPLE_LINKED`, `space_id` null) 행을 만들고 두 사람 모두에게 푸시. 해제: 상대에게만 `notifications`(`COUPLE_UNLINKED`, `space_id` null) 행을 만들고 푸시. 탈퇴로 인한 해제: 상대에게만 같은 `COUPLE_UNLINKED` 타입으로 만들되 제목 "[상대 이름]님이 탈퇴해 연결이 해제됐어요", 본문 "함께 쓴 기록은 더 이상 볼 수 없어요" (복구 안내 없음). 모두 설정과 관계없이 항상 푸시(받는 사람에게 유효 세션이 있을 때). Kakao 연결 해제 알림(4.8)으로 일어난 탈퇴 해제도 같다. 연결·해제 알림 행(탈퇴 해제 포함)은 `target_type` = `SETTINGS`, `target_id` = null이고 알림 목록의 `targetType`은 `SETTINGS`다. 알림 목록 행과 푸시를 누르면 설정(SCR-SET-01)으로 이동한다 (3.5, D-85) | PRD 8장, D-53, D-85, FR-AUTH-06.AC2·AC4, FR-NOTI-03 |
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
| FR-AUTH-01~05 | /auth/*, /me | 1장(`sid`, 세션 검사, 세션이 끝날 때 소셜 SDK 정리), 4.1~4.3, 5장, 3.1 `Me.createdAt` |
| FR-AUTH-02.AC3 한 기기 로그인 (D-51) | /auth/guest, /auth/social, /auth/switch, /auth/refresh (/auth/link는 정리 안 함) | 1장, 4.1, 4.2, 4.3, 4.7, 401 `SESSION_REPLACED` |
| FR-AUTH-03 게스트 → 회원 연동 (D-67, D-68, D-79) | POST /auth/link, POST /auth/switch | 4.3 (닉네임, 연동 뒤 SCR-COUPLE-01), 4.7, R-14 (403 `GUEST_ONLY`), 409 `SOCIAL_ALREADY_USED`, 404 `SOCIAL_NOT_REGISTERED`, ERD DB-12 |
| FR-AUTH-05 로그아웃 (D-50, D-80, D-86) | POST /auth/logout | R-17 (게스트는 403 `GUEST_NOT_ALLOWED`), `devices` 삭제, "다른 계정으로 로그인"은 같은 호출 (앱 동작). AC4: 온라인에서만, 오프라인·서버 오류면 로그아웃하지 않음, 이미 끊긴 세션이면 SCR-START-01 (3.1 앱 동작, D-88) |
| FR-AUTH-06 탈퇴 | DELETE /me, POST·GET /webhooks/kakao/unlink | 4.6 (AC3 Kakao 연결 끊기), 7장 (탈퇴 전용 해제 알림). AC4 Kakao 연결 해제 알림 = 탈퇴처럼, Google도 쓰면 `KAKAO` 행만 삭제 (3.6, 4.8, D-87, 401 `WEBHOOK_UNAUTHORIZED`). AC5: 온라인에서만, 오프라인·서버 오류면 탈퇴하지 않음 (3.1 앱 동작, D-86) |
| FR-AUTH-07 프로필 | /me, /me/profile-image, /users/{id}/profile-image | R-11, 8장, 닉네임 코드 포인트 10개·앞뒤 공백 제거 (D-82), 이름 없으면 "사용자" (D-69, 4.2, 4.3) |
| FR-AUTH-08 이용 동의, FR-AUTH-09 앱 밖 계정 삭제 요청 | API 없음(앱·웹) | |
| Q-11 게스트 정리 | API 없음 (정리 작업) | 4.1의 5단계, ERD 4.4 |
| FR-COUPLE-01~02, 06 | /invite-codes, /invite-codes/current, /couple/join, GET /me | 3.2 (`InviteCode`, `CoupleJoinResult`), 4.4 (재요청 계산, `current` 404, 오류 우선순위, 다른 유효 코드 무효화 DB-16), 6장(`LINKED`), R-09 |
| FR-COUPLE-02.AC4 오입력 제한 (D-83, NFR-SEC-03) | POST /couple/join | 4.4의 2단계 (최근 1시간 실패 10번의 미끄러지는 창, 형식 오류도 실패, `retryAfterSeconds` 계산), 429 `INVITE_RATE_LIMITED` |
| FR-COUPLE-03 | /couple/import | 4.4의 5·6·9·10단계 (빈 개인 공간은 바로 삭제, `importPending` 정의), R-18, 409 `NO_IMPORT_PENDING` (D-76은 앱 동작) |
| FR-COUPLE-04 | GET·PATCH /space | 3.2 (`Space`, 지우기 없음 D-84, 검사 순서), R-08, R-15, 4.4의 9단계(미래 날짜 거부, 1950년 이전 `DATE_OUT_OF_RANGE`) |
| FR-COUPLE-05 | DELETE /couple | R-18 (409 `NOT_COUPLE`), 4.5 (알림 삭제 포함, 4단계의 가져오기 대기 중 개인 공간 되살리기 D-78, 앱 초기화) |
| FR-CAL-01~03 | /events, GET /memos/dated, GET /notifications/unread-count | R-01, R-02, R-10, R-12, R-13 |
| FR-CAL-01.AC6 날짜 범위 1950~2050 (D-74) | POST/PATCH /events, /memos, /anniversaries, PATCH /space | R-15, 1장, 쓰기는 400 `DATE_OUT_OF_RANGE`, 범위 조회(GET /events, /anniversaries, /memos/dated)는 `from`·`to`를 범위 안으로 잘라서 조회, ERD DB-13 |
| FR-CAL-04 사람 색 | PATCH /space/colors | R-08, 3.2 (팔레트 키 12개, 검사 순서, `members[i].color` 필드 이름) |
| FR-CAL-05 일정 알림 | /events/{id}/reminder, PATCH /events/{id} | R-07, 7장 |
| FR-ANNIV-01~04 | /anniversaries | R-05, 7장 (기념일 알림 문구) |
| FR-ANNIV-04 기념일 목록 (D-71, D-75) | GET /anniversaries/upcoming, GET /anniversaries/past, GET /anniversaries?from=&to= (캘린더용, 3개월) | R-01, R-05, `GET /anniversaries/past`의 `totalCount`, FR-ANNIV-04.AC4 처음 만난 날이 없으면 `AUTO` 없음 |
| FR-MEMO-01~03 | /memos | R-03 |
| FR-MEMO-04 | 삭제됨 (PRD v0.4). PATCH /memos/{id}/checklist-items/{itemId} 삭제됨 | |
| FR-MEMO-05 | /memos/pinned, /memos/{id}/pin | R-04 |
| FR-MEMO-06 | /memos/{id}/favorite, ?view=favorites | R-06 |
| FR-NOTI-01~04 | /me/devices, /me/notification-settings (게스트 포함, D-62), notifyPartner | 6장, 7장, R-16 (유효 세션이 있을 때만 푸시, D-73), 알림 권한은 앱 동작 (D-70) |
| NFR-SEC-01 토큰·세션 (D-73, D-81) | /auth/*, 푸시 전송 | 1장 토큰 수명·토큰 형식(access JWT, refresh 무작위 문자열)·인증 실패 규칙과 검사 순서, 3.1 `AuthTokens`·`Me`, 4.2 (Google `iss` 두 값, Kakao `v2/user/me`, 제공자 장애는 500 `INTERNAL_ERROR`), R-16, 7장, ERD DB-02, DB-14 |
| NFR-LIMIT-01 글자 수 기준 (D-82) | PATCH /me, 소셜 프로필 이름 | 1장(코드 포인트로 센다), 3.1 `PATCH /me`(앞뒤 공백 제거, 빈 값은 `REQUIRED`, 초과는 `TOO_LONG`), 4.2의 3단계, 4.3의 4단계 |
| NFR-PRIV-01 소셜 개인정보 최소 수집 | /auth/social, /auth/link | 4.2 (Kakao는 `kakao_account.profile.nickname`만 받음, 동의항목 "닉네임") |
| FR-NOTI-03 푸시를 눌렀을 때 (D-85) | GET /notifications (`targetType`) | 3.5 (연결·해제 알림은 `SETTINGS`, `targetId` null), 7장 |
| FR-NOTI-05 알림 목록 | /notifications, /notifications/unread-count, /notifications/{id}/read | R-12, 3.5, 6장, 7장 |
| FR-SET-01 | GET /me, GET /space | 3.1 `Me.createdAt` (가입일), 3.2 `Space` |
| D-57 메모 작성자 닉네임 | API 변경 없음 | 앱이 `GET /space`의 구성원 닉네임을 메모의 `author_id`와 맞춰 채운다 |
| FR-SET-02 정보 | API 없음(앱·웹) | |
