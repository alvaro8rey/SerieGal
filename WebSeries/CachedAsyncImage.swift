import Foundation
import SwiftUI
import UIKit
import CryptoKit

struct CachedAsyncImage<Content: View, Placeholder: View>: View {

    let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @StateObject private var loader: CachedImageLoader

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        _loader = StateObject(wrappedValue: CachedImageLoader())
    }

    var body: some View {
        Group {
            if let uiImage = loader.image {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loader.load(from: url)
        }
    }
}

@MainActor
final class CachedImageLoader: ObservableObject {

    @Published var image: UIImage?
    private var lastURL: URL?

    func load(from url: URL?) async {
        guard lastURL != url || image == nil else { return }

        lastURL = url
        image = nil

        guard let url else { return }
        image = await ImageCache.shared.image(for: url)
    }
}

actor ImageCache {
    static let shared = ImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private let cacheDirectory: URL
    private let session: URLSession

    init() {
        memory.countLimit = 300
        memory.totalCostLimit = 120 * 1024 * 1024

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        cacheDirectory = caches.appendingPathComponent("WebSeriesImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 80 * 1024 * 1024,
            diskCapacity: 600 * 1024 * 1024,
            diskPath: "WebSeriesURLCache"
        )
        session = URLSession(configuration: config)
    }

    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        let nsKey = NSString(string: key)

        if let cached = memory.object(forKey: nsKey) {
            return cached
        }

        let fileURL = cacheDirectory.appendingPathComponent(key).appendingPathExtension("img")
        if let data = try? Data(contentsOf: fileURL),
           let diskImage = UIImage(data: data) {
            memory.setObject(diskImage, forKey: nsKey, cost: data.count)
            return diskImage
        }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 40

            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let downloadedImage = UIImage(data: data) else {
                return nil
            }

            memory.setObject(downloadedImage, forKey: nsKey, cost: data.count)
            try? data.write(to: fileURL, options: .atomic)
            return downloadedImage
        } catch {
            return nil
        }
    }

    private func cacheKey(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
