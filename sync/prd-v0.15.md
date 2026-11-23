# PRD v0.15 영향 분석

> 상태: PR 완료 (2026-11-23 사용자 결정, 작은 변경이라 리드가 직접 반영)
> 이전 버전: v0.14 → 새 버전: v0.15
> 브랜치: sync/prd-v0.15

## 1. 바뀐 ID

| ID | 변경 | 내용 |
| --- | --- | --- |
| D-154 | 수정 | 운영자·개인정보 보호책임자 이름을 출시 이름 "jucoding"으로 (이전: 실명) |

## 2. 문서별 할 일

| 문서 | 담당 | 할 일 |
| --- | --- | --- |
| legal/terms.md, legal/privacy.md, legal/account-deletion.md | 리드 | 이름을 "jucoding"으로. 처리방침 5장 위탁사 연락처, 9장 경찰청 |
| docs/SCREENS.md, docs/API.md, docs/ERD.md(+erd.html, ERD.png) | 리드 | 헤더 v0.15만 |

## 4. 위험 항목

- 개인정보: 처리방침의 보호책임자 표시가 이름 대신 출시 이름이 됨 (법률 검토 전 초안)

## 6. 검수 기록

| 회차 | 판정 | Critical | 비고 |
| --- | --- | --- | --- |
| - | 리드 확인 | 0 | ID 1개, `check-ids.sh` 통과 |
