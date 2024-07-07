//
//  CustomSlider.swift
//  RangeSlidersPlaygroun
//
//  Created by Codelaby on 7/7/24.
//

import SwiftUI

struct CustomSlider<Label: View, MinLabel: View, MaxLabel: View>: View {
    @Environment(\.layoutDirection) var layoutDirection
    
    @Binding var value: Double
    var range: ClosedRange<Double>
    
    var label: () -> Label
    var minimumValueLabel: () -> MinLabel
    var maximumValueLabel: () -> MaxLabel
    var onEditingChanged: ((Bool) -> Void)?
    
    let placeholderHeight: CGFloat = 4
    let thumbSize: CGSize = CGSize(width: 26, height: 26)
    
    let trackPlaceholderColor: Color = Color(UIColor.systemGray4)
    let trackColor: Color = .accentColor
    let thumbColor: Color = .white
    
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
                            .frame(width: totalWidth, height: placeholderHeight)
                            .overlay(alignment: .leading, content: {
                                Capsule()
                                    .fill(trackColor)
                                    .frame(width: CGFloat(self.normalizedValue) * totalWidth, height: placeholderHeight)
                            })
                        
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
        return CGFloat(normalizedValue) * width
    }
    
    private func updateValue(with gesture: DragGesture.Value, in geometry: GeometryProxy) {
        let dragPortion = layoutDirection == .rightToLeft
            ? abs(min(0, gesture.location.x - thumbSize.width / 2))
            : max(0, gesture.location.x - thumbSize.width / 2)
        
        let placeholderWidth = geometry.size.width - thumbSize.width
        let newValue = (dragPortion / placeholderWidth) * (range.upperBound - range.lowerBound) + range.lowerBound
        
        // Update state
        value = max(range.lowerBound, min(newValue, range.upperBound))
    }
}

#Preview {
    
    struct ContentView: View {
        @State private var sliderValue: Double = 1.0
        @State private var isEditing: Bool = false

        var body: some View {
            VStack {
                Text("Custom Slider")
                    .font(.largeTitle).bold().multilineTextAlignment(.center)
                    .padding()
                Text("RTL support + dark mode").font(.footnote).foregroundStyle(.secondary)
                
                Spacer()
                Text("Editing: \(isEditing ? "True" : "False")")

                //same argument from native Slider
                CustomSlider(
                    value: $sliderValue,
                    range: 1...5,
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
