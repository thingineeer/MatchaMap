# Push Notification Payload — FCM 페이로드 명세

- **작성**: `server-auth` · 2026-05-04
- **상태**: Phase 2 — ADR-303 §7 산출물
- **상위 결정**: [ADR-303](../architecture/ADR-303-app-check-security-rules.md)
- **iOS 페어링**: `ios-auth-monetize` (FCM token 등록), `ios-social-collection` (피드 알림 핸들링)

## 1. 인증 키

- APNs 인증 키 (.p8): Apple Developer > Certificates, Identifiers & Profiles > Keys > Apple Push Notifications service (APNs) 신규 키.
- 저장: `~/.env-vault/projects/matchamap-ios/apple/AuthKey_<KEY_ID>.p8` (vault, **레포 커밋 금지**).
- Firebase 등록: Firebase Console > Project Settings > Cloud Messaging > Apple app configuration > APNs Authentication Key.
  - Key ID + Team ID + .p8 파일 업로드.
- 발급된 키는 모든 앱(Bundle ID)에서 공유 가능.

## 2. 토큰 등록 (클라 → Firestore)

```
사용자 가입 + 푸시 권한 허용 → iOS 클라가 FCM token 받음 → Firestore users/{uid}/fcmTokens/{tokenId} 저장.
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `uid` | string | 본인 uid (path 일치) |
| `token` | string | FCM token (디바이스별 고유) |
| `platform` | string | `ios` (v1.0.0은 iOS만) |
| `appVersion` | string | 클라 앱 버전 |
| `locale` | string | BCP-47 (다국어 페이로드 라우팅) |
| `createdAt` | timestamp | 서버 |
| `updatedAt` | timestamp | 서버 |
| `lastSeenAt` | timestamp | 마지막 활성 (만료 토큰 정리 기준) |

> 다중 디바이스 지원 — 동일 사용자가 여러 토큰 가질 수 있음. Functions 푸시 발송 시 `users/{uid}/fcmTokens/*` 모두에 fanout.

## 3. 페이로드 구조

### 3.1 공통 골격

```json
{
  "token": "<FCM_TOKEN>",
  "notification": {
    "title": "<localized title>",
    "body": "<localized body>"
  },
  "data": {
    "kind": "<event_kind>",
    "deepLink": "matchamap://<path>",
    "...": "type-specific fields"
  },
  "apns": {
    "headers": {
      "apns-priority": "10",
      "apns-push-type": "alert"
    },
    "payload": {
      "aps": {
        "alert": {
          "loc-key": "<NSLocalizedKey>",
          "loc-args": ["<arg1>", "<arg2>"]
        },
        "sound": "default",
        "badge": 1,
        "thread-id": "<thread_id>",
        "mutable-content": 1
      }
    }
  }
}
```

### 3.2 다국어 — Server-side localization (권장)

서버가 `users/{uid}.locale`을 읽어 미리 번역된 title/body를 페이로드에 담음.

- 장점: 클라 처리 단순, Notification Service Extension 불필요.
- 단점: 사용자 locale 변경 시 즉시 반영 안 됨 (다음 푸시부터 적용).

번역 사전: `firebase-functions/src/push/i18n/{ko,en-US,en-GB,de-DE,ja,fr-FR}.json` (Phase 2-3 server-functions 작성).

### 3.3 다국어 — Client-side localization (백업 옵션)

`aps.alert.loc-key` 사용. iOS가 앱의 `Localizable.xcstrings`에서 키 찾아 표시.

- 장점: 즉시 locale 반영.
- 단점: String Catalog에 push 전용 키 추가 필요 + 사용자 locale 추론 신뢰 필요.

→ **MVP는 server-side를 디폴트**. v1.1.0+에서 client-side로 전환 검토 (locale 변경 즉시 반영 가치).

## 4. 이벤트별 페이로드

### 4.1 친구 요청 (`friend_request`)

```json
{
  "data": {
    "kind": "friend_request",
    "fromUid": "<requester_uid>",
    "fromDisplayName": "<requester_displayName>",
    "deepLink": "matchamap://friends/requests"
  },
  "notification": {
    "title": "새 친구 요청",
    "body": "{fromDisplayName}님이 친구 요청을 보냈습니다"
  },
  "apns": {
    "payload": {
      "aps": {
        "thread-id": "friend",
        "category": "FRIEND_REQUEST"
      }
    }
  }
}
```

- 발송: `requestFriend` 콜러블이 양방향 doc 작성 직후 (server-functions).
- 수신자: 요청 받은 사용자 (audienceUid = `friend.friendUid`).

### 4.2 친구 수락 (`friend_accepted`)

```json
{
  "data": {
    "kind": "friend_accepted",
    "byUid": "<accepter_uid>",
    "byDisplayName": "<accepter_displayName>",
    "deepLink": "matchamap://friends/list"
  },
  "notification": {
    "title": "친구 수락",
    "body": "{byDisplayName}님이 친구 요청을 수락했습니다"
  }
}
```

### 4.3 친구의 도감 등록 (`friend_collection_added`)

```json
{
  "data": {
    "kind": "friend_collection_added",
    "actorUid": "<friend_uid>",
    "actorDisplayName": "<friend_displayName>",
    "storeId": "<placeId>",
    "storeName": "<store_name>",
    "drink": "matcha_latte",
    "deepLink": "matchamap://feed"
  },
  "notification": {
    "title": "{actorDisplayName}님이 도감을 추가했습니다",
    "body": "{storeName} — {drink}"
  },
  "apns": {
    "payload": {
      "aps": {
        "thread-id": "feed",
        "interruption-level": "passive"
      }
    }
  }
}
```

- `interruption-level: passive` — 잠금화면 무음, 알림 센터에만 표시 (스팸 방지).
- 사용자 설정 `users/{uid}.notification.feedEnabled == false`이면 발송 생략.
- 빈도 제한: 같은 actor → 같은 audience에 1시간 내 중복 발송 차단 (server-functions Phase 2-3 정책).

### 4.4 친구의 리뷰 작성 (`friend_review_submitted`)

`friend_collection_added`와 유사 구조. `kind`만 다름.

### 4.5 좋아요 받음 (`review_like`) — 빈도 가드

```json
{
  "data": {
    "kind": "review_like",
    "byUid": "<liker_uid>",
    "byDisplayName": "<liker_displayName>",
    "reviewId": "<review_id>",
    "storeName": "<store_name>",
    "deepLink": "matchamap://reviews/{reviewId}"
  },
  "notification": {
    "title": "좋아요",
    "body": "{byDisplayName}님이 {storeName} 리뷰를 좋아합니다"
  }
}
```

- 빈도 제한: 같은 review → 동일 받는이에게 24h 내 1회만. 이후 likes는 묶음 알림 (`{N}명이 좋아합니다`).

### 4.6 시스템 알림 (`system_announcement`)

```json
{
  "data": {
    "kind": "system_announcement",
    "deepLink": "matchamap://announcement/{id}"
  },
  "notification": {
    "title": "<localized>",
    "body": "<localized>"
  }
}
```

- 발송: 큐레이터/PO가 콘솔에서 트리거. `users/{uid}.notification.systemEnabled` 필터.

## 5. 다국어 매트릭스 (예시: `friend_request`)

| locale | title | body |
|---|---|---|
| ko | 새 친구 요청 | {name}님이 친구 요청을 보냈습니다 |
| en-US | New friend request | {name} sent you a friend request |
| en-GB | New friend request | {name} has sent you a friend request |
| ja | 新しい友達リクエスト | {name}さんから友達リクエストが届きました |
| de-DE | Neue Freundschaftsanfrage | {name} hat dir eine Freundschaftsanfrage gesendet |
| fr-FR | Nouvelle demande d'ami | {name} vous a envoyé une demande d'ami |

(완전한 번역 사전은 `firebase-functions/src/push/i18n/*.json` Phase 3 작성.)

## 6. APNs 응답 코드별 처리

| 응답 | 의미 | 대응 |
|---|---|---|
| 200 | 성공 | nothing |
| 400 BadDeviceToken | 토큰 무효 | `users/{uid}/fcmTokens/{tokenId}` 즉시 삭제 |
| 410 Unregistered | 앱 삭제됨 | 위와 동일 |
| 429 TooManyRequests | rate limit | 지수 백오프 retry (max 3) |
| 500 InternalServerError | APNs 일시 장애 | retry 1회 + Cloud Logging |
| 503 ServiceUnavailable | 일시 장애 | retry |
| 기타 | discard | Cloud Logging |

## 7. 빈도 가드 + 사용자 설정

`users/{uid}.notification` 맵 (schema.md §1.1):
- `feedEnabled` (bool, default true) — 친구 피드 알림 on/off.
- `friendRequestEnabled` (bool, default true) — 친구 요청 알림.
- `likeEnabled` (bool, default true) — 좋아요 알림.
- `systemEnabled` (bool, default true) — 시스템 공지.

서버 측 Functions가 발송 직전 본 필드 체크.

## 8. 디버깅

- Firebase Console > Cloud Messaging > Test send → 토큰 입력 → 페이로드 입력 → 디바이스 수신 확인.
- 로컬: `firebase emulators:start --only functions` + `httpie`로 콜러블 호출.

## 9. 비용

- FCM은 **무료** (cost-projection.md §1.1).
- Functions invocation 비용만 — 사용자당 평균 5 푸시/일 가정 시 MAU 10K → 1.5M/월 호출, Spark 한도 2M 내.

## 10. Open Items

- [ ] **PUSH-1**: 다국어 사전 6개 언어 작성 (server-functions + qa-localization Phase 3).
- [ ] **PUSH-2**: 빈도 가드 정책 정량 — 사용자 알림 피로도 측정 후 조정 (Phase 4).
- [ ] **PUSH-3**: Notification Service Extension 도입 여부 (이미지 첨부, 액션 버튼 등). MVP는 미도입.
- [ ] **PUSH-4**: Apple Live Activity 활성화 검토 (체크인 진행 중 표시 등). v1.1.0+.
