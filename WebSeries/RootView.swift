import SwiftUI

struct RootView: View {

    @StateObject private var auth: AuthService
    @StateObject private var favorites: FavoritesService
    @StateObject private var progress: ProgressService
    @StateObject private var downloads: DownloadService

    init() {
        let authService = AuthService()
        _auth = StateObject(wrappedValue: authService)
        _favorites = StateObject(wrappedValue: FavoritesService(auth: authService))
        _progress = StateObject(wrappedValue: ProgressService(auth: authService))
        _downloads = StateObject(wrappedValue: DownloadService())
    }

    var body: some View {
        Group {
            if auth.isLoggedIn {
                ContentView()
                    .environmentObject(auth)
                    .environmentObject(favorites)
                    .environmentObject(progress)
                    .environmentObject(downloads)
                    .task {
                        let validSession = await auth.ensureValidSession()
                        guard validSession else { return }
                        async let favoritesTask: Void = favorites.loadFavorites()
                        async let progressTask: Void = progress.loadContinueWatching()
                        _ = await (favoritesTask, progressTask)
                    }
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
    }
}
