import SwiftUI

struct FavoritesView: View {

    @EnvironmentObject var favorites: FavoritesService
    let catalog: Catalog

    var body: some View {
        List {

            if favoriteSeries.isEmpty && favoriteMovies.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star")
                        .font(.system(size: 40))
                        .foregroundColor(.serieGalSecondary)

                    Text("Non tes favoritos")
                        .foregroundColor(.serieGalText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowSeparator(.hidden)
            }

            // =========================
            // SERIES
            // =========================
            if !favoriteSeries.isEmpty {
                Section("Series") {
                    ForEach(favoriteSeries) { serie in
                        NavigationLink {
                            SeriesDetailView(serie: serie)
                        } label: {
                            Text(serie.title)
                                .foregroundColor(.serieGalText)
                        }
                    }
                }
            }

            // =========================
            // PELÍCULAS
            // =========================
            if !favoriteMovies.isEmpty {
                Section("Películas") {
                    ForEach(favoriteMovies) { movie in
                        NavigationLink {
                            MovieDetailView(movie: movie)
                        } label: {
                            Text(movie.title)
                                .foregroundColor(.serieGalText)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favoritos")
        .listStyle(.plain)
        .background(Color.serieGalBackground)
    }

    private var favoriteSeries: [Series] {
        catalog.series.filter {
            favorites.favorites.contains($0.id)
        }
    }

    private var favoriteMovies: [Movie] {
        (catalog.movies ?? []).filter {
            favorites.favorites.contains($0.id)
        }
    }
}
