import SwiftUI

struct PlayerScreen: View {

    let episode: Episode
    let seriesId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var progress: ProgressService

    @State private var dragOffset: CGFloat = 0

    // ⏱ Progreso
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var lastSyncedSecond: Int = -1
    @State private var hasSavedAtClose = false

    init(episode: Episode, seriesId: String? = nil) {
        self.episode = episode
        self.seriesId = seriesId ?? episode.id
    }

    var body: some View {
        ZStack(alignment: .topLeading) {

            // =========================
            // REPRODUCTOR
            // =========================
            PlayerView(
                episode: episode,
                currentTime: $currentTime,
                duration: $duration
            )
            .ignoresSafeArea()
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 120 {
                            saveProgressAndDismiss()
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )

            // =========================
            // BOTÓN CERRAR
            // =========================
            Button {
                saveProgressAndDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 50)
            .padding(.leading, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.black)
        .onChange(of: currentTime) { _, newValue in
            syncPeriodicProgress(for: newValue)
        }
        .onDisappear {
            if !hasSavedAtClose {
                saveProgressSnapshotAndNotify()
            }
        }
    }

    // =========================
    // GUARDAR PROGRESO Y SALIR
    // =========================
    private func saveProgressAndDismiss() {
        hasSavedAtClose = true
        saveProgressSnapshotAndNotify()
        dismiss()
    }

    private func saveProgressSnapshotAndNotify() {
        let sanitizedTime = currentTime.isFinite ? max(currentTime, 0) : 0
        let sanitizedDuration = sanitizedDurationValue(for: sanitizedTime)

        guard sanitizedTime > 1, sanitizedDuration > 0 else { return }

        Task {
            await progress.saveProgress(
                seriesId: seriesId,
                episodeId: episode.id,
                episodeTitle: episode.title,
                url: episode.url,
                time: sanitizedTime,
                duration: sanitizedDuration
            )
            NotificationCenter.default.post(name: .progressUpdated, object: nil)
        }
    }

    private func syncPeriodicProgress(for newTime: Double) {
        guard newTime.isFinite, newTime > 1 else { return }

        let currentSecond = Int(newTime.rounded(.down))
        guard currentSecond % 10 == 0, currentSecond != lastSyncedSecond else { return }

        let sanitizedDuration = sanitizedDurationValue(for: newTime)
        guard sanitizedDuration > 0 else { return }

        lastSyncedSecond = currentSecond

        Task {
            await progress.saveProgress(
                seriesId: seriesId,
                episodeId: episode.id,
                episodeTitle: episode.title,
                url: episode.url,
                time: newTime,
                duration: sanitizedDuration
            )
        }
    }

    private func sanitizedDurationValue(for time: Double) -> Double {
        if duration.isFinite && duration > 0 {
            return duration
        }
        // Fallback para streams HLS donde AVPlayer tarda en exponer la duración real.
        return time + 120
    }
}
