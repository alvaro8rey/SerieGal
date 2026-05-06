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
        List(movies) { movie in
            NavigationLink {
                MovieDetailView(movie: movie)
            } label: {
                HStack(spacing: 12) {

                    AsyncImage(
                        url: URL(string: ServerConfig.webBaseURL + "/images/\(movie.id).jpg")
                    ) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.title)
                            .font(.headline)
                            .foregroundColor(.serieGalText)

                        Text(movie.year)
                            .font(.subheadline)
                            .foregroundColor(.serieGalSecondary)
                    }
                }
            }
        }
        .navigationTitle("Películas")
        .listStyle(.plain)
    }
}
