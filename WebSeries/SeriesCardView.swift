import SwiftUI

struct SeriesCardView: View {

    let serie: Series

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            AsyncImage(
                url: URL(string: ServerConfig.webBaseURL + "/images/\(serie.id).jpg")
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
            }
            .frame(width: 150, height: 220)
            .clipped()
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

            Text(serie.title)
                .font(.headline)
                .foregroundColor(.serieGalText)
                .lineLimit(2)
        }
        .frame(width: 150, alignment: .leading)
    }
}
