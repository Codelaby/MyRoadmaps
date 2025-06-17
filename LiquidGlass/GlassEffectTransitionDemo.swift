import SwiftUI

// MARK: Glass Effect transition
struct GlassEffectContainerDemo2: View {
    @State private var show: Bool = false
    
    var body: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                if show {
                    Image(systemName: "pencil")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect(.regular.tint(.pink.opacity(0.5)))
                    //.glassEffectTransition(.matchedGeometry(properties: [.position]))
                }
                
                Image(systemName: "ellipsis")
                    .frame(width: 80.0, height: 80.0)
                    .font(.system(size: 36))
                    .glassEffect(.regular.tint(.pink.opacity(0.5)))
                
                if show {
                    Image(systemName: "heart.fill")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect(.regular.tint(.pink.opacity(0.5)))
                    //.glassEffectTransition(.identity) // for remove liquid match effect
                }
            }
            
        }
        //.animation(.bouncy, value: show)
        .animation(.bouncy.speed(0.5), value: show) // Slow motion
        
        .frame(maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, content: {
            GroupBox("Control") {
                Toggle("show", isOn: $show)
                
            }
            .font(.caption)
        })
    }
}

#Preview("transition") {
    // SampleTitleView(title: "GlassEffectTransition Liquid Glass", summary: "Explore glassEffectTransition in SwiftUI")
    
    GlassEffectContainerDemo2()
    //.background(Image(.abstractBg))
    
    // CreditsView()
}

// MARK: Namespace transitions
struct GlassEffectContainerDemo3: View {
    let spacing: CGFloat = 16.0
    @State private var show: Bool = false
    @State private var show2: Bool = false

    @Namespace private var namespace
    @Namespace private var namespace2
    
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            VStack {
                Text("asign same namespace: ellipsis, pencil").font(.footnote)
                
                HStack(spacing: spacing) {
                    
                    Image(systemName: "ellipsis")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect(.regular.tint(.blue.opacity(0.5)))
                        .glassEffectID(1, in: namespace)
                    
                    if show {
                        Image(systemName: "pencil")
                            .frame(width: 80.0, height: 80.0)
                            .font(.system(size: 36))
                            .glassEffect(.regular.tint(.blue.opacity(0.5)))
                            .glassEffectID(2, in: namespace)
                    }
                    
                    Image(systemName: "heart.fill")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect(.regular.tint(.blue.opacity(0.5)))
                        .glassEffectID(3, in: namespace2)
                    
                }
                
                Text("asign same namespace: pencil, heart").font(.footnote)
                
                HStack(spacing: spacing) {
                    
                    Image(systemName: "ellipsis")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect(.regular.tint(.blue.opacity(0.5)))
                        .glassEffectID(1, in: namespace)
                    
                    if show2 {
                        Image(systemName: "pencil")
                            .frame(width: 80.0, height: 80.0)
                            .font(.system(size: 36))
                            .glassEffect(.regular.tint(.blue.opacity(0.5)))
                            .glassEffectID(2, in: namespace2)
                    }
                    
                    Image(systemName: "heart.fill")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect(.regular.tint(.blue.opacity(0.5)))
                        .glassEffectID(3, in: namespace2)
                }
            }
        }
        //.animation(.bouncy, value: show)
        .animation(.bouncy.speed(0.5), value: show) // Slow motion
        .animation(.bouncy.speed(0.5), value: show2) // Slow motion
        .frame(maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, content: {
            GroupBox("Control") {
                Toggle("show", isOn: $show)
                Toggle("show2", isOn: $show2)

            }
            .font(.caption)
        })
    }
}

#Preview("namespaces") {
    // SampleTitleView(title: "GlassEffectTransition Liquid Glass", summary: "Explore glassEffectTransition over namespace in SwiftUI")
    
    GlassEffectContainerDemo3()
        //.background(Image(.abstractBg))
    
    // CreditsView()
}

// MARK: Expandable
struct GlassEffectContainerDemo4: View {
    let spacing: CGFloat = 16.0
    @State private var show: Bool = false
    @Namespace private var namespace
    
    var body: some View {
        GlassEffectContainer(spacing: 20) {
            VStack {
                
                HStack(spacing: 16) {
                    
                    Image(systemName: "ellipsis")
                        .frame(width: 80.0, height: 80.0)
                        .font(.system(size: 36))
                        .glassEffect(.regular.tint(.purple.opacity(0.5)))
                        //.glassEffectID(1, in: namespace)
                    
                    if show {
                        Image(systemName: "plus")
                            .frame(width: 80.0, height: 80.0)
                            .font(.system(size: 36))
                            .glassEffect(.regular.tint(.purple.opacity(0.5)))
                        
                        Image(systemName: "pencil")
                            .frame(width: 80.0, height: 80.0)
                            .font(.system(size: 36))
                            .glassEffect(.regular.tint(.purple.opacity(0.5)))
                            //.glassEffectID(2, in: namespace)
                        
                        Image(systemName: "heart.fill")
                            .frame(width: 80.0, height: 80.0)
                            .font(.system(size: 36))
                            .glassEffect(.regular.tint(.purple.opacity(0.5)))
                            //.glassEffectID(3, in: namespace)
                    }
                    

                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
        }
        //.animation(.bouncy, value: show)
        .animation(.bouncy.speed(0.5), value: show) // Slow motion
        .frame(maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, content: {
            GroupBox("Control") {
                Toggle("show", isOn: $show)
            }
            .font(.caption)
        })
    }
}

#Preview("expandable") {
    // SampleTitleView(title: "GlassEffectTransition Liquid Glass", summary: "Explore glassEffectTransition in SwiftUI")
    
    GlassEffectContainerDemo4()
        //.background(Image(.abstractBg))
    
    // CreditsView()
}
