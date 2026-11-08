# PRD v0.7 영향 분석

> 상태: PR 완료
> 이전 버전: v0.6 → 새 버전: v0.7
> 브랜치: sync/prd-v0.7
> PR: https://github.com/DuriseoApp/Docs/pull/7

이 파일은 `/prd-sync` 팀원들이 읽는 계약이다. 여기 적힌 이름과 할 일을 그대로 따른다.

배경: Server 레포 단위 1(계정) 범위 점검에서 API.md·ERD에 빈 곳이 16개 나왔다 (Server `docs/progress/unit-1.md` "확인 필요"). 사용자가 추천안대로 정했다 (2026-10-26). PRD에는 제품 결정 두 개(D-81, D-82)만 넣고, 나머지 API 세부는 이 파일의 "이름 확정"대로 API.md·ERD에 채운다.

## 1. 바뀐 ID

| ID | 변경 | 내용 |
| --- | --- | --- |
| NFR-SEC-01 | 수정 | access는 JWT(1시간), refresh는 추측할 수 없는 무작위 토큰(회원 30일·게스트 365일, 쓸 때마다 연장), 서버는 refresh 해시만 저장 |
| NFR-LIMIT-01 | 수정 | 글자 수는 문자 단위로 센다 (D-82) |
| D-73 | 수정 | "자동 로그인은 JWT" 문구를 빼고 토큰 형식은 D-81로 |
| D-81 | 추가 | access 토큰은 JWT, refresh 토큰은 무작위 문자열(서버는 해시만 저장) |
| D-82 | 추가 | 입력 제한 글자 수는 유니코드 코드 포인트로 센다. 앞뒤 공백만 있는 닉네임은 빈 값 |

## 2. 문서별 할 일

| 문서 | 담당 | 할 일 |
| --- | --- | --- |
| docs/ERD.md (+ ERD.png) | data | 헤더 PRD v0.7. `auth_sessions.refresh_token_hash` 설명에 D-81(무작위 refresh 토큰, 3장 이름 확정의 형식)과 연결. `users.nickname` 설명에 D-82(코드 포인트, 앞뒤 공백 제거 후 저장). `devices.platform` 값은 `ANDROID`·`IOS`이고 API에서 검사(CHECK는 두지 않음, 기존 그대로)라고 적기. 스키마 변경 없음. ERD.png는 그림이 바뀌지 않으면 다시 만들지 않아도 됨 |
| docs/API.md | api | 헤더 PRD v0.7. 3장 "이름 확정"의 요청·응답 모양, 토큰 형식, 인증 오류 규칙, Kakao 프로필 이름 조회, Google `iss` 두 값을 1장·3.1·4.1~4.3·4.6·4.7·5장에 반영. 3.1 표의 각 경로에 성공 상태와 본문을 적고, 공통 모양(`AuthTokens`, `Me`)은 3.1 아래에 한 번 정의 |
| docs/SCREENS.md | screen | 헤더 PRD v0.7. 닉네임 입력이 있는 화면(SCR-SET-04 등)에 글자 수 기준(D-82)이 필요하면 한 줄 추가. 그 밖에는 바꾸지 않음 |
| 디자인 변경 요청서 | screen | 없음 (화면 변경 없음) |

## 3. 이름 확정

### 3.1 토큰

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| access 토큰 | JWT | HS256, 서버 비밀 키로 서명. 클레임 `sub`(사용자 ID, uuid 문자열), `sid`(세션 ID = `auth_sessions.id`), `iat`, `exp`(발급 + 1시간). 계정 종류는 토큰에 넣지 않는다(연동 직후 같은 토큰으로 판단이 바뀌어야 함, 서버는 DB에서 읽음) | D-81, NFR-SEC-01 |
| refresh 토큰 | 무작위 문자열 | 보안 난수 32바이트를 base64url(패딩 없음)로 인코딩한 43자. DB에는 SHA-256 16진수 64자만 저장 (`refresh_token_hash`, char(64)) | D-81, DB-02 |
| 요청 헤더 | `Authorization: Bearer <access>` | 기존 그대로 | 1장 |

### 3.2 공통 응답 모양

