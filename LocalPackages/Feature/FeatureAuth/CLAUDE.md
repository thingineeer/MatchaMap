# LocalPackages/Feature/FeatureAuth

> Apple Sign In + Passkey UI. **소유: `ios-auth-monetize`**.

## 책임

- 로그인/가입 화면.
- Apple Sign In 흐름 (`ASAuthorizationAppleIDProvider`).
- Passkey 등록/로그인 (AuthenticationServices).
- 가입 전환율 측정 이벤트 발화 (observability.md § auth_signup).

## 의존

- 내부: `Domain`, `DesignSystem`.
- 외부: `AuthenticationServices` (시스템 프레임워크).

## 금지

- `import Data` — Auth 구현체는 Composition Root에서 주입.
- `import FeatureMonetize` 등 다른 Feature 모듈.

## 가설 매핑

- H5 가입 전환율 — auth_signup 이벤트 발화.
- D0 cohort key는 첫 `auth_session_started` 시 server에서 set (observability §1).
