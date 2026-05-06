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
                        PlayerScreen(
                            episode: item.episode,
                            seriesId: item.seriesId,
                            startAtTime: item.resumeTime
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            CachedAsyncImage(url: URL(string: ServerConfig.webBaseURL + "/images/\(item.imageId).jpg")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.serieGalCardBackground)
                            }
                            .frame(width: 180, height: 102)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(alignment: .bottom) {
                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.black.opacity(0.4))
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.serieGalBlue, .serieGalViolet],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: proxy.size.width * min(max(item.progress, 0), 1))
                                    }
                                }
                                .frame(height: 6)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.serieGalText)
                                .lineLimit(1)

                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundColor(.serieGalSecondary)
                                .lineLimit(1)
                        }
                        .frame(width: 180, alignment: .leading)
                    }
                    .tint(.clear)
                }
            }
        }
    }
}

struct ContinueItem: Identifiable {
    let id: String
    let seriesId: String
    let episode: Episode
    let imageId: String
    let title: String
    let subtitle: String
    let progress: Double
    let resumeTime: Double?
}
