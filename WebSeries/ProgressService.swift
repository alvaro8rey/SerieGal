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
        } catch {
            print("❌ Error guardando progreso:", error)
        }
    }

    func getProgress(
        seriesId: String,
        episodeId: String
    ) async -> ProgressResponse? {

        guard let token = auth.token else { return nil }

        do {
            let data = try await APIClient.request(
                endpoint: "/progress/\(seriesId)/\(episodeId)",
                token: token
            )

            return try JSONDecoder().decode(ProgressResponse.self, from: data)
        } catch {
            return nil
        }
    }
}

struct ProgressResponse: Decodable {
    let time: Double
    let duration: Double
}
