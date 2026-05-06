import SwiftUI

struct SeriesCardView: View {

    let serie: Series

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(
                url: URL(string: ServerConfig.webBaseURL + "/images/\(serie.id).jpg")
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.serieGalCardBackground)
                    .overlay(
                        ProgressView()
                            .tint(.serieGalBlue)
                    )
            }
            .frame(width: 162, height: 242)
            .clipped()

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(serie.title)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text("\(serie.normalizedSeasons.count) temporadas")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
        }
        .frame(width: 162, height: 242)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 8, x: 0, y: 5)
    }
}
