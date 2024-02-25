//
//  GallerySectionTitleView.swift
//
//
//  Created by Shunya Yamada on 2024/01/12.
//

import SwiftUI

struct GallerySectionTitleView: View {
    var title: String
    var buttonTitle: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                action()
            }, label: {
                HStack(spacing: 4) {
                    Text(buttonTitle)
                        .font(.caption)

                    Image(systemName: "chevron.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                }
            })
        }
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 8, trailing: 16))
    }
}

#if DEBUG
#Preview {
    GallerySectionTitleView(
        title: "最近追加された作品",
        buttonTitle: "もっとみる",
        action: {}
    )
}
#endif