`AuthTokens` (토큰을 주는 경로의 응답 본문)

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `accessToken` | string | access JWT |
| `accessTokenExpiresAt` | 일시 (ISO 8601 UTC) | access 만료 시각 |
| `refreshToken` | string | refresh 토큰 원문 |
| `refreshTokenExpiresAt` | 일시 | refresh 만료 시각 (회원 30일, 게스트 365일) |
| `isNewUser` | boolean | 이번 요청으로 사용자가 새로 만들어졌는지. `/auth/guest`는 `true`, `/auth/switch`·`/auth/refresh`는 `false`, `/auth/social`은 신규 가입이면 `true` |

`Me` (`GET /me`, `PATCH /me` 응답 본문)

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `id` | uuid | 사용자 ID |
| `accountType` | `GUEST` \| `MEMBER` | |
| `nickname` | string | |
| `timeZone` | string | IANA 시간대 |
| `providers` | (`GOOGLE` \| `KAKAO`)[] | 연결된 로그인 수단. 게스트는 `[]` (FR-SET-01 로그인 수단 표시) |
| `hasProfileImage` | boolean | 프로필 사진이 있는지. 이미지는 `GET /users/{id}/profile-image` (단위 7) |
| `space` | `MeSpace` | 현재 활성 공간 요약 |

`MeSpace`

| 필드 | 타입 | 뜻 |
| --- | --- | --- |
| `id` | uuid | 활성 공간 ID |
| `type` | `PERSONAL` \| `COUPLE` | |
| `myColor` | string | 내 사람 색 팔레트 키 (`pick-*`) |
| `partner` | `MePartner` \| null | 커플 공간의 상대. 개인 공간이면 `null` |
| `togetherColor` | string \| null | '함께' 색. 개인 공간이면 `null` |
| `startDate` | 날짜 \| null | 처음 만난 날. 개인 공간이거나 안 정했으면 `null` |
| `importPending` | boolean | 가져오기 대기 중인 개인 공간이 있는지 (FR-COUPLE-03) |

`MePartner`: `id`(uuid), `nickname`(string), `color`(팔레트 키), `hasProfileImage`(boolean)

### 3.3 경로별 요청·응답

| API | 요청 | 성공 | 관련 ID |
| --- | --- | --- | --- |
| `POST /auth/guest` | 본문 없음 | 201 `AuthTokens` | FR-AUTH-01 |
| `POST /auth/social` | `{provider: "GOOGLE" \| "KAKAO", token: string}` | 200 `AuthTokens` | FR-AUTH-02 |
| `POST /auth/link` | `{provider, token}` | 204 (새 토큰 없음, 앱은 `GET /me`로 다시 읽음) | FR-AUTH-03 |
| `POST /auth/switch` | `{provider, token}` | 200 `AuthTokens` (`isNewUser: false`) | FR-AUTH-03.AC3, D-67 |
| `POST /auth/refresh` | `{refreshToken: string}` (access 토큰 불필요) | 200 `AuthTokens` (새 refresh 토큰, `sid` 그대로) | NFR-SEC-01, DB-02 |
| `POST /auth/logout` | 본문 없음 | 204 | FR-AUTH-05 |
| `GET /me` | | 200 `Me` | FR-SET-01 |
| `PATCH /me` | `{nickname?: string, timeZone?: string}`. 없는 필드는 바꾸지 않음. `null`을 보내면 400 `VALIDATION_FAILED`(`REQUIRED`) | 200 `Me` | FR-AUTH-07, NFR-TIME-01 |
| `DELETE /me` | 본문 없음 | 204 | FR-AUTH-06 |
| `PUT /me/devices` | `{fcmToken: string(최대 255), platform?: "ANDROID" \| "IOS"}` (기본 `ANDROID`) | 204 | NFR-SYNC-01 |

### 3.4 검증·오류 규칙

