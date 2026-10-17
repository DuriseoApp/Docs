# 둘이서 API 초안 (MVP v0.1)

> 기준 문서: 둘이서 PRD v0.3 (`docs/PRD.md`)
> 함께 보는 문서: `ERD.md` (테이블 정의), `ERD.png` (한눈에 보기)
> 작성일: 2026-10-17

이 문서는 둘이서 서버 API의 범위, 권한, 처리 흐름을 정한다. 요청·응답의 상세 스키마는 서버 코드의 OpenAPI(springdoc) 문서를 단일 기준으로 삼는다. PRD의 ID(FR, D, NFR, Q)와 ERD의 `DB-` 결정을 그대로 참조하며, PRD와 충돌하면 PRD가 우선이다.

---

## 1. 공통 규약

**응답은 성공이면 리소스 JSON을 그대로, 실패면 `{"code": "…", "message": "…"}`를 돌려준다.** 앱은 `code`로 분기하고, `message`는 로그용이다. 사용자에게 보이는 문구는 앱이 `code`에 맞춰 디자인 시스템의 말투(해요체)로 쓴다.

- 모든 경로는 `/api/v1` 아래에 있다
- `/auth/guest`, `/auth/social`, `/auth/refresh`를 빼면 access 토큰(`Authorization: Bearer …`)이 필요하다
- JSON 필드는 camelCase, 날짜는 `YYYY-MM-DD`, 일시는 ISO 8601 UTC (`2026-10-17T06:30:00Z`)
- access 토큰 1시간, refresh 토큰은 회원 30일·게스트 365일, 사용할 때마다 교체 (ERD DB-02)
- 입력 길이 제한은 NFR-LIMIT-01을 따르고, 넘으면 400 `VALIDATION_FAILED`와 필드 이름을 돌려준다
- 목록은 커서 페이지네이션 (`cursor`, `size`, 응답의 `nextCursor`)

---

## 2. 서버 권한 검사 규칙

**모든 요청은 먼저 "이 리소스가 요청자의 활성 공간에 있는가"를 검사하고, 아니면 404를 돌려준다.** 403이 아니라 404인 이유는 다른 커플의 리소스가 존재한다는 사실 자체를 알려주지 않기 위해서다 (NFR-SEC-02, ERD DB-05). 이 규칙들은 한 곳(`SpaceAccessPolicy` 같은 단일 컴포넌트)에서 구현하고, 각 규칙마다 허용·거부 테스트를 둔다. **리뷰에서 이 규칙 위반은 항상 Critical이다.**

| ID | 규칙 | 실패 응답 | 근거 |
| --- | --- | --- | --- |
| R-01 | 모든 콘텐츠 조회·변경: 리소스의 `space_id` = 요청자의 활성 공간(`space_members.left_at IS NULL`) | 404 `NOT_FOUND` | NFR-SEC-02 |
| R-02 | 일정 수정·삭제: 요청자 = `author_id`, 또는 `is_together = true` | 403 `NOT_AUTHOR` | D-12, D-34 |
| R-03 | 메모의 제목·본문·체크리스트 항목 수정, 메모 삭제: 요청자 = `author_id` | 403 `NOT_AUTHOR` | D-17 |
| R-04 | 체크리스트 체크 변경, 메모 고정·해제: 공간 구성원이면 허용 | (R-01만) | D-21, D-22 |
| R-05 | 직접 기념일 수정·삭제: 요청자 = `author_id` | 403 `NOT_AUTHOR` | FR-ANNIV-03 |
| R-06 | 즐겨찾기: 요청자 본인의 행만 만들고 지운다. 목록 조회 시 다른 사용자의 즐겨찾기는 응답에 넣지 않는다 | — | D-24 |
| R-07 | 일정 알림: 요청자 본인의 행만 만들고 바꾼다. 일정 응답에는 요청자의 알림만 넣는다 | — | D-16 |
| R-08 | 사귄 날, 사람 색 변경: 커플 공간의 구성원이면 허용. 개인 공간에서는 자기 색만 | 409 `NOT_COUPLE` | FR-COUPLE-04, FR-CAL-04 |
| R-09 | 초대코드 생성·입력: `account_type = MEMBER`이고 개인 공간에 있을 것 | 403 `GUEST_NOT_ALLOWED` / 409 `ALREADY_COUPLED` | D-07 |
| R-10 | 일정 대상: 요청 본문은 `isTogether`만 받고 대상 사용자는 받지 않는다. 개인 공간에서 `isTogether = true`면 거부 | 400 `INVALID_TARGET` | D-34 |
| R-11 | 프로필 사진 조회: 본인 또는 같은 활성 공간의 구성원만 | 404 `NOT_FOUND` | NFR-FILE-01 |

