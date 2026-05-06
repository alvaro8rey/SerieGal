import SwiftUI

struct SearchFullScreenView: View {

    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFieldFocused: Bool

    @State private var searchText = ""
    @State private var recentQueries = UserDefaults.standard.stringArray(forKey: Self.recentQueriesKey) ?? []

    let catalog: Catalog
    private static let recentQueriesKey = "seriegal_recent_searches"

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Group {
                if normalizedQuery.isEmpty {
                    idleContent
                } else {
                    liveResultsContent
                }
            }
            .animation(.easeInOut(duration: 0.2), value: normalizedQuery)
        }
        .background(Color.serieGalBackground)
        .onAppear {
            searchFieldFocused = true
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.serieGalText)
            }

            TextField("Buscar series ou películas…", text: $searchText)
                .focused($searchFieldFocused)
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(
                    Color(
                        uiColor: UIColor { trait in
                            trait.userInterfaceStyle == .dark
                            ? UIColor.white.withAlphaComponent(0.12)
                            : UIColor.black.withAlphaComponent(0.05)
                        }
                    )
                )
                .cornerRadius(12)
                .foregroundColor(.serieGalText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit {
                    rememberCurrentSearch()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.serieGalSecondary)
                }
            }
        }
        .padding()
        .background(Color.serieGalBackground)
    }

    private var idleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if !recentQueries.isEmpty {
                    Text("Búsquedas recientes")
                        .font(.headline)
                        .foregroundColor(.serieGalText)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(recentQueries, id: \.self) { query in
                                Button {
                                    searchText = query
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.caption)
                                        Text(query)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .foregroundColor(.serieGalText)
                                    .background(Color.serieGalCardBackground)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                discoverySection(
                    title: "Series populares",
                    subtitle: "Acceso rápido",
                    series: Array(catalog.series.prefix(8))
                )

                discoveryMoviesSection(
                    title: "Películas populares",
                    subtitle: "Sugerencias para hoy",
                    movies: Array((catalog.movies ?? []).prefix(8))
                )
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var liveResultsContent: some View {
        if rankedSeries.isEmpty && rankedMovies.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 34))
                    .foregroundColor(.serieGalSecondary)
                Text("Sin resultados para “\(searchText)”")
                    .font(.headline)
                    .foregroundColor(.serieGalText)
                Text("Prueba con otro título o una palabra más corta.")
                    .font(.subheadline)
                    .foregroundColor(.serieGalSecondary)
            }
            .padding(.top, 80)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !quickHits.isEmpty {
                        sectionTitle("Sugerencias rápidas")
                        LazyVStack(spacing: 10) {
                            ForEach(quickHits) { hit in
                                resultRow(for: hit)
                            }
                        }
                    }

                    if !rankedSeries.isEmpty {
                        sectionTitle("Series")
                        LazyVStack(spacing: 10) {
                            ForEach(rankedSeries.prefix(12)) { serie in
                                resultRow(for: .series(serie))
                            }
                        }
                    }

                    if !rankedMovies.isEmpty {
                        sectionTitle("Películas")
                        LazyVStack(spacing: 10) {
                            ForEach(rankedMovies.prefix(12)) { movie in
                                resultRow(for: .movie(movie))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private func resultRow(for hit: SearchHit) -> some View {
        switch hit {
        case .series(let serie):
            NavigationLink {
                SeriesDetailView(serie: serie)
            } label: {
                searchResultCard(
                    imageId: serie.id,
                    title: serie.title,
                    subtitle: "\(serie.normalizedSeasons.count) temporadas · \(serie.normalizedSeasons.reduce(0) { $0 + $1.episodes.count }) episodios",
                    badgeText: "SERIE"
                )
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                rememberCurrentSearch()
            })

        case .movie(let movie):
            NavigationLink {
                MovieDetailView(movie: movie)
            } label: {
                searchResultCard(
                    imageId: movie.id,
                    title: movie.title,
                    subtitle: "Película · \(movie.year)",
                    badgeText: "PELÍCULA"
                )
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                rememberCurrentSearch()
            })
        }
    }

    private func searchResultCard(
        imageId: String,
        title: String,
        subtitle: String,
        badgeText: String
    ) -> some View {
        HStack(spacing: 12) {
            CachedAsyncImage(
                url: URL(string: ServerConfig.webBaseURL + "/images/\(imageId).jpg")
            ) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.serieGalCardBackground)
            }
            .frame(width: 58, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.serieGalText)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.serieGalSecondary)

                Text(badgeText)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.serieGalBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.serieGalBlue.opacity(0.14))
                    .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.serieGalTertiary)
        }
        .padding(12)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.serieGalText)
    }

    private func discoverySection(
        title: String,
        subtitle: String,
        series: [Series]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.serieGalText)
                .padding(.horizontal)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.serieGalSecondary)
                .padding(.horizontal)

            HorizontalSlider {
                ForEach(series) { serie in
                    NavigationLink {
                        SeriesDetailView(serie: serie)
                    } label: {
                        SeriesCardView(serie: serie)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func discoveryMoviesSection(
        title: String,
        subtitle: String,
        movies: [Movie]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.serieGalText)
                .padding(.horizontal)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.serieGalSecondary)
                .padding(.horizontal)

            HorizontalSlider {
                ForEach(movies) { movie in
                    NavigationLink {
                        MovieDetailView(movie: movie)
                    } label: {
                        MovieCardView(movie: movie)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var normalizedQuery: String {
        searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var rankedSeries: [Series] {
        ranked(catalog.series) { $0.title }
    }

    private var rankedMovies: [Movie] {
        ranked(catalog.movies ?? []) { $0.title }
    }

    private var quickHits: [SearchHit] {
        let topSeries = Array(rankedSeries.prefix(4)).map(SearchHit.series)
        let topMovies = Array(rankedMovies.prefix(4)).map(SearchHit.movie)
        var merged: [SearchHit] = []
        let maxCount = max(topSeries.count, topMovies.count)
        for index in 0..<maxCount {
            if index < topSeries.count { merged.append(topSeries[index]) }
            if index < topMovies.count { merged.append(topMovies[index]) }
        }
        return merged
    }

    private func ranked<T>(_ items: [T], title: (T) -> String) -> [T] {
        guard !normalizedQuery.isEmpty else { return [] }
        let starts = items.filter { title($0).lowercased().hasPrefix(normalizedQuery) }
        let contains = items.filter {
            let value = title($0).lowercased()
            return value.contains(normalizedQuery) && !value.hasPrefix(normalizedQuery)
        }
        return starts + contains
    }

    private func rememberCurrentSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        recentQueries.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        recentQueries.insert(query, at: 0)
        recentQueries = Array(recentQueries.prefix(10))
        UserDefaults.standard.set(recentQueries, forKey: Self.recentQueriesKey)
    }
}

private enum SearchHit: Identifiable {
    case series(Series)
    case movie(Movie)

    var id: String {
        switch self {
        case .series(let serie): return "series-\(serie.id)"
        case .movie(let movie): return "movie-\(movie.id)"
        }
    }
}
