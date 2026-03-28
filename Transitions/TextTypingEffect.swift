//
//  TypingText.swift
//  ios19
//
//  Created by Codelaby on 16/6/25.
//

import SwiftUI

fileprivate extension Text.Layout {
    var flattenedRuns: some RandomAccessCollection<Text.Layout.Run> {
        flatMap { line in
            line
        }
    }
    
    var flattenedRunSlices: some RandomAccessCollection<Text.Layout.RunSlice> {
        flattenedRuns.flatMap(\.self)
    }
}

struct TypeWritterEffect: ViewModifier, @preconcurrency Animatable {
    var progress: Double
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        content.textRenderer(TypingTextRenderer(progress: progress))
    }
}

// MARK: Typing Text Renderer
struct TypingTextRenderer: TextRenderer {
    var progress: Double

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let flattenedSlices = layout.flatMap { $0.flatMap { $0 } }
        let totalCharacters = flattenedSlices.reduce(0) { $0 + $1.count }
        let visibleCharacters = Int(Double(totalCharacters) * progress)
        
        var drawnCharacters = 0
        
        for slice in flattenedSlices {
            if drawnCharacters >= visibleCharacters {
                break
            }
            
            context.draw(slice)
            drawnCharacters += slice.count
            
        }
    }

}

// MARK: Typing Text Renderer Caret
struct TypeWritterEffect2: ViewModifier, @preconcurrency Animatable {
    var progress: Double
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        content.textRenderer(TypingTextCaretRenderer(progress: progress))
    }
}

struct TypingTextCaretRenderer: TextRenderer {
    var progress: Double

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let flattenedSlices = layout.flatMap { $0.flatMap { $0 } }
        let totalCharacters = flattenedSlices.reduce(0) { $0 + $1.count }
        let visibleCharacters = Int(Double(totalCharacters) * progress)
        
        var drawnCharacters = 0
        var caretRect: CGRect = .zero   // tracks the last drawn slice bounds
        
        for slice in flattenedSlices {
            if drawnCharacters >= visibleCharacters {
                break
            }
            
            context.draw(slice)
            drawnCharacters += slice.count
            
            caretRect = slice.typographicBounds.rect

            
        }
        if visibleCharacters > 0 && totalCharacters != visibleCharacters {
            drawCaret(in: &context, after: caretRect)
        }
    }
    
    private func drawCaret(in context: inout GraphicsContext, after rect: CGRect) {
        let caretWidth: CGFloat = 2
        let caretPadding: CGFloat = 1   // small gap between text and caret

        let x = rect.maxX + caretPadding
        let top = rect.minY
        let bottom = rect.maxY

        var path = Path()
        path.move(to: CGPoint(x: x, y: top))
        path.addLine(to: CGPoint(x: x, y: bottom))

        context.stroke(
            path,
            with: .color(.primary),
            style: StrokeStyle(lineWidth: caretWidth, lineCap: .round)
        )
    }
        
}

// MARK: Typing Text Renderer Caret with TimelineView
struct TypeWritterEffect3: ViewModifier, @preconcurrency Animatable {
    var progress: Double
    var caretPhase: Double = 0
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        content.textRenderer(TypingTextCaretRenderer3(progress: progress, caretPhase: caretPhase))
    }
}

struct TypingTextCaretRenderer3: TextRenderer {
    var progress: Double
    var caretPhase: Double  // 0-1 for blinking animation

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let flattenedSlices = layout.flatMap { $0.flatMap { $0 } }
        let totalCharacters = flattenedSlices.reduce(0) { $0 + $1.count }
        let visibleCharacters = Int(Double(totalCharacters) * progress)
        
        var drawnCharacters = 0
        var caretRect: CGRect = .zero
        
        for slice in flattenedSlices {
            if drawnCharacters >= visibleCharacters {
                break
            }
            
            context.draw(slice)
            drawnCharacters += slice.count
            
            caretRect = slice.typographicBounds.rect
        }
        
        // Draw caret only when caretPhase > 0.5 (blinking effect)
        let isCaretVisible = visibleCharacters > 0 && visibleCharacters < totalCharacters && caretPhase > 0.5
        
