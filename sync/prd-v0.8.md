# PRD v0.8 영향 분석

> 상태: 진행 중
> 이전 버전: v0.7 → 새 버전: v0.8
> 브랜치: sync/prd-v0.8
> PR: (PR 완료 후 링크)

이 파일은 `/prd-sync` 팀원들이 읽는 계약이다. 여기 적힌 이름과 할 일을 그대로 따른다.

배경: Server 단위 2(커플) 범위 점검에서 10개(Server `docs/progress/unit-2.md` "확인 필요" 1~10), Android 단위 2(인증) 범위 점검에서 16개(Android `docs/progress/unit-2.md` "확인 필요" 1~16)의 빈 곳이 나왔다. 사용자가 2026-10-27에 모두 추천안대로 정했다("추천안대로 진행"). 같은 날 사용자가 새로 정한 것: Kakao "연결 해제 웹훅"(사용자가 Kakao 계정 설정에서 둘이서 연결을 끊으면 Kakao가 서버를 부름)은 **탈퇴처럼 처리**한다. PRD에는 제품 결정(D-83~D-88, Q-12)과 AC 문구만 넣었고, API·ERD·화면 세부는 이 파일의 "이름 확정"대로 채운다.

추천안이 없던 항목은 리드가 정했다: Android 12(게스트 ID 표시)는 PRD Q-12 기본값, Android 6(d)(switch의 404)는 공통 오류(최소안), Kakao 웹훅에서 Google도 쓰는 회원은 Kakao 로그인 수단만 지움(D-87 기본값 부분). 이 표시가 있는 줄은 "리드 결정"이라고 적었다.

## 1. 바뀐 ID

| ID | 변경 | 내용 |
| --- | --- | --- |
| FR-AUTH-05 | 수정 (AC4 추가) | 오프라인·서버 오류면 로그아웃하지 않고 안내 후 그대로 (D-86, D-88) |
| FR-AUTH-06 | 수정 (AC4, AC5 추가) | AC4: Kakao 연결 해제 알림 → 탈퇴처럼, Google도 쓰면 Kakao 수단만 삭제 (D-87). AC5: 오프라인·서버 오류면 탈퇴하지 않음 (D-86) |
| FR-COUPLE-02 | 수정 (AC4) | 오입력 제한은 최근 1시간 실패 10번, 가장 오래된 실패가 1시간 지나면 풀림 (D-83) |
| FR-COUPLE-04 | 수정 (AC1) | 처음 만난 날은 바꿀 수만 있고 지울 수 없음 (D-84) |
| FR-NOTI-03 | 수정 (AC1) | 연결·해제 알림(탈퇴 해제 포함)은 설정(SCR-SET-01)으로 (D-85) |
| FR-SET-01 | 수정 (AC1) | 계정: 회원은 로그인 수단과 가입일, 게스트는 게스트 ID(Q-12)와 연동 |
| NFR-SEC-03 | 수정 | "최근 1시간"(지금부터 거꾸로 셈) 문구 (D-83) |
| D-83 | 추가 | 오입력 제한 = 최근 1시간 실패 횟수(미끄러지는 창). 형식이 틀린 코드도 실패 |
| D-84 | 추가 | 처음 만난 날 지우기 없음 |
| D-85 | 추가 | 연결·해제 알림을 누르면 SCR-SET-01 |
| D-86 | 추가 | 로그아웃·탈퇴는 서버가 마쳐야 끝남. 오프라인·서버 오류면 그대로, 이미 끊긴 세션이면 시작 화면 |
| D-87 | 추가 | Kakao 연결 해제 알림 = 탈퇴처럼. Google도 쓰면 Kakao 로그인 수단만 삭제 |
| D-88 | 추가 | 공통 오류 스낵바(서버 오류·모르는 오류·소셜 로그인 실패), 소셜 로그인 취소는 안내 없음 |
| Q-12 | 추가 | 게스트 ID 표시. 기본값: UUID 36자 그대로, 길게 누르면 복사 |
| (4장 상태 모델 6번) | 수정 | 시작 화면으로 가는 경우에 "Kakao 계정 설정에서 둘이서 연결 끊기(D-87)" 추가 |

## 2. 문서별 할 일

