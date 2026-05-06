import SwiftUI


struct SeriesDetailView: View {

    @EnvironmentObject var favorites: FavoritesService

    let serie: Series

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(
                        url: URL(string: ServerConfig.webBaseURL + "/images/\(serie.id).jpg")
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.serieGalCardBackground)
                    }
                    .frame(height: 300)
                    .clipped()

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Serie")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.22))
                            .clipShape(Capsule())

                        Text(serie.title)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(seriesInfo)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 22)
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        Task {
                            await favorites.toggleFavorite(seriesId: serie.id)
                        }
                    } label: {
                        Image(systemName: favorites.isFavorite(serie.id) ? "star.fill" : "star")
                            .font(.headline)
                            .foregroundColor(favorites.isFavorite(serie.id) ? .yellow : .white)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)

                ForEach(serie.normalizedSeasons) { season in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(season.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.serieGalText)

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
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 18)
                    .background(Color.serieGalCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }

                Spacer(minLength: 30)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [Color.serieGalBackground, Color.serieGalSurface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var seriesInfo: String {
        let seasonCount = serie.normalizedSeasons.count
        let episodeCount = serie.normalizedSeasons.reduce(0) { partial, season in
            partial + season.episodes.count
        }
        return "\(seasonCount) temporadas · \(episodeCount) episodios"
    }
}
