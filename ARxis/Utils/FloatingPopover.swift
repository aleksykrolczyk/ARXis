//
//  FloatingPopover.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 10/10/2022.
//

import Foundation
import SwiftUI

struct FloatingPopover: ViewModifier {
    
    func body(content: Content) -> some View {
        return content
    }
}


extension View {
    func floatingPopover() -> some View {
        modifier(FloatingPopover())
    }
}