        if isCaretVisible {
            drawCaret(in: &context, after: caretRect, opacity: (caretPhase - 0.5) * 2)
        }
    }
    
    private func drawCaret(in context: inout GraphicsContext, after rect: CGRect, opacity: Double = 1.0) {
        let caretWidth: CGFloat = 2
        let caretPadding: CGFloat = 1
        
        let x = rect.maxX + caretPadding
        let top = rect.minY
        let bottom = rect.maxY
        
        var path = Path()
        path.move(to: CGPoint(x: x, y: top))
        path.addLine(to: CGPoint(x: x, y: bottom))
        
        context.opacity = opacity
        context.stroke(
            path,
            with: .color(.primary),
            style: StrokeStyle(lineWidth: caretWidth, lineCap: .round)
        )
    }
}



// MARK: Previews
#Preview("Typing markdown") {
    
    struct PreviewWrapper: View {
        @State private var progress: Double = 0.0
        @State private var startTime: Date = Date()

        var body: some View {
            VStack {
                
                
                Text(.init("Typewriting effect built with the new *TextRenderer API*, as seen at **WWDC24** for iOS18. \nThis is a other line"))
                    .font(.body)
                    .modifier(TypeWritterEffect(progress: progress))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding()
                    
                    
                    Text(.init("Typewriting effect built with the new *TextRenderer API*, as seen at **WWDC24** for iOS18. \nThis is a other line"))
                        .font(.body)
                        .modifier(TypeWritterEffect3(progress: progress, caretPhase: 1))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding()
                    // .border(.red)
                
                
                TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
                     let elapsed = timeline.date.timeIntervalSince(startTime)
                     let caretPhase = sin(elapsed * 2 * .pi * 2) // 2Hz blinking
                     let normalizedPhase = (caretPhase + 1) / 2 // Convert to 0-1 range
                     
                     Text(.init("Typewriting effect built with the new *TextRenderer API*, as seen at **WWDC24** for iOS18. \nThis is a other line"))
                         .font(.body)
                         .modifier(TypeWritterEffect3(progress: progress, caretPhase: normalizedPhase))
                         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                         .padding()
                }
                
                
                
                Button("Start Typing") {
                    withAnimation(.linear(duration: 3).speed(0.5)) {
                        progress = 1
                    }
                }
                .padding()
            }
        }
    }
    
    return VStack {
        SampleTitleView(title: "Markdown Typewriter in SwiftUI", summary: "Typing effect using markdown text")
        Spacer()
        
        PreviewWrapper()
            .frame(height: 400)
        
        Spacer()
        CreditsView()
    }
}






// MARK: Previews

#Preview("Typing atributeString") {
    
    struct PreviewWrapper: View {
        @State private var progress: Double = 0.0

        var body: some View {
            VStack {
                
                let textRenderer = Text("TextRenderer API")
                    .bold()
                    .foregroundStyle(.cyan)
                
                let wwdc24 = Text("WWDC24")
                    .bold()
                    .foregroundStyle(.brown)
                
                let ios18 = Text("iOS18")
                    .bold()
                    .foregroundStyle(.purple)
                
                
                Text("👋 Typewriting effect built with the new \(textRenderer)💕, as seen at \(wwdc24) for \(ios18). 🥳🎉")
                    .font(.body)
                    .modifier(TypeWritterEffect(progress: progress))
                
                
                Text("👋 Typewriting effect built with the new \(textRenderer)💕, as seen at \(wwdc24) for \(ios18). 🥳🎉")
                    .font(.body)
                    .modifier(TypingTextRenderer4())
                
                //.textRenderer(TypingTextRenderer(progress: progress))
                //.border(.red)
                

                
                
                
                Button("Start Typing") {
                    withAnimation(.linear(duration: 12)) {
                        progress = 1
                    }
                }
                .padding()
            }
        }
    }
    
    return VStack {
        SampleTitleView(title: "Rich Text Typewriter for SwiftUI", summary: "Typing effect support color, emojis, and more")
        Spacer()
        
        PreviewWrapper()
        
        Spacer()
        CreditsView()
    }
}

