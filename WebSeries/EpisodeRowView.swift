import SwiftUI

struct EpisodeRowView: View {

    let seriesId: String
    let episode: Episode
    let index: Int
    let serieTitle: String
    let isExpanded: Bool
    let resumeProgress: ProgressResponse?
    let progressData: ProgressResponse?
    let isCompletedBySeriesState: Bool
    let downloadStatus: DownloadStatus
    let onPrimaryTap: () -> Void
    let onContinueTap: (() -> Void)?
    let onRestartTap: (() -> Void)?
    let onDownloadQualitySelected: ((DownloadQuality) -> Void)?
    let onCancelDownload: (() -> Void)?
    let onDeleteDownload: (() -> Void)?
    let onRetryDownload: (() -> Void)?

    init(
        seriesId: String,
        episode: Episode,
        index: Int,
        serieTitle: String,
        isExpanded: Bool = false,
        resumeProgress: ProgressResponse? = nil,
        progressData: ProgressResponse? = nil,
        isCompletedBySeriesState: Bool = false,
        downloadStatus: DownloadStatus = .notDownloaded,
        onPrimaryTap: @escaping () -> Void = {},
        onContinueTap: (() -> Void)? = nil,
        onRestartTap: (() -> Void)? = nil,
        onDownloadQualitySelected: ((DownloadQuality) -> Void)? = nil,
        onCancelDownload: (() -> Void)? = nil,
        onDeleteDownload: (() -> Void)? = nil,
        onRetryDownload: (() -> Void)? = nil
    ) {
        self.seriesId = seriesId
        self.episode = episode
        self.index = index
        self.serieTitle = serieTitle
        self.isExpanded = isExpanded
        self.resumeProgress = resumeProgress
        self.progressData = progressData
        self.isCompletedBySeriesState = isCompletedBySeriesState
        self.downloadStatus = downloadStatus
        self.onPrimaryTap = onPrimaryTap
        self.onContinueTap = onContinueTap
        self.onRestartTap = onRestartTap
        self.onDownloadQualitySelected = onDownloadQualitySelected
        self.onCancelDownload = onCancelDownload
        self.onDeleteDownload = onDeleteDownload
        self.onRetryDownload = onRetryDownload
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onPrimaryTap) {
                episodeMainContent
            }
            .buttonStyle(.plain)

            downloadControls

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
    }

    @ViewBuilder
    private var downloadControls: some View {
        switch downloadStatus {
        case .notDownloaded:
            Menu {
                ForEach(DownloadQuality.allCases) { quality in
                    Button("Descargar \(quality.title)") {
                        onDownloadQualitySelected?(quality)
                    }
                }
            } label: {
                Label("Descargar episodio", systemImage: "arrow.down.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.serieGalSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        case .downloading(let progressValue, let quality):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Descargando \(quality.title)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.serieGalText)
                    Spacer()
                    Button("Cancelar") {
                        onCancelDownload?()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.orange)
                    .buttonStyle(.plain)
                }
                ProgressView(value: progressValue)
                    .tint(.serieGalBlue)
                Text("\(Int((progressValue * 100).rounded()))%")
                    .font(.caption2)
                    .foregroundColor(.serieGalSecondary)
            }
            .padding(.vertical, 2)
        case .downloaded:
            HStack {
                Label("Disponible offline", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)
                Spacer()
                Button("Eliminar") {
                    onDeleteDownload?()
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.red)
                .buttonStyle(.plain)
            }
        case .failed:
            HStack {
                Label("Error de descarga", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.orange)
                Spacer()
                Button("Reintentar") {
                    onRetryDownload?()
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.serieGalBlue)
                .buttonStyle(.plain)
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

            if duration > 0 || isCompleted {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { proxy in
                        let ratio = progressRatio
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

    private var isCompleted: Bool {
        isCompletedBySeriesState || (duration > 0 && currentTime / duration > 0.9)
    }

    private var currentTime: Double {
        progressData?.time ?? 0
    }

    private var duration: Double {
        progressData?.duration ?? 0
    }

    private var progressRatio: Double {
        if isCompleted {
            return 1
        }
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    private var progressLabel: String {
        let ratio = progressRatio
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
