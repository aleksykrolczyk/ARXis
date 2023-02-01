//
//  PixelDensitySlider.swift
//  ObjectManipulator
//
//  Created by Adam Korytowski on 25/10/2022.
//

import SwiftUI


struct PixelDensitySlider: View {
    var value: Double
    var bounds: ClosedRange<Float> = 0...1
    var separators: [Double] = []

    func clamp<T>(_ value: T, between: ClosedRange<T>) -> T where T: Comparable {
        min(max(value, between.lowerBound), between.upperBound)
    }

    let calculateColorFunc: (Double) -> Color

    func getPointerOffset(pointerDiameter: CGFloat, width: CGFloat) -> CGFloat {
        let x1 = pointerDiameter / CGFloat(2)
        let x2 = CGFloat(clamp(value, between: 0...100) / 100) * (width - pointerDiameter)
        let x3 = width / CGFloat(2)
        return x1 + x2 - x3
    }
    
    func getSeparators(pointerDiameter: CGFloat, width: CGFloat) -> some View {
        ForEach(separators, id: \.self) { separator in
            Rectangle()
                .frame(width: 1.5)
                .offset(x: pointerDiameter/2 + separator * (width - pointerDiameter) / 100 - width / 2)
        }
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let circleDiameter = geometry.size.height * 0.4
            
            VStack (spacing: 0) {
                
                Image(systemName: "arrowtriangle.down.fill")
                    .resizable()
                    .frame(width: 9, height: 9)
                    .foregroundColor(.white)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .offset(x: getPointerOffset(pointerDiameter: circleDiameter, width: width))
                    .padding(.bottom, 2)
                
                ZStack {
                    RoundedRectangle(cornerRadius: circleDiameter)
                        .background(RoundedRectangle(cornerRadius: circleDiameter).stroke(.black, lineWidth: 4))
                        .foregroundColor(calculateColorFunc(value))
                    
                    getSeparators(pointerDiameter: circleDiameter, width: width)
                    
                }
            }
        }
    }
}

struct PixelDensityVisualizer: View {
    // https://www.axis.com/learning/web-articles/perfect-pixel-count/pixel-density
    var pixelDensity: Double

    static fileprivate let DARK_GREEN = Color.init(red: 2/255, green: 138/255, blue: 15/255)


    func calcColor(_ pixelDensity: Double) -> Color {
        switch pixelDensity {
            case _ where pixelDensity < 4:
                return .red
            case _ where pixelDensity < 20:
                return .orange
            case _ where pixelDensity < 40:
                return .yellow
            case _ where pixelDensity < 80:
                return .green
            default:
                return PixelDensityVisualizer.DARK_GREEN
        }
    }
    
    var body: some View {
        VStack{
            Text("Pixel density: \(Int(pixelDensity))")
                .font(.system(size: 8))
            PixelDensitySlider(value: pixelDensity, separators: [4, 20, 40, 80], calculateColorFunc: calcColor)
        }

    }
}
