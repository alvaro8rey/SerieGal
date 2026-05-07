import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var downloads: DownloadService

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                storageCard

                if downloads.downloadedItems.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Descargado")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.serieGalText)

                        ForEach(sortedDownloads) { item in
                            downloadRow(item)
                        }
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
        .navigationTitle("Descargas")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedDownloads: [DownloadedMedia] {
        downloads.downloadedItems.sorted { $0.downloadedAt > $1.downloadedAt }
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gestión de memoria")
                .font(.headline.weight(.bold))
                .foregroundColor(.serieGalText)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedBytes(downloads.totalStorageBytes))
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("\(downloads.downloadedItems.count) elementos offline")
                        .font(.subheadline)
                        .foregroundColor(.serieGalSecondary)
                }
                Spacer()
                if !downloads.downloadedItems.isEmpty {
                    Button(role: .destructive) {
                        downloads.clearAllDownloads()
                    } label: {
                        Text("Borrar todo")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func downloadRow(_ item: DownloadedMedia) -> some View {
        HStack(spacing: 12) {
            NavigationLink {
                PlayerScreen(
                    episode: Episode(
                        id: item.episodeId,
                        title: item.episodeTitle,
                        url: item.episodeURL
                    ),
                    seriesId: item.seriesId
                )
            } label: {
                HStack(spacing: 12) {
                    CachedAsyncImage(url: URL(string: ServerConfig.webBaseURL + "/images/\(item.seriesId).jpg")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.serieGalSurface)
                    }
                    .frame(width: 90, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.episodeTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.serieGalText)
                            .lineLimit(2)
                        Text("Calidad \(item.quality.title) · \(formattedBytes(item.fileSizeBytes))")
                            .font(.caption)
                            .foregroundColor(.serieGalSecondary)
                        Text("Descargado \(item.downloadedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.serieGalSecondary.opacity(0.8))
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                downloads.deleteDownload(seriesId: item.seriesId, episodeId: item.episodeId)
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.red)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aún no tienes descargas")
                .font(.headline)
                .foregroundColor(.serieGalText)
            Text("Descarga episodios o películas y aparecerán aquí para reproducirlos sin conexión.")
                .font(.subheadline)
                .foregroundColor(.serieGalSecondary)
        }
        .padding(16)
        .background(Color.serieGalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
