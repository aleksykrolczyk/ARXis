//
//  MeshResource.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 27/09/2022.
//

import Foundation
import RealityKit

extension MeshResource {
    fileprivate static func coneIndices(
        _ sides: Int, _ lowerCenterIndex: UInt32, _ splitFaces: Bool,
        _ smoothNormals: Bool
    ) -> ([UInt32], [UInt32]) {
        var indices: [UInt32] = []
        var materialIndices: [UInt32] = []
        let uiSides = UInt32(sides) * (smoothNormals ? 1 : 2)
        for side in 0 ..< UInt32(sides) {
            let uiSideSmooth = side * (smoothNormals ? 1 : 2)
            let bottomLeft = uiSideSmooth
            let bottomRight = uiSideSmooth + 1
            let topVertex = side + uiSides + 1

            // First triangle of side
            indices.append(contentsOf: [bottomLeft, topVertex, bottomRight])

            // Add bottom cap triangle
            indices.append(contentsOf: [0, side + 1, side + 2].map { $0 + lowerCenterIndex })

            if splitFaces {
                materialIndices.append(0)
                materialIndices.append(1)
            }
        }
        return (indices, materialIndices)
    }

    fileprivate struct ConeVertices {
        var lowerEdge: [CompleteVertex]
        var upperEdge: [CompleteVertex]
        var lowerCap: [CompleteVertex]
        var combinedVerts: [CompleteVertex]?
        var indices: [UInt32]?
        var materialIndices: [UInt32]?
        var smoothNormals: Bool

        mutating func calculateDetails(
            height: Float, sides: Int, splitFaces: Bool
        ) -> Bool {
            let halfHeight = height / 2
            var vertices = lowerEdge
            vertices.append(contentsOf: upperEdge)

            let lowerCenterIndex = UInt32(vertices.count)
            vertices.append(CompleteVertex(
                position: [0, -halfHeight, 0], normal: [0, -1, 0], uv: [0.5, 0.5]
            ))

            vertices.append(contentsOf: lowerCap)
            self.combinedVerts = vertices
            (self.indices, self.materialIndices) = coneIndices(
                sides, lowerCenterIndex, splitFaces, self.smoothNormals
            )
            return true
        }
    }

    fileprivate static func coneVertices(
        _ sides: Int, _ radius: Float, _ height: Float, _ smoothNormals: Bool = false
    ) -> ConeVertices {
        var theta: Float = 0
        let thetaInc = 2 * .pi / Float(sides)
        let uStep: Float = 1 / Float(sides)
        // first vertices added will be bottom edges
        var vertices = [CompleteVertex]()
        // all top edge vertices of the cylinder
        var upperEdgeVertices = [CompleteVertex]()
        // bottom edge vertices
        var lowerCapVertices = [CompleteVertex]()

        let hyp = sqrtf(radius * radius + height * height)
        let coneNormX = radius / hyp
        let coneNormY = height / hyp
        // create vertices for all sides of the cylinder
        for side in 0 ... sides {
            let cosTheta = cos(theta)
            let sinTheta = sin(theta)

            let lowerPosition: SIMD3<Float> = [radius * cosTheta, -height / 2, radius * sinTheta]
            let coneBottomNormal: SIMD3<Float> = [coneNormY * cosTheta, coneNormX, coneNormY * sinTheta]

            if side != 0, !smoothNormals {
                vertices.append(CompleteVertex(
                    position: lowerPosition,
                    normal: [coneNormY * cos(theta - thetaInc / 2), coneNormX, coneNormY * sin(theta - thetaInc / 2)],
                    uv: [1 - uStep * Float(side), 0]
                ))
            }

            let bottomVertex = CompleteVertex(
                position: lowerPosition,
                normal: smoothNormals ? coneBottomNormal : [
                    coneNormY * cos(theta + thetaInc / 2), coneNormX, coneNormY * sin(theta + thetaInc / 2),
                ],
                uv: [1 - uStep * Float(side), 0]
            )

            // add vertex for bottom side of cone
            vertices.append(bottomVertex)

            // add vertex for bottom side facing down
            lowerCapVertices.append(CompleteVertex(
                position: bottomVertex.position,
                normal: [0, -1, 0], uv: [cosTheta + 1, sinTheta + 1] / 2)
            )

            let coneTopNormal: SIMD3<Float> = [
                coneNormY * cos(theta + thetaInc / 2), coneNormX,
                coneNormY * sin(theta + thetaInc / 2),
            ]

            // add vertex for top of the cone
            let topVertex = CompleteVertex(
                position: [0, height / 2, 0],
                normal: coneTopNormal, uv: [1 - uStep * (Float(side) + 0.5), 1]
            )
            upperEdgeVertices.append(topVertex)

            theta += thetaInc
        }

        return .init(
            lowerEdge: vertices,
            upperEdge: upperEdgeVertices,
            lowerCap: lowerCapVertices,
            smoothNormals: smoothNormals
        )
    }

