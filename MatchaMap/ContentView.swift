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
                .foregroundStyle(Color.MM.matcha)
            Text("MatchaMap")
                .font(.title)
                .foregroundStyle(Color.MM.deep)
            Text("Domain v\(Domain.version) · DesignSystem v\(DesignSystem.version)")
                .font(.caption)
                .foregroundStyle(Color.MM.muted)
        }
        .padding(MMSpacing.xl)
        .background(Color.MM.bg)
    }
}

#Preview {
    ContentView()
}
