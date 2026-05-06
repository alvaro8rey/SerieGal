import SwiftUI

struct SearchFullScreenView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchSubmitted = false

    let catalog: Catalog

    var body: some View {
        VStack(spacing: 0) {

            // =========================
            // BARRA SUPERIOR
            // =========================
            HStack(spacing: 12) {

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.serieGalText)
                }

                TextField("Buscar series ou películas…", text: $searchText)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        Color(
                            uiColor: UIColor { trait in
                                trait.userInterfaceStyle == .dark
                                ? UIColor.white.withAlphaComponent(0.12)
                                : UIColor.black.withAlphaComponent(0.05)
                            }
                        )
                    )
                    .cornerRadius(12)
                    .foregroundColor(.serieGalText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        searchSubmitted = true
                    }
                    .onChange(of: searchText) { _ in
                        searchSubmitted = false
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchSubmitted = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.serieGalSecondary)
                    }
                }
            }
            .padding()
            .background(Color.serieGalBackground)

            // =========================
            // CONTENIDO
            // =========================
            Group {

                // 1️⃣ Vacío al abrir
                if searchText.isEmpty {
                    EmptyView()
                }

                // 2️⃣ Sugerencias mientras escribe
                else if !searchSubmitted {
                    suggestionsView
                }

                // 3️⃣ Resultados al pulsar intro
                else {
                    SearchResultsListView(
                        searchText: searchText,
                        catalog: catalog
                    )
                }
            }
            .animation(.easeInOut, value: searchText)

            Spacer()
        }
        .background(Color.serieGalBackground)
    }

    // =========================
    // SUGERENCIAS (SOLO TEXTO)
    // =========================
    private var suggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                ForEach(filteredSuggestions, id: \.self) { suggestion in
                    Button {
                        searchText = suggestion
                        searchSubmitted = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.serieGalSecondary)

                            Text(suggestion)
                                .foregroundColor(.serieGalText)

                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 20)
        }
    }

    private var filteredSuggestions: [String] {
        let all = catalog.series.map { $0.title } +
                  (catalog.movies?.map { $0.title } ?? [])

        return all
            .filter {
                $0.lowercased().contains(searchText.lowercased())
            }
            .prefix(10)
            .map { $0 }
    }
}
