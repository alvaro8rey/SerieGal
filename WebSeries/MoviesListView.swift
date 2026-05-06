//
//  MoviesListView.swift
//  WebSeries
//
//  Created by alvaro on 3/1/26.
//


import SwiftUI

struct MoviesListView: View {

    let movies: [Movie]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(movies) { movie in
                    NavigationLink {
                        MovieDetailView(movie: movie)
                    } label: {
                        HStack(spacing: 14) {
                            AsyncImage(
                                url: URL(string: ServerConfig.webBaseURL + "/images/\(movie.id).jpg")
                            ) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Rectangle().fill(Color.serieGalCardBackground)
                            }
                            .frame(width: 72, height: 106)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(movie.title)
                                    .font(.headline)
                                    .foregroundColor(.serieGalText)

                                Text("Película · \(movie.year)")
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
        .navigationTitle("Películas")
    }
}
