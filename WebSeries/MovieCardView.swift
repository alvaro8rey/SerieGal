import SwiftUI

struct MovieCardView: View {

    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            AsyncImage(
                url: URL(string: ServerConfig.webBaseURL + "/images/\(movie.id).jpg")

            ) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 150, height: 220)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

            Text(movie.title)
                .font(.headline)
                .foregroundColor(.serieGalText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(movie.year)
                .font(.caption)
                .foregroundColor(.serieGalSecondary)
        }
        .frame(width: 150, alignment: .leading)
    }
}
