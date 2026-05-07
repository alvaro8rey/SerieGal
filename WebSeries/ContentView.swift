import SwiftUI

struct ContentView: View {

    @StateObject private var service = CatalogService()

    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var favorites: FavoritesService
    @EnvironmentObject var progress: ProgressService

    @State private var showSearch = false
    @State private var showFavorites = false
    @State private var hasPrefetchedInitialCovers = false
    @State private var featuredItems: [FeaturedItem] = []
    @State private var featuredSelection = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                content
            }
            .background(backgroundGradient.ignoresSafeArea())
            .fullScreenCover(isPresented: $showSearch) {
                if let catalog = service.catalog {
                    NavigationStack {
                        SearchFullScreenView(catalog: catalog)
                    }
                }
            }
            .navigationDestination(isPresented: $showFavorites) {
                if let catalog = service.catalog {
                    FavoritesView(catalog: catalog)
                }
            }
            .task {
                if service.catalog == nil && service.error == nil {
                    await service.load()
                }
                if let catalog = service.catalog {
                    if featuredItems.isEmpty {
                        refreshFeaturedItems(for: catalog)
                    }
                    if !hasPrefetchedInitialCovers {
                        hasPrefetchedInitialCovers = true
                        prefetchInitialCovers(for: catalog)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .progressUpdated)) { _ in
                Task {
                    await progress.loadContinueWatching()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 0) {
                    Text("Serie")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.serieGalText)

                    Text("Gal")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.serieGalBlue)
                }

                Spacer()

                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                        .foregroundColor(.serieGalText)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Menu {
                    Button {
                        showFavorites = true
                    } label: {
                        Label("Favoritos", systemImage: "star.fill")
                    }

                    Divider()

                    Button(role: .destructive) {
                        auth.logout()
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title3)
                        .foregroundColor(.serieGalText)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(.leading, 6)
                }
            }

            Text("Tu plataforma privada de series y películas")
                .font(.subheadline)
                .foregroundColor(.serieGalSecondary)

            quickActions
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var content: some View {

        if let catalog = service.catalog {
            let movies = catalog.movies ?? []
            let series = catalog.series

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 38) {
                    featuredCarousel(movies: movies, series: series)

                    if !continueItems.isEmpty {
                        ContinueWatchingView(items: continueItems)
                    }

                    if !movies.isEmpty {
                        sectionHeader(
                            title: "Películas",
                            subtitle: "Estrenos y favoritas de tu colección",
                            destination: MoviesListView(movies: movies)
                        )

                        HorizontalSlider {
                            ForEach(movies.prefix(12)) { movie in
                                NavigationLink {
                                    MovieDetailView(movie: movie)
                                } label: {
                                    MovieCardView(movie: movie)
                                }
                                .tint(.clear)
                            }
                        }
                    }

                    sectionHeader(
                        title: "Series",
                        subtitle: "Sagas para maratón",
                        destination: SeriesListView(series: series)
                    )

                    HorizontalSlider {
                        ForEach(series.prefix(12)) { serie in
                            NavigationLink {
                                SeriesDetailView(serie: serie)
                            } label: {
                                SeriesCardView(serie: serie)
                            }
                            .tint(.clear)
                        }
                    }

                    Spacer(minLength: 60)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }

        } else if let error = service.error {
            VStack(spacing: 10) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 34))
                    .foregroundColor(.serieGalBlue)

                Text("No se pudo cargar el catálogo")
                    .font(.headline)
                    .foregroundColor(.serieGalText)

                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.serieGalSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(Color.serieGalCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal)
            .padding(.top, 80)
        } else {
            ProgressView("Cargando catálogo…")
                .foregroundColor(.serieGalText)
                .padding(.top, 80)
        }
    }

    @ViewBuilder
    private func featuredCarousel(movies: [Movie], series: [Series]) -> some View {
        let items = featuredItemsForDisplay(movies: movies, series: series)
        if !items.isEmpty {
            VStack(spacing: 14) {
                TabView(selection: $featuredSelection) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        featuredHero(for: item)
                            .tag(index)
                    }
                }
                .frame(height: 320)
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 7) {
                    ForEach(items.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == featuredSelection ? Color.white : Color.white.opacity(0.35))
                            .frame(width: index == featuredSelection ? 18 : 7, height: 7)
                            .animation(.easeInOut(duration: 0.22), value: featuredSelection)
                    }
                }
            }
            .padding(.horizontal)
            .task(id: featuredRotationTaskID(for: items)) {
                guard items.count > 1 else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 6_500_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            featuredSelection = (featuredSelection + 1) % items.count
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader<Destination: View>(
        title: String,
        subtitle: String,
        destination: Destination
    ) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.serieGalText)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.serieGalSecondary)
            }

            Spacer()

            NavigationLink {
                destination
            } label: {
                HStack(spacing: 6) {
                    Text("Ver todo")
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                }
                .foregroundColor(.serieGalBlue)
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal)
    }

    private var continueItems: [ContinueItem] {
        guard let catalog = service.catalog else { return [] }

        return progress.continueWatching.compactMap { entry in
            let ratio = min(max(entry.ratio, 0), 1)
            guard ratio > 0.02 && ratio < 0.98 else { return nil }
            return continueItem(from: entry, catalog: catalog, ratio: ratio)
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.serieGalBackground,
                Color.serieGalSurface,
                Color.serieGalBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottom
        )
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickActionChip(icon: "tv.fill", title: "Series", count: service.catalog?.series.count)
                quickActionChip(icon: "film.fill", title: "Películas", count: service.catalog?.movies?.count)

                Button {
                    showFavorites = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                        Text("Favoritos")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.serieGalCardBackground)
                    .foregroundColor(.serieGalText)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func quickActionChip(icon: String, title: String, count: Int?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .fontWeight(.semibold)
            if let count {
                Text("\(count)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.serieGalBlue.opacity(0.22),
                                Color.serieGalViolet.opacity(0.22)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .font(.subheadline)
        .foregroundColor(.serieGalText)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.serieGalCardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func featuredItem(movies: [Movie], series: [Series]) -> FeaturedItem? {
        if let movie = movies.first {
            return .movie(movie)
        }
        if let serie = series.first {
            return .series(serie)
        }
        return nil
    }

    private func featuredItemsForDisplay(movies: [Movie], series: [Series]) -> [FeaturedItem] {
        if !featuredItems.isEmpty {
            return featuredItems
        }
        guard let featured = featuredItem(movies: movies, series: series) else {
            return []
        }
        return [featured]
    }

    private func featuredRotationTaskID(for items: [FeaturedItem]) -> String {
        items.map(\.stableID).joined(separator: "|")
    }

    private func refreshFeaturedItems(for catalog: Catalog) {
        let pool = (catalog.movies ?? []).map(FeaturedItem.movie) + catalog.series.map(FeaturedItem.series)
        guard !pool.isEmpty else {
            featuredItems = []
            featuredSelection = 0
            return
        }

        let selectionCount = min(pool.count, 7)
        featuredItems = Array(pool.shuffled().prefix(selectionCount))
        featuredSelection = 0
    }

    @ViewBuilder
    private func featuredHero(for featured: FeaturedItem) -> some View {
        switch featured {
        case .movie(let movie):
            featuredHeroCard(
                id: movie.id,
                title: movie.title,
                metadata: "Película · \(movie.year)",
                description: movie.description,
                isFavorite: favorites.isFavorite(movie.id),
                favoriteAction: {
                    Task {
                        await favorites.toggleFavorite(seriesId: movie.id)
                    }
                },
                primaryLabel: "Reproducir",
                primaryDestination: AnyView(
                    PlayerScreen(
                        episode: Episode(
                            id: movie.id,
                            title: movie.title,
                            url: movie.url
                        ),
                        seriesId: movie.id
                    )
                ),
                secondaryLabel: "Detalles",
                secondaryDestination: AnyView(MovieDetailView(movie: movie))
            )

        case .series(let serie):
            let firstEpisode = serie.normalizedSeasons.first?.episodes.first
            featuredHeroCard(
                id: serie.id,
                title: serie.title,
                metadata: "Serie · \(seriesInfo(for: serie))",
                description: "Descubre nuevos episodios y continúa tu maratón personal.",
                isFavorite: favorites.isFavorite(serie.id),
                favoriteAction: {
                    Task {
                        await favorites.toggleFavorite(seriesId: serie.id)
                    }
                },
                primaryLabel: "Continuar",
                primaryDestination: AnyView(
                    Group {
                        if let firstEpisode {
                            PlayerScreen(
                                episode: firstEpisode,
                                seriesId: serie.id
                            )
                        } else {
                            SeriesDetailView(serie: serie)
                        }
                    }
                ),
                secondaryLabel: "Episodios",
                secondaryDestination: AnyView(SeriesDetailView(serie: serie))
            )
        }
    }

    private func featuredHeroCard(
        id: String,
        title: String,
        metadata: String,
        description: String,
        isFavorite: Bool,
        favoriteAction: @escaping () -> Void,
        primaryLabel: String,
        primaryDestination: AnyView,
        secondaryLabel: String,
        secondaryDestination: AnyView
    ) -> some View {
        let coverURL = URL(string: ServerConfig.webBaseURL + "/images/\(id).jpg")

        ZStack(alignment: .bottomLeading) {
            ZStack {
                CachedAsyncImage(url: coverURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 18)
                        .overlay(Color.black.opacity(0.32))
                        .scaleEffect(1.08)
                } placeholder: {
                    Rectangle()
                        .fill(Color.serieGalCardBackground)
                }

                CachedAsyncImage(url: coverURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 9)
                        .frame(maxWidth: 230, maxHeight: 285, alignment: .topTrailing)
                        .padding(.top, 14)
                        .padding(.trailing, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 190, height: 270)
                        .padding(.top, 14)
                        .padding(.trailing, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(height: 320)
            .clipped()

            LinearGradient(
                colors: [
                    Color.serieGalBlue.opacity(0.2),
                    Color.serieGalViolet.opacity(0.25),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("DESTACADO")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [.serieGalBlue, .serieGalViolet],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())

                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(metadata)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    NavigationLink {
                        primaryDestination
                    } label: {
                        Label(primaryLabel, systemImage: "play.fill")
                            .font(.subheadline.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }

                    NavigationLink {
                        secondaryDestination
                    } label: {
                        Text(secondaryLabel)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.leading, 18)
            .padding(.top, 18)
            .padding(.bottom, 18)
            .padding(.trailing, 164)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: favoriteAction) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.headline)
                    .foregroundColor(isFavorite ? .yellow : .white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 16, x: 0, y: 8)
    }

    private func seriesInfo(for serie: Series) -> String {
        let seasonCount = serie.normalizedSeasons.count
        let episodeCount = serie.normalizedSeasons.reduce(0) { partial, season in
            partial + season.episodes.count
        }
        return "\(seasonCount) temporadas · \(episodeCount) episodios"
    }

    private func continueItem(
        from entry: ContinueWatchingEntry,
        catalog: Catalog,
        ratio: Double
    ) -> ContinueItem? {
        if let movie = (catalog.movies ?? []).first(where: { movie in
            idsMatch(movie.id, entry.seriesId) || idsMatch(movie.id, entry.episodeId)
        }) {
            return ContinueItem(
                id: entry.id,
                seriesId: movie.id,
                episode: Episode(
                    id: movie.id,
                    title: movie.title,
                    url: movie.url
                ),
                imageId: movie.id,
                title: movie.title,
                subtitle: "Película · \(movie.year)",
                progress: ratio,
                resumeTime: entry.time
            )
        }

        if let exactSeries = catalog.series.first(where: { idsMatch($0.id, entry.seriesId) }),
           let seriesItem = continueItemFromSeries(entry, series: [exactSeries], ratio: ratio) {
            return seriesItem
        }

        if let fallbackSeriesItem = continueItemFromSeries(entry, series: catalog.series, ratio: ratio) {
            return fallbackSeriesItem
        }

        guard let url = entry.url else { return nil }
        return ContinueItem(
            id: entry.id,
            seriesId: entry.seriesId,
            episode: Episode(
                id: entry.episodeId,
                title: entry.episodeTitle ?? "Continuar",
                url: url
            ),
            imageId: entry.seriesId,
            title: entry.episodeTitle ?? "Continuar viendo",
            subtitle: "Contenido guardado",
            progress: ratio,
            resumeTime: entry.time
        )
    }

    private func continueItemFromSeries(
        _ entry: ContinueWatchingEntry,
        series: [Series],
        ratio: Double
    ) -> ContinueItem? {
        for serie in series {
            for season in serie.normalizedSeasons {
                if let index = season.episodes.firstIndex(where: { idsMatch($0.id, entry.episodeId) }) {
                    let episode = season.episodes[index]
                    return ContinueItem(
                        id: entry.id,
                        seriesId: serie.id,
                        episode: episode,
                        imageId: serie.id,
                        title: serie.title,
                        subtitle: "Episodio \(index + 1): \(episode.title)",
                        progress: ratio,
                        resumeTime: entry.time
                    )
                }
            }
        }

        return nil
    }

    private func idsMatch(_ left: String, _ right: String) -> Bool {
        normalizedID(left) == normalizedID(right)
    }

    private func normalizedID(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func prefetchInitialCovers(for catalog: Catalog) {
        let movieURLs = (catalog.movies ?? [])
            .prefix(20)
            .compactMap { URL(string: ServerConfig.webBaseURL + "/images/\($0.id).jpg") }
        let seriesURLs = catalog.series
            .prefix(20)
            .compactMap { URL(string: ServerConfig.webBaseURL + "/images/\($0.id).jpg") }

        Task(priority: .utility) {
            await ImageCache.shared.prefetch(urls: movieURLs + seriesURLs)
        }
    }
}

private enum FeaturedItem {
    case movie(Movie)
    case series(Series)

    var stableID: String {
        switch self {
        case .movie(let movie):
            return "movie:\(movie.id)"
        case .series(let serie):
            return "series:\(serie.id)"
        }
    }
}
