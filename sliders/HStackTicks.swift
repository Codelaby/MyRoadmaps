//
//  HStackTicks.swift
//  RangeSlidersPlaygroun
//
//  Created by Codelaby on 21/6/24.
//

import SwiftUI

struct HStackTicks: Shape {
    var length: CGFloat = 8.0
    var candidates: Set<Int> = []
    var maxTicks: Int = 6
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Aseguramos que maxTicks no sea menor a 1
        let actualMaxTicks = max(maxTicks, 1)
        
        // Calculamos el espacio entre cada tick
        let spacing = (rect.width - 2) / CGFloat(actualMaxTicks - 1)
        
        // Dibujamos los ticks verticales
        for i in 0..<actualMaxTicks {
            if candidates.isEmpty || candidates.contains(i) {
                let xPosition = spacing * CGFloat(i) + 1
                path.move(to: CGPoint(x: xPosition, y: rect.minY))
                path.addLine(to: CGPoint(x: xPosition, y: rect.minY + length))
            }
        }
        
        return path
    }
}

#Preview {
    HStackTicks(length: 16, candidates: [], maxTicks: 20)
        .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .frame(width: 300, height: 50)
        .border(.red)
}
