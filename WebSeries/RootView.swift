import SwiftUI

struct RootView: View {

    @StateObject private var auth: AuthService
    @StateObject private var favorites: FavoritesService
    @StateObject private var progress: ProgressService

    init() {
        let authService = AuthService()
        _auth = StateObject(wrappedValue: authService)
        _favorites = StateObject(wrappedValue: FavoritesService(auth: authService))
        _progress = StateObject(wrappedValue: ProgressService(auth: authService))
    }

    var body: some View {
        Group {
            if auth.isLoggedIn {
                ContentView()
                    .environmentObject(auth)
                    .environmentObject(favorites)
                    .environmentObject(progress)
                    .task {
                        await favorites.loadFavorites()
                    }
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
    }
}
