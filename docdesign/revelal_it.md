```swift
//
//  ScratchSample.swift
//  DynamicColorPlayground
//
//  Created by Codelaby on 9/7/24.
//

import SwiftUI

struct ScratchView<Content: View, ScratchContent: View>: View {
    struct BrushPoint {
        var points = [CGPoint]()
        var lineWidth: CGFloat = 30.0
    }

    @State private var lines = [BrushPoint]()

    @Binding var isScratched: Bool
    
    var threshold: Double
    var scratchChanged: (Double) -> Void
    var content: () -> Content
    var scratchContent: () -> ScratchContent

    private let lineWidth: CGFloat = 30.0
    private let cellSize: CGSize = CGSize(width: 25.0, height: 25.0)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Hidden content view
                scratchContent()

                // Scratchable overlay view
                content()
                    .mask(
                        Canvas { context, _ in
                            for line in lines {
                                for point in line.points {
                                    var path = Path()
                                    path.addEllipse(in: CGRect(x: point.x - line.lineWidth / 2, y: point.y - line.lineWidth / 2, width: line.lineWidth, height: line.lineWidth))
                                    context.fill(path, with: .color(.white))
                                }
                            }
                        }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 2, coordinateSpace: .local)
                            .onChanged({ value in
                                let newPoint = roundToTwoDecimals(value.location)
                                
                                // Check if the new point is too close to the last few points
                                if shouldAddPoint(newPoint, to: lines) {
                                    var newLine = BrushPoint(lineWidth: lineWidth)
                                    newLine.points.append(newPoint)
                                    lines.append(newLine)
                                    let progress = percentageRevealed(size: geometry.size)
                                    scratchChanged(progress)
                                    if progress >= threshold {
                                        isScratched = true
                                    }
                                }
                            })
                    )
            }
        }
    }
    
    // Round CGPoint to two decimal places
    private func roundToTwoDecimals(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: (point.x * 100).rounded() / 100, y: (point.y * 100).rounded() / 100)
    }

    // Check if the new point should be added to the lines
    private func shouldAddPoint(_ newPoint: CGPoint, to lines: [BrushPoint], threshold: CGFloat = 5) -> Bool {
        let candidates = 25
        var recentPoints = [CGPoint]()
        for line in lines {
            recentPoints.append(contentsOf: line.points)
        }
        
        if recentPoints.count < candidates {
            return true
        }

        for i in stride(from: recentPoints.count - candidates, to: recentPoints.count, by: 1) {
            let point = recentPoints[i]
            let distance = sqrt(pow(point.x - newPoint.x, 2) + pow(point.y - newPoint.y, 2))
            if distance <= threshold {
                return false
            }
        }
        return true
    }
    
    // Calculate the percentage of the area revealed
    private func percentageRevealed(size: CGSize) -> Double {
        let filledCells = calculateFilledGridCells(size: size)
        let totalCells = Int(size.width / cellSize.width) * Int(size.height / cellSize.height)
        let percentage = Double(filledCells) / Double(totalCells)
        return percentage
    }

    // Calculate the number of filled grid cells
    private func calculateFilledGridCells(size: CGSize) -> Int {
        let numCellsX = Int(size.width / cellSize.width)
        let numCellsY = Int(size.height / cellSize.height)
        
        let filledCells = (0..<numCellsX).flatMap { i in
            (0..<numCellsY).map { j in
                CGRect(x: CGFloat(i) * cellSize.width,
                       y: CGFloat(j) * cellSize.height,
                       width: cellSize.width,
                       height: cellSize.height)
            }
        }.reduce(0) { result, cellRect in
            let isCellFilled = lines.contains { line in
                line.points.contains { point in
                    let distance = sqrt(pow(point.x - cellRect.midX, 2) + pow(point.y - cellRect.midY, 2))
                    return distance <= self.lineWidth / 2.0
                }
            }
            return result + (isCellFilled ? 1 : 0)
        }
        
        return filledCells
    }
}
```
Como se usa:

```swift
struct ScratchSample: View {

  @State private var isScratched = false
  @State private var progressScratched: CGFloat = 0

  var body: some View {
    VStack {
      // Title
      Text("Reveal it")
        .font(.largeTitle)
        .bold()
        .multilineTextAlignment(.center)

      // Description
      Text("Scratched surface. Detect percentage of revealed area.")
        .font(.footnote)
        .foregroundColor(.secondary)

      Spacer()

      // Current scratch state
      Text("Is scratched: \(isScratched)")

      // Scratch view with closure updates
ScratchView(isScratched: $isScratched, threshold: 0.92) { progress in
// Update progress state
progressScratched = progress
} content: {
// Content to be revealed (yellow rectangle)
RoundedRectangle(cornerRadius: 20)
  .fill(Color.yellow)
  .overlay {
    Text("Reveal content")
  }
} scratchContent: {
// Content hidden beneath (gray rectangle)
RoundedRectangle(cornerRadius: 20)
  .fill(Color.gray)
}
.frame(width: 280, height: 140)

      // Display scratch progress percentage
      Text(progressScratched, format: .percent.precision(.fractionLength(1)))

      Spacer()

      // Credit text
      Text("bento.me/codelaby")
        .foregroundColor(.blue)
    }
  }
}
#Preview {
    ScratchSample()
}
```
