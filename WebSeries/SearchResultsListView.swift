import SwiftUI

struct SearchResultsListView: View {

    let searchText: String
    let catalog: Catalog

    var body: some View {

        // =========================
        // ESTADO VACÍO
        // =========================
        if filteredSeries.isEmpty && filteredMovies.isEmpty {
            emptyState
        } else {
            resultsList
        }
    }

    // =========================
    // LISTA DE RESULTADOS
    // =========================
    private var resultsList: some View {
        List {

            // -------- SERIES --------
            ForEach(filteredSeries) { serie in
                NavigationLink {
                    SeriesDetailView(serie: serie)
                } label: {
                    HStack(spacing: 12) {

                        CachedAsyncImage(
                            url: URL(string: ServerConfig.webBaseURL + "/images/\(serie.id).jpg")
                        ) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 55, height: 80)
                        .cornerRadius(6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(serie.title)
                                .font(.headline)
                                .foregroundColor(.serieGalText)
                                .lineLimit(2)

                            Text(seriesSubtitle(for: serie))
                                .font(.caption)
                                .foregroundColor(.serieGalSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // -------- PELÍCULAS --------
            ForEach(filteredMovies) { movie in
                NavigationLink {
                    MovieDetailView(movie: movie)
                } label: {
                    HStack(spacing: 12) {

                        CachedAsyncImage(
                            url: URL(string: ServerConfig.webBaseURL + "/images/\(movie.id).jpg")
                        ) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 55, height: 80)
                        .cornerRadius(6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(movie.title)
                                .font(.headline)
                                .foregroundColor(.serieGalText)
                                .lineLimit(2)

                            Text(movie.year)
                                .font(.caption)
                                .foregroundColor(.serieGalSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.serieGalBackground)
    }

    // =========================
    // ESTADO "NO HAY RESULTADOS"
    // =========================
    private var emptyState: some View {
        VStack(spacing: 16) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.serieGalSecondary)

            Text("Non hai resultados")
                .font(.headline)
                .foregroundColor(.serieGalText)

            Text("Proba con outro termo de busca")
                .font(.subheadline)
                .foregroundColor(.serieGalSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.serieGalBackground)
    }

    // =========================
    // FILTROS
    // =========================
    private var filteredSeries: [Series] {
        catalog.series.filter {
            $0.title.lowercased().contains(searchText.lowercased())
        }
    }

    private var filteredMovies: [Movie] {
        (catalog.movies ?? []).filter {
            $0.title.lowercased().contains(searchText.lowercased())
        }
    }

    // =========================
    // SUBTÍTULO SERIES
    // =========================
    private func seriesSubtitle(for serie: Series) -> String {
        let seasons = serie.normalizedSeasons.count
        let episodes = serie.normalizedSeasons.reduce(0) {
            $0 + $1.episodes.count
        }

        if seasons > 1 {
            return "\(seasons) temp. · \(episodes) episodios"
        } else {
            return "\(episodes) episodios"
        }
    }
}
