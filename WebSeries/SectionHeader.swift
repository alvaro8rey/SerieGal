//
//  SectionHeader.swift
//  WebSeries
//
//  Created by alvaro on 3/1/26.
//
import SwiftUI

struct SectionHeader: View {

    let title: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button(action: action) {
                Text(actionTitle)
                    .foregroundColor(.serieGalBlue)
            }
        }
        .padding(.horizontal)
    }
}
