import SwiftUI
import AVKit

struct PlayerView: UIViewControllerRepresentable {

    let episode: Episode
    let startAtTime: Double?
    @Binding var currentTime: Double
    @Binding var duration: Double

    // =========================
    // COORDINATOR
    // =========================
    class Coordinator: NSObject {
        var timeObserver: Any?
        var statusObserver: NSKeyValueObservation?
        var pendingSeekTime: Double?

        func applyPendingSeekIfNeeded(player: AVPlayer) {
            guard let pendingSeekTime else { return }
            guard player.currentItem?.status == .readyToPlay else { return }

            let itemDuration = player.currentItem?.duration.seconds ?? 0
            let targetTime: Double
            if itemDuration.isFinite && itemDuration > 20 {
                targetTime = min(max(pendingSeekTime, 0), itemDuration - 2)
            } else {
                targetTime = max(pendingSeekTime, 0)
            }

            self.pendingSeekTime = nil
            player.seek(
                to: CMTime(seconds: targetTime, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // =========================
    // MAKE
    // =========================
    func makeUIViewController(context: Context) -> AVPlayerViewController {

        let controller = AVPlayerViewController()

        if let url = episode.streamURL {
            let player = AVPlayer(url: url)

            if let startAtTime, startAtTime > 5 {
                context.coordinator.pendingSeekTime = startAtTime
                context.coordinator.statusObserver = player.currentItem?.observe(\.status, options: [.initial, .new]) { _, _ in
                    context.coordinator.applyPendingSeekIfNeeded(player: player)
                }
            }

            // ⏱ OBSERVADOR DE TIEMPO
            context.coordinator.timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 1, preferredTimescale: 600),
                queue: .main
            ) { time in
                currentTime = time.seconds
                context.coordinator.applyPendingSeekIfNeeded(player: player)

                let rawDuration = player.currentItem?.duration.seconds ?? 0
                if rawDuration.isFinite && rawDuration > 0 {
                    duration = rawDuration
                } else if let lastRange = player.currentItem?.seekableTimeRanges.last?.timeRangeValue {
                    let seekableEnd = lastRange.start.seconds + lastRange.duration.seconds
                    if seekableEnd.isFinite && seekableEnd > 0 {
                        duration = seekableEnd
                    }
                }
            }

            controller.player = player
        }

        controller.showsPlaybackControls = true
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = true

        return controller
    }

    // =========================
    // UPDATE
    // =========================
    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {
        // No hace falta actualizar nada aquí
    }

    // =========================
    // CLEANUP
    // =========================
    static func dismantleUIViewController(
        _ uiViewController: AVPlayerViewController,
        coordinator: Coordinator
    ) {
        if let observer = coordinator.timeObserver {
            uiViewController.player?.removeTimeObserver(observer)
        }
        coordinator.statusObserver = nil

        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
