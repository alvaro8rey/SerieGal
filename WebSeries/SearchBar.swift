import SwiftUI

struct SearchBar: View {

    @Binding var text: String
    let suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Buscar series ou películas…", text: $text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.serieGalSearchBackground)
            .cornerRadius(12)

            if !text.isEmpty {
                ForEach(filteredSuggestions, id: \.self) { suggestion in
                    Button {
                        text = suggestion
                    } label: {
                        Text(suggestion)
                            .foregroundColor(.serieGalText)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var filteredSuggestions: [String] {
        suggestions.filter {
            $0.lowercased().contains(text.lowercased())
        }
    }
}

