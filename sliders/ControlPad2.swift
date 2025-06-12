//
//  ControlPad.swift
//  RangeSlidersPlaygroun
//
//  Created by Codelaby on 14/9/24.
//

import SwiftUI

/*
 RoundedRectangle(cornerRadius: 24, style: .continuous)
     .fill(.gray)
     .strokeBorder(Color.black.opacity(0.2), lineWidth: 3)
     .frame(width: totalSize, height: totalSize)
 */

/// A SwiftUI view representing a control pad with a movable circle over a grid of dots.
/// The circle's position updates `xValue` and `yValue`, which can be bound to external states.
struct ControlPad: View {

    // MARK: - Properties

    /// State variable to track the circle's position.
    @State private var currentPosition: CGPoint?

    /// Circle's radius; changes when being dragged.
    @State private var dotRadius: CGFloat = 5

    /// Binding variables to pass the x and y values to the parent view.
    @Binding var xValue: CGFloat
    @Binding var yValue: CGFloat

    let backgroundColor: some ShapeStyle = .gray.gradient.tertiary
    let placeholderColor: some ShapeStyle = .tint
    let borderColor: some ShapeStyle = Color.black.tertiary
    let foregroundColor: some ShapeStyle = .tint.tertiary
    let highlightColor: some ShapeStyle = .tint.secondary
    
    var gridSize = 11 // ood value for center
    let padding: CGFloat = 8 // padding box

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            // Constants for grid and layout.
            let totalSize = min(geometry.size.width, geometry.size.height)
            let dotCellSize = (totalSize - 2 * padding) / CGFloat(gridSize)

            // Calculate movable area bounds based on the current circle radius.
            let bounds = movableBounds(totalSize: totalSize, padding: padding, circleRadius: dotRadius)

            // Initialize circle position if not already set.
            let initialPosition = CGPoint(x: (bounds.minX + bounds.maxX) / 2,
                                          y: (bounds.minY + bounds.maxY) / 2)
            
            let circlePosition = self.currentPosition ?? initialPosition

            ZStack {
                // Background with gesture attached.
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(backgroundColor)
                    .strokeBorder(borderColor, lineWidth: 3)
                    .frame(width: totalSize, height: totalSize)
                .gesture(
                    // Drag gesture to move the circle.
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            var newLocation = value.location

                            // Increase circle radius when touch down.
                            withAnimation(.smooth) {
                                self.dotRadius = 16
                            }

                            // Recalculate movable area bounds based on the new circle radius.
                            let bounds = movableBounds(totalSize: totalSize, padding: padding, circleRadius: dotRadius)
                            // Constrain the circle's position within the bounds.
                            newLocation = constrainPoint(newLocation, within: bounds)

                            // Snap circle to the nearest grid dot if within threshold.
                            newLocation = snapToGrid(position: newLocation,
                                                     padding: padding,
                                                     dotCellSize: dotCellSize,
                                                     gridSize: gridSize,
                                                     snapThreshold: dotCellSize * 0.4)

                            self.currentPosition = newLocation

                            // Update xValue and yValue based on the new position.
                            updateValues(newLocation: newLocation, bounds: bounds)
//                            print("newloaction", value.location)
//                            print(geometry.size.width )
                            
                        }
                        .onEnded { _ in
                            // Snap to nearest grid dot on touch up.
                            if let currentPosition = self.currentPosition {
                                let snappedPosition = snapToGrid(position: currentPosition,
                                                                 padding: padding,
                                                                 dotCellSize: dotCellSize,
                                                                 gridSize: gridSize,
                                                                 snapThreshold: .infinity)

                                withAnimation(.easeInOut(duration: 0.39)) {
                                    // Snap circle to grid dot and reset radius.
                                    self.currentPosition = snappedPosition
                                    self.dotRadius = 5
                                }
                            } else {
                                // Reset circle radius on touch up.
                                withAnimation(.easeInOut(duration: 0.39)) {
                                    self.dotRadius = 5
                                }
                            }
                        }
                )

