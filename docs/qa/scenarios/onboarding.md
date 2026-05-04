# QA 시나리오 — 온보딩

> 담당 iOS: `ios-auth-monetize`. 담당 QA: `qa-functional`. 다국어: `qa-localization`.

## 사용자 플로우

1. 앱 설치 후 첫 실행 → Splash → 가치제안 → Apple/Passkey 로그인 → 위치 권한 → 지도 진입.

## 케이스

### A. 정상 — Apple Sign In (신규 가입)
- **Given**: 앱 첫 실행.
- **When**: "Apple로 시작하기" 탭 → Touch/Face ID → 이메일 공유 선택.
- **Then**: Firebase Auth 사용자 생성 + Firestore `users/{uid}` 문서 생성 + 지도 화면 진입.
- **검증**: `users/{uid}.createdAt` 존재 + `displayName` (Apple 제공) 또는 nil 허용.

### B. 정상 — Passkey (Apple 사용자가 Passkey 등록)
- **Given**: Apple Sign In 완료한 사용자.
- **When**: 설정 → Passkey 등록 → AASA 도메인 연결.
- **Then**: 다음 로그인 시 Passkey만으로 로그인 가능.
- **검증**: 이전 Apple Auth 토큰과 매핑된 user_id가 동일.

### C. 정상 — Passkey만으로 신규 가입
- **Given**: 앱 첫 실행, Passkey 미사용 디바이스 아님.
- **When**: "Passkey로 시작하기" 탭.
- **Then**: 신규 사용자 생성, `users/{uid}` 문서 생성.

### D. 엣지 — 위치 권한 거부
- **Given**: Apple 로그인 완료.
- **When**: 위치 권한 요청 시 "허용 안 함".
- **Then**: 서울 디폴트 카메라 + 검색바로 진입. 토스트로 "설정에서 권한 변경 가능" 안내.
- **검증**: `CLLocationManager.authorizationStatus == .denied`에서도 지도 표시.

### E. 엣지 — Apple 로그인 취소
- **Given**: 앱 첫 실행.
- **When**: Apple 시트에서 취소.
- **Then**: 로그인 화면 유지, 에러 메시지 없음(사용자 의도이므로 silent).

### F. 엣지 — Passkey 미지원 디바이스 (iOS 16 미만)
- **Given**: 앱 첫 실행, iOS 15 시뮬레이터(가상).
- **When**: 로그인 화면 진입.
- **Then**: Passkey 버튼 숨김, Apple Sign In만 노출.
- **참고**: 본 앱 iOS 26.2가 최소 → 이 케이스는 iOS 27 이상 디바이스만 대상이지만 미래 호환을 위해 가드 코드 검증.

### G. 엣지 — 네트워크 오프라인
- **Given**: 첫 실행, Wi-Fi/셀룰러 모두 OFF.
- **When**: Apple 로그인 시도.
- **Then**: 1회 자동 재시도 후 "네트워크 연결 후 다시 시도" 토스트. 오프라인 모드 진입 옵션은 제공하지 않음(첫 실행에는 Auth 필수).

### H. 엣지 — Firebase Auth 실패
- **Given**: Apple Auth 토큰은 받았으나 Firebase 교환 실패.
- **When**: 토큰 교환 호출.
- **Then**: 에러 핸들링 + 1회 자동 재시도 + 실패 시 "잠시 후 다시 시도" 토스트.

## 다국어 회귀 (qa-localization)

각 케이스를 6개 언어(ko, en-US, en-GB, de-DE, ja, fr-FR)로 반복:
- 가치제안 화면 텍스트 길이 검증(독일어 가장 길음).
- ATT 프롬프트 카피 자연스러움.
- "Apple로 시작하기" / "Sign in with Apple" / 일본어/프랑스어 대응 표기 정확성.

## 접근성 회귀

- VoiceOver: 로그인 버튼 라벨, Apple 시트 시점.
- Dynamic Type: 가장 큰 글자 크기에서 화면 깨짐 없음.
- 컬러 대비: 버튼 텍스트와 배경 대비 ≥ WCAG AA.

## 빌드 매트릭스

| 디바이스 | OS | 결과 |
|---|---|---|
| iPhone 17 | iOS 26.2 | TBD |
| iPhone 16 | iOS 26.2 | TBD |
| iPhone 15 | iOS 26.2 | TBD |
| iPad Pro 13" | iPadOS 26.2 | TBD |

## 사인오프

| 일자 | 빌드 번호 | 결과 | 사인오프 |
|---|---|---|---|
| TBD | TBD | TBD | qa-lead |
