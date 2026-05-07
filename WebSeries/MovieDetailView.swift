import SwiftUI

struct MovieDetailView: View {

    @EnvironmentObject var favorites: FavoritesService
    @EnvironmentObject var progress: ProgressService
    @EnvironmentObject var downloads: DownloadService

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

                    downloadPanel

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
        return ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(
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

    private var movieEpisode: Episode {
        Episode(
            id: movie.id,
            title: movie.title,
            url: movie.url
        )
    }

    @ViewBuilder
    private var downloadPanel: some View {
        let downloadStatus = downloads.status(seriesId: movie.id, episodeId: movie.id)
        switch downloadStatus {
        case .notDownloaded:
            Menu {
                ForEach(DownloadQuality.allCases) { quality in
                    Button("Descargar \(quality.title)") {
                        downloads.startDownload(
                            episode: movieEpisode,
                            seriesId: movie.id,
                            preferredTitle: movie.title,
                            quality: quality
                        )
                    }
                }
            } label: {
                Label("Descargar para ver offline", systemImage: "arrow.down.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.serieGalText)
                    .padding(.vertical, 8)
            }
        case .downloading(let progressValue, let quality):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Descargando (\(quality.title))", systemImage: "arrow.down.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.serieGalText)
                    Spacer()
                    Button("Cancelar") {
                        downloads.cancelDownload(seriesId: movie.id, episodeId: movie.id)
                    }
                    .font(.caption.weight(.semibold))
                }
                ProgressView(value: progressValue)
                    .tint(.serieGalBlue)
                Text("\(Int((progressValue * 100).rounded()))%")
                    .font(.caption)
                    .foregroundColor(.serieGalSecondary)
            }
        case .downloaded(let item):
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Disponible offline", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)
                    Text("Calidad \(item.quality.title)")
                        .font(.caption)
                        .foregroundColor(.serieGalSecondary)
                }
                Spacer()
                Button("Eliminar") {
                    downloads.deleteDownload(seriesId: movie.id, episodeId: movie.id)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.red)
            }
        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.orange)
                Button("Reintentar descarga") {
                    downloads.startDownload(
                        episode: movieEpisode,
                        seriesId: movie.id,
                        preferredTitle: movie.title,
                        quality: .media
                    )
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.serieGalBlue)
            }
        }
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
