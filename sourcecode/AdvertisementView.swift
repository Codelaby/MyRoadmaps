import SwiftUI

fileprivate struct ConcaveCornerShape: InsettableShape {
    var cornerRadii: (topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat)
    var insetAmount: CGFloat = 0
    
    init(topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0) {
        self.cornerRadii = (topLeft, topRight, bottomLeft, bottomRight)
    }
    
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let iw = insetRect.width
        let ih = insetRect.height
        
        let maxR = min(iw, ih) / 2
        let tl = min(abs(cornerRadii.topLeft), maxR)
        let tr = min(abs(cornerRadii.topRight), maxR)
        let bl = min(abs(cornerRadii.bottomLeft), maxR)
        let br = min(abs(cornerRadii.bottomRight), maxR)
        
        path.move(to: CGPoint(x: insetRect.minX, y: insetRect.minY + tl))
        
        if cornerRadii.topLeft > 0 {
            path.addArc(center: CGPoint(x: insetRect.minX + tl, y: insetRect.minY + tl), radius: tl,
                        startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else if cornerRadii.topLeft < 0 {
            path.addArc(center: CGPoint(x: insetRect.minX, y: insetRect.minY), radius: tl,
                        startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY))
        }
        
        path.addLine(to: CGPoint(x: insetRect.maxX - tr, y: insetRect.minY))
        
        if cornerRadii.topRight > 0 {
            path.addArc(center: CGPoint(x: insetRect.maxX - tr, y: insetRect.minY + tr), radius: tr,
                        startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        } else if cornerRadii.topRight < 0 {
            path.addArc(center: CGPoint(x: insetRect.maxX, y: insetRect.minY), radius: tr,
                        startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.minY))
        }
        
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - br))
        
        if cornerRadii.bottomRight > 0 {
            path.addArc(center: CGPoint(x: insetRect.maxX - br, y: insetRect.maxY - br), radius: br,
                        startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        } else if cornerRadii.bottomRight < 0 {
            path.addArc(center: CGPoint(x: insetRect.maxX, y: insetRect.maxY), radius: br,
                        startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
        }
        
        path.addLine(to: CGPoint(x: insetRect.minX + bl, y: insetRect.maxY))
        
        if cornerRadii.bottomLeft > 0 {
            path.addArc(center: CGPoint(x: insetRect.minX + bl, y: insetRect.maxY - bl), radius: bl,
                        startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        } else if cornerRadii.bottomLeft < 0 {
            path.addArc(center: CGPoint(x: insetRect.minX, y: insetRect.maxY), radius: bl,
                        startAngle: .degrees(0), endAngle: .degrees(-90), clockwise: true)
        } else {
            path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
        }
        
        path.closeSubpath()
        return path
    }
    
    nonisolated func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
#Preview {
    ConcaveCornerShape(topLeft: 20, topRight: -20, bottomLeft: 20, bottomRight: 20)
        .stroke(.gray, lineWidth: 2)
        .frame(width: 380, height: 90)
        .overlay(Text("Mixta").foregroundColor(.white))
}

// MARK: Advertisement View
struct AdvertisementView<Content: View>: View {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let onClose: () -> Void
    @ViewBuilder var content: Content
    
    init(
        cornerRadius: CGFloat = 20,
        lineWidth: CGFloat = 2,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.onClose = onClose
        self.content = content()
    }
    
    var body: some View {
        
        let shape =  ConcaveCornerShape(
            topLeft: cornerRadius,
            topRight: -cornerRadius - 6,
            bottomLeft: cornerRadius,
            bottomRight: cornerRadius
        )
        
        ZStack {
            content
                .clipShape(shape.inset(by: 0))

            shape
                //.inset(by: 6)
                .stroke(.tint, lineWidth: lineWidth)
                .overlay(alignment: .topTrailing) {
                    
                    Button(role: .close) {
                        onClose()
                    }
                    .controlSize(.mini)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .labelStyle(.iconOnly)
                    //.tint(.gray)
                    .alignmentGuide(.top) { dim in
                        (dim.height / 2)
                    }
                    .alignmentGuide(.trailing) { dim in
                        (dim.width / 2)
                    }
                }
        }
        .background(.thinMaterial, in: shape)

    }
}

#Preview {
    
    AdvertisementView(cornerRadius: 10, lineWidth: 2, onClose: {
        print("tap close")
    }) {
        Color.clear
            .overlay {
                AsyncImage(url: URL(string: "https://de.cdn-website.com/bd3df2183eab4df89686dd288c83ac83/dms3rep/multi/COLOUR-MOVILE-web-transp.png")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
            }
            .clipped()
        
    }
    .frame(width: 380, height: 100)
    .tint(.green)
        //.environment(\.layoutDirection, .rightToLeft) // Test RTL
    
}
