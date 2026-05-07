import SwiftUI

struct ActiveDownloadsView: View {
    @EnvironmentObject var downloads: DownloadService

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard

                if downloads.activeDownloads.isEmpty {
                    Text("No hay descargas activas en este momento.")
                        .font(.subheadline)
                        .foregroundColor(.serieGalSecondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.serieGalCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    ForEach(downloads.activeDownloads) { item in
                        activeDownloadRow(item)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .background(
            LinearGradient(
                colors: [Color.serieGalBackground, Color.serieGalSurface, Color.serieGalBackground],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Descargando")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Descargas en curso")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.serieGalText)
                Text("\(downloads.activeDownloads.count) activas")
                    .font(.caption)
                    .foregroundColor(.serieGalSecondary)
            }
            Spacer()
            Text("\(Int((downloads.aggregateActiveProgress * 100).rounded()))%")
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func activeDownloadRow(_ item: ActiveDownloadInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.serieGalText)
                        .lineLimit(2)
                    Text("Calidad \(item.quality.title)")
                        .font(.caption)
                        .foregroundColor(.serieGalSecondary)
                }
                Spacer()
                Button("Cancelar") {
                    downloads.cancelDownload(seriesId: item.seriesId, episodeId: item.episodeId)
                }
                .font(.caption.weight(.bold))
                .foregroundColor(.orange)
                .buttonStyle(.plain)
            }

            ProgressView(value: item.progress)
                .tint(.serieGalBlue)

            Text(progressText(for: item))
                .font(.caption2)
                .foregroundColor(.serieGalSecondary)
        }
        .padding(14)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func progressText(for item: ActiveDownloadInfo) -> String {
        let percent = "\(Int((item.progress * 100).rounded()))%"
        guard let downloaded = item.downloadedBytes, let total = item.totalBytes, total > 0 else {
            return percent
        }
        return "\(formattedBytes(downloaded)) / \(formattedBytes(total)) · \(percent)"
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
