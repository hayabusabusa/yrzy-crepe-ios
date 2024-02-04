//
//  CrepeApp.swift
//  App
//
//  Created by Shunya Yamada on 2024/01/07.
//

import AppFeature
import ComposableArchitecture
import SwiftUI

@main
struct CrepeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView(store: appDelegate.store)
        }
    }
}
