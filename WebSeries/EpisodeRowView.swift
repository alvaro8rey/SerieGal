import SwiftUI

struct EpisodeRowView: View {

    let seriesId: String
    let episode: Episode
    let index: Int
    let serieTitle: String

    @EnvironmentObject var progress: ProgressService

    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    var body: some View {
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
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .task {
            await loadProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: .progressUpdated)) { _ in
            Task {
                await loadProgress()
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
