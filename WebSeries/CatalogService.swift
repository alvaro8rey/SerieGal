//
//  CatalogService.swift
//  WebSeries
//

import Foundation

@MainActor
final class CatalogService: ObservableObject {

    @Published var catalog: Catalog?
    @Published var error: String?

    func load() async {

        let urlString = ServerConfig.webBaseURL + "/catalog.json"

        debugLog("📡 Intentando cargar catálogo desde:", urlString)

        guard let url = URL(string: urlString) else {
            error = "URL inválida"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let http = response as? HTTPURLResponse {
                debugLog("📥 HTTP status:", http.statusCode)
            }

            let decoder = JSONDecoder()
            let catalog = try decoder.decode(Catalog.self, from: data)

            debugLog("✅ Catálogo decodificado correctamente")
            debugLog("Series:", catalog.series.count)
            debugLog("Películas:", catalog.movies?.count ?? 0)

            self.catalog = catalog
            self.error = nil

        } catch {
            debugLog("❌ ERROR cargando catálogo:", error)
            self.error = error.localizedDescription
        }
    }
}
