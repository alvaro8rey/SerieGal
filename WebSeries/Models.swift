import Foundation

// MARK: - Catalog

struct Catalog: Decodable {
    let title: String
    let series: [Series]
    let movies: [Movie]?
}

// MARK: - Series

struct Series: Decodable, Identifiable {
    let id: String
    let title: String
    let lang: String?
    let type: String?

    // JSON puede traer UNA de estas dos
    let seasons: [Season]?
    let episodes: [Episode]?

    /// Normaliza series con y sin temporadas
    var normalizedSeasons: [Season] {
        if let seasons = seasons {
            return seasons
        }
        if let episodes = episodes {
            return [
                Season(
                    season: 1,
                    title: "Temporada 1",
                    episodes: episodes
                )
            ]
        }
        return []
    }
}

// MARK: - Season

struct Season: Decodable, Identifiable {
    let season: Int
    let title: String
    let episodes: [Episode]

    var id: Int { season }
}

// MARK: - Episode

struct Episode: Decodable, Identifiable {
    let id: String
    let title: String
    let url: String

    /// URL HLS del episodio (contenido web, NO API)
    var streamURL: URL? {
        URL(string: ServerConfig.webBaseURL + url)
    }
}

// MARK: - Movie

struct Movie: Decodable, Identifiable {
    let id: String
    let title: String
    let lang: String
    let url: String
    let type: String
    let description: String
    let year: String

    /// URL HLS de la película (contenido web, NO API)
    var streamURL: URL? {
        URL(string: ServerConfig.webBaseURL + url)
    }
}
