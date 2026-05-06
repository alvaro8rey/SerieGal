//
//  HorizontalSlider.swift
//  WebSeries
//
//  Created by alvaro on 3/1/26.
//

import SwiftUI

struct HorizontalSlider<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                content
            }
            .padding(.horizontal)
        }
    }
}