| 항목 | 규칙 | 관련 ID |
| --- | --- | --- |
| 인증 실패 | `Authorization` 헤더가 없음, `Bearer` 형식이 아님, 서명이 틀림, 클레임이 없거나 틀림 → 401 `SESSION_INVALID`. 서명은 맞고 `exp`가 지남 → 401 `TOKEN_EXPIRED`. 그 뒤 세션 검사(1장)는 기존 그대로. 검사 순서: 형식·서명 → 만료 → 세션 | NFR-SEC-01 |
| 소셜 제공자 장애 | Google 공개키를 받지 못함, Kakao가 5xx를 주거나 시간 초과 → 500 `INTERNAL_ERROR`(아무것도 바꾸지 않음). Kakao가 토큰을 거부(4xx) → 401 `SOCIAL_TOKEN_INVALID` | NFR-SEC-01 |
| Google `iss` | `accounts.google.com`과 `https://accounts.google.com` 둘 다 허용 | NFR-SEC-01 |
| Google 이름 | ID 토큰의 `name` 클레임. 없거나 공백뿐이면 "사용자" (D-69) | FR-AUTH-07.AC1 |
| Kakao 이름 | 토큰 확인(`access_token_info`) 뒤 `GET https://kapi.kakao.com/v2/user/me`로 `kakao_account.profile.nickname`만 받는다. 없거나 공백뿐이면 "사용자". 이메일 등 다른 값은 받거나 저장하지 않는다 (NFR-PRIV-01). Kakao Developers에서 "닉네임" 동의항목이 켜져 있어야 한다 | FR-AUTH-07.AC1, D-69 |
| Kakao 이름 조회 시점 (리드 결정) | `/v2/user/me`는 닉네임이 필요한 때만 부른다: `/auth/social` 신규 가입, `/auth/link`(닉네임이 정확히 "게스트"일 때, D-68). `/auth/switch`와 기존 회원의 `/auth/social` 로그인은 `access_token_info`만 | FR-AUTH-07.AC1 |
| 닉네임 | 앞뒤 공백을 지운 값으로 저장하고 코드 포인트로 센다. 1~10자. 지운 뒤 빈 값이면 `VALIDATION_FAILED`(`nickname`, `REQUIRED`), 10자 초과면 `TOO_LONG`. 소셜 이름을 자를 때도 코드 포인트 10개 | D-82, NFR-LIMIT-01 |
| 시간대 | Java `ZoneId`로 해석되는 IANA 이름만. 아니면 `VALIDATION_FAILED`(`timeZone`, `INVALID`). 새 사용자는 `Asia/Seoul`로 시작하고 앱이 실행 때 `PATCH /me`로 갱신 | NFR-TIME-01 |
| fcmToken | 비었으면 `VALIDATION_FAILED`(`fcmToken`, `REQUIRED`), 255자 초과면 `TOO_LONG` (리드 결정, 검수 1회차). `platform`이 두 값이 아니면 `INVALID` | NFR-SYNC-01 |
| Kakao `/v2/user/me` 실패 (리드 결정, 검수 1회차) | 4xx(동의항목 꺼짐 등)는 거부하지 않고 이름 없음으로 보고 "사용자"(D-69). 5xx·시간 초과는 500 `INTERNAL_ERROR`. `SOCIAL_TOKEN_INVALID`는 `access_token_info` 단계의 거부에만 | FR-AUTH-07.AC1, D-69 |

새 오류 코드는 없다. 기존 `TOKEN_EXPIRED`, `SESSION_INVALID`, `INTERNAL_ERROR`, `VALIDATION_FAILED`의 "언제" 열만 위 규칙에 맞게 넓힌다.

## 4. 위험 항목

- [ ] DB 마이그레이션 필요: 없음
- [ ] 데이터 삭제: 없음
- [ ] 권한 변경: 없음 (R- 규칙 그대로)
- [x] 앱 호환성이 깨지는 API 변경: 아직 출시 전이고 인증 API 구현 전이라 영향 없음. 이번에 응답 모양을 처음 정한다
- [x] 개인정보 처리 변경: Kakao `/v2/user/me` 호출을 추가하지만 닉네임만 받는다 (NFR-PRIV-01 범위 안). 사람이 할 일: Kakao Developers 동의항목 "닉네임" 확인

## 5. 열린 질문

- 없음 (사용자가 추천안대로 결정, 2026-10-26)

## 6. 검수 기록

| 회차 | 판정 | Critical | 비고 |
| --- | --- | --- | --- |
| 1 | 머지 가능 | 0 | Major 0, Minor 4: fcmToken reason·Kakao /v2/user/me 4xx는 리드 결정으로 api가 반영, ERD nickname 문장 정리는 data, SCREENS 이름 규칙은 그대로 둠(아래 줄이 기준을 설명) |
