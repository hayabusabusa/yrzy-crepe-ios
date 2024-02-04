//
//  Live.swift
//
//
//  Created by Shunya Yamada on 2024/02/04.
//

@_exported import FirebaseClient
import FirebaseCore
import Foundation
import Dependencies

extension FirebaseClient: DependencyKey {
    public static var liveValue: FirebaseClient {
        .init {
            FirebaseApp.configure()
        }
    }
}
