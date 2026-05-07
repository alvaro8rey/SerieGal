import SwiftUI

struct PlayerScreen: View {

    let episode: Episode
    let seriesId: String
    let startAtTime: Double?
    let upNextQueue: [Episode]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var progress: ProgressService
    @EnvironmentObject var downloads: DownloadService

    @State private var dragOffset: CGFloat = 0

    // ⏱ Progreso
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var lastSyncedSecond: Int = -1
    @State private var hasSavedAtClose = false
    @State private var didFinishPlayback = false
    @State private var showUpNextOverlay = false
    @State private var upNextCountdown = 10
    @State private var upNextTask: Task<Void, Never>?
    @State private var pendingAutoPlayback: AutoPlaybackRequest?

    init(
        episode: Episode,
        seriesId: String? = nil,
        startAtTime: Double? = nil,
        upNextQueue: [Episode] = []
    ) {
        self.episode = episode
        self.seriesId = seriesId ?? episode.id
        self.startAtTime = startAtTime
        self.upNextQueue = upNextQueue
    }

    var body: some View {
        ZStack {

            // =========================
            // REPRODUCTOR
            // =========================
            PlayerView(
                episode: episode,
                playbackURL: offlinePlaybackURL,
                startAtTime: startAtTime,
                currentTime: $currentTime,
                duration: $duration,
                didFinishPlayback: $didFinishPlayback
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

            if showUpNextOverlay, let nextEpisode = upNextQueue.first {
                upNextOverlay(nextEpisode: nextEpisode)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
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
        .onChange(of: didFinishPlayback) { _, ended in
            guard ended else { return }
            handlePlaybackFinished()
        }
        .onDisappear {
            upNextTask?.cancel()
            if !hasSavedAtClose {
                saveProgressSnapshotAndNotify()
            }
        }
        .navigationDestination(item: $pendingAutoPlayback) { request in
            PlayerScreen(
                episode: request.episode,
                seriesId: seriesId,
                startAtTime: nil,
                upNextQueue: request.upNextQueue
            )
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

    private var offlinePlaybackURL: URL? {
        downloads.localPlaybackURL(for: episode, seriesId: seriesId)
    }

    @ViewBuilder
    private func upNextOverlay(nextEpisode: Episode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Siguiente episodio en \(upNextCountdown)s")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
            Text(nextEpisode.title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)

            HStack(spacing: 10) {
                Button {
                    cancelAutoNext()
                } label: {
                    Text("Cancelar")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.14))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                Button {
                    playNextImmediately()
                } label: {
                    Label("Reproducir ahora", systemImage: "play.fill")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func handlePlaybackFinished() {
        guard let nextEpisode = upNextQueue.first else { return }
        guard !showUpNextOverlay else { return }

        debugLog("⏭️ Episodio finalizado. Preparando autoplay para \(nextEpisode.id)")
        showUpNextOverlay = true
        upNextCountdown = 10
        startUpNextCountdown()
    }

    private func startUpNextCountdown() {
        upNextTask?.cancel()
        upNextTask = Task {
            while upNextCountdown > 0, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    upNextCountdown -= 1
                    if upNextCountdown <= 0 {
                        playNextImmediately()
                    }
                }
            }
        }
    }

    private func cancelAutoNext() {
        upNextTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            showUpNextOverlay = false
        }
    }

    private func playNextImmediately() {
        upNextTask?.cancel()
        guard let nextEpisode = upNextQueue.first else { return }
        hasSavedAtClose = true
        saveProgressSnapshotAndNotify()
        pendingAutoPlayback = AutoPlaybackRequest(
            episode: nextEpisode,
            upNextQueue: Array(upNextQueue.dropFirst())
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            showUpNextOverlay = false
        }
    }
}

private struct AutoPlaybackRequest: Identifiable, Hashable {
    let id = UUID()
    let episode: Episode
    let upNextQueue: [Episode]

    static func == (lhs: AutoPlaybackRequest, rhs: AutoPlaybackRequest) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
