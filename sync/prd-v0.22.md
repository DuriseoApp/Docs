# PRD v0.22 영향 분석

> 상태: 검수 중 (디자인 반영 완료, 캔버스 버전 46)
> 이전 버전: v0.21 → 새 버전: v0.22
> 브랜치: sync/prd-v0.22
> PR: (PR 완료 후 링크)

이 파일은 `/prd-sync` 팀원들이 읽는 계약이다. 여기 적힌 이름과 할 일을 그대로 따른다.

진행 방식: **팀** (ERD, API, SCREENS, 디자인 요청서를 모두 고친다). 개인정보처리방침 초안(`legal/privacy.md`)은 리드가 고친다.
사용자 결정: 2026-11-25. 장애 팝업과 강제·권장 업데이트를 넣는다. 두 기능은 따로 설정하고, 둘 다 Remote Config와 서버 두 곳에서 설정한다. 표시 순서, 서버 426 차단, 메뉴 [업데이트] 유지, 장애 안내의 "오늘 하루 안 보기", 기본 이미지 4종을 추천안대로 정했다.

## 1. 바뀐 ID

| ID | 변경 | 내용 |
| --- | --- | --- |
| FR-APP-01 | 추가 | 장애 팝업(차단·안내). 두 곳 합치기, 닫기 규칙, 이미지, 서버 3초 |
| FR-APP-02 | 추가 | 강제·권장 업데이트. 빌드·OS 조건, 즉시 업데이트, 오늘 하루 안 보기, 426 처리, 메뉴 버튼은 그대로 |
| FR-APP-03 | 추가 | 기기 정보 헤더와 저장 |
| SCR-APP-01 | 추가 | 장애 팝업 (가운데 다이얼로그) |
| SCR-APP-02 | 추가 | 업데이트 팝업 (가운데 다이얼로그) |
| D-176 | 추가 | 장애 팝업 설정: Remote Config `app_notices` + 서버 `app_notices`, 필드, 관리자 API |
| D-177 | 추가 | 업데이트 규칙: Remote Config `app_update_rules` + 서버 `app_update_rules`, 조건 형식, 앱이 판단 |
| D-178 | 추가 | 표시 순서(강제 → 차단 → 권장 → 안내), 같은 `id` 합치기, 확인 시점, RC 가져오기 간격 5분 |
| D-179 | 추가 | 닫기 규칙과 "오늘 하루 안 보기"(id별, 기기 단위) |
| D-180 | 추가 | 서버 426 `APP_VERSION_UNSUPPORTED` 차단, 예외, 기본 문구 |
| D-181 | 추가 | 이미지: `preset:` 4종 또는 `https://`, 서버 이미지 저장 |
| D-182 | 추가 | 기기 정보 헤더 4개, `devices` 저장, 개인정보처리방침 |
| NFR-PRIV-03 | 추가 | 기기 정보의 쓰임과 삭제, Remote Config 위탁 |
| NFR-SEC-04 | 추가 | 관리자 API는 관리자 키 헤더로만 |
| Q-21, Q-22, Q-23 | 추가 | 팝업 뒤로 가기·밖 누르기, [다시 확인] 중·오프라인, `https://` 이미지 받는 중 (screen 질문, 기본값) |
| D-151, FR-SET-02 AC4 | 수정 | "강제 업데이트는 하지 않는다" → 메뉴 [업데이트]는 유연 업데이트, 강제는 FR-APP-02 |
| 용어 7개, 3장 범위(운영 행, 범위 밖 관리 웹), 5장 화면 목록 | 수정 | 위와 같음 |

## 2. 문서별 할 일

