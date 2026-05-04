# LocalPackages/Core

> 가장 아래 레이어. **Foundation / OSLog만** 의존. 다른 LocalPackage import 금지.

## 책임

- 로깅(`AppLogger`, `LogCategory`).
- 환경 정보(`AppEnvironment`) — Bundle 정보, build/version 헬퍼.
- 네트워크 추상(`HTTPClient` 프로토콜) — 실제 URLSession 구현은 `Data`에.
- 단순 유틸 (Date/Result 확장 등).

## 금지

- SwiftUI / UIKit / Combine.
- 외부 SDK (Firebase / GoogleMaps / GoogleMobileAds).
- 다른 LocalPackage(`Domain` 포함) import.

## Public API 규약

- 새 타입은 `public` + `Sendable` 기본.
- 로깅 메시지는 `privacy: .public` 명시 (PII 제로 정책 — observability.md §0).

## 테스트

`cd LocalPackages/Core && swift test`. macOS에서도 즉시 실행 가능.