// ---------

    struct TypingTextRenderer4: ViewModifier {
        @State private var progress: Double = 0
        @State private var isCaretVisible = true
        @State private var timer: Timer?
        
        let totalDuration: TimeInterval
        let blinkInterval: TimeInterval
        var onComplete: (() -> Void)?
        
        init(duration: TimeInterval = 3.0, blinkInterval: TimeInterval = 0.5, onComplete: (() -> Void)? = nil) {
            self.totalDuration = duration
            self.blinkInterval = blinkInterval
            self.onComplete = onComplete
        }
        
        func body(content: Content) -> some View {
            content
                .textRenderer(TypingCaretRenderer4(progress: progress, isCaretVisible: isCaretVisible))
                .onAppear {
                    startTypingAnimation()
                    startCaretBlinking()
                }
                .onDisappear {
                    stopTimers()
                }
        }
        
        private func startTypingAnimation() {
            let startTime = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                let elapsed = Date().timeIntervalSince(startTime)
                let newProgress = min(elapsed / totalDuration, 1.0)
                
                DispatchQueue.main.async {
                    progress = newProgress
                    
                    if newProgress >= 1.0 {
                        stopTypingAnimation()
                        onComplete?()
                    }
                }
            }
        }
        
        private func stopTypingAnimation() {
            timer?.invalidate()
            timer = nil
        }
        
        private func startCaretBlinking() {
            Timer.scheduledTimer(withTimeInterval: blinkInterval, repeats: true) { _ in
                DispatchQueue.main.async {
                    isCaretVisible.toggle()
                }
            }
        }
        
        private func stopTimers() {
            timer?.invalidate()
            timer = nil
        }
    }

    struct TypingCaretRenderer4: TextRenderer {
        var progress: Double
        var isCaretVisible: Bool
        
        func draw(layout: Text.Layout, in context: inout GraphicsContext) {
            let flattenedSlices = layout.flatMap { $0.flatMap { $0 } }
            let totalCharacters = flattenedSlices.reduce(0) { $0 + $1.count }
            let visibleCharacters = Int(Double(totalCharacters) * progress)
            
            var drawnCharacters = 0
            var lastCharacterRect: CGRect = .zero

            for slice in flattenedSlices {
                if drawnCharacters >= visibleCharacters {
                    break
                }
                
                context.draw(slice)
                drawnCharacters += slice.count
                
                lastCharacterRect = slice.typographicBounds.rect
            }
            
            // Draw caret logic
            let isTypingInProgress = visibleCharacters > 0 && visibleCharacters < totalCharacters
            
            if isTypingInProgress && isCaretVisible {
                drawCaret(in: &context, after: lastCharacterRect)
            }
        }
        
        private func drawCaret(in context: inout GraphicsContext, after rect: CGRect) {
            let caretWidth: CGFloat = 2
            let caretPadding: CGFloat = 2
            
            let x = rect.maxX + caretPadding
            let top = rect.minY
            let bottom = rect.maxY
            
            var path = Path()
            path.move(to: CGPoint(x: x, y: top))
            path.addLine(to: CGPoint(x: x, y: bottom))
            
            context.stroke(
                path,
                with: .color(.primary),
                style: StrokeStyle(lineWidth: caretWidth, lineCap: .round)
            )
        }
    }




// MARK: - Other

