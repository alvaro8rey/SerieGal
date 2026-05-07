import Foundation
import AVFoundation

enum DownloadQuality: String, CaseIterable, Identifiable {
    case alta
    case media
    case baja

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alta:
            return "Alta"
        case .media:
            return "Media"
        case .baja:
            return "Baja"
        }
    }

    var minimumBitrate: Double {
        switch self {
        case .alta:
            return 4_500_000
        case .media:
            return 2_200_000
        case .baja:
            return 900_000
        }
    }
}

enum DownloadStatus: Equatable {
    case notDownloaded
    case downloading(
        progress: Double,
        quality: DownloadQuality,
        downloadedBytes: Int64?,
        totalBytes: Int64?
    )
    case downloaded(item: DownloadedMedia)
    case failed(message: String)
}

struct DownloadedMedia: Codable, Identifiable, Equatable {
    let id: String
    let seriesId: String
    let episodeId: String
    let episodeTitle: String
    let episodeURL: String
    let qualityRaw: String
    let relativeLocalPath: String
    let downloadedAt: Date
    let fileSizeBytes: Int64

    var quality: DownloadQuality {
        DownloadQuality(rawValue: qualityRaw) ?? .media
    }
}

private struct PendingDownload {
    let key: String
    let seriesId: String
    let episode: Episode
    let episodeTitle: String
    let quality: DownloadQuality
    var estimatedTotalBytes: Int64?
}

final class DownloadService: NSObject, ObservableObject {

    @Published private(set) var statuses: [String: DownloadStatus] = [:]
    @Published private(set) var downloadedItems: [DownloadedMedia] = []
    @Published private(set) var totalStorageBytes: Int64 = 0

