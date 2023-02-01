//
//  SceneManager.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 20/09/2022.
//

import ARKit
import Foundation
import RealityKit

fileprivate extension UIColor {
    static func random(alpha: CGFloat) -> UIColor {
        let colors: [UIColor] = [.red, .magenta, .green, .blue, .cyan, .purple, .yellow]
        return colors.randomElement()!.withAlphaComponent(alpha)
    }
}

struct LensPosition {
    let pos: CGPoint
    let isInFront: Bool
}

class SceneManager: ObservableObject {
    let arView: ARView
    private let device = MTLCreateSystemDefaultDevice()!
    private var library: MTLLibrary {
        device.makeDefaultLibrary()!
    }

    @Published var cameras: [CameraInScene] = []
    @Published var lensesPositions: [UInt64?: LensPosition] = [:]

    init(arView: ARView) {
        self.arView = arView
    }

    func placeCamera(_ camera: CameraModel, transform: simd_float4x4) {
        let anchor = AnchorEntity(world: transform)
        let object = camera.getNew()

        let fov = createFOV(height: 0.4, fov: camera.defaultFOV, culling: .none)
        let coneAnchor = Entity()

        coneAnchor.orientation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])

        coneAnchor.addChild(fov)
        anchor.addChild(object)
        
        let lensEntity = object.findEntity(named: camera.lensPart)!
        
        lensEntity.addChild(coneAnchor)
//        fov.look(at: [0, 0, 1], from: [0, 0, 0], relativeTo: lensEntity)

        arView.scene.anchors.append(anchor)
        arView.installGestures(.translation, for: object)
        cameras.append(CameraInScene(anchor: anchor, model: camera, fov: fov))
    }

    func createFOV(height: Float, fov: (v: Float, h: Float), culling: CustomMaterial.FaceCulling, materials: [Material]? = nil) -> FOVEntity {
        if let materials = materials {
            return FOVEntity(height: height, fov: fov, materials: materials, sceneManager: self)
        }

        let material = SimpleMaterial(color: .random(alpha: 0.6), isMetallic: false)

        var custom1 = try! CustomMaterial(
            from: material,
            geometryModifier: .init(named: "emptyGeometryModifier", in: library)
        )
        custom1.faceCulling = culling
        custom1.baseColor = .init(tint: material.color.tint)

        return FOVEntity(height: height, fov: fov, materials: [custom1], sceneManager: self)
    }

    func setFovHeight(of camera: CameraInScene, to height: Float) {
        let index = cameras.index(of: camera)
        let newHeight = min((1/(-height + 1)) - 1, 100)
        cameras[index].replaceFov(createFOV(height: newHeight, fov: camera.fov.fov, culling: .none, materials: camera.fov.model?.materials))
    }

    func setDistanceToFloor(for entity: FOVEntity) {
        guard let camera = getCamera(for: entity.anchor!.id), camera.distanceToFloor != nil else {
            return
        }
    }

    func getCamera(at point: CGPoint) -> CameraInScene? {
        let res = arView.hitTest(point)
        if let first = res.first {
            let id = first.entity.anchor?.id
            return cameras.first {
                $0.anchor.id == id
            }
        }
        return nil
    }

    func removeCamera(_ camera: CameraInScene) {
        camera.anchor.removeFromParent()
        cameras.removeAll {
            $0.id == camera.id
        }
    }

    func getCamera(for id: UInt64) -> CameraInScene? {
        cameras.first(where: { $0.anchor.id == id })
    }

    func setSeesIpad(for entity: FOVEntity) {
        guard let camera = getCamera(for: entity.anchor!.id) else {
            return
        }

        let ipadEntity = arView.getSelfEntity()
        let relativeIpadPos = ipadEntity.position(relativeTo: entity)

        let x = relativeIpadPos.y * tan(entity.fov.v.toRadians / 2)
        let z = relativeIpadPos.y * tan(entity.fov.h.toRadians / 2)

        let seesIpad = x > abs(relativeIpadPos.x) && z > abs(relativeIpadPos.z)
        cameras[cameras.index(of: camera)].seesIpad = seesIpad
        
        if !seesIpad {
            return
        }

        guard let (camPos, _) = self.getCamVector() else {
            return
        }
        let dir = camera.cameraEntity.position(relativeTo: nil) - camPos
        let rcQuery = ARRaycastQuery(
            origin: camPos, direction: dir,
            allowing: .estimatedPlane, alignment: .any
        )
        let result = self.arView.session.raycast(rcQuery)
        if let hit = result.first {
            let pos = hit.worldTransform.columns.3
            let leng = ([pos.x, pos.y, pos.z] - camera.cameraEntity.position(relativeTo: nil)).length
            if leng > 0.09 { // chosen arbitrarily
                cameras[cameras.index(of: camera)].seesIpad = false
            }
        }
    }

    func setPixelDensity(for entity: FOVEntity) {
        // We calculate pixel density based on the camera's (currently set) horizontal field of view (angle), the
        // sensor's horizontal pixel count and the distance to the target. Pixel density at the target = sensor's
        // horizontal pixel count / (( horizontal field of view / 180 ) * Pi * the distance to the target ).
        guard let camera = getCamera(for: entity.anchor!.id) else {
            return
        }

        let ipadEntity = arView.getSelfEntity()
        let dist = ipadEntity.position(relativeTo: entity).length
        let spec = camera.model.spec

        // TODO: fov.v is really fov.h
        cameras[cameras.index(of: camera)].pixelDensity = (Double(spec.resolution.0) / Double(camera.fov.fov.v.toRadians * dist)) / 5.0
    }

    func setLensPosition(for fov: FOVEntity) {
        
//        let projection = arView.project(fov.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
        let relPos = fov.position(relativeTo: arView.getSelfEntity())
        
        let lensPos = LensPosition(
            pos: arView.project(fov.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1),
            isInFront: relPos.z < 0
        )
        
        lensesPositions[fov.id] = lensPos
    }


    func toggleCone(for camera: CameraInScene) {
        let index = cameras.index(of: camera)
        cameras[index].toggleFOVCone()
    }
    
    func placeCamera(ofType cameraModelId: String) {
        guard let (camPos, camDir) = self.getCamVector() else {
            return
        }
        let rcQuery = ARRaycastQuery(
            origin: camPos, direction: camDir,
            allowing: .estimatedPlane, alignment: .any
        )
        let result = self.arView.session.raycast(rcQuery)
        if let hit = result.first, let camera = CAMERAS.first(where: { $0.id == cameraModelId }) {
            self.placeCamera(camera, transform: hit.worldTransform)
        }
    }
    
    internal func getCamVector() -> (position: SIMD3<Float>, direciton: SIMD3<Float>)? {
        let camTransform = self.arView.cameraTransform
        let camDirection = camTransform.matrix.columns.2
        return (camTransform.translation, -[camDirection.x, camDirection.y, camDirection.z])
    }
}

extension Array where Element == CameraInScene {
    func index(of camera: CameraInScene) -> Int {
        firstIndex(where: { $0.id == camera.id })!
    }
}

extension ARView {
    func getSelfEntity() -> Entity {
        let entity = Entity()
        let p = cameraTransform.matrix.columns.3
        entity.move(to: Transform(translation: [p.x, p.y, p.z]), relativeTo: nil)
        entity.transform.rotation = cameraTransform.rotation
        return entity
    }
}
