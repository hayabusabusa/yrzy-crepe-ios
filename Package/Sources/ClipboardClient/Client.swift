//
//  ClipboardClient.swift
//
//
//  Created by Shunya Yamada on 2024/05/01.
//

import Dependencies
import UIKit

/// `UIPasteboard` をラップしたクライアント.
public struct ClipboardClient {
    /// クリップボードに文字をセットする.
    public var setString: @Sendable (String) -> Void
    /// クリップボードにセットされた文字があれば返す.
    public var getString: @Sendable () -> String?

    public init(
        setString: @escaping @Sendable (String) -> Void,
        getString: @escaping @Sendable () -> String?
    ) {
        self.setString = setString
        self.getString = getString
    }
}

extension ClipboardClient: TestDependencyKey {
    public static var previewValue: ClipboardClient {
        .init { _ in
            
        } getString: {
            return nil
        }
    }

    public static var testValue: ClipboardClient {
        .init { _ in
            unimplemented("\(Self.self)\(#function)")
        } getString: {
            unimplemented("\(Self.self)\(#function)")
        }
    }
}

extension ClipboardClient: DependencyKey {
    public static var liveValue: ClipboardClient {
        .init { string in
            UIPasteboard.general.string = string
        } getString: {
            UIPasteboard.general.string
        }
    }
}

extension DependencyValues {
    public var clipboardClient: ClipboardClient {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue }
    }
}
