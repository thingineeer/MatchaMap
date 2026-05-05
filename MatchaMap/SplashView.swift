//
//  SplashView.swift
//  MatchaMap
//
//  핸드오프 v2 Screen2Splash — MM2.cream 배경 + 매차 핀 모양 SVG + 한글/영문 타이틀.
//

import SwiftUI
import DesignSystem

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.MM.cream.ignoresSafeArea()
            VStack(spacing: 26) {
                MatchaMapLogo()
                    .frame(width: 84, height: 100)
                Text("말차맵")
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundStyle(Color.MM.deep)
                    .tracking(-0.8)
                Text("MATCHAMAP")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.MM.muted)
                    .tracking(3.3)
                Text("세상의 말차를\n한 잔씩 모아두는 곳")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.MM.text)
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
                    .padding(.top, 12)
                    .frame(maxWidth: 280)
            }
            VStack {
                Spacer()
                Text("EST. 2025 · KYOTO")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.MM.muted)
                    .tracking(2.0)
                    .padding(.bottom, 50)
            }
        }
    }
}

/// 핸드오프 v2 84×100 매차 핀 시그니처 — pin shape + matcha leaf.
private struct MatchaMapLogo: View {
    var body: some View {
        Canvas { context, size in
            let scale = size.width / 84
            // pin shape
            var pin = Path()
            pin.move(to: CGPoint(x: 42*scale, y: 6*scale))
            pin.addCurve(to: CGPoint(x: 4*scale, y: 46*scale),
                         control1: CGPoint(x: 18*scale, y: 6*scale),
                         control2: CGPoint(x: 4*scale, y: 24*scale))
            pin.addCurve(to: CGPoint(x: 42*scale, y: 96*scale),
                         control1: CGPoint(x: 4*scale, y: 70*scale),
                         control2: CGPoint(x: 42*scale, y: 96*scale))
            pin.addCurve(to: CGPoint(x: 80*scale, y: 46*scale),
                         control1: CGPoint(x: 42*scale, y: 96*scale),
                         control2: CGPoint(x: 80*scale, y: 70*scale))
            pin.addCurve(to: CGPoint(x: 42*scale, y: 6*scale),
                         control1: CGPoint(x: 80*scale, y: 24*scale),
                         control2: CGPoint(x: 66*scale, y: 6*scale))
            pin.closeSubpath()
            context.fill(pin, with: .color(Color.MM.deep))

            // leaf
            var leaf = Path()
            leaf.move(to: CGPoint(x: 22*scale, y: 56*scale))
            leaf.addCurve(to: CGPoint(x: 60*scale, y: 24*scale),
                          control1: CGPoint(x: 22*scale, y: 36*scale),
                          control2: CGPoint(x: 36*scale, y: 24*scale))
            leaf.addCurve(to: CGPoint(x: 22*scale, y: 56*scale),
                          control1: CGPoint(x: 58*scale, y: 46*scale),
                          control2: CGPoint(x: 44*scale, y: 56*scale))
            leaf.closeSubpath()
            context.fill(leaf, with: .color(Color.MM.matchaSoft.opacity(0.95)))
        }
    }
}

#Preview {
    SplashView()
}