앱 화면에서 버튼을 숨기는 것은 사용성을 위한 것이고, 보안은 위 규칙으로만 보장한다.

---

## 3. API 목록

"권한" 열의 R-번호는 2장의 규칙이다.

### 3.1 인증·내 정보

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| POST | /auth/guest | 게스트 시작 | 없음 | FR-AUTH-01 |
| POST | /auth/social | 소셜 로그인 `{provider, token}`, 응답에 `isNewUser` | 없음 | FR-AUTH-02 |
| POST | /auth/link | 게스트 → 회원 연동 `{provider, token}` | GUEST만 | FR-AUTH-03 |
| POST | /auth/refresh | refresh 토큰 교체 발급 | refresh 토큰 | NFR-SEC-01 |
| POST | /auth/logout | 현재 세션 무효화 | MEMBER만 | FR-AUTH-05 |
| GET | /me | 내 정보 + 현재 공간 요약 (종류, 공간 ID, 상대, 사람 색, 사귄 날, `importPending`) | 로그인 | FR-SET-01 |
| PATCH | /me | 닉네임, 시간대 변경 | 로그인 | FR-AUTH-07 |
| PUT | /me/profile-image | 프로필 사진 업로드 (multipart) | 로그인 | FR-AUTH-07.AC3 |
| DELETE | /me/profile-image | 프로필 사진 삭제 | 로그인 | FR-AUTH-07.AC5 |
| GET | /users/{id}/profile-image | 프로필 사진 조회 | R-11 | FR-AUTH-07 |
| DELETE | /me | 탈퇴 | 로그인 | FR-AUTH-06 |
| PUT | /me/devices | FCM 토큰 등록·갱신 | 로그인 | NFR-SYNC-01 |
| GET, PATCH | /me/notification-settings | 알림 설정 조회·변경 | 로그인 | FR-NOTI-02 |

### 3.2 공간·커플

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /space | 현재 공간 상세 (구성원, 사람 색, 사귄 날) | 로그인 | FR-SET-01 |
| PATCH | /space | 사귄 날 변경 `{startDate}` | R-08 | FR-COUPLE-04 |
| PATCH | /space/colors | 사람 색 변경 `{members: [{userId, color}], together}` | R-08 | FR-CAL-04 |
| POST | /invite-codes | 초대코드 생성·재발급 | R-09 | FR-COUPLE-01 |
| GET | /invite-codes/current | 내 유효한 초대코드와 남은 시간 | R-09 | FR-COUPLE-01 |
| POST | /couple/join | 초대코드로 연결 `{code}`, 응답에 `restored`, `importPending` | R-09 | FR-COUPLE-02, 06 |
| POST | /couple/import | 기록 가져오기 결정 `{import: boolean}` | 가져오기 대기 중인 본인 | FR-COUPLE-03 |
| DELETE | /couple | 연결 해제 | 커플 구성원 | FR-COUPLE-05 |

### 3.3 일정·기념일

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /events?from=&to= | 날짜 범위의 일정 (최대 3개월). 각 일정에 요청자의 알림만 포함 | R-01, R-07 | FR-CAL-01 |
| POST | /events | 일정 생성 `{title, note, isAllDay, start, end, isTogether, notifyPartner}`. `notifyPartner` 기본 true, 커플 공간에서만 의미 있음 | R-01, R-10 | FR-CAL-02, FR-NOTI-04 |
| GET | /events/{id} | 일정 상세 | R-01 | FR-CAL-03 |
| PATCH | /events/{id} | 일정 수정 (수정 시에는 상대에게 알림 없음) | R-02, R-10 | FR-CAL-03 |
| DELETE | /events/{id} | 일정 삭제 | R-02 | FR-CAL-03 |
| PUT | /events/{id}/reminder | 내 알림 설정 `{option}` | R-01, R-07 | FR-CAL-05 |
| DELETE | /events/{id}/reminder | 내 알림 끄기 | R-01, R-07 | FR-CAL-05 |
| GET | /anniversaries?from=&to= | 자동 + 직접 기념일을 합쳐 날짜순으로 (`kind: AUTO` 또는 `CUSTOM`). D-N 계산 포함 | R-01 | FR-ANNIV-01~04 |
| POST | /anniversaries | 직접 기념일 생성 | R-01 | FR-ANNIV-03 |
| PATCH, DELETE | /anniversaries/{id} | 직접 기념일 수정·삭제 | R-05 | FR-ANNIV-03 |

