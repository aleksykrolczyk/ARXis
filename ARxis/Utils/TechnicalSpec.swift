//
//  TechnicalSpec.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 26/10/2022.
//

import Foundation

struct TSCamera {
    let sensor: String
    let sensorSize: String
    let lightfinder: String
    let wideDynamicRange: String
    let minIllumination: Float // lux
    let maxIllumination: Float
}

struct TSAudio {
    let audioSupport: Bool
    let builInMicrophone: Bool
}

struct TSVideo {
    let resolution: (Int, Int)
    let maxFPS: String
    let dayAndNightFunctionality: Bool
    let electronicImageStabilization: Bool
}

struct TSSecurity {
    let signedFirmware: Bool
    let secureBoot: Bool
    let axisEdgeVault: Bool
}

struct TSLens {
    let focalLength: (Int, Int)
    let hFOV: (Int, Int)
    let vFOV: (Int, Int)
}

struct TSGeneral {
    let remoteFocus: Bool
    let remoteZoom: Bool
    let builtinIR: Bool
    let localStorage: Bool
    let operatingTemperature: ClosedRange<Float>
    let outdoorReady: Bool
    let vandalRating: String
    let ipRating: String?
    let designedForRepaint: Bool
    let sustainability: String
}

struct TCPanTiltZoom {
    let remotePTRZ: Bool
}

struct TCCompression {
    let zipstream: Bool
    let h264: String
    let h265: Bool
    let motionJPEG: Bool
}

struct TechnicalSpec {
    let resolution: (Int, Int)
    let vFOV: ClosedRange<Float>
    let hFOV: ClosedRange<Float>
}


