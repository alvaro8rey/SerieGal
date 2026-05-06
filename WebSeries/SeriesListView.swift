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
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(series) { serie in
                    NavigationLink {
                        SeriesDetailView(serie: serie)
                    } label: {
                        HStack(spacing: 14) {
                            CachedAsyncImage(
                                url: URL(string: ServerConfig.webBaseURL + "/images/\(serie.id).jpg")
                            ) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.serieGalCardBackground)
                            }
                            .frame(width: 72, height: 106)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(serie.title)
                                    .font(.headline)
                                    .foregroundColor(.serieGalText)

                                Text(seriesInfo(for: serie))
                                    .font(.subheadline)
                                    .foregroundColor(.serieGalSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.serieGalTertiary)
                        }
                        .padding(14)
                        .background(Color.serieGalCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color.serieGalBackground, Color.serieGalSurface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Series")
    }

    // MARK: - Info series
    private func seriesInfo(for serie: Series) -> String {
        let seasons = serie.normalizedSeasons.count
        let episodes = serie.normalizedSeasons.reduce(0) { partial, season in
            partial + season.episodes.count
        }

        return "\(seasons) temporadas · \(episodes) episodios"
    }
}
