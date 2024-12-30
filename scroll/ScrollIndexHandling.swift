struct GradualScaleCarousel<Content: View, Data: RandomAccessCollection>: View where Data.Element: Identifiable {
    
    @State private var scrollPosition: ScrollPosition = .init(idType: ColorDemoModel.self)
    
    private let data: Data
    @Binding var currentIndex: Int
    private let content: (Data.Element) -> Content
    
    init(data: Data, selection: Binding<Int>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self._currentIndex = selection
        self.content = content
    }
    
    
    let itemSize: CGSize = .init(width: 80, height: 80)
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            
            GeometryReader { geometry in
                let size = geometry.size
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        //ForEach(data, id: \.self.id) { item in
                        ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                            
                            content(item)
                                .id(index)
                                .visualEffect { [size] (content, proxy) in
                                    let frame = proxy.frame(in: .global)
                                    
                                    let screenWidth = size.width //geometry.frame(in: .scrollView).width
                                    
                                    // the center X of the screen
                                    let centerXScreen = screenWidth / 2
                                    
                                    // the distance from the center of the screen to the center of the frame
                                    let distanceX = abs(centerXScreen - frame.midX)
                                    
                                    let fixProgress = max(min(distanceX / centerXScreen, 1), 0)
                                    
                                    // the scale factor
                                    let scale = 1.0 - (0.5 * fixProgress)
                                    
                                    
                                    return content
                                        .scaleEffect(scale)
                                    
                                }
                                .onTapGesture {
                                    print("tap", item)
                                }
                        }
                        
                        
                    }
                    .scrollTargetLayout()
                }
                .safeAreaPadding(.horizontal, max((geometry.size.width - itemSize.width) / 2, 0))
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: .init(
                    get: { currentIndex },
                    set: { value, _ in
                        if let value {
                            currentIndex = value
                        }
                    }
                ))
                .onChange(of: currentIndex, initial: true) { oldValue, newValue in
                    if oldValue == newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() ) {
                            scrollViewProxy.scrollTo(newValue, anchor: .center)
                            //currentIndex = newValue
                        }
                    }
                    
                }
                
            }
            .frame(height: itemSize.height * 2)
            
        }
        
    }
    
    
}

#Preview {
    @Previewable @State var selectedID: Int = 2
        
    SampleTitleView(title: "Gradual Scale carousel with SwiftUI", summary: "Interactive + RTL Support").padding()
    Spacer()
    
    
    GradualScaleCarousel(
        data: ColorDemoModel.allItems,
        selection: $selectedID
    ) { item in
        Circle()
            .fill(item.color.gradient)
            .overlay {
                Text(item.title).font(.footnote)
            }
            .frame(width: 80, height: 80)
    }
    
    Text("\(selectedID)")
    //.environment(\.layoutDirection, .rightToLeft)
    
    
    Spacer()
    CreditsView()
    
}