| 문서 | 담당 | 할 일 |
| --- | --- | --- |
| docs/ERD.md (+ erd.html, ERD.png) | data | 새 테이블 `app_notices`, `app_update_rules`(3장 이름 확정 그대로). `devices`에 컬럼 3개. 2장 한눈에 보기, 3.1 `devices` 서비스 규칙(등록 때 버전 저장), 새 절 "3.4 운영"(또는 맞는 위치), 4장 수명주기(관리자 API로만 생성·삭제, 자동 삭제 없음, 탈퇴·로그아웃은 `devices`와 함께), 4.4 정리 작업의 "프로필 사진 파일 정리"가 공지 이미지(`notice/` 접두어)를 지우지 않게, DB-21·DB-22, 6장 추적표(FR-APP-01~03). erd.html에 두 테이블(관계 없음)과 `devices` 컬럼 추가 후 ERD.png 다시 렌더 |
| docs/API.md | api | 1장: 공통 요청 헤더 4개(D-182), access 토큰이 필요 없는 경로에 공개 조회 3개와 관리자 API(관리자 키) 추가. 새 R-19(관리자 키), R-20(강제 업데이트 차단). 3.1 `PUT /me/devices` 요청 필드 3개. 새 절 "3.7 운영: 장애 팝업·업데이트 규칙"(공개 조회 3개, 관리자 API 8개, 응답 모양 `AppNotice`·`AppUpdateRule`, 판단 규칙, Remote Config 값 모양이 같다는 것). 4장 새 흐름 "4.9 앱 실행 때 팝업 확인 (FR-APP-01, FR-APP-02)". 5장 오류 코드 `APP_VERSION_UNSUPPORTED`(426)·`ADMIN_KEY_INVALID`(401), `VALIDATION_FAILED`에 새 필드. 1.1 `details` 표에 426 모양. 8장에 공지 이미지 저장. 9장 추적표 |
| docs/SCREENS.md | screen | SCR-APP-01, SCR-APP-02 새 절(구성, 상태: 이미지 있음/없음, 링크 버튼 있음/없음, 차단/안내, 강제/권장, 동작, 접근성, 문구). 앱 전체 공통 규칙(모든 화면 위, 한 번에 하나)을 적는다. 디자인 상태는 "변경 요청됨" |
| design/change-requests/prd-v0.22.md | screen | 새 보드 2개(장애 팝업: 차단·안내 × 이미지 있음/없음, 업데이트 팝업: 강제·권장), 기본 이미지 4종 그림(`maintenance`, `error`, `update`, `notice`), 만들 PNG 목록 |
| legal/privacy.md | 리드 | 수집 항목 "기기·알림"에 "기기 정보(OS 버전, 앱 버전)" 추가, 위탁 표에 Firebase Remote Config(Google LLC) 추가, 이용 목적에 "장애 안내와 업데이트 안내" 추가 |

## 3. 이름 확정

**Remote Config 키** (값은 JSON 문자열. 서버 응답과 같은 모양 `{"items": [...]}`)

| 키 | 값 | 관련 ID |
| --- | --- | --- |
| `app_notices` | `{"items": [AppNotice, ...]}` | D-176 |
| `app_update_rules` | `{"items": [AppUpdateRule, ...]}` | D-177 |

Remote Config 사용자 지정 신호(custom signal)는 쓰지 않는다. 규칙 판단을 앱이 하므로 콘솔 조건이 필요 없다 (초안의 `osVersion` 신호는 뺐다).

**응답·값 모양**

`AppNotice`

| 필드 | 타입 | 규칙 |
| --- | --- | --- |
| `id` | string | 1~50자, `[a-z0-9_-]`만. 두 곳에서 같은 장애는 같은 값 |
| `type` | `"BLOCK"` \| `"INFO"` | 필수 |
| `title` | string | 필수, 1~40자 |
| `body` | string | 필수, 1~500자. 줄바꿈 `\n` 허용 |
| `image` | string \| null | `preset:maintenance`·`preset:error`·`preset:update`·`preset:notice` 또는 `https://` 주소(500자 이하) |
| `linkText` | string \| null | 1~20자. `linkUrl`과 둘 다 있어야 버튼이 보인다 |
| `linkUrl` | string \| null | `https://` 주소, 500자 이하 |
| `platform` | `"ANDROID"` \| `"IOS"` \| null | null이면 모든 플랫폼 |
| `startsAt` | 일시 \| null | null이면 지금 바로 |
| `endsAt` | 일시 \| null | null이면 끝 없음. `startsAt`보다 뒤여야 함 |

`AppUpdateRule`

