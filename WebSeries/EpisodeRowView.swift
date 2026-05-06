import SwiftUI

struct EpisodeRowView: View {

    let seriesId: String
    let episode: Episode
    let index: Int
    let serieTitle: String
    let isExpanded: Bool
    let resumeProgress: ProgressResponse?
    let onPrimaryTap: () -> Void
    let onContinueTap: (() -> Void)?
    let onRestartTap: (() -> Void)?

    @EnvironmentObject var progress: ProgressService

    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    init(
        seriesId: String,
        episode: Episode,
        index: Int,
        serieTitle: String,
        isExpanded: Bool = false,
        resumeProgress: ProgressResponse? = nil,
        onPrimaryTap: @escaping () -> Void = {},
        onContinueTap: (() -> Void)? = nil,
        onRestartTap: (() -> Void)? = nil
    ) {
        self.seriesId = seriesId
        self.episode = episode
        self.index = index
        self.serieTitle = serieTitle
        self.isExpanded = isExpanded
        self.resumeProgress = resumeProgress
        self.onPrimaryTap = onPrimaryTap
        self.onContinueTap = onContinueTap
        self.onRestartTap = onRestartTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onPrimaryTap) {
                episodeMainContent
            }
            .buttonStyle(.plain)

            if isExpanded, let resumeProgress {
                Divider()
                    .overlay(Color.white.opacity(0.1))

                Text("Progreso guardado en \(formattedTime(resumeProgress.time))")
                    .font(.caption)
                    .foregroundColor(.serieGalSecondary)

                HStack(spacing: 10) {
                    Button {
                        onContinueTap?()
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
                        onRestartTap?()
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
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.serieGalCardBackground,
                    Color.serieGalSurface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isExpanded ? Color.serieGalBlue.opacity(0.45) : Color.white.opacity(0.08),
                    lineWidth: isExpanded ? 1.2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .task {
            await loadProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: .progressUpdated)) { _ in
            Task {
                await loadProgress()
            }
        }
    }

    private var episodeMainContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                episodeBadge

                VStack(alignment: .leading, spacing: 6) {
                    Text("Episodio \(index)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.serieGalTertiary)

                    Text(
                        formattedEpisodeTitle(
                            serieTitle: serieTitle,
                            episodeTitle: episode.title,
                            index: index
                        )
                    )
                    .font(.headline)
                    .foregroundColor(.serieGalText)
                    .lineLimit(2)
                }

                Spacer()

                Image(systemName: isCompleted ? "checkmark.seal.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? Color.green : Color.serieGalBlue)
            }

            if duration > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { proxy in
                        let ratio = min(max(currentTime / duration, 0), 1)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.serieGalBlue, .serieGalViolet, .serieGalMagenta],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: proxy.size.width * ratio)
                        }
                    }
                    .frame(height: 6)

                    Text(progressLabel)
                        .font(.caption)
                        .foregroundColor(.serieGalSecondary)
                }
            } else {
                Text("Sin progreso guardado")
                    .font(.caption)
                    .foregroundColor(.serieGalSecondary)
            }
        }
    }

    private func loadProgress() async {
        if let data = await progress.getProgress(
            seriesId: seriesId,
            episodeId: episode.id
        ) {
            currentTime = data.time
            duration = data.duration
        }
    }

    private var isCompleted: Bool {
        duration > 0 && currentTime / duration > 0.9
    }

    private var progressLabel: String {
        let ratio = currentTime / duration
        if ratio > 0.9 {
            return "Completado"
        }
        let value = Int((ratio * 100).rounded())
        return "Visto \(value)%"
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

    private var episodeBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.serieGalBlue, .serieGalViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)

            Text("\(index)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
        }
    }
}
