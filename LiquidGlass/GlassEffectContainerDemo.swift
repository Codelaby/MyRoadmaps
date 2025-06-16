struct GlassEffectContainerDemo: View {
    @State private var spacing: CGFloat = 16.0
    @State private var containerSpacing: CGFloat = 16.0
    @State private var show: Bool = true
    
    var body: some View {
        GlassEffectContainer(spacing: containerSpacing) {
            
            HStack(spacing: spacing) {
                Image(systemName: "heart.fill")
                    .frame(width: 80.0, height: 80.0)
                    .font(.system(size: 36))
                    .glassEffect(.regular.tint(.pink.opacity(0.5)))
                
                if show {
                    Image(systemName: "heart.fill")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect(.regular.tint(.pink.opacity(0.5)))
                    //.offset(x: offsetX, y: offsetY)
                }
            }
        }
        //.animation(.bouncy, value: show)
        .animation(.bouncy.speed(0.5), value: show) // Slow motion
        
        .frame(maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, content: {
            
            GroupBox("Control") {
                
                Text("spacing \(spacing , format: .number.precision(.fractionLength(0)))").monospacedDigit()
                Slider(value: $spacing, in: -80.0 ... 16.0, step: 8, label: {})
                
                Text("Glass Container Spacing \(containerSpacing , format: .number.precision(.fractionLength(0)))").monospacedDigit()
                
                Slider(value: $containerSpacing , in: 0.0 ... 80.0, step: 8, label: {})
                
                Toggle("show", isOn: $show)
            }
            .font(.caption)
        })
    }
}

#Preview {
  GlassEffectContainerDemo()
}