| 문서 | 담당 | 할 일 |
| --- | --- | --- |
| docs/ERD.md (+ ERD.png) | data | 헤더 PRD v0.8. 3장 "이름 확정"의 ERD 열을 반영: `invite_codes.revoked_at` 설명(3.4), `invite_code_attempts`에 무엇을 남기는지와 미끄러지는 창(3.3), `spaces.start_date` 지우기 없음(D-84), `space_members.color`·`spaces.together_color`의 팔레트 키 12개(3.5), `notifications.target_type`의 연결·해제 값(3.6), `users.created_at` = `Me.createdAt`(3.1), `social_accounts`에 Kakao 연결 해제 알림 처리(3.8), 4.1 "커플 연결" 줄에 다른 유효 코드 무효화, 4.3에 Kakao 연결 해제 알림으로 인한 탈퇴(연결 끊기 호출 없음). 새 결정 **DB-15**(Kakao 연결 해제 알림 처리), **DB-16**(연결 때 두 사람의 다른 유효 코드 무효화). 6장 추적표에 D-83·D-84·D-85·D-87 줄. **스키마 변경 없음** (`target_type` CHECK에 `SETTINGS`가 이미 있고 `revoked_at`·`created_at`도 있음). ERD.png는 그림이 바뀌지 않으면 다시 만들지 않음 |
| docs/API.md | api | 헤더 PRD v0.8 (작성일 줄에 갱신 2026-10-27). 3장 "이름 확정"의 API 열을 모두 반영: 1장(웹훅 경로는 access 토큰 예외, 세션이 끝날 때 앱의 소셜 SDK 정리 3.9), 1.1(웹훅은 200 빈 본문 예외), 2장 **R-18** 추가와 R-08 문구, 3.1 `Me.createdAt`·`DELETE /me`·`POST /auth/logout` 앱 동작(D-86), 3.2 표를 3.1처럼 "요청 → 성공" 열이 있는 표로 바꾸고 `InviteCode`·`CoupleJoinResult`·`Space`·`SpaceMember`를 표 아래에 한 번 정의, 3.5 `targetType`, 새 **3.6 웹훅** 절(`POST /webhooks/kakao/unlink`), 4.4(오류 우선순위, 오입력 제한 계산, 재요청 계산, 다른 유효 코드 무효화, `current` 404), 4.5(`NOT_COUPLE`과 앱 동작), 4.6(웹훅 탈퇴는 Kakao 연결 끊기 호출 없음), 새 **4.8 Kakao 연결 해제 알림**, 5장(새 오류 코드 `WEBHOOK_UNAUTHORIZED`, 기존 코드 "언제" 열 넓힘), 7장 연결·해제 알림의 이동 대상, 9장 추적표 줄 |
| docs/SCREENS.md | screen | 헤더 PRD v0.8 (갱신 줄). 3장 "이름 확정"의 SCREENS 열을 반영: 공통 표(공통 오류 D-88 근거, 요청 중 표시, 소셜 로그인 취소·실패), SCR-START-01(상태·오류, 스낵바 위치, 기능 칩 문구, 로고 접근성 문구), SCR-SET-01(보드 문구, 가입일 형식, 게스트 ID Q-12, 연동 성공 안내, 연동·switch 오류 처리, 로그아웃·탈퇴 실패 D-86, 탈퇴 다이얼로그 버튼 이미지 차이), SCR-NOTI-01 이동 표에 D-85, 처음 만난 날 선택 시트와 SCR-COUPLE-04에 "지우기 없음"(D-84), SCR-COUPLE-03 오류 줄에 D-83 |
| design/design-system.md | screen | 갱신 줄 추가. 3.10의 컴포넌트 수치(버튼 54 등, 시작 화면, 게스트 배너, 메뉴 행, 섹션 제목, 로그인 카드, 정보 행, 다이얼로그)를 "하단 탭"·"스낵바"와 같은 표 형식으로 보드 행 번호를 붙여 적는다. **토큰 값은 바꾸지 않는다.** "로고" 절을 `design/logo/` 파일을 가리키게 고친다 (3.11) |
| design/logo/ (새 폴더) | screen | 보드 인라인 SVG를 그대로 옮긴 파일 3개 (3.11) |
| 디자인 변경 요청서 | screen | 있음: `design/change-requests/prd-v0.8.md` (3.12). 캔버스 수정은 게스트 ID 샘플 값 하나, 나머지는 PNG 다시 만들기 |

## 3. 이름 확정

### 3.1 내 정보 (`Me`)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 응답 필드 | `Me.createdAt` | 일시 (ISO 8601 UTC), not null. `users.created_at` 그대로. 게스트가 연동한 회원은 게스트로 시작한 시각이다(계정이 그대로이므로). `Me` 표에서 `hasProfileImage` 다음, `space` 앞에 둔다. `GET /me`, `PATCH /me` 둘 다 | FR-SET-01 |
| 화면 | SCR-SET-01 계정 · 회원 "가입일" | `Me.createdAt`을 기기 시간대 날짜로 바꿔 "2026년 10월 12일" 형식(연·월·일, 요일 없음, 앞자리 0 없음)으로 보여준다. 회원 화면에만 있다 | FR-SET-01 |
| ERD | `users.created_at` | 설명 칸에 "API `Me.createdAt`(가입일)로 내보낸다" 추가. 컬럼 변경 없음 | FR-SET-01 |

### 3.2 공간·커플 경로 (API.md 3.2를 이 표로 바꾼다)

모든 경로는 `/api/v1` 아래. "요청 → 성공" 형식은 3.1과 같다.

| 메서드 | 경로 | 요청 → 성공 | 권한 | 관련 ID |
| --- | --- | --- | --- | --- |
| GET | /space | → 200 `Space` | 로그인 | FR-SET-01 |
| PATCH | /space | `{startDate: 날짜}` → 200 `Space` | R-08, R-15 | FR-COUPLE-04, D-84 |
| PATCH | /space/colors | `{members?: [{userId: uuid, color: string}], together?: string}` → 200 `Space` | R-08 | FR-CAL-04 |
| POST | /invite-codes | 본문 없음 → 201 `InviteCode` | R-09 | FR-COUPLE-01 |
| GET | /invite-codes/current | → 200 `InviteCode`. 유효한 코드가 없으면 404 `NOT_FOUND` | R-09 | FR-COUPLE-01.AC5 |
| POST | /couple/join | `{code: string}` → 200 `CoupleJoinResult` | R-09 | FR-COUPLE-02, FR-COUPLE-06 |
| POST | /couple/import | `{import: boolean}` → 204 | R-18 | FR-COUPLE-03 |
| DELETE | /couple | 본문 없음 → 204 | R-18 | FR-COUPLE-05 |

**공통 응답 모양** (3.1의 `AuthTokens`·`Me`처럼 3.2 표 아래에 한 번 정의)

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
| `members` | `SpaceMember`[] | 활성 구성원(`left_at IS NULL`). 개인 공간 1개, 커플 공간 2개. 순서는 뜻이 없고 앱은 `userId`로 나를 찾는다 |

`SpaceMember`: `userId`(uuid), `nickname`(string), `color`(팔레트 키), `hasProfileImage`(boolean)

- `Space`는 `MeSpace`를 대신하지 않는다. `GET /me`의 `MeSpace`는 그대로 둔다 (`MeSpace`는 요약, `Space`는 SCR-SET-01·SCR-SET-03·메모 작성자 닉네임용 상세).
- `PATCH /space`, `PATCH /space/colors`의 응답은 바뀐 뒤의 `Space` 전체다.

### 3.3 초대코드 규칙 (API.md 4.4, 5장 / ERD `invite_codes`, `invite_code_attempts`)

