import SwiftUI
import AVKit

struct PlayerView: UIViewControllerRepresentable {

    let episode: Episode
    @Binding var currentTime: Double
    @Binding var duration: Double

    // =========================
    // COORDINATOR
    // =========================
    class Coordinator: NSObject {
        var timeObserver: Any?
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

            // ⏱ OBSERVADOR DE TIEMPO
            context.coordinator.timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 1, preferredTimescale: 600),
                queue: .main
            ) { time in
                currentTime = time.seconds
                duration = player.currentItem?.duration.seconds ?? 0
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

        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
