import SwiftUI


struct SeriesDetailView: View {

    @EnvironmentObject var favorites: FavoritesService

    let serie: Series

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // =========================
                // HEADER
                // =========================
                VStack(alignment: .leading, spacing: 16) {

                    AsyncImage(
                        url: URL(string: ServerConfig.webBaseURL + "/images/\(serie.id).jpg")
                    ) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 260)
                    .clipped()
                    .cornerRadius(20)

                    HStack {
                        Text(serie.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.serieGalText)

                        Spacer()

                        Button {
                            Task {
                                await favorites.toggleFavorite(seriesId: serie.id)
                            }
                        } label: {
                            Image(systemName: favorites.isFavorite(serie.id) ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(.serieGalBlue)
                        }
                    }

                }
                .padding(.horizontal)

                // =========================
                // TEMPORADAS + EPISODIOS
                // =========================
                ForEach(serie.normalizedSeasons) { season in
                    VStack(alignment: .leading, spacing: 16) {

                        Text(season.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.serieGalText)
                            .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(Array(season.episodes.enumerated()), id: \.element.id) { index, episode in
                                NavigationLink {
                                    PlayerScreen(episode: episode)
                                } label: {
                                    EpisodeRowView(
                                        seriesId: serie.id,
                                        episode: episode,
                                        index: index + 1,
                                        serieTitle: serie.title
                                    )
                                }
                                .buttonStyle(.plain) // ⬅️ elimina flecha del sistema
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 30)
            }
            .padding(.top)
        }
        .background(Color.serieGalBackground)
    }
}
