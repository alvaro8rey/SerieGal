import SwiftUI

struct MovieDetailView: View {

    @EnvironmentObject var favorites: FavoritesService

    let movie: Movie

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(
                        url: URL(string: ServerConfig.webBaseURL + "/images/\(movie.id).jpg")
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.serieGalCardBackground)
                    }
                    .frame(height: 360)
                    .clipped()

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Película")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())

                        Text(movie.title)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(movie.year)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 22)
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        Task {
                            await favorites.toggleFavorite(seriesId: movie.id)
                        }
                    } label: {
                        Image(systemName: favorites.isFavorite(movie.id) ? "star.fill" : "star")
                            .font(.headline)
                            .foregroundColor(favorites.isFavorite(movie.id) ? .yellow : .white)
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

                VStack(alignment: .leading, spacing: 20) {
                    NavigationLink {
                        PlayerScreen(
                            episode: Episode(
                                id: movie.id,
                                title: movie.title,
                                url: movie.url
                            )
                        )
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Reproducir película")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Text("Sinopse")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.serieGalText)

                    Text(movie.description)
                        .foregroundColor(.serieGalSecondary)
                        .font(.body)
                        .lineSpacing(5)

                    Text(movie.year)
                        .font(.subheadline)
                        .foregroundColor(.serieGalTertiary)
                        .padding(.top, 8)
                }
                .padding(20)
                .background(Color.serieGalCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
        .background(
            LinearGradient(
                colors: [Color.serieGalBackground, Color.serieGalSurface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}
