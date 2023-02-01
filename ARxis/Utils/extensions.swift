//
//  extensions.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 20/09/2022.
//

import Foundation
import SwiftUI

extension Array where Element == NSItemProvider {
    func loadObjects<T>(
        ofType theType: T.Type,
        firstOnly: Bool = false,
        using load: @escaping (T) -> Void
    ) -> Bool where T: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            provider.loadObject(ofClass: theType) { object, _ in
                if let value = object as? T {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }

    func loadObjects<T>(
        ofType theType: T.Type,
        firstOnly: Bool = false,
        using load: @escaping (T) -> Void
    ) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            _ = provider.loadObject(ofClass: theType) { object, _ in
                if let value = object {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }

    func loadFirstObject<T>(
        ofType theType: T.Type,
        using load: @escaping (T) -> Void
    ) -> Bool where T: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }

    func loadFirstObject<T>(
        ofType theType: T.Type,
        using load: @escaping (T) -> Void
    ) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
}

extension Float {
    var toRadians: Float { self * .pi / 180 }
}