| 항목 | 규칙 | 관련 ID |
| --- | --- | --- |
| 유효한 코드 | `used_at IS NULL AND revoked_at IS NULL AND expires_at > now`. 만료 경계: `expires_at <= now`면 만료 | FR-COUPLE-01.AC2 |
| 재요청 계산 | 가장 최근 `created_at` + 60초 `<= now`면 허용. 아니면 429 `INVITE_REISSUE_TOO_SOON`, `retryAfterSeconds` = (최근 `created_at` + 60초 − 지금)을 초 단위로 올림, 최소 1 | FR-COUPLE-01.AC3 |
| `GET /invite-codes/current` | R-09 검사 뒤, 요청자의 유효한 코드가 있으면 200 `InviteCode`. 없으면(만든 적 없음, 만료됨, 무효됨, 사용됨 모두) 404 `NOT_FOUND`. 앱은 404면 `POST /invite-codes`를 부른다 (만료 코드는 발급 후 10분이 지나 429가 나지 않음) | FR-COUPLE-01.AC5, D-42 |
| 연결 때 다른 코드 무효화 (DB-16) | `/couple/join` 트랜잭션에서 A(만든 사람)와 B(입력한 사람)의 **다른** 유효한 코드(`used_at IS NULL AND revoked_at IS NULL`, 만료됐어도 포함)에 `revoked_at` = 지금을 기록한다. 입력한 코드는 기존대로 사용 처리(`used_at`, `used_by_user_id`) | FR-COUPLE-02.AC3 |
| ERD `invite_codes.revoked_at` 설명 | "재요청으로 만료되거나(FR-COUPLE-01.AC3), 만든 사람이 커플로 연결돼 무효가 된 시각(DB-16)" | FR-COUPLE-01.AC3, FR-COUPLE-02.AC3 |
| 오입력 제한 (D-83) | 미끄러지는 창: 요청자의 `invite_code_attempts` 중 `succeeded = false`이고 `attempted_at > now − 1시간`인 행이 10개 이상이면 429 `INVITE_RATE_LIMITED`. `retryAfterSeconds` = (그 실패 중 **10번째로 최근** 실패의 `attempted_at` + 1시간 − 지금)을 초 단위로 올림, 최소 1 | FR-COUPLE-02.AC4, NFR-SEC-03 |
| 시도로 남기는 것 | 실패 = 아래 오류 순서의 5~9번(형식 오류 포함 `INVITE_NOT_FOUND`, `INVITE_SELF`, `INVITE_USED`, `INVITE_UNAVAILABLE`, `INVITE_EXPIRED`). 실패 기록은 연결 트랜잭션과 별도로 커밋된다(응답이 오류여도 남음). 성공은 연결 트랜잭션 안에서 `succeeded = true`로 남긴다. **남기지 않는 것**: R-09 거부, `VALIDATION_FAILED`, 429 `INVITE_RATE_LIMITED` 자체 | D-83, NFR-SEC-03 |

**`POST /couple/join` 오류 우선순위** (위에서부터 검사하고 처음 걸린 것으로 응답)

| 순서 | 조건 | 응답 | 실패로 셈 |
| --- | --- | --- | --- |
| 1 | R-09: 게스트 | 403 `GUEST_NOT_ALLOWED` | 아니오 |
| 2 | R-09: 요청자가 이미 커플 공간 | 409 `ALREADY_COUPLED` | 아니오 |
| 3 | `code`가 없음·null·공백만 있음 | 400 `VALIDATION_FAILED` (`code`, `REQUIRED`) | 아니오 |
| 4 | 오입력 제한 (위 규칙) | 429 `INVITE_RATE_LIMITED` | 아니오 |
| 5 | 공백 제거·대문자 변환 뒤 6자리가 아니거나 31자 집합 밖 글자가 있음 | 404 `INVITE_NOT_FOUND` | 예 |
| 6 | 그 코드가 없음 | 404 `INVITE_NOT_FOUND` | 예 |
| 7 | 만든 사람 = 요청자 (만료·사용 여부와 관계없이) | 409 `INVITE_SELF` | 예 |
| 8 | 사용된 코드 | 409 `INVITE_USED` | 예 |
| 9 | 만든 사람이 지금 커플 공간에 있거나 탈퇴함 (`deleted_at` 있음) | 409 `INVITE_UNAVAILABLE` | 예 |
| 10 | 만료됨 또는 무효(`revoked_at` 있음) | 409 `INVITE_EXPIRED` | 예 |

- **리드 결정 (서버 확인 필요 4 추천안의 9·10 순서 바꿈)**: 추천안은 만료·무효(`INVITE_EXPIRED`)를 만든 사람 상태(`INVITE_UNAVAILABLE`)보다 먼저 봤다. 그런데 이번에 정한 "연결 때 다른 코드 무효화"(DB-16) 때문에, 만든 사람이 다른 사람과 연결되면 그 코드에 `revoked_at`이 생겨 `INVITE_EXPIRED`가 나온다. 이러면 PRD FR-COUPLE-02 AC3("사용할 수 없는 코드")이 깨지므로 만든 사람 상태를 먼저 본다. 만든 사람이 해제해 다시 개인 공간이면 9번에 걸리지 않고 10번(만료된 코드)이 된다.
- 5·6번 다음의 7~10번 검사는 코드 행을 잠근 뒤(`FOR UPDATE`) 한다. 잠금 순서는 Server 레포 결정(문서 밖).

### 3.4 권한 규칙 (API.md 2장)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| R- 규칙 (새) | R-18 | 규칙: "커플 연결 해제(`DELETE /couple`): 요청자의 활성 공간이 `COUPLE`일 것. 기록 가져오기(`POST /couple/import`): 요청자에게 가져오기 대기 중인 개인 공간이 있을 것(그런 공간은 커플 공간에 있는 동안만 있다, D-78). 게스트·회원 구분 없이 이 조건만 본다". 실패 응답: "409 `NOT_COUPLE` (`DELETE /couple`) / 409 `NO_IMPORT_PENDING` (`POST /couple/import`)". 근거: "FR-COUPLE-05, FR-COUPLE-03, D-78". 둘이 동시에 해제하면 두 번째 요청은 잠금 뒤 개인 공간을 보고 `NOT_COUPLE`이다 | FR-COUPLE-05, FR-COUPLE-03 |
| R- 규칙 (수정) | R-08 | 규칙 문구에 "처음 만난 날(`PATCH /space`)은 커플 공간에서만. 사람 색(`PATCH /space/colors`)은 개인 공간에서는 자기 색만"을 분명히 한다. 실패 응답 그대로 409 `NOT_COUPLE` | FR-COUPLE-04, FR-CAL-04 |
| 3.2 권한 열 | `POST /couple/import` → R-18, `DELETE /couple` → R-18 | 기존 "가져오기 대기 중인 본인", "커플 구성원"을 바꾼다 | |
| 앱 동작 | `DELETE /couple`이 409 `NOT_COUPLE` | 이미 해제된 것이므로 앱은 4.5의 6단계 앱 초기화를 한다 (D-37) | FR-COUPLE-05.AC3 |

