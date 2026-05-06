import SwiftUI

struct MovieDetailView: View {
    
    @EnvironmentObject var favorites: FavoritesService

    let movie: Movie

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // =========================
                // HERO / CARÁTULA
                // =========================
                ZStack(alignment: .bottomLeading) {

                    AsyncImage(
                        url: URL(string: ServerConfig.webBaseURL + "/images/\(movie.id).jpg")
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                    }
                    .frame(height: 360)
                    .clipped()

                    // Degradado inferior
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)

                    // Título
                    HStack {
                        Text(movie.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            Task {
                                await favorites.toggleFavorite(seriesId: movie.id)
                            }
                        } label: {
                            Image(systemName: favorites.isFavorite(movie.id) ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                // =========================
                // CONTENIDO
                // =========================
                VStack(alignment: .leading, spacing: 20) {

                    // BOTÓN REPRODUCIR
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
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.serieGalText)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                    }

                    // SINOPSIS
                    Text("Sinopse")
                        .font(.headline)
                        .foregroundColor(.serieGalText)

                    Text(movie.description)
                        .foregroundColor(.serieGalSecondary)
                        .font(.body)
                        .lineSpacing(5)

                    // AÑO
                    Text(movie.year)
                        .foregroundColor(.serieGalSecondary)
                        .font(.subheadline)
                        .padding(.top, 8)
                }
                .padding()
            }
        }
        .background(Color.serieGalBackground)
        // 🔥 ESTO ES LO IMPORTANTE PARA LA DYNAMIC ISLAND
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
