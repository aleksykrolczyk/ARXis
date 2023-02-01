//
//  RoundedImage.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 11/10/2022.
//

import SwiftUI

struct RoundedImage: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .cornerRadius(10)
    }
}

