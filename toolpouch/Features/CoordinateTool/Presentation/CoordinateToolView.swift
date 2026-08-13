import MapKit
import SwiftUI

struct CoordinateToolView: View {
    private static let initialCoordinate = GeographicCoordinate(
        latitude: 52.229676,
        longitude: 21.012229
    )

    @State private var query = ""
    @State private var selectedCoordinate = initialCoordinate
    @State private var cameraPosition = MapCameraPosition.region(
        region(around: initialCoordinate)
    )
    @State private var searchResults: [PlaceSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Map Coordinates",
                    subtitle: "Search for a place or click the map to read and convert its coordinates."
                )
                searchCard
                mapCard
                conversionsCard
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .scrollIndicators(.never)
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Place or coordinates", text: $query)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    #endif
                    .onSubmit(search)

                Button(action: search) {
                    if isSearching {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .toolPouchIcon(.small)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                .accessibilityLabel("Search")
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if !searchResults.isEmpty {
                Divider()
                ForEach(searchResults) { result in
                    Button {
                        select(result.coordinate)
                        query = result.name
                        searchResults = []
                    } label: {
                        HStack {
                            Image(systemName: "mappin")
                                .toolPouchIcon(.small)
                            Text(result.name)
                                .lineLimit(1)
                            Spacer()
                            Text(CoordinateDisplayFormat.decimalDegrees.string(for: result.coordinate))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("You can also paste DD, DDM, or DMS coordinates.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var mapCard: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                Marker("Selected point", coordinate: selectedCoordinate.coreLocationCoordinate)
                    .tint(Color.accentColor)
            }
            .mapStyle(.standard(pointsOfInterest: .all))
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    guard let coordinate = proxy.convert(value.location, from: .local) else {
                        return
                    }
                    selectedCoordinate = GeographicCoordinate(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    query = ""
                    searchResults = []
                    errorMessage = nil
                }
            )
        }
        .frame(minHeight: 320)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topLeading) {
            Label("Click or tap to select a point", systemImage: "hand.tap")
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.regularMaterial, in: .capsule)
                .padding(10)
                .allowsHitTesting(false)
        }
        .accessibilityLabel("Coordinate selection map")
    }

    private var conversionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coordinate formats")
                .font(.headline)

            ForEach(CoordinateDisplayFormat.allCases) { format in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(format.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(format.string(for: selectedCoordinate))
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                    }
                    Spacer(minLength: 8)
                    CopyButton(value: format.string(for: selectedCoordinate))
                }

                if format != CoordinateDisplayFormat.allCases.last {
                    Divider()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func search() {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedQuery.isEmpty else { return }

        if let coordinate = CoordinateParser.parse(cleanedQuery) {
            select(coordinate)
            searchResults = []
            errorMessage = nil
            return
        }

        isSearching = true
        errorMessage = nil
        searchResults = []

        Task {
            defer { isSearching = false }
            do {
                let request = MKLocalSearch.Request(naturalLanguageQuery: cleanedQuery)
                request.resultTypes = [.address, .pointOfInterest]
                let response = try await MKLocalSearch(request: request).start()
                let results = response.mapItems.prefix(5).map { item in
                    PlaceSearchResult(
                        name: item.name ?? cleanedQuery,
                        coordinate: GeographicCoordinate(
                            latitude: item.location.coordinate.latitude,
                            longitude: item.location.coordinate.longitude
                        )
                    )
                }
                searchResults = results
                if let first = results.first {
                    select(first.coordinate)
                } else {
                    errorMessage = "No matching places were found."
                }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = "The place search could not be completed."
            }
        }
    }

    private func select(_ coordinate: GeographicCoordinate) {
        selectedCoordinate = coordinate
        cameraPosition = .region(Self.region(around: coordinate))
    }

    private static func region(around coordinate: GeographicCoordinate) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate.coreLocationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    }
}

private struct PlaceSearchResult: Identifiable {
    let name: String
    let coordinate: GeographicCoordinate

    var id: String {
        "\(name)|\(coordinate.latitude)|\(coordinate.longitude)"
    }
}
