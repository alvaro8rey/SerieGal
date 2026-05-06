import SwiftUI


struct SeriesDetailView: View {

    @EnvironmentObject var favorites: FavoritesService
    @EnvironmentObject var progress: ProgressService

    let serie: Series
    @State private var selectedSeasonID: Int?
    @State private var pendingPlayback: EpisodePlaybackRequest?
    @State private var expandedEpisodeID: String?
    @State private var resumeProgressByEpisode: [String: ProgressResponse] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero

                detailsPanel

                if seasons.count > 1 {
                    seasonSelector
                }

                if let selectedSeason {
                    episodesSection(for: selectedSeason)
                } else {
                    Text("No hay episodios disponibles")
                        .font(.subheadline)
                        .foregroundColor(.serieGalSecondary)
                        .padding()
                }

                Spacer(minLength: 36)
            }
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [Color.serieGalBackground, Color.serieGalSurface, Color.serieGalBackground],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            if selectedSeasonID == nil {
                selectedSeasonID = seasons.first?.id
            }
        }
        .task(id: serie.id) {
            await loadSeriesProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: .progressUpdated)) { _ in
            Task {
                await loadSeriesProgress()
            }
        }
        .navigationDestination(item: $pendingPlayback) { playback in
            PlayerScreen(
                episode: playback.episode,
                seriesId: playback.seriesId,
                startAtTime: playback.startAt
            )
        }
    }

    private var seriesInfo: String {
        let seasonCount = serie.normalizedSeasons.count
        let episodeCount = serie.normalizedSeasons.reduce(0) { partial, season in
            partial + season.episodes.count
        }
        return "\(seasonCount) temporadas · \(episodeCount) episodios"
    }

    private var seasons: [Season] {
        serie.normalizedSeasons
    }

    private var selectedSeason: Season? {
        if let selectedSeasonID {
            return seasons.first(where: { $0.id == selectedSeasonID }) ?? seasons.first
        }
        return seasons.first
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(
                url: URL(string: ServerConfig.webBaseURL + "/images/\(serie.id).jpg")
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.serieGalCardBackground)
            }
            .frame(height: 320)
            .clipped()

            LinearGradient(
                colors: [
                    Color.serieGalBlue.opacity(0.15),
                    Color.serieGalViolet.opacity(0.25),
                    Color.black.opacity(0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("SERIE")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())

                Text(serie.title)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(seriesInfo)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
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
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var detailsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disfruta de tu maratón en alta calidad y retoma donde lo dejaste.")
                .font(.subheadline)
                .foregroundColor(.serieGalSecondary)
                .lineSpacing(3)

            HStack(spacing: 10) {
                metadataChip(icon: "square.stack.3d.down.right.fill", value: "\(seasons.count) temporadas")
                metadataChip(icon: "play.rectangle.fill", value: "\(totalEpisodes) episodios")
            }
        }
        .padding(18)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var seasonSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(seasons) { season in
                    let selected = selectedSeasonID == season.id
                    Button {
                        selectedSeasonID = season.id
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Temporada \(season.season)")
                                .font(.subheadline.weight(.semibold))
                            Text("\(season.episodes.count) episodios")
                                .font(.caption)
                                .opacity(0.85)
                        }
                        .foregroundColor(selected ? .white : .serieGalText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selected {
                                    LinearGradient(
                                        colors: [.serieGalBlue, .serieGalViolet],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color.serieGalCardBackground
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(selected ? 0.0 : 0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func episodesSection(for season: Season) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(season.title)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.serieGalText)
                    Text("\(season.episodes.count) episodios")
                        .font(.subheadline)
                        .foregroundColor(.serieGalSecondary)
                }
                Spacer()
            }

            LazyVStack(spacing: 12) {
                ForEach(Array(season.episodes.enumerated()), id: \.element.id) { index, episode in
                    episodeRow(episode: episode, index: index)
                }
            }
        }
        .padding(18)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func episodeRow(episode: Episode, index: Int) -> some View {
        let rowProgress = progressDataForEpisode(episode)
        let rowCompleted = isEpisodeCompleted(episode: episode, progressData: rowProgress)

        return EpisodeRowView(
            seriesId: serie.id,
            episode: episode,
            index: index + 1,
            serieTitle: serie.title,
            progressData: rowProgress,
            isCompletedBySeriesState: rowCompleted,
            isExpanded: expandedEpisodeID == episode.id,
            resumeProgress: resumeProgressByEpisode[episode.id],
            onPrimaryTap: {
                handleEpisodeTap(episode)
            },
            onContinueTap: {
                if let savedProgress = resumeProgressByEpisode[episode.id] {
                    startPlayback(for: episode, startAt: savedProgress.time)
                }
            },
            onRestartTap: {
                startPlayback(for: episode, startAt: nil)
            }
        )
    }

    private func handleEpisodeTap(_ episode: Episode) {
        if let cached = progress.cachedProgress(seriesId: serie.id, episodeId: episode.id),
           shouldOfferResume(cached) {
            resumeProgressByEpisode[episode.id] = cached
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedEpisodeID = (expandedEpisodeID == episode.id) ? nil : episode.id
            }
            return
        }

        Task {
            let progressData = await progress.getProgress(
                seriesId: serie.id,
                episodeId: episode.id
            )

            await MainActor.run {
                guard let progressData, shouldOfferResume(progressData) else {
                    startPlayback(for: episode, startAt: nil)
                    return
                }

                resumeProgressByEpisode[episode.id] = progressData
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedEpisodeID = (expandedEpisodeID == episode.id) ? nil : episode.id
                }
            }
        }
    }

    private func startPlayback(for episode: Episode, startAt: Double?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedEpisodeID = nil
        }
        pendingPlayback = EpisodePlaybackRequest(
            episode: episode,
            seriesId: serie.id,
            startAt: startAt
        )
    }

    private func loadSeriesProgress() async {
        await progress.loadSeriesCompletedEpisodes(seriesId: serie.id)
    }

    private func progressDataForEpisode(_ episode: Episode) -> ProgressResponse? {
        if let expanded = resumeProgressByEpisode[episode.id] {
            return expanded
        }
        return progress.cachedProgress(seriesId: serie.id, episodeId: episode.id)
    }

    private func isEpisodeCompleted(episode: Episode, progressData: ProgressResponse?) -> Bool {
        if let progressData,
           progressData.duration > 0,
           (progressData.duration - progressData.time) < 30 {
            return true
        }

        return progress.isEpisodeCompleted(seriesId: serie.id, episodeId: episode.id)
    }

    private var totalEpisodes: Int {
        seasons.reduce(0) { partial, season in
            partial + season.episodes.count
        }
    }

    private func metadataChip(icon: String, value: String) -> some View {
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

    private func shouldOfferResume(_ progress: ProgressResponse) -> Bool {
        progress.time > 5 && progress.duration > 0 && progress.time < (progress.duration - 15)
    }

}

private struct EpisodePlaybackRequest: Identifiable, Hashable {
    let id = UUID()
    let episode: Episode
    let seriesId: String
    let startAt: Double?

    static func == (lhs: EpisodePlaybackRequest, rhs: EpisodePlaybackRequest) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
