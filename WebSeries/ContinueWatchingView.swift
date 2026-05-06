//
//  ContinueWatchingView.swift
//  WebSeries
//
//  Created by alvaro on 4/1/26.
//


import SwiftUI

struct ContinueWatchingView: View {

    let items: [ContinueItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Seguir viendo")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.serieGalText)
                .padding(.horizontal)

            HorizontalSlider {
                ForEach(items) { item in
                    NavigationLink {
                        PlayerScreen(episode: item.episode)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {

                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 160, height: 90)
                                .overlay(
                                    ProgressView(value: item.progress)
                                        .tint(.serieGalBlue)
                                        .padding(6),
                                    alignment: .bottom
                                )

                            Text(item.title)
                                .font(.caption)
                                .foregroundColor(.serieGalText)
                                .lineLimit(1)
                        }
                    }
                    .tint(.clear)
                }
            }
        }
    }
}

struct ContinueItem: Identifiable {
    let id: String
    let episode: Episode
    let title: String
    let progress: Double
}