    private lazy var downloadSession: AVAssetDownloadURLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "seriegel.offline.hls")
        return AVAssetDownloadURLSession(
            configuration: configuration,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue()
        )
    }()

    private var pendingByTaskId: [Int: PendingDownload] = [:]
    private var tempLocationByTaskId: [Int: URL] = [:]

    private let folderName = "offline-downloads"
    private let indexFileName = "download-index.json"

    override init() {
        super.init()
        loadPersistedDownloads()
        purgeOrphanedDownloadArtifacts()
        cancelUntrackedBackgroundTasks()
        recomputeStorage()
    }

    func key(seriesId: String, episodeId: String) -> String {
        "\(seriesId)|\(episodeId)"
    }

    func status(seriesId: String, episodeId: String) -> DownloadStatus {
        statuses[key(seriesId: seriesId, episodeId: episodeId)] ?? .notDownloaded
    }

    func localPlaybackURL(for episode: Episode, seriesId: String) -> URL? {
        let media = downloadedItems.first { item in
            normalizedID(item.seriesId) == normalizedID(seriesId)
                && normalizedID(item.episodeId) == normalizedID(episode.id)
        }
        guard let media else { return nil }
        let absolute = downloadsDirectory().appendingPathComponent(media.relativeLocalPath)
        return playableURL(for: absolute)
    }

    func startDownload(
        episode: Episode,
        seriesId: String,
        preferredTitle: String,
        quality: DownloadQuality
    ) {
        let key = key(seriesId: seriesId, episodeId: episode.id)

        if let existingStatus = statuses[key] {
            switch existingStatus {
            case .downloading, .downloaded:
                return
            case .notDownloaded, .failed:
                break
            }
        }

        guard let url = episode.streamURL else {
            statuses[key] = .failed(message: "URL inválida")
            return
        }

        let asset = AVURLAsset(url: url)
        let options: [String: Any] = [
            AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: quality.minimumBitrate
        ]

        guard let task = downloadSession.makeAssetDownloadTask(
            asset: asset,
            assetTitle: preferredTitle,
            assetArtworkData: nil,
            options: options
        ) else {
            statuses[key] = .failed(message: "No se pudo crear la descarga")
            return
        }

        pendingByTaskId[task.taskIdentifier] = PendingDownload(
            key: key,
            seriesId: seriesId,
            episode: episode,
            episodeTitle: preferredTitle,
            quality: quality,
            estimatedTotalBytes: nil
        )
        statuses[key] = .downloading(
            progress: 0,
            quality: quality,
            downloadedBytes: nil,
            totalBytes: nil
        )
        task.resume()
    }

    func cancelDownload(seriesId: String, episodeId: String) {
        let key = key(seriesId: seriesId, episodeId: episodeId)
        guard let taskId = pendingByTaskId.first(where: { $0.value.key == key })?.key else { return }
        downloadSession.getAllTasks { tasks in
            if let targetTask = tasks.first(where: { $0.taskIdentifier == taskId }) {
                targetTask.cancel()
            }
        }
        DispatchQueue.main.async {
            self.statuses[key] = .notDownloaded
        }
    }

    func deleteDownload(seriesId: String, episodeId: String) {
        let key = key(seriesId: seriesId, episodeId: episodeId)
        guard let itemIndex = downloadedItems.firstIndex(where: { $0.id == key }) else {
            statuses[key] = .notDownloaded
            return
        }

        let item = downloadedItems[itemIndex]
        let path = downloadsDirectory().appendingPathComponent(item.relativeLocalPath)
        try? FileManager.default.removeItem(at: path)

        downloadedItems.remove(at: itemIndex)
        statuses[key] = .notDownloaded
        purgeOrphanedDownloadArtifacts()
        persistDownloadsIndex()
        recomputeStorage()
    }

    func clearAllDownloads() {
        for item in downloadedItems {
            let path = downloadsDirectory().appendingPathComponent(item.relativeLocalPath)
            try? FileManager.default.removeItem(at: path)
            statuses[item.id] = .notDownloaded
        }
        downloadedItems.removeAll()
        removeAllDownloadArtifacts()
        persistDownloadsIndex()
        recomputeStorage()
    }

    private func finalizeDownload(taskIdentifier: Int) {
        guard let pending = pendingByTaskId[taskIdentifier] else { return }
        guard let tempURL = tempLocationByTaskId[taskIdentifier] else {
            statuses[pending.key] = .failed(message: "No se guardó el archivo")
            pendingByTaskId[taskIdentifier] = nil
            return
        }

        let extensionSuffix = tempURL.pathExtension.isEmpty ? "" : ".\(tempURL.pathExtension)"
        let destinationFolder = downloadsDirectory().appendingPathComponent(
            safeFolderName(for: pending.key) + extensionSuffix
        )
        try? FileManager.default.removeItem(at: destinationFolder)

        do {
            try FileManager.default.createDirectory(
                at: downloadsDirectory(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try FileManager.default.moveItem(at: tempURL, to: destinationFolder)

            let fileSize = folderByteSize(url: destinationFolder)
            let media = DownloadedMedia(
                id: pending.key,
                seriesId: pending.seriesId,
                episodeId: pending.episode.id,
                episodeTitle: pending.episodeTitle,
                episodeURL: pending.episode.url,
                qualityRaw: pending.quality.rawValue,
                relativeLocalPath: destinationFolder.lastPathComponent,
                downloadedAt: Date(),
                fileSizeBytes: fileSize
            )

            downloadedItems.removeAll { $0.id == pending.key }
            downloadedItems.append(media)
            statuses[pending.key] = .downloaded(item: media)
            persistDownloadsIndex()
            recomputeStorage()
        } catch {
            statuses[pending.key] = .failed(message: "Error moviendo descarga")
        }

        pendingByTaskId[taskIdentifier] = nil
        tempLocationByTaskId[taskIdentifier] = nil
    }

    private func persistDownloadsIndex() {
        do {
            let data = try JSONEncoder().encode(downloadedItems)
            let path = downloadsDirectory().appendingPathComponent(indexFileName)
            try FileManager.default.createDirectory(
                at: downloadsDirectory(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: path, options: .atomic)
        } catch {
            debugLog("❌ Error guardando índice de descargas:", error)
        }
    }

    private func loadPersistedDownloads() {
        let path = downloadsDirectory().appendingPathComponent(indexFileName)
        guard let data = try? Data(contentsOf: path),
              let decoded = try? JSONDecoder().decode([DownloadedMedia].self, from: data) else {
            return
        }

        downloadedItems = decoded.filter { item in
            let absolute = downloadsDirectory().appendingPathComponent(item.relativeLocalPath)
            return FileManager.default.fileExists(atPath: absolute.path)
        }

        for item in downloadedItems {
            statuses[item.id] = .downloaded(item: item)
        }
        persistDownloadsIndex()
    }

    private func recomputeStorage() {
        totalStorageBytes = downloadedItems.reduce(0) { $0 + $1.fileSizeBytes }
    }

    private func downloadsDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(folderName, isDirectory: true)
    }

    private func folderByteSize(url: URL) -> Int64 {
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        var total: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys)) {
            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: resourceKeys),
                      values.isRegularFile == true,
                      let size = values.fileSize else { continue }
                total += Int64(size)
            }
        }
        return total
    }

    private func safeFolderName(for key: String) -> String {
        key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "|", with: "_")
    }

    private func estimatedBytes(for quality: DownloadQuality, duration: Double) -> Int64? {
        guard duration.isFinite, duration > 0 else { return nil }
        return Int64((quality.minimumBitrate * duration) / 8)
    }

    private func playableURL(for absolutePath: URL) -> URL? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: absolutePath.path) else { return nil }

        // Typical AVAssetDownloadTask output is a .movpkg bundle.
        if absolutePath.pathExtension == "movpkg" {
            return absolutePath
        }

        var isDirectory: ObjCBool = false
        if fm.fileExists(atPath: absolutePath.path, isDirectory: &isDirectory), isDirectory.boolValue {
            if let children = try? fm.contentsOfDirectory(
                at: absolutePath,
                includingPropertiesForKeys: nil
            ) {
                if let movpkg = children.first(where: { $0.pathExtension == "movpkg" }) {
                    return movpkg
                }
                if let playlist = children.first(where: { $0.pathExtension == "m3u8" }) {
                    return playlist
                }
            }

            if let enumerator = fm.enumerator(at: absolutePath, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "m3u8" {
                        return fileURL
                    }
                }
            }
        }

        return absolutePath
    }

    private func normalizedID(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func purgeOrphanedDownloadArtifacts() {
        let directory = downloadsDirectory()
        let fm = FileManager.default

        guard let children = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return
        }

        let referenced = Set(downloadedItems.map(\.relativeLocalPath) + [indexFileName])
        for child in children where !referenced.contains(child.lastPathComponent) {
            try? fm.removeItem(at: child)
        }
    }

    private func removeAllDownloadArtifacts() {
        let directory = downloadsDirectory()
        let fm = FileManager.default
        try? fm.removeItem(at: directory)
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }

    private func cancelUntrackedBackgroundTasks() {
        downloadSession.getAllTasks { tasks in
            for task in tasks {
                task.cancel()
            }
        }
    }
}