### 3.4 메모

| 메서드 | 경로 | 설명 | 권한 | FR |
| --- | --- | --- | --- | --- |
| GET | /memos?view=&cursor=&size= | 고정되지 않은 메모 목록. `view` = `newest`(기본), `oldest`, `favorites`. 커서는 (created_at, id) | R-01, R-06 | FR-MEMO-01 |
| GET | /memos/pinned | 고정 메모 전체, 최근 고정순. 앱은 3개만 보여주고 4개 이상이면 "더보기" | R-01 | FR-MEMO-05 |
| POST | /memos | 메모 생성 `{title, body, checklist: [{content}], notifyPartner}` | R-01 | FR-MEMO-02, FR-NOTI-04 |
| GET | /memos/{id} | 메모 상세 (요청자의 즐겨찾기 여부 포함) | R-01, R-06 | FR-MEMO-03 |
| PATCH | /memos/{id} | 제목, 본문, 체크리스트 수정. 체크리스트는 전체 교체이며 `id`가 있는 항목은 체크 상태를 유지 | R-03 | FR-MEMO-03, 04 |
| DELETE | /memos/{id} | 메모 삭제 | R-03 | FR-MEMO-03 |
| PATCH | /memos/{id}/checklist-items/{itemId} | 체크 상태 변경 `{checked}` | R-04 | FR-MEMO-04.AC2 |
| PUT, DELETE | /memos/{id}/pin | 고정·해제 | R-04 | FR-MEMO-05 |
| PUT, DELETE | /memos/{id}/favorite | 즐겨찾기·해제 | R-06 | FR-MEMO-06 |

---

## 4. 핵심 흐름

여러 테이블을 함께 바꾸는 흐름은 모두 한 트랜잭션에서 처리한다. 커플 연결처럼 두 사람이 동시에 움직일 수 있는 흐름은 행 잠금(`SELECT … FOR UPDATE`)으로 순서를 보장한다.

### 4.1 게스트로 시작 (FR-AUTH-01)

1. 앱이 `POST /auth/guest`를 호출한다.
2. 서버가 `users`(GUEST, 닉네임 "게스트"), `notification_settings`, `spaces`(PERSONAL), `space_members`(색 주황)를 만든다.
3. access 토큰과 refresh 토큰(365일)을 돌려준다. 앱은 refresh 토큰을 암호화해 저장한다.

### 4.2 소셜 로그인 (FR-AUTH-02)

1. 앱이 Google SDK에서 ID 토큰, Kakao SDK에서 액세스 토큰을 받아 `POST /auth/social`로 보낸다.
2. 서버가 제공자에게 검증한다. Google은 ID 토큰의 서명과 `aud`(앱의 클라이언트 ID)를, Kakao는 사용자 정보 API로 토큰을 확인해 `provider_user_id`를 얻는다.
3. `social_accounts`에 있으면 그 사용자로 로그인한다. 없으면 MEMBER 사용자와 개인 공간을 만들고 `isNewUser: true`를 돌려준다. 앱은 이때 SCR-COUPLE-01을 띄운다 (PRD D-31).

### 4.3 게스트 → 회원 연동 (FR-AUTH-03)

1. 게스트가 `POST /auth/link`로 소셜 토큰을 보낸다. 4.2의 2단계처럼 검증한다.
2. `social_accounts`에 행을 넣는다. UNIQUE 위반이면 409 `SOCIAL_ALREADY_USED`로 거부하고 아무것도 바꾸지 않는다 (PRD Q-01).
3. `users.account_type`을 MEMBER로 바꾼다. 사용자 ID와 모든 데이터는 그대로다. 다음 토큰 갱신부터 회원 만료 정책(30일)을 쓴다.

### 4.4 커플 연결과 기록 가져오기 (FR-COUPLE-01~03, 06)