//struct TypewriterEffect: ViewModifier {
//    var progress: Double
//    var showCaret: Bool
//    
//    func body(content: Content) -> some View {
//        content.textRenderer(
//            TypingTextRenderer(
//                progress: progress,
//                showCaret: showCaret
//            )
//        )
//    }
//}
//
//extension View {
//    func typewriter(progress: Double, showCaret: Bool) -> some View {
//        self.modifier(TypewriterEffect(progress: progress, showCaret: showCaret))
//    }
//}
//
//// MARK: - TextRenderer
//
//struct TypingTextRenderer: TextRenderer {
//    var progress: Double
//    var showCaret: Bool
//    
//    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
//        let slices = layout.flatMap { $0.flatMap { $0 } }
//        
//        let totalCharacters = slices.reduce(0) { $0 + $1.count }
//        let visibleCharacters = Int(Double(totalCharacters) * progress)
//        
//        var drawnCharacters = 0
//        
//        for slice in slices {
//            let sliceCount = slice.count
//            
//            // Caso 1: aún no llegamos → dibujar entero
//            if drawnCharacters + sliceCount < visibleCharacters {
//                context.draw(slice)
//                drawnCharacters += sliceCount
//                continue
//            }
//            
//            // Caso 2: el corte está dentro de este slice
//            let remaining = visibleCharacters - drawnCharacters
//            
//            if remaining > 0 {
//                let partial = slice.prefix(remaining)
//                context.draw(partial)
//            }
//            
//            // Dibujar caret
//            if showCaret {
//                drawCaret(
//                    in: &context,
//                    slice: slice,
//                    characterIndex: max(remaining, 0)
//                )
//            }
//            
//            break
//        }
//        
//        // Caso especial: todo el texto visible → caret al final
//        if visibleCharacters >= totalCharacters, showCaret {
//            if let lastSlice = slices.last {
//                drawCaret(
//                    in: &context,
//                    slice: lastSlice,
//                    characterIndex: lastSlice.count
//                )
//            }
//        }
//    }
//}
//
//// MARK: - Caret
//
//private extension TypingTextRenderer {
//    
//    func drawCaret(
//        in context: inout GraphicsContext,
//        slice: Text.Layout.RunSlice,
//        characterIndex: Int
//    ) {
//        // Guard empty slice
//        guard slice.count > 0 else { return }
//
//        // Clamp index within slice bounds
//        let idx = max(0, min(characterIndex, slice.count))
//
//        // Compute caret X by measuring the prefix width of the slice up to idx
//        // We approximate by drawing the prefix into a temporary context to get its resolved bounds.
//        // However, GraphicsContext doesn't provide measurement; instead, use the slice's cluster boundaries.
//        // `prefix(_:)` returns a RunSlice covering the first `n` elements.
//        let prefixSlice = slice.prefix(idx)
//
//        // Use typographic bounds from the current slice for height and baseline
//        let bounds = slice.typographicBounds
//        let height = bounds.ascent + bounds.descent
//
//        // Derive caret x from the trailing edge of the prefix slice's layout frame; if empty, use the slice's leading edge (x = 0 within the run's local coords).
//        // The draw API positions slices using their internal glyph positions, but these aren't directly exposed. SwiftUI draws RunSlice at its intrinsic location in the layout.
//        // To approximate, we draw a 0-width rect using the prefix's trailing inset via `stroke` at x = prefixSlice.typographicBounds.leadingInset.
//        // Since we can't access glyph positions, we can place the caret at the end by drawing an underline shape from the slice's `inlineOffset`.
//
//        // Fallback: draw caret at the end when idx == slice.count, else at the start when idx == 0.
//        // This avoids relying on unavailable glyph positions.
//        let isAtStart = (idx == 0)
//        let isAtEnd = (idx >= slice.count)
//
//        // Compute Y using ascent to align to baseline within the run
//        let y = -bounds.ascent
//
//        // Determine x: start or end of slice using the slice's visual width if available; typographicBounds has `width`.
//        let x: CGFloat
//        if isAtStart {
//            x = 0
//        } else if isAtEnd {
//            x = bounds.width
//        } else {
//            // Mid-slice approximation: proportion of width by character ratio
//            let ratio = CGFloat(idx) / CGFloat(slice.count)
//            x = bounds.width * ratio
//        }
//
//        let rect = CGRect(x: x, y: y, width: 2, height: height)
//        context.fill(Path(rect), with: .color(.primary))
//    }
//}
//
//struct TypewriterDemo: View {
//    @State private var progress: Double = 0
//    @State private var blink: Bool = true
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            
//            Text(.init("Typewriting effect built with the new *TextRenderer API*, as seen at **WWDC24** for iOS18. 🚀"))
//                .font(.body)
//                .typewriter(progress: progress, showCaret: blink)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding()
//            
//            Button("Start Typing") {
//                progress = 0
//                
//                withAnimation(.linear(duration: 4)) {
//                    progress = 1
//                }
//            }
//        }
//        .padding()
//        .onAppear {
//            startBlink()
//        }
//    }
//    
//    private func startBlink() {
//        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
//            blink.toggle()
//        }
//    }
//}
//
//#Preview {
//    TypewriterDemo()
//}

// ----------------

