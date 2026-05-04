# LocalPackages/Feature/FeatureSocial

> 친구 피드, 친구 추가/수락. **소유: `ios-social-collection`**.

## 책임

- 친구 피드 (`FeedScreen`).
- 친구 초대 / 수락 / 차단.
- 활동 알림 (FCM 푸시 → in-app 표시).

## 의존

- 내부: `Domain`, `DesignSystem`.

## 금지

- `import Data`. 다른 `Feature/*` 모듈 import.

## 가설 매핑

- H3 친구 1+ 보유 비율.
