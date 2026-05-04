---
name: project-context
description: 말차맵 프로젝트 1.0.0 컨텍스트 — 글로벌 말차 카페 발견·기록·도감 앱, iOS 26.2 SwiftUI 우선, 다국어 6개
type: project
---

말차맵(MatchaMap)은 전세계 말차 덕후를 위한 매장 발견·리뷰·도감(Collection)·소셜 피드 앱.

**Why:** 말차 전용 매장 정보 + 글로벌 여행 시 매장 발견 + 시음 도감(수집욕) + 친구 공유. 일반 카페 앱과 차별화는 "말차 전문 큐레이션 + 글로벌 도감".

**How to apply:**
- iOS 26.2 SwiftUI Liquid Glass 우선 + Compose 안드로이드는 추후(트리거 발생 후).
- 백엔드: Firebase 프로젝트 `MatchaMapAPP`(구 one-problem-app, Firebase 신규 프로젝트 한도로 재활용).
- 지도: Google Maps SDK (Places API/인기시간/스트리트뷰/길찾기 활용).
- 인증: Apple Sign In + Passkey (이메일/비번 미사용).
- 수익화 MVP: AdMob 3슬롯(배너/인터/보상). 첫 60초 광고 금지(UX).
- 다국어 우선: ko → ja → en-US → en-GB → de-DE → fr-FR.
- **출시 시퀀스(ADR-PROD-003, 2026-05-04 확정)**: 3그룹 시차 출시 — APAC 비치헤드(KR+JP D0) → 글로벌 매출(US+UK D+30) → EU 확장(DE+FR D+60). KR vs US 비치헤드 동률(8.0=8.0) 해소 결과. 30일 간격은 운영 부담 분산 + 데이터 보강 윈도우.
- 핵심 화면(v2 화이트톤): Splash → Login(Apple/Passkey) → 위치권한 → 지도 → 매장 상세/리뷰/검색 → 피드 → 위시리스트 → 프로필.
- Bundle ID: `th1ngjin.MatchaMap` / 빌드 번호 = `YYMMDD_HHMM` KST.
