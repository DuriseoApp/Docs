# 둘이서 개발 환경 설정값

> 기준 문서: 둘이서 PRD v0.6 (`docs/PRD.md`)
> 작성일: 2026-10-25

Server·Android 에이전트가 설정 파일을 만들 때 쓰는 값을 모아 둔 문서예요. **여기에는 공개돼도 되는 값만 적어요.** 비밀값은 이름과 보관 위치만 적고 값은 절대 쓰지 않아요 (CLAUDE.md "하지 않는 것").

## 1. 앱 식별자

| 항목 | 값 |
| --- | --- |
| Android `applicationId`, `namespace`, 코드 패키지 | `com.duriseo.android` |
| Gradle convention plugin ID | `duriseo.android.*` (application, library, compose, hilt, feature) |
| 앱 이름 | 둘이서 |

## 2. 공개 설정값

앱 APK 안에 들어가거나 서버가 토큰을 검증할 때 비교하는 값이라 공개돼도 괜찮아요.

| 서비스 | 항목 | 값 | 쓰는 곳 |
| --- | --- | --- | --- |
| Firebase | 프로젝트 ID | `duriseo-c00eb` | 서버(FCM 발송), 앱 |
| Google 로그인 | 웹 애플리케이션 클라이언트 ID | `164429031544-nkgkrjdauageetenid2rkl39i2h6tjbg.apps.googleusercontent.com` | 앱(Credential Manager의 `serverClientId`), 서버(ID 토큰 `aud` 검증, NFR-SEC-01) |
| Google 로그인 | Android 클라이언트 | 패키지 `com.duriseo.android` + 디버그 SHA-1로 등록됨 | 콘솔 등록만 (앱 코드에 넣지 않음) |
| 카카오 | 네이티브 앱 키 | `ecbb523761a070e1905bdaf429c81c40` | 앱(Kakao SDK 초기화, `AndroidManifest`의 scheme `kakao<네이티브 앱 키>`) |
| 카카오 | 앱 ID | `1621631` | 서버(`access_token_info`의 `app_id` 검증, NFR-SEC-01) |
| 카카오 | 동의 항목 | 닉네임만 (필수 동의). 이메일·전화번호·프로필 사진 받지 않음 | NFR-PRIV-01 |
| 문의 메일 | 주소 | `jucoding99@gmail.com` (바뀔 수 있어 앱 설정값으로) | PRD Q-10, FR-SET-02 |

Google OAuth 동의 화면은 "테스트" 상태예요. 테스트 사용자로 등록된 계정만 Google 로그인을 할 수 있어요. 출시 때 "앱 게시"로 바꿔요.

## 3. 비밀값 (값은 여기에 쓰지 않음)

| 항목 | 쓰는 곳 | 보관 위치 |
| --- | --- | --- |
| Firebase 서비스 계정 키 (JSON) | 서버 FCM 발송 | 사용자 맥 → GitHub Secrets → AWS 서버 환경변수 (서버 키트에서 이름을 정함) |
| `google-services.json` | Android 앱 빌드 | 사용자 맥, CI는 GitHub Secrets. 공개 레포라 커밋하지 않음 |
| 카카오 어드민 키 | 서버, 탈퇴 시 연결 끊기 (FR-AUTH-06 AC3) | 사용자 맥 → GitHub Secrets → AWS 서버 환경변수 |
| Google 웹 클라이언트 secret | 쓰지 않음 | 보관하지 않아도 됨 |
| 릴리스 키스토어와 비밀번호 | Play 배포 | 아직 없음. 만들면 사용자 맥과 안전한 백업, CI는 GitHub Secrets |

## 4. 인프라

| 항목 | 값 |
| --- | --- |
| 클라우드 | AWS 서울 리전 `ap-northeast-2`. 계정은 크레딧 방식(2026-10 가입) |
| 구성 | 서버 1대 + Docker Compose (개발 앱, 운영 앱, PostgreSQL). 개발 환경과 운영 환경을 나눔 |
| 예산 알림 | AWS Budgets 월 10달러 |
| 약관·개인정보처리방침·계정 삭제 안내 | Notion에 게시 (PRD Q-03, 주소는 게시 후 기록) |

이 구성은 ERD 7장 Q-D2(로컬 개발, RDS)와 다르다. 서버 키트를 만들 때 ERD·API의 해당 표현을 함께 고친다.