### 3.5 공간 변경 규칙

| 항목 | 규칙 | 관련 ID |
| --- | --- | --- |
| 팔레트 키 12개 | `pick-orange`, `pick-rose`, `pick-amber`, `pick-mustard`, `pick-green`, `pick-teal`, `pick-blue`, `pick-purple`, `pick-magenta`, `pick-brown`, `pick-gray`, `pick-ink` (`design/tokens.json`의 `color.pick` 이름 그대로, 이 순서가 팔레트 순서). 기본값: 나·만든 사람 `pick-orange`, 입력한 사람 `pick-blue`, 함께 `pick-purple`. ERD 3.2 `space_members` 팔레트 키 줄에 12개를 적고, API.md 3.2 `Space` 아래에도 적는다 | FR-CAL-04, D-15 |
| `PATCH /space` (D-84) | 검사 순서: R-08(개인 공간이면 409 `NOT_COUPLE`) → `startDate`가 없거나 `null`이면 400 `VALIDATION_FAILED`(`startDate`, `REQUIRED`), 날짜 형식이 아니면 `INVALID` → 오늘(요청자 시간대)보다 뒤면 400 `VALIDATION_FAILED`(`startDate`, `INVALID`) → 1950-01-01보다 앞이면 400 `DATE_OUT_OF_RANGE`(`startDate`, `OUT_OF_RANGE`). **지우기는 없다** | FR-COUPLE-04.AC1·AC3, D-74, D-84 |
| ERD `spaces.start_date` | 설명에 "커플 공간에서 한번 정하면 바꿀 수만 있고 null로 되돌리지 않는다 (PRD D-84). 연결 직후에는 null(건너뛰기)" 추가 | D-84 |
| `PATCH /space/colors` 필드 | 모든 필드 선택. 없는 필드는 바꾸지 않는다. 같은 색 허용(경고는 앱, FR-CAL-04.AC4) | FR-CAL-04 |
| `PATCH /space/colors` 검사 순서 | ① `members`와 `together`가 둘 다 없거나 `members`가 빈 배열이고 `together`도 없음 → 400 `VALIDATION_FAILED`(`members`, `REQUIRED`). `members`나 `together`, `members[i].userId`, `members[i].color`가 `null` → 400 `VALIDATION_FAILED`(해당 필드, `REQUIRED`) ② 개인 공간인데 `together`가 있거나 `members`에 자기 밖 `userId`가 있음 → 409 `NOT_COUPLE` ③ 값 검사 → 400 `VALIDATION_FAILED`(`INVALID`): 팔레트 키 12개 밖의 `color`·`together`(필드 `members[i].color`, `together`), 활성 공간 구성원이 아닌 `userId`(다른 공간 사용자도 같은 응답이라 존재를 드러내지 않음, `members[i].userId`), 같은 `userId`가 두 번(`members[i].userId`, 두 번째 것) | FR-CAL-04, R-08 |
| `details.fields`의 필드 이름 | 배열 원소는 `members[0].color`처럼 0부터 센 인덱스로 쓴다 | 1.1 |
| `POST /couple/import` | `import`가 없거나 `null`이면 400 `VALIDATION_FAILED`(`import`, `REQUIRED`). R-18이 먼저다 | FR-COUPLE-03 |

### 3.6 알림 이동 대상 (D-85)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 알림 행 | `COUPLE_LINKED`, `COUPLE_UNLINKED`(해제·탈퇴 해제 모두) | `target_type = SETTINGS`, `target_id = null`, `space_id = null`(기존) | FR-NOTI-03, D-85 |
| API 3.5 | `targetType` 설명 | "`COUPLE_LINKED`, `COUPLE_UNLINKED`는 `SETTINGS`(`targetId` null). 그 밖에 이동 대상이 없으면 둘 다 null" | D-85 |
| 화면 | SCR-NOTI-01 이동 표 | "연결, 해제, 상대 탈퇴 → 설정 (SCR-SET-01)"에 D-85 표시. 푸시를 눌러도 같다 | FR-NOTI-03 |

### 3.7 동기화 신호 `LINKED`

- API.md는 바꾸지 않는다 (`/couple/join` 커밋 뒤 두 사람 기기에 SYNC `SPACE`/`LINKED`). 발송 코드는 Server 단위 6이 FCM과 함께 만들고, 단위 2는 커밋 뒤 전달되는 연결 이벤트까지만 만든다. Server `docs/PLAN.md` 단위 2 문구("SYNC `LINKED`" → "SYNC `LINKED` 연결점")는 Server 레포가 고친다 (문서 밖, 서버 확인 필요 1). 앱은 FR-COUPLE-02 AC5의 5초 확인으로 신호 없이도 연결을 알아챈다.

### 3.8 Kakao 연결 해제 알림 (웹훅, D-87)

