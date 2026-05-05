import SwiftUI
import MapKit
import Domain
import DesignSystem

/// 지도 화면 — Phase 3 MVP MapKit 기반.
/// TODO(Phase5): GMSMapView 교체 — vault GMS_API_KEY_IOS 사용.
public struct MapView: View {
    @Bindable private var viewModel: MapViewModel
    private let onTapStore: (Store) -> Void
    private let onTapSearch: () -> Void

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.5, longitude: 134.0),
            span: MKCoordinateSpan(latitudeDelta: 14, longitudeDelta: 14)
        )
    )

    public init(
        viewModel: MapViewModel = MapViewModel(),
        onTapStore: @escaping (Store) -> Void = { _ in },
        onTapSearch: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onTapStore = onTapStore
        self.onTapSearch = onTapSearch
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                ForEach(viewModel.markers) { store in
                    Annotation(
                        store.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: store.location.latitude,
                            longitude: store.location.longitude
                        )
                    ) {
                        Button {
                            onTapStore(store)
                        } label: {
                            pinView(for: store)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .ignoresSafeArea()

            searchButton
                .padding(.bottom, MMSpacing.xl)
        }
    }

    private func pinView(for store: Store) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(pinColor(for: store))
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.MM.paper)
            }
            Triangle()
                .fill(pinColor(for: store))
                .frame(width: 12, height: 8)
                .offset(y: -1)
        }
    }

    private func pinColor(for store: Store) -> Color {
        switch store.pinTier ?? .B {
        case .S: return Color.MM.deep
        case .A: return Color.MM.matcha
        case .B: return Color.MM.matchaSoft
        case .C: return Color.MM.mutedSoft
        }
    }

    private var searchButton: some View {
        Button {
            onTapSearch()
        } label: {
            HStack(spacing: MMSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                Text("매장 검색")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.MM.deep)
            .padding(.horizontal, MMSpacing.lg)
            .padding(.vertical, MMSpacing.sm)
            .background(Color.MM.paper, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.MM.lineSoft, lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
