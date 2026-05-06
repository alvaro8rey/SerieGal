//
//  SeriesListView.swift
//  WebSeries
//
//  Created by alvaro on 3/1/26.
//


import SwiftUI

struct SeriesListView: View {

    let series: [Series]

    var body: some View {
        List(series) { serie in
            NavigationLink {
                SeriesDetailView(serie: serie)
            } label: {
                HStack(spacing: 12) {

                    // Carátula
                    AsyncImage(
                        url: URL(string: ServerConfig.webBaseURL + "/images/\(serie.id).jpg")
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 90)
                    .clipped()
                    .cornerRadius(8)

                    // Texto
                    VStack(alignment: .leading, spacing: 4) {
                        Text(serie.title)
                            .font(.headline)
                            .foregroundColor(.serieGalText)

                        Text(seriesInfo(for: serie))
                            .font(.subheadline)
                            .foregroundColor(.serieGalSecondary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Series")
        .listStyle(.plain)
    }

    // MARK: - Info series
    private func seriesInfo(for serie: Series) -> String {
        let seasons = serie.seasons?.count ?? 0
        let episodes = serie.seasons?
            .flatMap { $0.episodes }
            .count ?? 0

        return "\(seasons) temporadas · \(episodes) episodios"
    }
}