API.md에 새 **3.6 웹훅** 절(경로 표)과 새 **4.8 Kakao 연결 해제 알림** 절(흐름)을 만든다. 기존 3.6 이후 절 번호는 없으므로 밀리는 절은 없다.

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| API | `GET`·`POST /webhooks/kakao/unlink` | `/api/v1` 아래 (전체 `https://<서버 주소>/api/v1/webhooks/kakao/unlink`). Kakao 서버만 부른다. Kakao는 GET(쿼리 문자열)이나 POST(폼)로 보낼 수 있어 같은 경로에서 둘 다 받는다. **access 토큰이 필요 없는 경로**라 1장의 "access 토큰이 필요 없는 경로" 목록에 더한다. 권한 열: "Kakao 어드민 키 (3.6)". FR 열: FR-AUTH-06.AC4 | FR-AUTH-06.AC4, D-87 |
| 요청 | Kakao가 보내는 값 (Kakao 문서 "연결 해제 웹훅" 확인, 2026-10-27) | 헤더 `Authorization: KakaoAK <대표 어드민 키>`. 값 `app_id`(필수), `user_id`(필수, Kakao 회원번호), `referrer_type`(필수: `ACCOUNT_DELETE`, `FORCED_ACCOUNT_DELETE`, `UNLINK_FROM_ADMIN`, `UNLINK_FROM_APPS`, `INCOMPLETE_SIGN_UP`), `group_user_token`(그룹 앱일 때만, 쓰지 않음). GET은 쿼리 문자열, POST는 `application/x-www-form-urlencoded`. `referrer_type` 값으로 동작을 나누지 않는다(모든 값을 같게 처리). 서버 밖에서 `DELETE /me`의 연결 끊기 호출로 끊은 경우에는 Kakao가 보내지 않는다 | D-87 |
| 인증 | 서버 검사 | ① 헤더가 정확히 `KakaoAK ` + 서버 설정의 Kakao 어드민 키와 같은지(상수 시간 비교) ② `app_id`가 서버 설정의 Kakao 앱 ID(4.2에서 `access_token_info`의 `app_id`와 비교하는 값과 같음)와 같은지. 하나라도 틀리면 401 `WEBHOOK_UNAUTHORIZED`이고 아무것도 바꾸지 않는다. 헤더 값과 키는 로그에 쓰지 않는다. **새 비밀값 없음**(기존 Kakao 앱 ID·어드민 키 설정을 쓴다) | NFR-SEC-01 |
| 입력 검사 | `user_id` | 인증 뒤 `user_id`가 없거나 비었으면 아무것도 바꾸지 않고 200 (Kakao 요구: 오류여도 200). 경고 로그만 남긴다 | |
| 성공 응답 | 200, 본문 없음, 3초 안에 | 1.1의 "돌려줄 내용이 없는 성공은 204"의 예외다. Kakao는 **3초 안에 `200 OK`**를 요구하고, **사용자가 없거나 오류가 나도 200**으로 답하라고 한다. 아래 "처리"의 모든 결과(아무것도 안 함 포함)가 200이다 | D-87 |
| 처리 (한 트랜잭션) | 4.8 | ① `social_accounts`에서 `provider = KAKAO`, `provider_user_id = user_id`인 행을 찾는다. 없으면 200(아무것도 안 함: 모르는 사용자, 이미 탈퇴함, 같은 알림을 두 번 받음, 서버가 `DELETE /me`에서 연결 끊기를 불러 온 알림). ② 그 사용자 행을 잠근다(`FOR UPDATE`, 탈퇴와 같은 잠금). 잠근 뒤 행이 없어졌거나 `deleted_at`이 있으면 200. ③ 그 사용자에게 `KAKAO` 밖의 `social_accounts`(곧 `GOOGLE`)가 있으면 **`KAKAO` 행만 지우고** 200. 세션·기기·데이터는 그대로이고 `Me.providers`에서 `KAKAO`가 빠진다. ④ 아니면 **`DELETE /me`와 같은 탈퇴(4.6, ERD 4.3)**를 한다. 커플이면 연결 해제와 상대에게 탈퇴 전용 `COUPLE_UNLINKED`, 속했던 커플 공간 `purge_at` +90일, 개인 공간 삭제, 익명화, 세션 `WITHDRAWN` 무효화 뒤 삭제. **커밋 뒤 Kakao 연결 끊기 API는 부르지 않는다**(이미 끊김). 200 | FR-AUTH-06.AC1·AC2·AC4, D-87, D-36, D-53 |
| 오류 응답 (Kakao 요구) | 처리 중 서버 오류 | 트랜잭션은 롤백하고 **그래도 200**으로 답한다 (200이 아니면 Kakao가 웹훅을 끌 수 있음). 처리하지 못한 알림은 ERROR 로그에 Kakao `user_id`, `referrer_type`, `traceId`를 남기고 운영자가 처리한다(`docs/DEPLOY.md`). 키·헤더 값은 로그에 쓰지 않는다. 인증 실패(`WEBHOOK_UNAUTHORIZED`)만 200이 아니다(Kakao가 보낸 요청이 아님) | |
| 앱 동작 | 탈퇴된 사용자의 기기 | 세션이 지워져 다음 요청에서 401 `SESSION_INVALID` → 안내 없이 SCR-START-01 (1장 기존 규칙). 기기의 Kakao SDK 정리는 3.9 | FR-AUTH-06.AC4 |
| 오류 코드 (새) | `WEBHOOK_UNAUTHORIZED` | 401. "웹훅 요청의 인증 실패: `Authorization`이 `KakaoAK <어드민 키>`가 아니거나 `app_id`가 둘이서 앱 ID가 아님 (`POST /webhooks/kakao/unlink`). 아무것도 바꾸지 않는다". 관련: D-87, NFR-SEC-01. 앱은 이 코드를 받을 일이 없다 | D-87 |
| ERD | `social_accounts` 서비스 줄 | "Kakao 연결 해제 알림(`POST /webhooks/kakao/unlink`): `KAKAO` 밖의 행이 있으면 `KAKAO` 행만 지우고, 없으면 그 사용자를 4.3과 같이 탈퇴 처리한다. 이때 Kakao 연결 끊기 호출은 하지 않는다 (DB-15, PRD D-87)" | D-87 |
| ERD 결정 (새) | DB-15 | 결정: "Kakao 연결 해제 알림은 `social_accounts`의 (`KAKAO`, `provider_user_id`)로 사용자를 찾아, Kakao가 유일한 로그인 수단이면 4.3 탈퇴로, 다른 수단이 있으면 `KAKAO` 행 삭제로 처리한다. 못 찾으면 아무것도 하지 않는다". 이유: "Kakao로만 들어오던 회원은 다시 들어올 방법이 없어 데이터를 남기지 않음(PRD D-87). 같은 알림이 여러 번 와도 결과가 같다(멱등). 지금은 회원이 로그인 수단을 둘 가질 API가 없지만 UNIQUE (user_id, provider)가 허용하므로 정의해 둔다" | D-87 |
| ERD 결정 (새) | DB-16 | 결정: "커플 연결 트랜잭션에서 두 사람의 다른 유효한 초대코드에 `revoked_at`을 기록한다". 이유: "연결 뒤 남은 코드가 해제 직후 다시 쓸 수 있는 코드가 되지 않게. 연결 중인 사람의 코드를 넣으면 `INVITE_UNAVAILABLE`(API 오류 우선순위)" | FR-COUPLE-02.AC3 |
| 구현 단위 | Server 단위 2 | 단위 1(탈퇴)의 후속으로 Server 단위 2에서 만든다 (탈퇴 서비스를 그대로 쓰므로). Server `docs/PLAN.md` 반영은 Server 레포 일 | |
| 사람이 할 일 | Kakao Developers | 앱 › 웹훅 › **연결 해제 웹훅**에 개발·운영 서버의 위 전체 주소를 등록한다(요청 방식을 고를 수 있으면 POST). 새 SSF 방식 "계정 상태 변경 웹훅"은 쓰지 않는다. 서버 단위 2가 배포된 뒤 등록한다 | |

