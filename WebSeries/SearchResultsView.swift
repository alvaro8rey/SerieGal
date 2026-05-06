import SwiftUI

struct SearchResultsView: View {

    let searchText: String
    let catalog: Catalog

    var body: some View {
        VStack(spacing: 24) {

            let movieResults = catalog.movies?.filter {
                $0.title.lowercased().contains(searchText.lowercased())
            } ?? []

            let seriesResults = catalog.series.filter {
                $0.title.lowercased().contains(searchText.lowercased())
            }

            // =========================
            // PELÍCULAS
            // =========================
            if !movieResults.isEmpty {
                Text("Películas")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.serieGalText)
                    .padding(.horizontal)

                HorizontalSlider {
                    ForEach(movieResults) { movie in
                        NavigationLink {
                            PlayerScreen(
                                episode: Episode(
                                    id: movie.id,
                                    title: movie.title,
                                    url: movie.url
                                )
                            )
                        } label: {
                            MovieCardView(movie: movie)
                        }
                        .tint(.clear)
                    }
                }
            }

            // =========================
            // SERIES
            // =========================
            if !seriesResults.isEmpty {
                Text("Series")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.serieGalText)
                    .padding(.horizontal)

                HorizontalSlider {
                    ForEach(seriesResults) { serie in
                        NavigationLink {
                            SeriesDetailView(serie: serie)
                        } label: {
                            SeriesCardView(serie: serie)
                        }
                        .tint(.clear)
                    }
                }
            }
        }
    }
}
