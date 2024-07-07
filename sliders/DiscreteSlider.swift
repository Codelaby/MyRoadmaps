//
//  DiscreteSlider.swift
//  RangeSlidersPlaygroun
//
//  Created by Codelaby on 6/7/24.
//

import SwiftUI

struct DiscreteSlider<Label: View, MinLabel: View, MaxLabel: View>: View {
    @Environment(\.layoutDirection) var layoutDirection
    
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    
    var label: () -> Label
    var minimumValueLabel: () -> MinLabel
    var maximumValueLabel: () -> MaxLabel
    var onEditingChanged: ((Bool) -> Void)?

    let placeholderHeight: CGFloat = 4
    let thumbSize: CGSize = CGSize(width: 26, height: 26)
    let ticksSize: CGSize = CGSize(width: 1, height: 8)
    
    let trackPlaceholderColor: Color = Color(UIColor.systemGray4)
    let tickMarkColor: Color = .secondary
    let trackColor: Color = .accentColor
    let thumbColor: Color = .white
    
    private var maxTicks: Int {
        let totalSteps = (range.upperBound - range.lowerBound) / step
        return Int(totalSteps) + 1
    }
    
    var body: some View {
        VStack {
                label()

            HStack {
                minimumValueLabel()
                
                GeometryReader { geometry in
                    
                    let totalWidth = geometry.size.width
                    let placeholderWidth = geometry.size.width - thumbSize.width
                    
                    ZStack(alignment: .center) {
                        // Placeholder
                        Capsule()
                            .fill(trackPlaceholderColor)
                            .frame(width: placeholderWidth , height: placeholderHeight)
                            .overlay(alignment: .leading, content: {
                                Capsule()
                                    .fill(trackColor)
                                    .frame(width: CGFloat(self.normalizedValue) * placeholderWidth, height: placeholderHeight)
                            })
                        
                        //Ticks mark
//                        HStackTicks(length: ticksSize.height, maxTicks: maxTicks)
//                            .stroke(tickMarkColor, lineWidth: ticksSize.width)
//                            .offset(x: thumbSize.width  / 2)
//                            .padding(.top, geometry.size.height / 2 - 4)
//                            .padding(.trailing, thumbSize.width )
                        
                        //Dots ticks
                        HStackDots(diameter: ticksSize.height - 4, maxDots: maxTicks, inSet: true)
                            .fill(tickMarkColor)
                            .offset(x: thumbSize.width  / 2)
                            .padding(.trailing, thumbSize.width )
                        
//                        ZStack {
//                            HLine()
//                                .stroke(trackPlaceholderColor, style: StrokeStyle(
//                                    lineWidth: 4,
//                                    lineCap: .round
//                                ))
//                                .frame(width: placeholderWidth - 2 , height: placeholderHeight)
//                                .overlay(alignment: .leading, content: {
//                                    Capsule()
//                                        .fill(trackColor)
//                                        .frame(width: CGFloat(self.normalizedValue) * placeholderWidth, height: placeholderHeight)
//                                })
//                            // Ticks
//                            HStackTicks(length: ticksSize.height, maxTicks: maxTicks)
//                                .stroke(.black, lineWidth: 4)
//                                .offset(x: thumbSize.width  / 2)
//                                .padding(.trailing, thumbSize.width )
//                                .padding(.top, geometry.size.height / 2 - 4)
//                                .blendMode(.destinationOut)
//
//                        }
//                        .compositingGroup()


                        //Thumb/Knob with gesture
                        HStack {
                            thumbView()
                                .offset(x: self.thumbOffset(width: placeholderWidth))
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            self.updateValue(with: gesture, in: geometry)
                                            onEditingChanged?(true)
                                        }
                                        .onEnded { _ in
                                            onEditingChanged?(false)
                                        }
                                )
                                Spacer()
                        }
                    }
                }
                .frame(height: thumbSize.height)
                
                maximumValueLabel()
            }
            .frame(height: thumbSize.height + 16)
        }
    }
    
    @ViewBuilder
    private func thumbView() -> some View {
        Circle()
            .fill(thumbColor)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .shadow(color: .gray.opacity(0.4), radius: 3, x: 2, y: 2)
    }
    
    private var normalizedValue: Double {
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private func thumbOffset(width: CGFloat) -> CGFloat {
        let stepCount = (range.upperBound - range.lowerBound) / step
        let tickWidth = width / CGFloat(stepCount)
        let currentStep = (value - range.lowerBound) / step
        let offset = tickWidth * CGFloat(currentStep)
        return offset
    }
    
    private func updateValue(with gesture: DragGesture.Value, in geometry: GeometryProxy) {

        //Suport RTL
        let dragPortion = layoutDirection == .rightToLeft
            ? abs(min(0, gesture.location.x - thumbSize.width / 2)) // Restringir a 0 y negativos
            : max(0, gesture.location.x - thumbSize.width / 2) // Restringir a 0 y positivos
        
        //Snapping next position
        let stepCount = (range.upperBound - range.lowerBound) / step
        let tickWidth = (geometry.size.width - thumbSize.width) / CGFloat(stepCount)
        let knobX = max(0, min(dragPortion, geometry.size.width - thumbSize.width))
        
        // Calculate new value based on knob position
        let newValue = range.lowerBound + Double(round(knobX / tickWidth)) * step
        value = max(range.lowerBound, min(newValue, range.upperBound))
    }
}

struct HLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

#Preview {
    
    struct ContentView: View {
        @State private var sliderValue: Double = 1.0
        @State private var isEditing: Bool = false

        var body: some View {
            VStack {
                Text("Discrete Slider with snapping tick marks")
                    .font(.largeTitle).bold().multilineTextAlignment(.center)
                    .padding()
                Text("Discrete scale + mark ticks + RTL support + dark mode").font(.footnote).foregroundStyle(.secondary)
                
                
                Spacer()
                Text("Editing: \(isEditing ? "True" : "False")")

                //same argument from native Slider
                DiscreteSlider(
                    value: $sliderValue,
                    range: 1...5,
                    step: 1,
                    label: {
                        HStack {
                            Text("Text size")
                            Spacer()
                            Text(sliderValue, format: .number)
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }, minimumValueLabel: {
                        Text("A")
                            .font(.body.smallCaps())
                            .bold()
                    }, maximumValueLabel: {
                        Text("A")
                            .font(.body)
                            .bold()
                    }, onEditingChanged: { editing in
                        isEditing = editing
                     })
                .accentColor(.blue)
                
                Spacer()
                
                Text("bento.me/codelaby").foregroundStyle(.blue)
            }
            .padding()
        }
    }
    
    return ContentView()
       //.environment(\.layoutDirection, .rightToLeft)

}