### 3.9 로그아웃·탈퇴·세션 끊김 (앱 동작, D-86)

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 앱 동작 (API 3.1 `POST /auth/logout`·`DELETE /me` 설명) | 실패 처리 | 쓰기와 같이 온라인에서만 부른다. 오프라인이면 부르지 않고 "인터넷 연결이 필요해요". 응답이 401 `SESSION_REPLACED`·`SESSION_INVALID`면 이미 끊긴 세션이므로 1장 규칙대로 로컬을 지우고 SCR-START-01. 그 밖의 오류(5xx 포함)는 공통 오류 스낵바(D-88)를 보여주고 로그인 상태 그대로 둔다(기기 데이터와 토큰을 지우지 않음) | FR-AUTH-05.AC4, FR-AUTH-06.AC5, D-86, D-50 |
| 앱 동작 (API 1장, 세션 끊김 항목 다음에 한 줄) | 소셜 SDK 정리 | 로그아웃(204 뒤), 탈퇴(204 뒤), 세션 끊김(`SESSION_REPLACED`·`SESSION_INVALID`) 때 앱은 기기의 소셜 SDK 로그인 상태도 지운다: Kakao SDK 로그아웃(기기의 Kakao 토큰 삭제), Google Credential Manager 자격 증명 상태 지우기. 실패는 무시한다. Kakao 앱 연결 끊기는 서버가 한다(4.6). 서버 API는 없다 | FR-AUTH-05, FR-AUTH-06 |

### 3.10 화면 (SCREENS.md, 공통·SCR-START-01·SCR-SET-01)

보드에만 있던 문구는 보드 그대로 SCREENS에 옮긴다 (Android 확인 필요 5, 추천 A). 문구는 아래 따옴표 그대로.

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 공통 표 "공통 오류" 줄 | 근거 열 | "API.md 5장 `INTERNAL_ERROR`, D-88"로 바꾸고, 내용에 "소셜 로그인 SDK 실패(기기에 Google 계정 없음 포함)와 `SOCIAL_TOKEN_INVALID`·`GUEST_ONLY`·`GUEST_NOT_ALLOWED`도 이 안내" 추가 | D-88 |
| 공통 표 (새 줄) | "요청 중" | 로그인·연동·로그아웃·탈퇴 요청 중에는 누른 버튼과 같은 화면의 다른 시작 버튼을 비활성으로 둔다. 문구·스피너는 없다 | D-88 |
| 공통 표 (새 줄) | "소셜 로그인 취소" | 사용자가 Google·Kakao 로그인 창을 닫으면 아무 안내 없이 원래 화면 그대로 | D-88 |
| SCR-START-01 상태 | 오류·안내 위치 | 이 화면의 스낵바(다른 기기 로그인, 오프라인 안내, 공통 오류)는 모두 위에서 40 (`Main.dc.html` 51행과 같은 자리) | D-51, D-88 |
| SCR-START-01 구성 | 기능 칩 문구 | "쉐어 캘린더", "공지사항", "메모장" | |
| SCR-START-01 구성 | 로고 접근성 | "두 원이 겹친 둘이서 로고" | |
| SCR-SET-01 전체 메뉴 | 섹션 제목·계정 행 값 | 섹션 "설정"(보드 그대로). 계정 행 값: 회원 "Google 로그인" / "카카오 로그인", 게스트 "게스트 · 로그인하기" | FR-SET-01 |
| SCR-SET-01 계정 · 게스트 | 문구 | 섹션 제목 "로그인 연결", 안내 배너 본문 "앱을 지우거나 휴대폰을 바꾸면 일정과 메모를 다시 찾을 수 없어요. 로그인하면 지금까지의 기록이 계정으로 그대로 옮겨져요." (전체 메뉴 배너와 다른 문구), 정보 행 라벨 "게스트 ID" | FR-AUTH-04 |
| SCR-SET-01 계정 · 게스트 | 게스트 ID (Q-12) | 값은 `Me.id`(UUID 36자) 그대로, 줄이지 않는다. 한 줄에 안 들어가면 줄바꿈. 길게 누르면 복사하고 스낵바 없이 시스템 복사 안내를 따른다 | Q-12, FR-SET-01 |
| SCR-SET-01 계정 · 게스트 | 연동 성공 안내 | 연동(`POST /auth/link` 204)이 끝나면 계정 화면이 회원 모습으로 바뀌고, 위에 상태 문구 "로그인했어요. 게스트 기록을 계정으로 옮겼어요."를 보여준다 (`Account.dc.html` 52~53행, 화면을 떠나면 사라짐). FR-AUTH-03 AC4로 SCR-COUPLE-01로 가는 경우에는 보여주지 않는다 | FR-AUTH-03 |
| SCR-SET-01 계정 · 회원 | 문구 | 정보 행 라벨 "로그인 방식"(값 "Google" / "카카오"), "가입일"(값은 3.1 형식) | FR-SET-01 |
| SCR-SET-01 연동 오류 | 앱 동작 | `SOCIAL_ALREADY_USED` → 다이얼로그 ①(기존). `SOCIAL_TOKEN_INVALID`·`GUEST_ONLY` → 공통 오류(`GUEST_ONLY`면 `GET /me`를 다시 읽음). 오프라인 → "인터넷 연결이 필요해요" | D-88, FR-AUTH-03 |
| SCR-SET-01 다이얼로그 ② 뒤 (`POST /auth/switch`) | 오류 처리 | `SOCIAL_TOKEN_INVALID` → 소셜 SDK에서 토큰을 **한 번** 다시 받아 다시 보낸다(사용자 동작 없음). 다시 실패하거나 SDK가 실패하면 공통 오류. `SOCIAL_NOT_REGISTERED` → 공통 오류 후 다이얼로그를 닫고 게스트 그대로(리드 결정: 자동 연동은 하지 않음). 그 밖 → 공통 오류, 게스트 그대로 | D-67, D-88 |
| SCR-SET-01 로그아웃·탈퇴 | 실패 | 3.9 "실패 처리"를 한 줄로: 오프라인 "인터넷 연결이 필요해요", 서버 오류 공통 오류, 둘 다 다이얼로그를 닫고 그대로 | D-86 |
| SCR-SET-01 디자인 줄 | 탈퇴 다이얼로그 이미지 차이 | `SCR-SET-01--withdraw-dialog.png`의 뒤 화면 맨 아래 버튼이 "회원 탈퇴"로 보이지만 보드(`Account.dc.html`)와 이 문서는 "탈퇴하기"다. 구현은 "탈퇴하기". 이미지는 요청서대로 다시 만든다 | FR-AUTH-06 |
| 접근성 문구 | 공통 | 아이콘 버튼 "뒤로 가기", "닫기" (보드 그대로). 공통 표 또는 SCR-SET-01에 한 줄 | |
| SCR-SET-01 처음 만난 날 선택 시트, SCR-COUPLE-04 | 지우기 없음 | "고른 날짜를 지우는 버튼은 없어요. 다른 날로 바꿀 수만 있어요 (D-84)" | D-84 |
| SCR-COUPLE-03 오류 줄 | 입력 제한 | "1시간 10회 실패로 입력 제한" 뒤에 "(최근 1시간 실패 10번, 가장 오래된 실패가 1시간 지나면 다시 입력 가능, D-83)" | D-83 |

