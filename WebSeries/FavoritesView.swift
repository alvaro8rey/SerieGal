import SwiftUI

struct FavoritesView: View {

    @EnvironmentObject var favorites: FavoritesService
    let catalog: Catalog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if favoriteSeries.isEmpty && favoriteMovies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.serieGalSecondary)

                        Text("Aún no tienes favoritos")
                            .font(.headline)
                            .foregroundColor(.serieGalText)

                        Text("Marca películas y series para tenerlas siempre a mano.")
                            .font(.subheadline)
                            .foregroundColor(.serieGalSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .padding(.horizontal, 20)
                    .background(Color.serieGalCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }

                if !favoriteSeries.isEmpty {
                    sectionTitle("Series")
                    ForEach(favoriteSeries) { serie in
                        NavigationLink {
                            SeriesDetailView(serie: serie)
                        } label: {
                            favoriteRow(
                                id: serie.id,
                                title: serie.title,
                                subtitle: seriesInfo(for: serie)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !favoriteMovies.isEmpty {
                    sectionTitle("Películas")
                    ForEach(favoriteMovies) { movie in
                        NavigationLink {
                            MovieDetailView(movie: movie)
                        } label: {
                            favoriteRow(
                                id: movie.id,
                                title: movie.title,
                                subtitle: "Película · \(movie.year)"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Favoritos")
        .background(
            LinearGradient(
                colors: [Color.serieGalBackground, Color.serieGalSurface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
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

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.bold))
            .foregroundColor(.serieGalText)
            .padding(.top, 4)
    }

    private func favoriteRow(id: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            CachedAsyncImage(url: URL(string: ServerConfig.webBaseURL + "/images/\(id).jpg")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.serieGalSurface)
            }
            .frame(width: 72, height: 106)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.serieGalText)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.serieGalSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.serieGalTertiary)
        }
        .padding(14)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func seriesInfo(for serie: Series) -> String {
        let seasons = serie.normalizedSeasons.count
        let episodes = serie.normalizedSeasons.reduce(0) { partial, season in
            partial + season.episodes.count
        }
        return "\(seasons) temporadas · \(episodes) episodios"
    }
}