                // Grid of dots and movable circle.
                ZStack {
                    // Grid of dots.
                    drawGrid(circlePosition: circlePosition,
                             gridSize: gridSize,
                             dotCellSize: dotCellSize,
                             padding: padding,
                             circleRadius: dotRadius)

                    // Movable circle.
                    Circle()
                        .fill(highlightColor)
                        .frame(width: dotRadius * 2, height: dotRadius * 2)
                        .blur(radius: dotRadius == 16 ? 3 : 0)
                        .brightness(dotRadius == 16 ? 0.3 : 0)
                        .position(circlePosition)
                        .animation(.smooth, value: dotRadius)

                        //.animation(.easeInOut(duration: 0.39), value: circleRadius)
                }
            }
            .frame(width: totalSize, height: totalSize)
            .shadow(color: Color.accentColor.opacity(0.05), radius: 3, x: 0, y: 3) //.opacity(0.05)
            .shadow(color: Color.accentColor.opacity(0.16), radius: 39, x: 0, y: 16) // .opacity(0.16)
            .animation(.snappy, value: circlePosition)

            //.animation(.easeInOut(duration: 0.39), value: circlePosition)
        }
    }

    // MARK: - Helper Functions

    /// Calculates the movable area bounds based on the circle radius.
//    private func movableBounds(totalSize: CGFloat, padding: CGFloat, circleRadius: CGFloat) -> (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
//        let minX = padding + circleRadius / 2
//        let maxX = totalSize - padding - circleRadius / 2
//        let minY = padding + circleRadius / 2
//        let maxY = totalSize - padding - circleRadius / 2
//        return (minX, maxX, minY, maxY)
//    }
    
    private func movableBounds(totalSize: CGFloat, padding: CGFloat, circleRadius: CGFloat) -> (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
        let minX =  circleRadius / 2
        let maxX = totalSize - circleRadius / 2
        let minY =  circleRadius / 2
        let maxY = totalSize - circleRadius / 2
        return (minX, maxX, minY, maxY)
    }
    

    /// Constrains a point within the specified bounds.
    private func constrainPoint(_ point: CGPoint, within bounds: (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat)) -> CGPoint {
        var constrainedPoint = point
        constrainedPoint.x = min(max(point.x, bounds.minX), bounds.maxX)
        constrainedPoint.y = min(max(point.y, bounds.minY), bounds.maxY)
        return constrainedPoint
    }

    /// Snaps the given position to the nearest grid dot if within the snap threshold.
    private func snapToGrid(position: CGPoint, padding: CGFloat, dotCellSize: CGFloat, gridSize: Int, snapThreshold: CGFloat) -> CGPoint {
        let column = Int(round((position.x - padding - dotCellSize / 2) / dotCellSize))
        let row = Int(round((position.y - padding - dotCellSize / 2) / dotCellSize))
        let clampedColumn = min(max(column, 0), gridSize - 1)
        let clampedRow = min(max(row, 0), gridSize - 1)

        let gridDotCenterX = padding + (CGFloat(clampedColumn) + 0.5) * dotCellSize
        let gridDotCenterY = padding + (CGFloat(clampedRow) + 0.5) * dotCellSize

//        let dx = gridDotCenterX - position.x
//        let dy = gridDotCenterY - position.y
        //let distance = sqrt(dx * dx + dy * dy)

        // If within snap threshold, snap to grid dot.
        return CGPoint(x: gridDotCenterX, y: gridDotCenterY)

//        if distance < snapThreshold {
//            return CGPoint(x: gridDotCenterX, y: gridDotCenterY)
//        } else {
//            return position
//        }
    }

    /// Updates `xValue` and `yValue` based on the new circle position.
    private func updateValues(newLocation: CGPoint, bounds: (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat)) {
        let centerX = (bounds.minX + bounds.maxX) / 2
        let centerY = (bounds.minY + bounds.maxY) / 2
        
        // Calculate the maximum possible distance from center to edge
        let maxXDistance = bounds.maxX - centerX
        let maxYDistance = centerY - bounds.minY  // Note: Y axis is inverted (top is positive in screen coordinates)
        
        Task { @MainActor in
            self.xValue = max(-100, min(100, ((newLocation.x - centerX) / maxXDistance) * 100))
            self.yValue = max(-100, min(100, ((centerY - newLocation.y) / maxYDistance) * 100))
        }
    }

    /// Draws the grid of dots.
    @ViewBuilder
    private func drawGrid(circlePosition: CGPoint,
                          gridSize: Int,
                          dotCellSize: CGFloat,
                          padding: CGFloat,
                          circleRadius: CGFloat) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(dotCellSize), spacing: 0), count: gridSize),
            spacing: 0
        ) {
            ForEach(0..<gridSize * gridSize, id: \.self) { index in
                let row = index / gridSize
                let column = index % gridSize

                // Calculate the dot's center position.
                let dotX = padding + (CGFloat(column) + 0.5) * dotCellSize
                let dotY = padding + (CGFloat(row) + 0.5) * dotCellSize

                // Calculate the distance from the dot to the circle's center.
                let dx = dotX - circlePosition.x
                let dy = dotY - circlePosition.y
                let distance = sqrt(dx * dx + dy * dy)

                // Define a maximum distance for full effect.
                let maxDistance: CGFloat = dotCellSize * 4.5

                // Calculate normalized distance.
                let normalizedDistance = min(distance / maxDistance, 1.0)

                // Calculate base opacity based on distance.
                let baseOpacity = max(0.3, 1.0 - normalizedDistance)

                // Check if the dot is aligned with the circle's center.
                let isAlignedX = abs(dotX - circlePosition.x) < dotCellSize / 2
                let isAlignedY = abs(dotY - circlePosition.y) < dotCellSize / 2

                // Increase opacity for dots along the axes.
                let opacity = (isAlignedX || isAlignedY) ? max(baseOpacity, 0.7) : baseOpacity

                // Calculate dot size based on distance.
                let minDotSize: CGFloat = 3
                let maxDotSize: CGFloat = circleRadius == 16 ? 9 : 5
                let dotSize = minDotSize + (maxDotSize - minDotSize) * (1.0 - normalizedDistance)

                //let dotSize = dotCellSize + (2 * (1.0 - normalizedDistance))
                //let dotSize = dotCellSize + (1 * (1.0 - pow(normalizedDistance, 2)))
                
                if row == gridSize / 2 && column == gridSize / 2 {
                    // This is the center dot.
                    Circle()
                        .strokeBorder(placeholderColor.opacity(opacity), lineWidth: 1)
                        .frame(width: 5, height: 5)
                        .frame(width: dotCellSize, height: dotCellSize)
                } else {
                    // Other dots.
                    Circle()
                        .fill(foregroundColor.opacity(opacity))
                        .frame(width: dotSize, height: dotSize)
                       // .scaleEffect(1.5 * 1.0 - normalizedDistance)
           //             .frame(width: dotSize, height: dotSize)
                        .frame(width: dotCellSize, height: dotCellSize)
                }
            }
        }
        .padding(padding)
    }
}

// MARK: Playground
#Preview {
    struct PreviewWrapper: View {

        @State var xValue: CGFloat = -41
        @State var yValue: CGFloat = 21

        var body: some View {
            VStack {
                
                HStack(spacing: 10) {
                    Text("X Value: \(Int(xValue))")
                    Text("Y Value: \(Int(yValue))")
                }
                .font(.caption).monospacedDigit()
                .padding()
                .background(.thinMaterial, in: .capsule)
                
                ControlPad(xValue: $xValue, yValue: $yValue)
                    .frame(width: 256, height: 256)
                    .accentColor(.white)
                    .tint(.primary)

                
            }

        }
    }
    
    return PreviewWrapper()
}
