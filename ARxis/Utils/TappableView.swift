//
//  TappableView.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 27/09/2022.
//

import SwiftUI

typealias TapCallback = (CGPoint) -> Void

struct TappableView<ViewType: View>: UIViewRepresentable {
    var content: ViewType
    var tapCallback: TapCallback

    func makeUIView(context: Context) -> some UIView {
        let v = UIHostingController(rootView: content)
        let gestureTapped = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        gestureTapped.numberOfTapsRequired = 1
        v.view.addGestureRecognizer(gestureTapped)

        return v.view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    class Coordinator: NSObject {
        let tapCallback: TapCallback
        init(tapCallback: @escaping TapCallback) {
            self.tapCallback = tapCallback
        }

        @objc func tapped(gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            tapCallback(point)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(tapCallback: tapCallback)
    }
}

struct TappableViewModifier: ViewModifier {
    let callback: TapCallback

    func body(content: Content) -> some View {
        TappableView(content: content, tapCallback: callback)
    }
}

extension View {
    func onTap(callback: @escaping TapCallback) -> some View {
        modifier(TappableViewModifier(callback: callback))
    }
}