    /// Creates a new cone mesh with the specified values 🍦
    /// - Parameters:
    ///   - radius: Radius of the code base
    ///   - height: Height of the code from base to tip
    ///   - sides: How many sides the cone should have, default is 24, minimum is 3
    ///   - splitFaces: A Boolean you set to true to indicate that vertices shouldn’t be merged.
    ///   - smoothNormals: Whether to smooth the normals. Good for high numbers of sides to give a rounder shape.
    ///                    Smoothed normal setting also reduces the total number of vertices
    /// - Returns: A cone mesh
    public static func generateCone(
        radius: Float, height: Float, sides: Int = 24, splitFaces: Bool = false,
        smoothNormals: Bool = false
    ) throws -> MeshResource {
        assert(sides > 2, "Sides must be an integer above 2")
        // first vertices added to vertices will be bottom edges
        // upperEdgeVertices are all top edge vertices of the cylinder
        // lowerCapVertices are the bottom edge vertices
        var coneVerties = coneVertices(sides, radius, height, smoothNormals)
        if !coneVerties.calculateDetails(
            height: height, sides: sides, splitFaces: splitFaces
        ) {
            assertionFailure("Could not calculate cone")
        }
        let meshDescr = coneVerties.combinedVerts!.generateMeshDescriptor(
            with: coneVerties.indices!, materials: coneVerties.materialIndices!
        )
        return try MeshResource.generate(from: [meshDescr])
    }
}

internal struct CompleteVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var uv: SIMD2<Float>
}

internal extension Array where Element == CompleteVertex {
    func generateMeshDescriptor(
        with indices: [UInt32], materials: [UInt32] = []
    ) -> MeshDescriptor {
        var meshDescriptor = MeshDescriptor()
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        for vx in self {
            positions.append(vx.position)
            normals.append(vx.normal)
            uvs.append(vx.uv)
        }
        meshDescriptor.positions = MeshBuffers.Positions(positions)
        meshDescriptor.normals = MeshBuffers.Normals(normals)
        meshDescriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        meshDescriptor.primitives = .triangles(indices)
        if !materials.isEmpty {
            meshDescriptor.materials = MeshDescriptor.Materials.perFace(materials)
        }
        return meshDescriptor
    }

    func move(x: Float = 0, y: Float = 0, z: Float = 0) -> [CompleteVertex] {
        return self.map { vertex in
            CompleteVertex(position: vertex.position + SIMD3(x: x, y: y, z: z), normal: vertex.normal, uv: vertex.uv)
        }
    }
}

internal extension SIMD3 where Scalar == Float {
    var normalised: SIMD3<Float> {
        return self / self.length
    }

    var length: Float {
        return sqrt(length_squared(self))
    }
}

fileprivate struct Vertex {
    let x: Float
    let y: Float
    let z: Float

    init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    var simd: SIMD3<Float> {
        return [self.x, self.y, self.z]
    }
    
}

extension MeshResource {
    private static func generatePyramidVertices(height: Float, hFOV: Float, vFOV: Float) -> [Vertex] {
        let x = height * tan(vFOV.toRadians / 2)
        let z = height * tan(hFOV.toRadians / 2)
        return [
            Vertex(0, 0, 0),
            Vertex(x, height, z),
            Vertex(x, height, -z),
            Vertex(-x, height, z),
            Vertex(-x, height, -z),
        ]
    }

    private static var verticesIndices: [UInt32] {
        return [0, 2, 1,
                0, 4, 2,
                0, 3, 4,
                0, 1, 3,]
                // top of the pyramid, the rectangle
//                1, 2, 3,
//                2, 4, 3]
    }

    // FOVS in degrees
    public static  func generatePyramid(height: Float, horizontalFOV: Float, verticalFOV: Float) throws -> MeshResource {
        let vertices = generatePyramidVertices(height: height, hFOV: horizontalFOV, vFOV: verticalFOV)
        
        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffers.Positions(vertices.map { $0.simd })
        descriptor.primitives = .triangles(verticesIndices)
        
        return try MeshResource.generate(from: [descriptor])
        
    }
}
