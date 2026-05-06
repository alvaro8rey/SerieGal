import SwiftUI

struct ContentView: View {

    @StateObject private var service = CatalogService()

    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var favorites: FavoritesService
    @EnvironmentObject var progress: ProgressService

    @State private var showSearch = false
    @State private var showFavorites = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // =========================
                // HEADER FIJO
                // =========================
                header

                // =========================
                // CONTENIDO
                // =========================
                content
            }
            .background(Color.serieGalBackground)
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
        }
    }

    // =========================
    // HEADER
    // =========================
    private var header: some View {
        VStack {
            HStack {

                // LOGO
                HStack(spacing: 0) {
                    Text("Serie")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.serieGalText)

                    Text("Gal")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.serieGalBlue)
                }

                Spacer()

                // BUSCAR
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.serieGalText)
                }

                // MENÚ USUARIO
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
                        .font(.title2)
                        .foregroundColor(.serieGalText)
                        .padding(.leading, 8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.serieGalBackground)
    }

    // =========================
    // CONTENIDO PRINCIPAL
    // =========================
    @ViewBuilder
    private var content: some View {

        if let catalog = service.catalog {

            let movies = catalog.movies ?? []
            let series = catalog.series

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 48) {

                    // =========================
                    // SEGUIR VIENDO
                    // =========================
                    if !continueItems.isEmpty {
                        ContinueWatchingView(items: continueItems)
                    }

                    // =========================
                    // PELÍCULAS
                    // =========================
                    if !movies.isEmpty {
                        sectionHeader(
                            title: "Películas",
                            destination: MoviesListView(movies: movies)
                        )

                        HorizontalSlider {
                            ForEach(movies.prefix(10)) { movie in
                                NavigationLink {
                                    MovieDetailView(movie: movie)
                                } label: {
                                    MovieCardView(movie: movie)
                                }
                                .tint(.clear)
                            }
                        }
                    }

                    // =========================
                    // SERIES
                    // =========================
                    sectionHeader(
                        title: "Series",
                        destination: SeriesListView(series: series)
                    )

                    HorizontalSlider {
                        ForEach(series.prefix(10)) { serie in
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
                .padding(.top, 24)
            }

        } else if let error = service.error {
            Text("Error: \(error)")
                .foregroundColor(.serieGalText)
                .padding()
        } else {
            ProgressView("Cargando catálogo…")
                .foregroundColor(.serieGalText)
                .task {
                    await service.load()
                }
                .padding(.top, 80)
        }
    }

    // =========================
    // HEADER DE SECCIÓN
    // =========================
    private func sectionHeader<Destination: View>(
        title: String,
        destination: Destination
    ) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.serieGalText)

            Spacer()

            NavigationLink {
                destination
            } label: {
                Text("Ver máis")
                    .foregroundColor(.serieGalBlue)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }

    // =========================
    // CONTINUE WATCHING (stub)
    // =========================
    private var continueItems: [ContinueItem] {
        // 🔜 En el siguiente paso lo conectamos al backend (/progress/all)
        []
    }
}
