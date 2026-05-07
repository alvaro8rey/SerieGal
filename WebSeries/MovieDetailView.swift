import SwiftUI

struct MovieDetailView: View {

    @EnvironmentObject var favorites: FavoritesService
    @EnvironmentObject var progress: ProgressService

    let movie: Movie
    @State private var pendingPlayback: MoviePlaybackRequest?
    @State private var expandedPlayOptions = false
    @State private var savedProgress: ProgressResponse?

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
                        Button {
                            handlePlayTap()
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
                        .buttonStyle(.plain)

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

                    if expandedPlayOptions, let savedProgress {
                        Divider()
                            .overlay(Color.white.opacity(0.1))

                        Text("Progreso guardado en \(formattedTime(savedProgress.time))")
                            .font(.caption)
                            .foregroundColor(.serieGalSecondary)

                        HStack(spacing: 10) {
                            Button {
                                startPlayback(startAt: savedProgress.time)
                            } label: {
                                Label("Continuar viendo", systemImage: "play.fill")
                                    .font(.subheadline.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [.serieGalBlue, .serieGalViolet],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button {
                                startPlayback(startAt: nil)
                            } label: {
                                Text("Ver desde el inicio")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.05))
                                    .foregroundColor(.serieGalText)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
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
        .navigationDestination(item: $pendingPlayback) { playback in
            PlayerScreen(
                episode: playback.episode,
                seriesId: playback.seriesId,
                startAtTime: playback.startAt
            )
        }
    }

    private var hero: some View {
        let coverURL = URL(string: ServerConfig.webBaseURL + "/images/\(movie.id).jpg")

        return ZStack(alignment: .bottomLeading) {
            ZStack {
                CachedAsyncImage(url: coverURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 18)
                        .overlay(Color.black.opacity(0.36))
                        .scaleEffect(1.1)
                } placeholder: {
                    Rectangle()
                        .fill(Color.serieGalCardBackground)
                }

                CachedAsyncImage(url: coverURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 26)
                        .padding(.vertical, 14)
                        .shadow(color: .black.opacity(0.42), radius: 16, x: 0, y: 10)
                } placeholder: {
                    Rectangle()
                        .fill(Color.clear)
                }
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

    private func handlePlayTap() {
        Task {
            let progressData = await progress.getProgress(
                seriesId: movie.id,
                episodeId: movie.id
            )

            await MainActor.run {
                guard let progressData, shouldOfferResume(progressData) else {
                    startPlayback(startAt: nil)
                    return
                }

                savedProgress = progressData
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedPlayOptions.toggle()
                }
            }
        }
    }

    private func startPlayback(startAt: Double?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedPlayOptions = false
        }
        pendingPlayback = MoviePlaybackRequest(
            episode: Episode(
                id: movie.id,
                title: movie.title,
                url: movie.url
            ),
            seriesId: movie.id,
            startAt: startAt
        )
    }

    private func shouldOfferResume(_ progress: ProgressResponse) -> Bool {
        progress.time > 5 && progress.duration > 0 && progress.time < (progress.duration - 15)
    }

    private func formattedTime(_ time: Double) -> String {
        let totalSeconds = Int(max(time, 0))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct MoviePlaybackRequest: Identifiable, Hashable {
    let id = UUID()
    let episode: Episode
    let seriesId: String
    let startAt: Double?

    static func == (lhs: MoviePlaybackRequest, rhs: MoviePlaybackRequest) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