| 필드 | 타입 | 규칙 |
| --- | --- | --- |
| `id` | string | `AppNotice.id`와 같은 규칙 |
| `mode` | `"FORCE"` \| `"RECOMMEND"` | 필수 |
| `platform` | `"ANDROID"` \| `"IOS"` | 필수 |
| `build` | object | 필수. `op`: `EQ`·`LTE`·`GTE`(→ `value` 필수), `RANGE`(→ `min`·`max` 필수, `min` ≤ `max`, 양 끝 포함), `IN`(→ `values` 필수, 1~50개). 쓰지 않는 필드는 `null`. 값은 0 이상 정수(versionCode) |
| `osVersion` | object \| null | `{min, max}`, 둘 중 하나 이상 정수, 양 끝 포함. Android는 API 레벨. null이면 OS 조건 없음 |
| `title` | string | 필수, 1~40자 |
| `body` | string | 필수, 1~500자 |
| `image` | string \| null | `AppNotice.image`와 같은 규칙. null이면 앱은 `preset:update` |

"지금 유효함"(장애 팝업)은 `(startsAt IS NULL OR startsAt <= now) AND (endsAt IS NULL OR now < endsAt)`이고, 플랫폼은 `platform IS NULL OR platform = 앱 플랫폼`이다. 업데이트 규칙에는 기간이 없다(지우면 끝난다).

**API**

| 메서드 | 경로 | 인증 | 요청 → 응답 | 관련 ID |
| --- | --- | --- | --- | --- |
| GET | /app-notices | 없음 | → 200 `{"items": [AppNotice]}`. 지금 유효한 것만, 모든 플랫폼. 정렬은 `created_at` 오래된 순, 같으면 `id` | FR-APP-01, D-176 |
| GET | /app-update-rules | 없음 | → 200 `{"items": [AppUpdateRule]}`. 모든 규칙, 같은 정렬 | FR-APP-02, D-177 |
| GET | /app-notice-images/{fileName} | 없음 | → 200 이미지 바이트, `Cache-Control: public, max-age=86400`. 없으면 404 `NOT_FOUND` | D-181 |
| GET | /admin/app-notices | 관리자 키 | → 200 `{"items": [AppNotice]}` (끝난 것 포함) | D-176 |
| PUT | /admin/app-notices/{id} | 관리자 키 | `AppNotice`에서 `id`를 뺀 본문 → 200 `AppNotice`. 없으면 만들고 있으면 바꾼다 | D-176 |
| DELETE | /admin/app-notices/{id} | 관리자 키 | → 204. 없으면 404 `NOT_FOUND` | D-176 |
| GET | /admin/app-update-rules | 관리자 키 | → 200 `{"items": [AppUpdateRule]}` | D-177 |
| PUT | /admin/app-update-rules/{id} | 관리자 키 | `AppUpdateRule`에서 `id`를 뺀 본문 → 200 `AppUpdateRule` | D-177 |
| DELETE | /admin/app-update-rules/{id} | 관리자 키 | → 204. 없으면 404 `NOT_FOUND` | D-177 |
| POST | /admin/app-notice-images | 관리자 키 | multipart `file`(PNG·JPEG·WebP, 1MB 이하) → 201 `{"url": "https://<API 도메인>/api/v1/app-notice-images/<fileName>"}` | D-181 |
| DELETE | /admin/app-notice-images/{fileName} | 관리자 키 | → 204. 없으면 404 `NOT_FOUND` | D-181 |
| PUT | /me/devices (수정) | 로그인 | 요청에 `osVersion?: string(최대 20)`, `appVersion?: string(최대 50)`, `appBuild?: integer(0 이상)` 추가. 보낸 값만 저장하고 안 보낸 값은 null로 둔다 | FR-APP-03, D-182 |

**공통 요청 헤더 (D-182)**

| 헤더 | 값 | 예 |
| --- | --- | --- |
| `X-Platform` | `ANDROID` \| `IOS` | `ANDROID` |
| `X-App-Version` | versionName | `1.0.0` |
| `X-App-Build` | versionCode (0 이상 정수) | `10` |
| `X-OS-Version` | Android API 레벨 (정수) | `34` |

**관리자 키 (NFR-SEC-04)**

