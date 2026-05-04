import SwiftUI
import DesignSystem

/// 미니 세계지도 — Google Maps SDK 비사용. 가벼움 우선 (handoff-mapping §12 / agent 협업룰).
/// MVP: 직사각형 등거리 원통 투영 + 디자이너 SVG 자산이 정식 도착하면 Path overlay로 대체.
/// designer-icon 후속: `_design_assets/svg/icon/globe-search.svg` + 국가 핀 SVG.
public struct MiniWorldMapView: View {
    public let highlights: [GeoCoord]
    public let height: CGFloat
    public let pinSize: CGFloat
    public let pinColor: Color

    public init(
        highlights: [GeoCoord],
        height: CGFloat = 160,
        pinSize: CGFloat = 8,
        pinColor: Color = Color.MM.matcha
    ) {
        self.highlights = highlights
        self.height = height
        self.pinSize = pinSize
        self.pinColor = pinColor
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: MMRadius.lg)
                    .fill(Color.MM.matchaPale)
                ContinentsBackdrop()
                    .stroke(Color.MM.matchaSoft.opacity(0.6), lineWidth: 1)
                    .background(
                        ContinentsBackdrop()
                            .fill(Color.MM.cream.opacity(0.8))
                    )
                ForEach(highlights, id: \.self) { coord in
                    pin(for: coord, in: geo.size)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MMRadius.lg)
                .strokeBorder(Color.MM.line, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mini world map with \(highlights.count) pins")
    }

    private func pin(for coord: GeoCoord, in size: CGSize) -> some View {
        let n = MatchaOriginCoords.normalizedPosition(for: coord)
        let x = n.x * size.width
        let y = n.y * size.height
        return Circle()
            .fill(pinColor)
            .frame(width: pinSize, height: pinSize)
            .overlay(Circle().strokeBorder(Color.MM.paper, lineWidth: 1))
            .position(x: x, y: y)
    }
}

/// 디자이너 SVG 도착 전 대체 경로 — 매우 거친 대륙 외곽선 (직사각형 + 사다리꼴).
/// MVP만. 정식 SVG는 designer-icon에 globe-search.svg 활용 (handoff `_design_assets/svg/icon/globe-search.svg`).
struct ContinentsBackdrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 본 stub은 시각 단서만 — 디자이너 SVG 도착 시 교체.
        let w = rect.width
        let h = rect.height
        // 유라시아 추상 라인
        path.addRoundedRect(in: CGRect(x: w*0.2, y: h*0.15, width: w*0.55, height: h*0.45), cornerSize: CGSize(width: 8, height: 8))
        // 아메리카 추상 라인
        path.addRoundedRect(in: CGRect(x: w*0.05, y: h*0.18, width: w*0.18, height: h*0.55), cornerSize: CGSize(width: 6, height: 6))
        // 아프리카 추상 라인
        path.addRoundedRect(in: CGRect(x: w*0.42, y: h*0.45, width: w*0.18, height: h*0.40), cornerSize: CGSize(width: 8, height: 8))
        // 호주 추상 라인
        path.addRoundedRect(in: CGRect(x: w*0.78, y: h*0.65, width: w*0.15, height: h*0.20), cornerSize: CGSize(width: 6, height: 6))
        return path
    }
}
