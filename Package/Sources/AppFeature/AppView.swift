//
//  AppView.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import GalleryFeature
import SwiftUI

public struct AppView: View {
    public var body: some View {
        GalleryView()
    }

    public init() {}
}

#if DEBUG
#Preview {
    AppView()
}
#endif
