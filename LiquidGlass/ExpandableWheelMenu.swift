//
//  ExpandableButtonsDemo.swift
//  ios19
//
//  Created by Codelaby on 10/7/25.
//

import SwiftUI

// MARK: Circular Stack
struct CircularStack<Content: View>: View {
    var itemSize: CGSize = .init(width: 50, height: 50)
    var startAngle: Angle = .zero
    var endAngle: Angle = .degrees(360)
    var clockwise: Bool = true
    
    @ViewBuilder var content: Content
    
    var body: some View {
        GeometryReader { geometry in
            Group(subviews: content) { collection in
                let totalItems = collection.count
                let angleRange = endAngle - startAngle
                
                // Ajuste automático del angleIncrement
                let angleIncrement: Double = if angleRange.degrees >= 360 {
                    angleRange.radians / Double(totalItems)
                } else {
                    angleRange.radians / Double(totalItems - 1)
                }
                
                let radius = min(geometry.size.width, geometry.size.height) / 2 - (itemSize.width / 2)
                
                ZStack {
                    ForEach(Array(collection.enumerated()), id: \.offset) { index, subview in
                        let calculatedAngle = Angle(radians: angleIncrement * Double(index))
                        let angle = startAngle + (clockwise ? calculatedAngle : -calculatedAngle)
                        
                        let offsetX = cos(angle.radians) * radius
                        let offsetY = sin(angle.radians) * radius
                        subview
                            .position(
                                x: geometry.size.width / 2 + offsetX,
                                y: geometry.size.height / 2 + offsetY
                            )
                    }
                }
            }
        }
    }
}

// MARK: ExpandableWheelMenu
struct ExpandableWheelMenu<Content: View>: View {
    @Binding var isExpanded: Bool
    
    @ViewBuilder var content: Content
    
    var body: some View {
        
        GlassEffectContainer(spacing: 20) {
            
            ZStack {
                if isExpanded {
                    CircularStack(itemSize: CGSize.init(width: 40, height: 40), startAngle: .degrees(180), endAngle: .degrees(( 180 + 90)), clockwise: true) {
                        Group(subviews: content) { collection in
                            ForEach(Array(collection.enumerated()), id: \.offset) { index, subview in
                                subview
                            }
                        }
                        .labelStyle(.iconOnly)
                        .controlSize(.large)
                        .clipShape(.buttonBorder)
                        .buttonBorderShape(.circle)
                        .buttonStyle(.glass)
                        .contentTransition(.symbolEffect)
                    }
                }
                
                Button("plus", systemImage: isExpanded ? "xmark" : "plus") {
                    withAnimation(.bouncy) {
                        isExpanded.toggle()
                    }
                }
                .labelStyle(.iconOnly)
                .controlSize(.large)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .clipShape(.buttonBorder)
                .contentTransition(.symbolEffect)
                
                
            }
            .frame(width: 280)
        }
        
        
    }
    
    
}

// MARK: Preview
#Preview {
    @Previewable @State var isExpanded = false
    
    // SampleTitleView(title: "Expandable Wheel Menu in SwiftUI", summary: "")
    // Spacer()
    
    ExpandableWheelMenu(isExpanded: $isExpanded) {
        
        Button("favorite", systemImage: "heart") {}
        Button("share", systemImage: "square.and.arrow.up") {}
        Button("edit", systemImage: "pencil") {}
        Button("delete", systemImage: "trash") {
            withAnimation(.bouncy) {
                isExpanded.toggle()
            }
        }
    }
    
    // Spacer()
    // CreditsView()
}

