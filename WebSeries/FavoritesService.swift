//
//  FavoritesService.swift
//  WebSeries
//
//  Created by alvaro on 4/1/26.
//


import Foundation
import SwiftUI

@MainActor
final class FavoritesService: ObservableObject {

    @Published var favorites: Set<String> = []

    private let auth: AuthService

    init(auth: AuthService) {
        self.auth = auth
    }

    func loadFavorites() async {
        guard let token = auth.token else {
            print("⚠️ loadFavorites cancelado: no hay token.")
            return
        }

        do {
            let data = try await APIClient.request(
                endpoint: "/favorites",
                token: token
            )

            let list = try JSONDecoder().decode([FavoriteDTO].self, from: data)
            favorites = Set(list.map { $0.seriesId })
            print("✅ Favoritos cargados:", favorites.count)

        } catch {
            print("❌ Error cargando favoritos:", error)
        }
    }

    func toggleFavorite(seriesId: String) async {
        guard let token = auth.token else { return }

        do {
            let body = try JSONEncoder().encode([
                "seriesId": seriesId
            ])

            _ = try await APIClient.request(
                endpoint: "/favorites",
                method: "POST",
                body: body,
                token: token
            )

            if favorites.contains(seriesId) {
                favorites.remove(seriesId)
            } else {
                favorites.insert(seriesId)
            }

        } catch {
            print("❌ Error guardando favorito:", error)
        }
    }

    func isFavorite(_ seriesId: String) -> Bool {
        favorites.contains(seriesId)
    }
}

struct FavoriteDTO: Decodable {
    let seriesId: String
}
