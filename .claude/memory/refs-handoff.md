---
name: refs-handoff
description: 디자인 핸드오프 — _handoff/matchamap/project/MatchaMap v2.html이 정전. 13개 화면 + 4개 탭바
type: reference
---

**경로**: `./_handoff/matchamap/project/`.

**정전(canon)**: `MatchaMap v2.html` (화이트톤 개편) + `mm-shared-v2.jsx` (MM2 팔레트 + Phone2/StatusBar2/TabBar2/CityMap2 컴포넌트) + `mm-screens-v2.jsx` (실제 13개 화면).

**v2 화면 목록(13개)**:
1. Splash
2. Login (Apple/Passkey)
3. Location 권한 (Lottie)
4. 전세계 지도
5. 도시 줌 지도
6. 매장 미리보기 (지도 위 카드)
7. 매장 상세
8. 리뷰 탭
9. 검색 결과
10. 리뷰 작성
11. 친구 피드
12. 위시리스트 (국가별 그룹)
13. 프로필

**참조하지 말 것**: `MatchaMap MVP.html` (v1) — 진한 톤은 폐기. v1의 일부 컴포넌트(Icon/Stars/Photo/MatchaPin/GradeChip)는 v2에서도 재사용되므로 `mm-shared.jsx`도 함께 보지만, 색상 토큰은 MM2(v2)만 사용.

**구현 시 주의**:
- HTML/JSX는 *프로토타입*. 픽셀-퍼펙트로 SwiftUI 재현하되 내부 구조는 SwiftUI 관용구로.
- 디자인 단계에서 브라우저 렌더 금지(사용자 README 명시). 소스에서 dimension/color 직접 추출.