extension DownloadService: AVAssetDownloadDelegate, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        assetDownloadTask: AVAssetDownloadTask,
        didLoad timeRange: CMTimeRange,
        totalTimeRangesLoaded loadedTimeRanges: [NSValue],
        timeRangeExpectedToLoad: CMTimeRange
    ) {
        guard var pending = pendingByTaskId[assetDownloadTask.taskIdentifier] else { return }
        let expected = timeRangeExpectedToLoad.duration.seconds
        guard expected > 0 else { return }

        let loaded = loadedTimeRanges
            .map { $0.timeRangeValue.duration.seconds }
            .reduce(0, +)
        let ratio = min(max(loaded / expected, 0), 1)
        if pending.estimatedTotalBytes == nil {
            pending.estimatedTotalBytes = estimatedBytes(for: pending.quality, duration: expected)
            pendingByTaskId[assetDownloadTask.taskIdentifier] = pending
        }
        let totalBytes = pending.estimatedTotalBytes
        let downloadedBytes = totalBytes.map { Int64(Double($0) * ratio) }

        DispatchQueue.main.async {
            self.statuses[pending.key] = .downloading(
                progress: ratio,
                quality: pending.quality,
                downloadedBytes: downloadedBytes,
                totalBytes: totalBytes
            )
        }
    }

    func urlSession(
        _ session: URLSession,
        assetDownloadTask: AVAssetDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        DispatchQueue.main.async {
            self.tempLocationByTaskId[assetDownloadTask.taskIdentifier] = location
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskIdentifier = task.taskIdentifier
        guard let pending = pendingByTaskId[taskIdentifier] else { return }

        DispatchQueue.main.async {
            if let error {
                if (error as NSError).code == NSURLErrorCancelled {
                    self.statuses[pending.key] = .notDownloaded
                } else {
                    self.statuses[pending.key] = .failed(message: "Descarga fallida")
                }
                self.pendingByTaskId[taskIdentifier] = nil
                self.tempLocationByTaskId[taskIdentifier] = nil
                return
            }
            self.finalizeDownload(taskIdentifier: taskIdentifier)
        }
    }
}
