import SwiftUI
import MapKit

struct LocationMapView: View {
    let coordinate: Coordinate
    @Environment(\.dismiss) private var dismiss
    @State private var mapStyle: MapDisplayStyle = .standard
    @State private var position: MapCameraPosition

    init(coordinate: Coordinate) {
        self.coordinate = coordinate
        _position = State(initialValue: .camera(MapCamera(
            centerCoordinate: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            distance: 5000,
            heading: 0,
            pitch: 0
        )))
    }

    enum MapDisplayStyle: String, CaseIterable {
        case standard = "Map"
        case satellite = "Satellite"
        case hybrid = "Hybrid"

        var mapStyle: MapStyle {
            switch self {
            case .standard: .standard(elevation: .realistic)
            case .satellite: .imagery(elevation: .realistic)
            case .hybrid: .hybrid(elevation: .realistic)
            }
        }
    }

    private var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                Marker("", coordinate: clCoordinate)
                    .tint(.red)
            }
            .mapStyle(mapStyle.mapStyle)
            .ignoresSafeArea()

            VStack(spacing: 8) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color(.systemGray3))
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                    .padding(.leading)
                    .accessibilityLabel("Close map")
                    Spacer()
                }
                .padding(.top, 8)

                Picker("Map Type", selection: $mapStyle) {
                    ForEach(MapDisplayStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
            }
        }
    }
}