- 헤더 `X-Admin-Key`. 서버 환경변수 `DURISEO_ADMIN_API_KEY`(운영은 Parameter Store `/duriseo/secret/ADMIN_API_KEY`). 비교는 상수 시간.
- 환경변수가 비어 있으면 `/admin/**`는 모두 404 `NOT_FOUND`(관리자 API가 꺼짐). 키가 없거나 틀리면 401 `ADMIN_KEY_INVALID`.
- 관리자 API는 access 토큰을 보지 않는다.

**강제 업데이트 차단 (R-20, D-180)**

- `/api/v1` 아래 모든 요청에 적용. 예외: `GET /app-notices`, `GET /app-update-rules`, `GET /app-notice-images/{fileName}`, `/admin/**`. (헬스체크는 `/api/v1` 밖이라 해당 없음.)
- `X-Platform`과 `X-App-Build`가 모두 있고 읽을 수 있을 때만 검사한다. 하나라도 없거나 형식이 틀리면 통과. `X-OS-Version`이 없거나 틀리면 `osVersion` 조건이 있는 규칙만 건너뛴다.
- 검사 순서는 인증 검사(1장)보다 먼저다(로그인 전 요청도 막는다).
- 맞는 `FORCE` 규칙이 있으면 426, 오류 객체 `code`=`APP_VERSION_UNSUPPORTED`, `details`=`{"ruleId", "title", "body", "image"}` (여럿이면 정렬 첫 번째).
- 서버는 규칙을 요청마다 DB에서 읽지 않고 짧게(최대 30초) 메모리에 캐시해도 된다.

**오류 코드**

| 코드 | 상태 | 언제 |
| --- | --- | --- |
| `APP_VERSION_UNSUPPORTED` | 426 | R-20 |
| `ADMIN_KEY_INVALID` | 401 | 관리자 키가 없거나 틀림 |
| `VALIDATION_FAILED` | 400 | 관리자 API 본문 규칙 위반(위 표의 필드 이름, `REQUIRED`·`TOO_LONG`·`INVALID`), `PUT /me/devices`의 새 필드 형식 |
| `IMAGE_TOO_LARGE` | 413 | 공지 이미지 1MB 초과 (기존 코드 재사용) |
| `IMAGE_TYPE_NOT_ALLOWED` | 415 | 공지 이미지가 PNG·JPEG·WebP가 아니거나 디코드 실패 (기존 코드 재사용) |

**테이블·컬럼**

| 테이블.컬럼 | 타입 | 제약 |
| --- | --- | --- |
| `app_notices.id` | varchar(50) | PK. **UUID PK 원칙의 예외**: Remote Config와 같은 `id`를 써야 해서 운영자가 정한 문자열 |
| `app_notices.type` | varchar(10) | not null, CHECK (`BLOCK`, `INFO`) |
| `app_notices.title` | varchar(40) | not null |
| `app_notices.body` | varchar(500) | not null |
| `app_notices.image` | varchar(500) | null |
| `app_notices.link_text` | varchar(20) | null |
| `app_notices.link_url` | varchar(500) | null |
| `app_notices.platform` | varchar(10) | null (API에서 검사, `devices.platform`과 같은 예외) |
| `app_notices.starts_at`, `ends_at` | timestamptz | null |
| `app_notices.created_at`, `updated_at` | timestamptz | not null default now() |
| `app_update_rules.id` | varchar(50) | PK (같은 예외) |
| `app_update_rules.mode` | varchar(10) | not null, CHECK (`FORCE`, `RECOMMEND`) |
| `app_update_rules.platform` | varchar(10) | not null |
| `app_update_rules.build_op` | varchar(5) | not null, CHECK (`EQ`, `LTE`, `GTE`, `RANGE`, `IN`) |
| `app_update_rules.build_value`, `build_min`, `build_max` | integer | null |
| `app_update_rules.build_values` | integer[] | null |
| `app_update_rules.os_min`, `os_max` | integer | null |
| `app_update_rules.title`, `body`, `image` | `app_notices`와 같음 | |
| `app_update_rules.created_at`, `updated_at` | timestamptz | not null default now() |
| `devices.os_version` | varchar(20) | null |
| `devices.app_version` | varchar(50) | null |
| `devices.app_build` | integer | null |

