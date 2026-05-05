// FeatureSocial — 친구 피드, 친구 추가/수락, 좋아요/댓글.
// 의존: Domain, DesignSystem. Data import 금지.
//
// 구성 (Phase 3 MVP):
// - Feed/FeedView + ViewModel — 친구 피드 (옵티미스틱 좋아요/댓글, 무한 스크롤)
//
// 미포함 (이연):
// - Stories: po-lead 결정 → v1.1.0 이연.
// - 친구 검색/QR: v1.0.0 friendship 콜러블만 활용 — UI는 ProfileView 메뉴 stub.
// - Ranking: v1.1.0 이연.

import Domain
import DesignSystem

public enum FeatureSocial {
    public static let version: String = "0.2.0"
}
