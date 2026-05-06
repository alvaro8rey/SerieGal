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

        print("📡 Intentando cargar catálogo desde:")
        print(urlString)

        guard let url = URL(string: urlString) else {
            error = "URL inválida"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let http = response as? HTTPURLResponse {
                print("📥 HTTP status:", http.statusCode)
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("📦 JSON recibido:")
                print(raw)
            }

            let decoder = JSONDecoder()
            let catalog = try decoder.decode(Catalog.self, from: data)

            print("✅ Catálogo decodificado correctamente")
            print("Series:", catalog.series.count)
            print("Películas:", catalog.movies?.count ?? 0)

            self.catalog = catalog
            self.error = nil

        } catch {
            print("❌ ERROR cargando catálogo:")
            print(error)
            self.error = error.localizedDescription
        }
    }
}
