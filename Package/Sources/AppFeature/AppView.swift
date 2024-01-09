//
//  AppView.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import SwiftUI

public struct AppView: View {
    public var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    AppView()
}
#endif
