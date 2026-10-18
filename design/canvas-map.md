# 디자인 캔버스 대응표

디자인 원본은 claude.ai 디자인 캔버스에 있어요. 이 파일은 캔버스의 보드와 이 레포의 화면 ID·이미지를 이어 줘요. `/design-sync`(claude.ai 프로젝트 채팅)가 갱신해요.

| 항목 | 값 |
| --- | --- |
| 디자인 캔버스 | 커플 공유 앱 데모 — https://claude.ai/artifact/LKUStrD3gPGhMkprsPKgaS |
| 디자인 시스템 | 디자인시스템 — https://claude.ai/artifact/X1WrZonYhaZ3qXSc3o2Mrj (캔버스 안 사본: `project/ds/duriseo/tokens.json`) |
| 마지막 반영 | 2026-10-18 · 캔버스 버전 30 · PRD v0.4 |

캔버스 링크는 주코님 계정에서만 열려요(비공개).

## 보드 → 화면

| 캔버스 보드 | 화면 ID | 이미지 |
| --- | --- | --- |
| Main.dc.html | SCR-START-01 | SCR-START-01.png |
| Connect.dc.html | SCR-COUPLE-01 | SCR-COUPLE-01.png |
| ConnectGuest.dc.html | SCR-COUPLE-01 (게스트) | SCR-COUPLE-01--guest.png |
| InviteCreate.dc.html | SCR-COUPLE-02 | SCR-COUPLE-02.png |
| InviteCreateCooldown.dc.html | SCR-COUPLE-02 (재요청 대기) | SCR-COUPLE-02--cooldown.png |
| InviteCreateRenewed.dc.html | SCR-COUPLE-02 (만료 후 자동 재발급) | SCR-COUPLE-02--renewed.png |
| InviteEnter.dc.html | SCR-COUPLE-03 | SCR-COUPLE-03.png |
| Connected.dc.html | SCR-COUPLE-04 | SCR-COUPLE-04.png |
| ConnectedDialog.dc.html | SCR-COUPLE-04 (가져오지 않기 확인) | SCR-COUPLE-04--drop-dialog.png |
| Calendar.dc.html | SCR-CAL-01 | SCR-CAL-01.png |
| CalendarExpanded.dc.html | SCR-CAL-01 (펼친 상태) | SCR-CAL-01--expanded.png |
| EventDetail.dc.html | SCR-CAL-02 (내 일정) | SCR-CAL-02.png |
| EventDetailPartner.dc.html | SCR-CAL-02 (상대 일정) | SCR-CAL-02--partner.png |
| EventDetailDialog.dc.html | SCR-CAL-02 (삭제 확인) | SCR-CAL-02--delete-dialog.png |
| AddEvent.dc.html | SCR-CAL-03 | SCR-CAL-03.png |
| AddEventSolo.dc.html | SCR-CAL-03 (개인 공간) | SCR-CAL-03--solo.png |
| AddEventMemo.dc.html | SCR-MEMO-04 | SCR-MEMO-04.png |
| AddEventMemoDate.dc.html | SCR-MEMO-04 (날짜 추가됨) | SCR-MEMO-04--date.png |
| Anniversaries.dc.html | SCR-ANNIV-01 | SCR-ANNIV-01.png |
| AnniversaryEdit.dc.html | SCR-ANNIV-02 | SCR-ANNIV-02.png |
| Memo.dc.html | SCR-MEMO-01 | SCR-MEMO-01.png |
| PinnedAll.dc.html | SCR-MEMO-02 | SCR-MEMO-02.png |
| MemoDetail.dc.html | SCR-MEMO-03 (내 메모, 날짜 있음) | SCR-MEMO-03.png |
| MemoDetailPartner.dc.html | SCR-MEMO-03 (상대 메모, 날짜 없음) | SCR-MEMO-03--partner.png |
| MemoDetailDialog.dc.html | SCR-MEMO-03 (삭제 확인) | SCR-MEMO-03--delete-dialog.png |
| Menu.dc.html | SCR-SET-01 (연결됨) | SCR-SET-01.png |
| MenuGuest.dc.html | SCR-SET-01 (게스트) | SCR-SET-01--guest.png |
| MenuSolo.dc.html | SCR-SET-01 (혼자 사용 중) | SCR-SET-01--solo.png |
| ConnectionInfo.dc.html | SCR-SET-01 (커플 관리) | SCR-SET-01--couple.png |
| ConnectionInfoDialog.dc.html | SCR-SET-01 (연결 해제 확인) | SCR-SET-01--unlink-dialog.png |
| ConnectionInfoSolo.dc.html | SCR-SET-01 (혼자 사용 중) | SCR-SET-01--couple-solo.png |
| Account.dc.html | SCR-SET-01 (계정 · 게스트) | SCR-SET-01--account-guest.png |
| AccountWithdraw.dc.html | SCR-SET-01 (탈퇴 확인) | SCR-SET-01--withdraw-dialog.png |
| NotificationSettings.dc.html | SCR-SET-02 | SCR-SET-02.png |
| NotificationSettingsMixed.dc.html | SCR-SET-02 (일부 꺼짐) | SCR-SET-02--mixed.png |
| ColorSettings.dc.html | SCR-SET-03 | SCR-SET-03.png |
| ProfileEdit.dc.html | SCR-SET-04 | SCR-SET-04.png |
| ProfilePhotoSheet.dc.html | SCR-SET-04 (사진 시트) | SCR-SET-04--photo-sheet.png |
| Notifications.dc.html | SCR-NOTI-01 (안 읽음 섞임) | SCR-NOTI-01.png |
| NotificationsRead.dc.html | SCR-NOTI-01 (모두 읽음) | SCR-NOTI-01--read.png |
| NotificationsEmpty.dc.html | SCR-NOTI-01 (빈 상태) | SCR-NOTI-01--empty.png |
| V04Flow.dc.html | 화면 흐름 (PRD v0.4: 알림 목록·상세·알림 설정) | flow-prd-v0.4.png |

이미지로 만들지 않는 보드: `AppIcons.dc.html`(앱 아이콘 시안), `*_v1.dc.html`·`*_v2.dc.html`(이전 버전)

## 디자인 없는 화면

없음 (PRD v0.4 기준 모든 화면에 보드가 있어요)