1. A가 `POST /invite-codes`를 호출하면 A의 기존 유효 코드를 무효화(`revoked_at`)하고 새 코드를 만든다.
2. B가 `POST /couple/join`으로 코드를 보낸다. 먼저 최근 1시간 실패가 10회 이상인지 본다 (NFR-SEC-03). 시도는 성공·실패 모두 `invite_code_attempts`에 남긴다.
3. 코드 행을 잠그고 검사한다: 존재, 미만료, 미사용, 미무효, 만든 사람이 B가 아님, A와 B 모두 MEMBER이고 개인 공간에 있음. 실패마다 다른 오류 코드를 돌려준다 (FR-COUPLE-02.AC2, 5장).
4. **복구 확인**: `purge_at`이 지나지 않았고 이전 구성원이 정확히 A와 B인 UNLINKED 커플 공간이 있으면, 그 공간을 다시 ACTIVE로 바꾸고 두 사람의 `space_members.left_at`과 공간의 `unlinked_at`, `purge_at`을 비운다 (FR-COUPLE-06). 없으면 새 커플 공간과 구성원(A 주황, B 파랑, 함께 보라)을 만든다.
5. A와 B의 개인 공간 소속에 `left_at`을 기록하고 코드를 사용 처리한다. 개인 공간 자체는 아직 지우지 않는다 (가져오기 대기).
6. 응답에 `restored`와, 개인 공간에 데이터가 있으면 `importPending: true`를 넣는다. A에게 연결 완료 푸시를 보낸다.
7. 두 사람은 각자 `POST /couple/import`로 고른다. `import: true`면 자기 개인 공간의 `events`, `anniversaries`, `memos`의 `space_id`를 커플 공간으로 바꾼 뒤 개인 공간을 지운다. `false`면 개인 공간을 지운다 (FR-COUPLE-03).
8. 앱을 다시 열었을 때 가져오기 대기 중인 개인 공간(소속에 `left_at`이 있는 PERSONAL 공간)이 남아 있으면 다시 묻는다.

### 4.5 연결 해제 (FR-COUPLE-05)

1. 둘 중 한 명이 `DELETE /couple`을 호출한다.
2. 커플 공간을 UNLINKED로 바꾸고 `unlinked_at` = 지금, `purge_at` = 지금 + 30일로 기록한다. 두 구성원의 소속에 `left_at`을 기록한다.
3. 그 공간의 `event_reminders`를 삭제한다 (더 이상 볼 수 없는 일정의 알림이 가지 않도록).
4. 두 사람 각자에게 새 개인 공간을 만든다. 사람 색은 기본값(주황)으로 시작한다.
5. 상대 기기에 동기화 신호(`SPACE`, `UNLINKED`)와 해제 푸시를 보낸다.
6. **앱 초기화** (PRD D-37): 해제한 사람은 응답을 받은 직후, 상대는 신호를 받거나 다음 실행 시 `GET /me`의 활성 공간 ID가 기기에 저장된 값과 다른 것을 확인하면, 로그인 정보를 뺀 로컬 데이터를 지우고 재시작해 자동 로그인한 뒤 SCR-COUPLE-01(연결 방법 선택)로 이동한다.

### 4.6 탈퇴 (FR-AUTH-06)

`DELETE /me`는 한 트랜잭션에서 ERD 4.3의 순서로 처리한다: 연결 해제 → 속했던 커플 공간 `purge_at`을 +90일로 연장 → 개인 공간 삭제 → 사용자 익명화. 응답 후 앱은 로컬 데이터를 모두 지우고 SCR-START-01로 이동한다.

---

## 5. 오류 코드

| HTTP | code | 언제 | 관련 |
| --- | --- | --- | --- |
| 400 | VALIDATION_FAILED | 필수값 누락, 길이 초과, 종료가 시작보다 이름 | FR-CAL-02.AC3, NFR-LIMIT-01 |
| 400 | INVALID_TARGET | 개인 공간에서 '함께' 일정을 만들려 함 | R-10 |
| 401 | TOKEN_EXPIRED | access 토큰 만료 (앱이 refresh 후 재시도) | |
| 401 | SESSION_INVALID | refresh 토큰 만료·무효 (시작 화면으로) | |
| 403 | NOT_AUTHOR | 작성자가 아닌 수정·삭제 | R-02, R-03, R-05 |
| 403 | GUEST_NOT_ALLOWED | 게스트의 커플 연결 시도 | R-09, D-07 |
| 404 | NOT_FOUND | 없거나 다른 공간의 리소스 | R-01 |
| 404 | INVITE_NOT_FOUND | 존재하지 않는 초대코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_EXPIRED | 만료된 코드 | FR-COUPLE-01.AC2 |
| 409 | INVITE_USED | 이미 사용되었거나 재발급으로 무효가 된 코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_SELF | 자신이 만든 코드 | FR-COUPLE-02.AC2 |
| 409 | INVITE_UNAVAILABLE | 코드를 만든 사람이 이미 다른 사람과 연결됨 | FR-COUPLE-02.AC3 |
| 409 | ALREADY_COUPLED | 요청자가 이미 커플 공간에 있음 | R-09 |
| 409 | NOT_COUPLE | 커플 공간이 필요한 요청을 개인 공간에서 보냄 | R-08 |
| 409 | SOCIAL_ALREADY_USED | 연동하려는 소셜 계정이 이미 다른 회원 | FR-AUTH-03.AC2 |
| 413 | IMAGE_TOO_LARGE | 프로필 사진 10MB 초과 | NFR-FILE-01 |
| 415 | IMAGE_TYPE_NOT_ALLOWED | JPEG·PNG가 아님 | NFR-FILE-01 |
| 429 | INVITE_RATE_LIMITED | 1시간 내 초대코드 오입력 10회 | NFR-SEC-03 |