- Flyway: Server 레포의 다음 버전 하나(`V4__app_notices_update_rules_device_info.sql`)에 셋 다 넣는다.
- 공지 이미지 스토리지 객체 키: `notice/{uuid}.{png|jpg|webp}`. `fileName` = `{uuid}.{ext}`. 프로필 사진 정리 작업(ERD 4.4)은 `profile/` 접두어만 본다. 공지 이미지는 자동으로 지우지 않는다(관리자 API로만).
- ERD 결정 번호: DB-21(두 테이블, 문자열 PK 예외, 자동 정리 없음), DB-22(`devices` 버전 컬럼, 등록 때 덮어씀).
- API 규칙 번호: R-19(관리자 키), R-20(강제 업데이트 차단).

**화면·문구**

| 화면 | 요소 | 문구·규칙 | 관련 ID |
| --- | --- | --- | --- |
| SCR-APP-01 | 차단 버튼 | "다시 확인" | D-179 |
| SCR-APP-01 | 안내 버튼 | "확인", "오늘 하루 안 보기" | D-179 |
| SCR-APP-01 | 링크 버튼 | `linkText` 그대로 | FR-APP-01 AC3 |
| SCR-APP-01 | [다시 확인] 뒤에도 차단이면 | 팝업 그대로, 문구 바뀌면 새 값으로 | FR-APP-01 AC2 |
| SCR-APP-02 | 강제 버튼 | "업데이트" | D-179 |
| SCR-APP-02 | 권장 버튼 | "업데이트", "오늘 하루 안 보기", "닫기" | D-179 |
| SCR-APP-02 | 426 기본 문구 | 제목 "업데이트가 필요해요", 본문 "새 버전으로 업데이트해야 계속 쓸 수 있어요." | D-180 |
| 공통 | 기본 이미지 키 | `maintenance`, `error`, `update`, `notice` | D-181 |

## 4. 위험 항목

- [x] **DB 마이그레이션 필요**: 새 테이블 2개, `devices` 컬럼 3개 (V4). 모두 추가라 기존 데이터에 영향 없음.
- [ ] 데이터 삭제: 없음. 단, 프로필 사진 정리 작업이 공지 이미지를 지우지 않게 접두어로 나눠야 한다.
- [x] **권한 변경**: 로그인 없이 부르는 공개 경로 3개, 관리자 키로 부르는 경로 7개가 생긴다. 관리자 키가 새는 것이 가장 큰 위험이다(아무나 차단 팝업을 띄울 수 있음).
- [x] **앱 호환성**: 서버가 426으로 앱 요청을 막을 수 있다. 규칙을 잘못 넣으면 모든 사용자가 앱을 못 쓴다. 헤더 없는 요청은 통과시켜 옛 앱은 막지 않는다(출시 전이라 없음).
- [x] **개인정보 처리 변경**: 기기 정보(OS 버전, 앱 버전) 수집, Firebase Remote Config 위탁. 개인정보처리방침 고침(초안은 이 PR, Notion 게시는 사람).

## 5. 열린 질문

2026-11-25 사용자 승인(start)으로 아래 기본값을 모두 확정했다:

1. 권장 업데이트에 [닫기](이번만 닫기)도 둔다. ("오늘 하루 안 보기"만 두면 업데이트하거나 하루를 숨기는 것 말고는 닫을 수 없음)
2. 426 기본 문구: "업데이트가 필요해요" / "새 버전으로 업데이트해야 계속 쓸 수 있어요."
3. 장애 차단 팝업의 버튼은 [다시 확인] (+ 선택 링크 버튼).
4. 길이 제한: 제목 40자, 본문 500자, 링크 버튼 20자. 공지 이미지 1MB.

## 6. 검수 기록

| 회차 | 판정 | Critical | 비고 |
| --- | --- | --- | --- |
| 1 | 통과 | 0 | Major 3(D-180 예외 경로·응답 필드 → 리드, ERD 3.4 읽기 경로 표현 → data), Minor 7(개인정보 Remote Config 항목, 권한 매트릭스 각주, API 정수 범위·DELETE 404·동기화 신호 줄, SCREENS 값 거르기·스낵바 위치·이미지 대기 합치기). 모두 고침. check-ids 통과 |
