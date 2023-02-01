//
//  ECS.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 05/10/2022.
//

import Foundation
import RealityKit

class ARXisSystem: System {
    required init(scene: Scene) {}

    private static let query = EntityQuery(where: .has(IsFOV.self))

    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).compactMap { $0 as? FOVEntity }.forEach { fov in
            fov.sceneManager.setSeesIpad(for: fov)
            fov.sceneManager.setPixelDensity(for: fov)
            fov.sceneManager.setLensPosition(for: fov)
        }
    }
}
