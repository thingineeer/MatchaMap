//
//  ContentView.swift
//  MatchaMap
//
//  Created by 이명진 on 5/4/26.
//

import SwiftUI
import DesignSystem
import Domain

struct ContentView: View {
    var body: some View {
        VStack(spacing: MMSpacing.md) {
            Image(systemName: "leaf.fill")
                .imageScale(.large)
                .foregroundStyle(MMColor.matchaPrimary)
            Text("MatchaMap")
                .font(.title)
            Text("Domain v\(Domain.version) · DesignSystem v\(DesignSystem.version)")
                .font(.caption)
                .foregroundStyle(MMColor.onSurface.opacity(0.6))
        }
        .padding(MMSpacing.xl)
    }
}

#Preview {
    ContentView()
}
