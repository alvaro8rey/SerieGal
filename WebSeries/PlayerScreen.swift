import SwiftUI

struct PlayerScreen: View {

    let episode: Episode
    let seriesId: String
    let startAtTime: Double?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var progress: ProgressService

    @State private var dragOffset: CGFloat = 0

    // ⏱ Progreso
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var lastSyncedSecond: Int = -1
    @State private var hasSavedAtClose = false

    init(episode: Episode, seriesId: String? = nil, startAtTime: Double? = nil) {
        self.episode = episode
        self.seriesId = seriesId ?? episode.id
        self.startAtTime = startAtTime
    }

    var body: some View {
        ZStack {

            // =========================
            // REPRODUCTOR
            // =========================
            PlayerView(
                episode: episode,
                startAtTime: startAtTime,
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

        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.black)
        .onChange(of: currentTime) { _, newValue in
            syncPeriodicProgress(for: newValue)
        }
        .onAppear {
            if let startAtTime {
                debugLog("▶️ PlayerScreen abierto -> seriesId=\(seriesId), episodeId=\(episode.id), resume=\(Int(startAtTime))s")
            } else {
                debugLog("▶️ PlayerScreen abierto -> seriesId=\(seriesId), episodeId=\(episode.id), resume=inicio")
            }
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
        debugLog("🛑 Cerrando reproductor. Guardando snapshot final.")
        hasSavedAtClose = true
        saveProgressSnapshotAndNotify()
        dismiss()
    }

    private func saveProgressSnapshotAndNotify() {
        let sanitizedTime = currentTime.isFinite ? max(currentTime, 0) : 0
        let sanitizedDuration = sanitizedDurationValue(for: sanitizedTime)

        guard sanitizedTime > 5, sanitizedDuration > 0 else { return }
        debugLog("💾 Snapshot progreso: t=\(Int(sanitizedTime)) d=\(Int(sanitizedDuration))")

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
        guard newTime.isFinite, newTime > 5 else { return }

        let currentSecond = Int(newTime.rounded(.down))
        guard currentSecond % 10 == 0, currentSecond != lastSyncedSecond else { return }

        let sanitizedDuration = sanitizedDurationValue(for: newTime)
        guard sanitizedDuration > 0 else { return }

        lastSyncedSecond = currentSecond
        debugLog("⏱ Sync periódico de progreso en segundo \(currentSecond)")

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
