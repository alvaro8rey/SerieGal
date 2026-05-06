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
        VStack(spacing: 8) {

            HStack(spacing: 14) {

                // PLAY / CHECK
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.serieGalBlue)
                        .frame(width: 90, height: 60)

                    Image(systemName: isCompleted ? "checkmark" : "play.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {

                    Text("Episodio \(index)")
                        .font(.caption)
                        .foregroundColor(.serieGalSecondary)

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
                    .onReceive(NotificationCenter.default.publisher(for: .progressUpdated)) { _ in
                        Task {
                            await loadProgress()
                        }
                    }
                }

                Spacer()
            }

            // =========================
            // BARRA DE PROGRESO
            // =========================
            if duration > 0 {
                ProgressView(value: currentTime / duration)
                    .tint(.serieGalBlue)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.serieGalBackground)
                .shadow(color: .black.opacity(0.1), radius: 6)
        )
        .task {
            await loadProgress()
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
}
