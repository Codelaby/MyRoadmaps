//
//  HStackDots.swift
//  RangeSlidersPlaygroun
//
//  Created by Codelaby on 5/7/24.
//

import SwiftUI

struct HStackDots: Shape {
    var diameter: CGFloat = 8.0
    var candidates: Set<Int> = []
    var maxDots: Int = 6
    var inSet: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Aseguramos que maxDots no sea menor a 1
        let actualMaxDots = max(maxDots, 1)
        
        // Calculamos el espacio entre cada punto
        let spacing = inSet ? (rect.width - diameter) / CGFloat(actualMaxDots - 1) : rect.width / CGFloat(actualMaxDots - 1)
        
        // Dibujamos los círculos
        for i in 0..<actualMaxDots {
            if candidates.isEmpty || candidates.contains(i) {
                let xPosition = inSet ? spacing * CGFloat(i) + diameter / 2 : spacing * CGFloat(i)
                let yPosition = rect.midY
                path.addEllipse(in: CGRect(x: xPosition - diameter / 2, y: yPosition - diameter / 2, width: diameter, height: diameter))
            }
        }
        
        return path
    }
}

#Preview {
    VStack {
        HStackDots(diameter: 8, candidates: [], maxDots: 6, inSet: false)
            .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 300, height: 50)
            .border(.red)
        
        HStackDots(diameter: 8, candidates: [], maxDots: 6, inSet: true)
            .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 300, height: 50)
            .border(.blue)
    }
}
