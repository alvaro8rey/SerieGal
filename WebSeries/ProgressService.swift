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

    @Published private(set) var allProgress: [ProgressItem] = []

    private let auth: AuthService

    init(auth: AuthService) {
        self.auth = auth
    }

    func saveProgress(
        seriesId: String,
        episodeId: String,
        time: Double,
        duration: Double
    ) async {
        guard let token = auth.token else { return }

        let body: [String: Any] = [
            "series_id": seriesId,
            "episode_id": episodeId,
            "time": time,
            "duration": duration
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: body)

            _ = try await APIClient.request(
                endpoint: "/progress",
                method: "POST",
                body: data,
                token: token
            )

            mergeLocalProgress(
                seriesId: seriesId,
                episodeId: episodeId,
                time: time,
                duration: duration
            )
        } catch {
            print("❌ Error guardando progreso:", error)
        }
    }

    func loadAllProgress() async {
        guard let token = auth.token else { return }

        do {
            let data = try await APIClient.request(
                endpoint: "/progress/all",
                token: token
            )

            allProgress = try decodeProgressItems(from: data)
        } catch {
            print("❌ Error cargando progreso global:", error)
        }
    }

    func getProgress(
        seriesId: String,
        episodeId: String
    ) async -> ProgressResponse? {

        if let cached = allProgress.first(where: { item in
            item.seriesId == seriesId && item.episodeId == episodeId
        }) {
            return ProgressResponse(time: cached.time, duration: cached.duration)
        }

        if let cachedByEpisode = allProgress.first(where: { item in
            item.episodeId == episodeId
        }) {
            return ProgressResponse(time: cachedByEpisode.time, duration: cachedByEpisode.duration)
        }

        guard let token = auth.token else { return nil }

        do {
            let data = try await APIClient.request(
                endpoint: "/progress/\(seriesId)/\(episodeId)",
                token: token
            )

            let decoded = try JSONDecoder().decode(ProgressResponse.self, from: data)

            mergeLocalProgress(
                seriesId: seriesId,
                episodeId: episodeId,
                time: decoded.time,
                duration: decoded.duration
            )

            return decoded
        } catch {
            return nil
        }
    }

    private func mergeLocalProgress(
        seriesId: String,
        episodeId: String,
        time: Double,
        duration: Double
    ) {
        let updated = ProgressItem(
            seriesId: seriesId,
            episodeId: episodeId,
            time: time,
            duration: duration,
            updatedAt: nil
        )

        if let index = allProgress.firstIndex(where: { item in
            item.seriesId == seriesId && item.episodeId == episodeId
        }) {
            allProgress[index] = updated
        } else {
            allProgress.append(updated)
        }
    }

    private func decodeProgressItems(from data: Data) throws -> [ProgressItem] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let direct = try? decoder.decode([ProgressItem].self, from: data) {
            return direct
        }

        if let wrapped = try? decoder.decode(ProgressEnvelope.self, from: data) {
            return wrapped.items
        }

        let json = try JSONSerialization.jsonObject(with: data)

        if let array = json as? [[String: Any]] {
            return array.compactMap(ProgressItem.init(dictionary:))
        }

        if let dict = json as? [String: Any] {
            for key in ["progress", "items", "data", "results"] {
                if let array = dict[key] as? [[String: Any]] {
                    return array.compactMap(ProgressItem.init(dictionary:))
                }
            }
        }

        return []
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

struct ProgressItem: Decodable, Identifiable {
    let seriesId: String
    let episodeId: String
    let time: Double
    let duration: Double
    let updatedAt: Date?

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
        case time
        case duration
        case updatedAt
    }

    init(
        seriesId: String,
        episodeId: String,
        time: Double,
        duration: Double,
        updatedAt: Date?
    ) {
        self.seriesId = seriesId
        self.episodeId = episodeId
        self.time = time
        self.duration = duration
        self.updatedAt = updatedAt
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
        self.time = time
        self.duration = duration

        if let updatedString = decodeString(["updated_at", "updatedAt", "date"]) {
            let iso = ISO8601DateFormatter()
            self.updatedAt = iso.date(from: updatedString)
        } else {
            self.updatedAt = nil
        }
    }

    init?(dictionary: [String: Any]) {
        let possibleSeries = ["series_id", "seriesId", "series"]
        let possibleEpisode = ["episode_id", "episodeId", "episode"]
        let possibleTime = ["time", "current_time", "position"]
        let possibleDuration = ["duration", "total_duration"]
        let possibleUpdated = ["updated_at", "updatedAt", "date"]

        func readString(_ keys: [String]) -> String? {
            for key in keys {
                if let value = dictionary[key] as? String, !value.isEmpty {
                    return value
                }
            }
            return nil
        }

        func readDouble(_ keys: [String]) -> Double? {
            for key in keys {
                if let value = dictionary[key] as? Double {
                    return value
                }
                if let value = dictionary[key] as? Int {
                    return Double(value)
                }
                if let value = dictionary[key] as? String, let number = Double(value) {
                    return number
                }
            }
            return nil
        }

        guard let seriesId = readString(possibleSeries),
              let episodeId = readString(possibleEpisode) else {
            return nil
        }

        self.seriesId = seriesId
        self.episodeId = episodeId
        self.time = readDouble(possibleTime) ?? 0
        self.duration = readDouble(possibleDuration) ?? 0

        if let dateValue = readString(possibleUpdated) {
            let iso = ISO8601DateFormatter()
            self.updatedAt = iso.date(from: dateValue)
        } else {
            self.updatedAt = nil
        }
    }
}

private struct ProgressEnvelope: Decodable {
    let items: [ProgressItem]

    enum CodingKeys: String, CodingKey {
        case progress
        case items
        case data
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let progress = try? container.decode([ProgressItem].self, forKey: .progress) {
            items = progress
            return
        }
        if let values = try? container.decode([ProgressItem].self, forKey: .items) {
            items = values
            return
        }
        if let data = try? container.decode([ProgressItem].self, forKey: .data) {
            items = data
            return
        }
        items = (try? container.decode([ProgressItem].self, forKey: .results)) ?? []
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
