//
//  Entities.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 05/10/2022.
//

import Foundation
import RealityKit

typealias FOV_T = (v: Float, h: Float)

struct IsFOV: Component {
    let sceneManager: SceneManager
}

class FOVEntity: Entity, HasModel {
    required init() {}

    var sceneManager: SceneManager {
        components[IsFOV.self]!.sceneManager
    }

    var height: Float = -1
    var fov: FOV_T = (v: -1, h: -1)

    init(height: Float, fov: FOV_T, materials: [Material], sceneManager: SceneManager) {
        super.init()
        self.name = "fov"

        let mesh = try! MeshResource.generatePyramid(height: height, horizontalFOV: fov.h, verticalFOV: fov.v)

        model = ModelComponent(mesh: mesh, materials: materials)
        components[IsFOV.self] = IsFOV(sceneManager: sceneManager)

        self.height = height
        self.fov = fov
        createEdges()
    }

    private func createEdges() {
        let x = height * tan(fov.v.toRadians / 2)
        let z = height * tan(fov.h.toRadians / 2)

        var edges: [Entity] = []
        let depth = length(SIMD3([x, height, z]))
        for _ in 0..<4 {
            edges.append(createBox(depth: depth))
        }

        edges[0].look(
                at: SIMD3([x, height, z]).normalised,
                from: SIMD3([x / 2, height / 2, z / 2]),
                relativeTo: self
        )
        edges[1].look(
                at: SIMD3([x, height, -z]).normalised,
                from: SIMD3([x / 2, height / 2, -z / 2]),
                relativeTo: self
        )
        edges[2].look(
                at: SIMD3([-x, height, z]).normalised,
                from: SIMD3([-x / 2, height / 2, z / 2]),
                relativeTo: self
        )
        edges[3].look(
                at: SIMD3([-x, height, -z]).normalised,
                from: SIMD3([-x / 2, height / 2, -z / 2]),
                relativeTo: self
        )

        children.append(contentsOf: edges)
    }
}

private func createBox(depth: Float) -> ModelEntity {
    let box = MeshResource.generateBox(width: 0.005, height: 0.005, depth: depth)
    let material = UnlitMaterial(color: .black)
    let boxEntity = ModelEntity(mesh: box, materials: [material])
    return boxEntity
}
