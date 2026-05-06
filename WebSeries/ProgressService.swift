//
//  ProgressService.swift
//  WebSeries
//
//  Created by alvaro on 4/1/26.
//


import Foundation
import SwiftUI

@MainActor
final class ProgressService: ObservableObject {

    @Published private(set) var continueWatching: [ContinueWatchingEntry] = []

    private let auth: AuthService
    private var progressCache: [String: ProgressResponse] = [:]

    init(auth: AuthService) {
        self.auth = auth
    }

    func saveProgress(
        seriesId: String,
        episodeId: String,
        episodeTitle: String? = nil,
        url: String? = nil,
        time: Double,
        duration: Double
    ) async {
        guard let token = auth.token else {
            debugLog("⚠️ saveProgress cancelado: no hay token.")
            return
        }

        debugLog("🧭 saveProgress -> series_id=\(seriesId), episode_id=\(episodeId), time=\(Int(time))s, duration=\(Int(duration))s")

        var body: [String: Any] = [
            "series_id": seriesId,
            "episode_id": episodeId,
            "time": time,
            "duration": duration
        ]
        if let episodeTitle {
            body["episode_title"] = episodeTitle
        }
        if let url {
            body["url"] = url
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: body)

            _ = try await APIClient.request(
                endpoint: "/progress",
                method: "POST",
                body: data,
                token: token
            )

            progressCache[cacheKey(seriesId: seriesId, episodeId: episodeId)] = ProgressResponse(
                time: time,
                duration: duration
            )
        } catch {
            debugLog("❌ Error guardando progreso:", error)
        }
    }

    func loadContinueWatching() async {
        guard let token = auth.token else {
            debugLog("⚠️ loadContinueWatching cancelado: no hay token.")
            return
        }

        do {
            let data = try await APIClient.request(
                endpoint: "/continue-watching",
                token: token
            )

            let items = try JSONDecoder().decode([ContinueWatchingEntry].self, from: data)
            continueWatching = items
            debugLog("✅ /continue-watching cargado. Items:", items.count)
            for item in items {
                progressCache[cacheKey(seriesId: item.seriesId, episodeId: item.episodeId)] = ProgressResponse(
                    time: item.time,
                    duration: item.duration
                )
            }
        } catch {
            debugLog("❌ Error cargando continue-watching:", error)
        }
    }

    func getProgress(
        seriesId: String,
        episodeId: String
    ) async -> ProgressResponse? {
        if let cached = progressCache[cacheKey(seriesId: seriesId, episodeId: episodeId)] {
            debugLog("🧠 getProgress cache hit -> \(seriesId)/\(episodeId)")
            return cached
        }

        guard let token = auth.token else {
            debugLog("⚠️ getProgress cancelado: no hay token para \(seriesId)/\(episodeId).")
            return nil
        }

        debugLog("🧭 getProgress request -> \(seriesId)/\(episodeId)")

        do {
            let data = try await APIClient.request(
                endpoint: "/progress/\(seriesId)/\(episodeId)",
                token: token
            )

            let decoded = try JSONDecoder().decode(ProgressResponse.self, from: data)
            progressCache[cacheKey(seriesId: seriesId, episodeId: episodeId)] = decoded
            return decoded
        } catch {
            return nil
        }
    }

    private func cacheKey(seriesId: String, episodeId: String) -> String {
        "\(seriesId)|\(episodeId)"
    }
}

struct ProgressResponse: Decodable {
    let time: Double
    let duration: Double

    init(time: Double, duration: Double) {
        self.time = time
        self.duration = duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        func decodeDouble(_ keys: [String]) -> Double? {
            for key in keys {
                guard let codingKey = DynamicCodingKeys(stringValue: key) else { continue }
                if let value = try? container.decode(Double.self, forKey: codingKey) {
                    return value
                }
                if let value = try? container.decode(Int.self, forKey: codingKey) {
                    return Double(value)
                }
                if let value = try? container.decode(String.self, forKey: codingKey),
                   let number = Double(value) {
                    return number
                }
            }
            return nil
        }

        self.time = decodeDouble(["time", "current_time", "position"]) ?? 0
        self.duration = decodeDouble(["duration", "total_duration"]) ?? 0
    }
}

struct ContinueWatchingEntry: Decodable, Identifiable {
    let seriesId: String
    let episodeId: String
    let episodeTitle: String?
    let url: String?
    let time: Double
    let duration: Double

    var id: String {
        "\(seriesId)|\(episodeId)"
    }

    var ratio: Double {
        guard duration > 0 else { return 0 }
        return time / duration
    }

    enum CodingKeys: String, CodingKey {
        case seriesId
        case episodeId
        case episodeTitle
        case url
        case time
        case duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        func decodeString(_ keys: [String]) -> String? {
            for key in keys {
                guard let codingKey = DynamicCodingKeys(stringValue: key) else { continue }
                if let value = try? container.decode(String.self, forKey: codingKey), !value.isEmpty {
                    return value
                }
            }
            return nil
        }

        func decodeDouble(_ keys: [String]) -> Double? {
            for key in keys {
                guard let codingKey = DynamicCodingKeys(stringValue: key) else { continue }
                if let value = try? container.decode(Double.self, forKey: codingKey) {
                    return value
                }
                if let intValue = try? container.decode(Int.self, forKey: codingKey) {
                    return Double(intValue)
                }
                if let stringValue = try? container.decode(String.self, forKey: codingKey),
                   let value = Double(stringValue) {
                    return value
                }
            }
            return nil
        }

        let seriesId = decodeString(["series_id", "seriesId", "series"])
        let episodeId = decodeString(["episode_id", "episodeId", "episode"])
        let episodeTitle = decodeString(["episode_title", "episodeTitle", "title"])
        let url = decodeString(["url", "episode_url"])
        let time = decodeDouble(["time", "current_time", "position"]) ?? 0
        let duration = decodeDouble(["duration", "total_duration"]) ?? 0

        guard let seriesId, let episodeId else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "No se encontraron seriesId/episodeId en progreso"
                )
            )
        }

        self.seriesId = seriesId
        self.episodeId = episodeId
        self.episodeTitle = episodeTitle
        self.url = url
        self.time = time
        self.duration = duration
    }
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
