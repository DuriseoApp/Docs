# PRD v<버전> 영향 분석

> 상태: 승인 대기 | 진행 중 | 검수 중 | PR 완료
> 이전 버전: v<이전 버전> → 새 버전: v<버전>
> 브랜치: sync/prd-v<버전>
> PR: (PR 완료 후 링크)

이 파일은 `/prd-sync` 팀원들이 읽는 계약이다. 여기 적힌 이름과 할 일을 그대로 따른다.

## 1. 바뀐 ID

| ID | 변경 | 내용 |
| --- | --- | --- |
| FR-XXX-NN | 추가 / 수정 / 삭제 | 한 줄 요약 |

## 2. 문서별 할 일

| 문서 | 담당 | 할 일 |
| --- | --- | --- |
| docs/ERD.md (+ ERD.png) | data | |
| docs/API.md | api | |
| docs/SCREENS.md | screen | |
| 디자인 변경 요청서 | screen | 있음 / 없음 |

## 3. 이름 확정

| 종류 | 이름 | 정의 | 관련 ID |
| --- | --- | --- | --- |
| 테이블.컬럼 | events.example_col | boolean NOT NULL DEFAULT false | FR-XXX-NN |
| API | POST /api/v1/example | 요청 필드 exampleCol | FR-XXX-NN |
| 오류 코드 | EXAMPLE_ERROR | 409 | FR-XXX-NN |
| 화면 | SCR-XXX-NN | 요소·문구 | FR-XXX-NN |

## 4. 위험 항목

- [ ] DB 마이그레이션 필요:
- [ ] 데이터 삭제:
- [ ] 권한 변경:
- [ ] 앱 호환성이 깨지는 API 변경:
- [ ] 개인정보 처리 변경:

## 5. 열린 질문

- 없음

## 6. 검수 기록

| 회차 | 판정 | Critical | 비고 |
| --- | --- | --- | --- |
