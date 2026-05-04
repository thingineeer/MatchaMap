---
name: decisions-travel-mode
description: 여행 모드 판별 정책 — 클라이언트 1차 + 서버 IP geolocation 백업. UX 결정은 클라 값 단독
type: project
---

여행 모드(`travel_mode` 유저 프로퍼티) = `country != home_country`. 본 필드는 PRD H1 가설(travel_mode=true 사용자 도감 등록률 ≥ 50%)의 분모/분자 분기 기준이라 정확도가 결과 신뢰성에 직결.

**판별 정책 (observability.md §2 정전):**
- **클라이언트 1차**: iOS `CLLocationManager` + `CLGeocoder.reverseGeocodeLocation` → ISO 국가 코드. 위치 권한 거부 시 `country = nil` → `travel_mode = false` 디폴트.
- **서버 IP geolocation 백업**: 콜러블 함수 `resolveCountry`가 GCP geolocate 또는 MaxMind GeoLite2 조회. 활성 조건은 (1) 클라 위치 측위 60초 이상 실패, 또는 (2) 클라 country vs IP geo country가 4시간 이상 불일치. 후자는 클라값 유지 + `country_source=conflict` 부속 필드 기록(분석 노이즈 필터).
- **서버 IP는 분석 보정용**. UX 결정(예: 도감 잠금 해제, 여행 모드 인디케이터 표시)은 **항상 클라 값 단독** 사용.

**`home_country` 결정:**
1. 가입 시 device locale region (`Locale.current.regionCode`).
2. 첫 30일 동안 일별 첫 좌표 국가가 70% 이상 단일이면 그 국가로 보정 1회만. 이후 영구 동결.
3. 명시 변경 UI는 v1.1.0(설정 > 기본 국가).

**Why:** H1 가설의 결정을 좌우하는 분기 신호. 서버 단독으로 IP geo만 쓰면 VPN/모바일 캐리어 라우팅으로 잘못 판별 발생. 클라 좌표가 가장 신뢰할 수 있고, 측위 실패 케이스에만 서버 백업.

**How to apply:**
- iOS 구현(Phase 2 ios-map / ios-auth-monetize): 좌표 측위 + reverseGeocode + `setUserProperty("travel_mode", ...)`.
- 서버 구현(Phase 2 server-functions): `resolveCountry` 콜러블, 단 클라가 명시 요청한 케이스에만 응답. 분석 단계의 `country_source=conflict` 필드 처리는 BigQuery export 후 처리.
- 분석 시: H1 결과 산출 시 `country_source=conflict` 행은 제외.
