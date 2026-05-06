import SwiftUI
import AVKit

struct FullscreenPlayer: UIViewControllerRepresentable {

    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        print("🎥 makeUIViewController")
        let controller = AVPlayerViewController()
        controller.player = context.coordinator.player
        controller.modalPresentationStyle = .fullScreen
        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {
        print("🔄 updateUIViewController")
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject {

        let player: AVPlayer

        init(url: URL) {
            print("🎬 Coordinator INIT")
            print("URL:", url.absoluteString)
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
                        print("✅ AVPlayerItem READY TO PLAY")
                        player.play()
                    case .failed:
                        print("❌ AVPlayerItem FAILED")
                        print(item.error ?? "Error desconocido")
                    case .unknown:
                        print("⚠️ AVPlayerItem UNKNOWN")
                    @unknown default:
                        print("❓ Estado desconocido")
                    }
                }
            }
        }

        deinit {
            print("🧹 Coordinator DEINIT")
            player.currentItem?.removeObserver(self, forKeyPath: "status")
        }
    }
}
