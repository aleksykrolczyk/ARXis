//
//  CameraList.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 04/10/2022.
//

import SwiftUI

struct CameraList: View {
    let cameras: [CameraInScene]
    var selectedCameraId: ObjectIdentifier?
    var onCameraTap: (CameraInScene) -> Void

    var body: some View {
        
        ScrollView(.horizontal, showsIndicators: true) {
            HStack {
                ForEach(cameras) { camera in
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(selectedCameraId != nil && camera.id == selectedCameraId ? .green : .clear)
                                .frame(width: 80, height: 80)
        
                            Image(uiImage: camera.model.image)
                                .resizable()
                                .frame(width: 75, height: 75)
                                .cornerRadius(10)
                                .padding()
                        }
                        .offset(y: selectedCameraId != nil && camera.id == selectedCameraId ? -15 : 0)
                        
                        
                        HStack {
                            if camera.seesIpad {
                                PixelDensityVisualizer(pixelDensity: camera.pixelDensity)
                            } else {
                                Image(systemName:"x.square").foregroundColor(.red)
                            }
                        }
                        .frame(width: 100, height: 30)
                    }
                    .padding()
                    .onTapGesture {
                        onCameraTap(camera)
                    }
                }
            }
        }
    }
}
