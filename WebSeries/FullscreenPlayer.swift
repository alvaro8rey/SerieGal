import SwiftUI
import AVKit

struct FullscreenPlayer: UIViewControllerRepresentable {

    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        debugLog("🎥 makeUIViewController")
        let controller = AVPlayerViewController()
        controller.player = context.coordinator.player
        controller.modalPresentationStyle = .fullScreen
        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {
        debugLog("🔄 updateUIViewController")
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject {

        let player: AVPlayer

        init(url: URL) {
            debugLog("🎬 Coordinator INIT")
            debugLog("URL:", url.absoluteString)
            self.player = AVPlayer(url: url)
            super.init()

            // 🔎 Observar estado del player
            player.currentItem?.addObserver(
                self,
                forKeyPath: "status",
                options: [.old, .new],
                context: nil
            )
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey : Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            if keyPath == "status" {
                if let item = object as? AVPlayerItem {
                    switch item.status {
                    case .readyToPlay:
                        debugLog("✅ AVPlayerItem READY TO PLAY")
                        player.play()
                    case .failed:
                        debugLog("❌ AVPlayerItem FAILED")
                        debugLog(item.error ?? "Error desconocido")
                    case .unknown:
                        debugLog("⚠️ AVPlayerItem UNKNOWN")
                    @unknown default:
                        debugLog("❓ Estado desconocido")
                    }
                }
            }
        }

        deinit {
            debugLog("🧹 Coordinator DEINIT")
            player.currentItem?.removeObserver(self, forKeyPath: "status")
        }
    }
}