**design-system.md 컴포넌트 수치** (Android 확인 필요 7, 추천 A: 토큰을 바꾸지 않고 보드 값을 컴포넌트 명세에 적는다). 담당 screen이 보드에서 값을 다시 읽고 행 번호를 붙인다. 아래 값은 Android가 보드에서 읽은 것이다. 보드와 다르면 보드가 맞다.

| 컴포넌트 (design-system 새 절) | 보드 | 값 |
| --- | --- | --- |
| 시작 화면 (SCR-START-01) | `Main.dc.html` | 위 여백 96, 로고 112×72, 묶음 간격 28, 소개 17/400 행간 1.55, 칩 안쪽 위아래 6·좌우 12와 13/500, 작은 글 12/400 행간 1.6, 게스트 아이콘 20, 버튼 높이 54 |
| 버튼 | `Main.dc.html`, `Account.dc.html` | 높이 54. `size-button-lg`(56)와 다르다고 적고 **토큰과 56으로 바꾸지 않는다** (보드 값 그대로) |
| 게스트 안내 배너 | `Menu.dc.html`, `Account.dc.html` | 안쪽 18, 아이콘 22, 본문 13 행간 1.6 |
| 메뉴 행 | `Menu.dc.html` | 높이 56(전체 메뉴 주요 행)·52(정보 행) — 보드에서 어느 행이 어느 높이인지 적는다 |
| 섹션 제목 | `Account.dc.html` 38행("로그인 연결"), `Menu.dc.html` 115행("설정") | 13/600. 글자색이 보드마다 다르다(`#5B5666`, `#77727F`) — 각각 토큰 이름으로 대응해 적고 하나로 합치지 않는다 |
| 로그인 카드 | `Account.dc.html` | 안쪽 20, 체크 아이콘 선 2.2 |
| 정보 행 | `Account.dc.html` 65~66행 | 높이 52, 라벨 14 `ink-600`, 값 15/600 |
| 다이얼로그 | `Account.dc.html` 78행 이후 | 안쪽 위 24·좌우 20·아래 20, 제목 아래 간격 8, 버튼 위 16 (기존 "폭 최대 320, 모서리 24"에 더함) |

### 3.11 로고 파일 (`design/logo/`, Android 확인 필요 8)

