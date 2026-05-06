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
    }

    // =========================
    // GUARDAR PROGRESO Y SALIR
    // =========================
    private func saveProgressAndDismiss() {
        Task {
            if duration > 0 {
                await progress.saveProgress(
                    seriesId: seriesId,
                    episodeId: episode.id,
                    time: currentTime,
                    duration: duration
                )

                // 🔔 Avisar a toda la app
                NotificationCenter.default.post(name: .progressUpdated, object: nil)
            }
            dismiss()
        }
    }
}