---

## 6. 동기화 신호 (NFR-SYNC-01)

공간의 데이터가 바뀌면 서버는 그 공간의 **다른** 구성원 기기에 FCM 데이터 메시지를 보낸다. 사용자에게 보이는 알림이 아니며, 앱은 받은 즉시 해당 데이터를 다시 불러온다.

```json
{"type": "SYNC", "resource": "EVENT", "id": "0192…", "action": "UPDATED"}
```

- `resource`: `EVENT`, `ANNIVERSARY`, `MEMO`, `SPACE`(사귄 날, 사람 색, 구성원 변경)
- `action`: `CREATED`, `UPDATED`, `DELETED`, `UNLINKED`(`SPACE`만, 앱 초기화 신호)
- 커밋이 끝난 뒤에 보낸다 (트랜잭션이 실패하면 보내지 않음). 전송 실패는 재시도하지 않는다: 앱이 화면 진입 시 다시 불러오므로 (NFR-SYNC-02)

---

## 7. 알림 발송

| 작업 | 주기 | 내용 | 관련 |
| --- | --- | --- | --- |
| 일정 알림 | 1분마다 | `fire_at <= now`이고 `sent_at`이 없는 `event_reminders`를 보내고 `sent_at` 기록. 사용자의 `event_reminder` 설정이 꺼져 있으면 기록만 하고 보내지 않음 | FR-CAL-05 |
| 기념일 알림 | 매시 정각 | 각 사용자의 시간대로 지금이 오전 9시인 사용자에게, 오늘이 기념일(자동·직접)이면 발송 | D-32 |
| 상대 활동 알림 | 즉시 | 커플 공간에서 `notifyPartner = true`로 일정·메모를 만들었을 때, 메모를 고정했을 때 상대에게 발송 (상대의 `partner_created`, `memo_pinned` 설정 확인) | D-27, D-35 |
| 연결·해제 알림 | 즉시 | 설정과 관계없이 발송 | PRD 8장 |

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
| FR-AUTH-01~05 | /auth/*, /me | 4.1~4.3 |
| FR-AUTH-06 탈퇴 | DELETE /me | 4.6 |
| FR-AUTH-07 프로필 | /me, /me/profile-image, /users/{id}/profile-image | R-11, 8장 |
| FR-COUPLE-01~02, 06 | /invite-codes, /couple/join | 4.4, R-09 |
| FR-COUPLE-03 | /couple/import | 4.4의 7단계 |
| FR-COUPLE-04 | PATCH /space | R-08 |
| FR-COUPLE-05 | DELETE /couple | 4.5 |
| FR-CAL-01~03 | /events | R-01, R-02, R-10 |
| FR-CAL-04 사람 색 | PATCH /space/colors | R-08 |
| FR-CAL-05 일정 알림 | /events/{id}/reminder | R-07, 7장 |
| FR-ANNIV-01~04 | /anniversaries | R-05 |
| FR-MEMO-01~03 | /memos | R-03 |
| FR-MEMO-04 | PATCH /memos/{id}, /checklist-items/{itemId} | R-03, R-04 |
| FR-MEMO-05 | /memos/pinned, /memos/{id}/pin | R-04 |
| FR-MEMO-06 | /memos/{id}/favorite, ?view=favorites | R-06 |
| FR-NOTI-01~04 | /me/devices, /me/notification-settings, notifyPartner | 6장, 7장 |
| FR-SET-01 | GET /me, GET /space | |
