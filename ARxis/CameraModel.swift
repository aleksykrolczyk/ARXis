//
//  CameraModel.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 12/10/2022.
//

import Foundation
import RealityKit
import SwiftUI

struct CameraModel: Identifiable {
    var id: String {
        name
    }

    let name: String
    let model: ModelEntity
    let image: UIImage
    let spec: TechnicalSpec

    let rotatablePart: String
    let lensPart: String

    var defaultFOV: FOV_T {
        (v: spec.vFOV.upperBound, h: spec.hFOV.upperBound)
    }

    fileprivate init(name: String, rotatablePart: String, lensPart: String, spec: TechnicalSpec) {
        self.name = name
        self.spec = spec
        self.rotatablePart = rotatablePart
        self.lensPart = lensPart

        let entity = try! Entity.load(named: "\(name)")

        entity.generateCollisionShapes(recursive: true)
        model = ModelEntity()
        model.addChild(entity)

        image = UIImage(named: "CameraModels/\(name).png") ?? UIImage(systemName: "chevron.up")!
    }

    func getNew() -> ModelEntity {
        model.clone(recursive: true)
    }
}

let CAMERAS: [CameraModel] = [
    CameraModel(
        name: "M4216_LV",
        rotatablePart: "OurLens",
        lensPart: "OurLens",
        spec: TechnicalSpec(
            resolution: (2304, 1728),
            vFOV: 45 ... 100,
            hFOV: 34 ... 72
        )
    ),
    CameraModel(
        name: "P1375-E",
        rotatablePart: "OurPart",
        lensPart: "OurLens",
        spec: TechnicalSpec(
            resolution: (1920, 1080),
            vFOV: 42 ... 107,
            hFOV: 24 ... 57
        )
    ),
    CameraModel(
        name: "P1375",
        rotatablePart: "OurPart",
        lensPart: "OurLens",
        spec: TechnicalSpec(
            resolution: (1920, 1080),
            vFOV: 42 ... 124,
            hFOV: 24 ... 65
        )
    ),
]

func createBox(size: Float) -> ModelEntity {
    let box = MeshResource.generateBox(size: size)
    let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
    let boxEntity = ModelEntity(mesh: box, materials: [material])
    boxEntity.generateCollisionShapes(recursive: true)
    return boxEntity
}

func createSphere(radius: Float) -> ModelEntity {
    let sphere = MeshResource.generateSphere(radius: radius)
    let material = SimpleMaterial(color: .red, roughness: 0.5, isMetallic: true)

    let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
    sphereEntity.generateCollisionShapes(recursive: true)

    return sphereEntity
}
