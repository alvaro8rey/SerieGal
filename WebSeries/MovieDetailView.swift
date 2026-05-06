import SwiftUI

struct MovieDetailView: View {

    @EnvironmentObject var favorites: FavoritesService

    let movie: Movie

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        infoChip(icon: "film.fill", value: "Película")
                        infoChip(icon: "calendar", value: movie.year)
                        if !movie.lang.isEmpty {
                            infoChip(icon: "globe", value: movie.lang.uppercased())
                        }
                    }

                    HStack(spacing: 10) {
                        NavigationLink {
                            PlayerScreen(
                                episode: Episode(
                                    id: movie.id,
                                    title: movie.title,
                                    url: movie.url
                                )
                            )
                        } label: {
                            Label("Reproducir", systemImage: "play.fill")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [.serieGalBlue, .serieGalViolet],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Button {
                            Task {
                                await favorites.toggleFavorite(seriesId: movie.id)
                            }
                        } label: {
                            Image(systemName: favorites.isFavorite(movie.id) ? "star.fill" : "star")
                                .font(.headline)
                                .foregroundColor(favorites.isFavorite(movie.id) ? .yellow : .white)
                                .frame(width: 48, height: 48)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    Text("Sinopsis")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.serieGalText)

                    Text(movie.description)
                        .foregroundColor(.serieGalSecondary)
                        .font(.body)
                        .lineSpacing(5)
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
                colors: [Color.serieGalBackground, Color.serieGalSurface, Color.serieGalBackground],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
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
                    Color.serieGalMagenta.opacity(0.15),
                    Color.serieGalViolet.opacity(0.2),
                    Color.black.opacity(0.87)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 8) {
                Text("PELÍCULA")
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
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func infoChip(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(value)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.serieGalText)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.serieGalSurface)
        .clipShape(Capsule())
    }
}