보드 인라인 SVG를 **그대로** 옮긴다(좌표·색 값 변경 없음, 새로 그리지 않음). 색 값은 보드의 hex 그대로 두고 design-system "로고"에 토큰 대응(`person-me` #E0612F, `person-partner` #2F6FDB, `brand-500` #6D4AE0)을 적는다. 마크 색은 브랜드 고정값이라 사용자의 사람 색을 따르지 않는다(기존 문장 유지).

| 파일 | 원본 | 내용 |
| --- | --- | --- |
| `design/logo/duriseo-mark.svg` | `Menu.dc.html` 145행 (`AppIcons.dc.html` A안과 같은 도형) | `viewBox="22 32 64 44"`, 원 2개(r 20) + 겹친 부분 path. 투명 배경. 전체 메뉴 앱 정보 카드 등 작은 마크 |
| `design/logo/duriseo-mark-start.svg` | `Main.dc.html` 20~25행 | `viewBox="0 0 112 72"`, 원 2개(r 34) + clipPath 겹침. `{{accent}}`는 보드 기본값 `#6D4AE0`(`brand-500`)로 바꾼다. 시작 화면 로고 112×72 전용(도형 비율이 위 마크와 다르다고 적는다) |
| `design/logo/duriseo-app-icon.svg` | `AppIcons.dc.html` 33행 (A안) | 흰 바탕 + 마크, `viewBox="18 18 72 72"`(adaptive icon 72dp 표시 영역). 기존 "로고" 절의 A안 |

- design-system.md "로고" 절: "`Logos` 그룹에 두 파일" 문장을 "`design/logo/`에 세 파일(캔버스 `Logos` 그룹과 보드에서 옮김)"로 바꾸고 위 표를 넣는다. Android는 VectorDrawable로 옮겨 쓴다고 한 줄.

### 3.12 디자인 변경 요청서 (`design/change-requests/prd-v0.8.md`)

이전 요청서 형식을 따른다. 상태 "요청됨". 새 화면·새 토큰 없음.

1. **SCR-SET-01 계정 · 게스트** (보드 `Account.dc.html`): 게스트 ID 값 자리 "[게스트 ID]"에 샘플 UUID 36자(예: `0192f3a1-7c2e-7b8d-9a41-3f5e6d7c8b9a`)를 넣어 줄바꿈 모양을 확인하고 `SCR-SET-01--account-guest.png`를 다시 만든다 (Q-12). 다른 것은 바꾸지 않는다.
2. **SCR-SET-01 탈퇴 확인** (보드 `AccountWithdraw.dc.html`): 보드는 이미 "탈퇴하기"라 캔버스 수정 없이 `SCR-SET-01--withdraw-dialog.png`만 다시 만든다.

## 4. 위험 항목

- [ ] DB 마이그레이션 필요: 없음 (`notifications.target_type` CHECK에 `SETTINGS` 있음, `invite_codes.revoked_at`·`users.created_at` 있음)
- [x] 데이터 삭제: Kakao 웹훅이 서버 밖의 호출로 **탈퇴(되돌릴 수 없는 삭제)**를 일으킨다. 어드민 키 헤더와 `app_id` 검사가 유일한 방어라 비교·로그 규칙(3.8)을 지켜야 한다. Google도 쓰는 회원은 `social_accounts`의 `KAKAO` 행만 지운다. 연결 때 두 사람의 다른 유효 코드에 `revoked_at` 기록(DB-16)
- [x] 권한 변경: R-18 추가(`DELETE /couple` 409 `NOT_COUPLE`, `POST /couple/import` `NO_IMPORT_PENDING`), R-08 문구. 인증 없는 경로 `POST /webhooks/kakao/unlink`가 생긴다(어드민 키로 보호, 새 401 `WEBHOOK_UNAUTHORIZED`). `PATCH /space/colors`의 공간 밖 `userId`는 400(존재를 드러내지 않음)
- [x] 앱 호환성이 깨지는 API 변경: 출시 전. `Me.createdAt`은 필드 추가. 3.2 응답 모양은 처음 정한다(Server·Android 단위 2 구현 전). `GET /invite-codes/current`가 유효 코드 없음에 404. `/couple/join` 오류 우선순위의 9·10번은 서버 추천안과 순서가 다르다(3.3 리드 결정, Server 단위 2가 따라야 함)
- [x] 개인정보 처리 변경: Kakao 웹훅으로 Kakao `user_id`·`app_id`·`referrer_type`을 받는다(새로 저장하지 않음). Kakao에서 연결을 끊으면 탈퇴처럼 삭제된다 — 개인정보처리방침(Q-03)을 쓸 때 이 경우를 넣어야 하는지 사람이 확인

## 5. 열린 질문

- 없음 (사용자가 추천안대로 결정, 2026-10-27). Q-12(게스트 ID)는 기본값으로 진행하고, 바꾸려면 사용자가 알려 준다.
- Kakao 웹훅 형식은 Kakao 문서(https://developers.kakao.com/docs/latest/ko/kakaologin/callback)로 확인해 3.8에 반영했다. 재전송 여부는 문서에 없어 "오류여도 200 + ERROR 로그 + 운영자 처리"로 정했다.

## 6. 문서 밖 결정 (참고, Docs를 고치지 않음)

| 출처 | 항목 | 정한 것 | 할 곳 |
| --- | --- | --- | --- |
| Server 확인 필요 1 | SYNC `LINKED` 발송 단위 | 단위 6 (FCM과 함께). 단위 2는 커밋 뒤 이벤트까지 | Server `docs/PLAN.md` 문구 |
| Android 확인 필요 2 | 신규 소셜 회원의 첫 화면 | 단위 2는 분기 결과(`NewMember`)까지, SCR-COUPLE-01 연결은 단위 3 | Android 단위 2 |
| Android 확인 필요 3 | 전체 메뉴 진입 | 단위 2에서 캘린더 자리표시 화면에 앱바 [전체 메뉴] 버튼만 둠 | Android 단위 2 |
| Android 확인 필요 4 | SCR-SET-01 범위, FR-SET-02 단위 | 단위 2는 계정·로그아웃 부분만. FR-SET-02는 출시 단위 또는 단위 8 (Android PLAN) | Android `docs/PLAN.md` |
| Android 확인 필요 9 | 약관 링크 주소 | 링크 모양만, 동작 없음. Q-03이 정해지면 설정값으로 | Android 단위 2 |
| Android 확인 필요 14 | Server PLAN 배포 표시 | 맥에서 실제 호출로 확인하고 Server 문서를 맞춤 | Server `docs/PLAN.md` |
| Android 확인 필요 15 | Robolectric | `testImplementation`으로 추가 | Android `docs/MODULES.md` |
| Android 확인 필요 16 | 소셜 로그인 코드 위치 | `core:common`의 `social` 패키지 | Android 단위 2 |
| Server 결정 후보 | 잠금 순서, 경계값 구현, 이벤트 이름 등 | Server 단위 2 "결정"대로 (경계값은 3.3에 적은 것이 기준) | Server 단위 2 |

## 7. 검수 기록

| 회차 | 판정 | Critical | 비고 |
| --- | --- | --- | --- |
