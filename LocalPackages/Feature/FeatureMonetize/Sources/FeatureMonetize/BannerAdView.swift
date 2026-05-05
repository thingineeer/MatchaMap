import SwiftUI
import DesignSystem

/// 배너 광고 placeholder — Phase 3 MVP는 회색 박스.
/// TODO(Phase5): GoogleMobileAds GADBannerView UIViewRepresentable로 교체.
public struct BannerAdView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.MM.cream
            Text("광고")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(Color.MM.muted)
        }
        .frame(width: 320, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.MM.lineSoft, lineWidth: 0.5)
        )
        .accessibilityLabel("광고 영역")
    }
}

#Preview {
    BannerAdView()
        .padding()
        .background(Color.MM.bg)
}
