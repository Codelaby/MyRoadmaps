
import SwiftUI

// MARK: ScrollAwareTitleModifier
struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = Anchor<CGRect>?
    static let defaultValue: Value = nil
    static func reduce(value: inout Value, nextValue: () -> Value) {
        guard let newValue = nextValue() else { return }
        value = newValue
    }
}

extension View {
    public func titleVisibilityAnchor() -> some View {
        self.anchorPreference(
            key: BoundsPreferenceKey.self,
            value: .bounds
        ) { anchor in
            anchor
        }
    }
}

private struct ScrollAwareTitleModifier<V: View>: ViewModifier {
    @State private var isShowNavigationTitle = false
    let title: () -> V
    
    func body(content: Content) -> some View {
        content
            .backgroundPreferenceValue(BoundsPreferenceKey.self) { anchor in
                GeometryReader { proxy in
                    if let anchor = anchor {
                        let scrollFrame = proxy.frame(in: .local).minY
                        let itemFrame = proxy[anchor]
                        let isVisible = itemFrame.maxY > scrollFrame
                        DispatchQueue.main.async {
                            if isVisible {
                                isShowNavigationTitle = false
                            } else if !isVisible {
                                isShowNavigationTitle = true
                            }
                        }
                    }
                    return Color.clear
                }
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    title()
                        .fontDesign(.serif)
                        .bold()
                        .opacity(isShowNavigationTitle ? 1 : 0)
                        .animation(.easeIn(duration: 0.15), value: isShowNavigationTitle)
                }
            }
        //            .toolbar {
        //                ToolbarItem(placement: toolbarPlacement) {
        //                    Button {
        //                        print("action plus")
        //                    } label: {
        //                        Image(systemName: "plus")
        //                    }
        //                }
        //            }
    }
    
    //    private var toolbarPlacement: ToolbarItemPlacement {
    //        #if os(macOS)
    //            return .primaryAction
    //        #else
    //            return .navigationBarTrailing
    //        #endif
    //    }
}

extension View {
    public func scrollAwareTitle<V: View>(@ViewBuilder _ title: @escaping () -> V) -> some View {
        modifier(ScrollAwareTitleModifier(title: title))
    }
}

extension View {
    public func scrollAwareTitle<S: StringProtocol>(_ title: S) -> some View {
        scrollAwareTitle{
            Text(title)
        }
    }
    public func scrollAwareTitle(_ title: LocalizedStringKey) -> some View {
        scrollAwareTitle{
            Text(title)
        }
    }
}

// MARK: Demo
struct AdaptativeNavTitleDemo: View {
    var body: some View {
        NavigationStack{
            ScrollView {
                    VStack(spacing: 4) {
                        Text("My Favorites")
                            .font(.callout).fontDesign(.serif)
                            .foregroundStyle(.secondary)
                        
                        Text("Books") // Set title this
                            .font(.largeTitle.bold())
                            .fontDesign(.serif)
                            .titleVisibilityAnchor() // Set anchor visibility

                        
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 32)
                
                FavoriteBooksDemo()
            }
#if os(iOS)
            .listStyle(.grouped)
#endif
            .scrollAwareTitle("Books") // Set title this
            .navigationTitle("Books") // only see in macos
        }
        
    }
    

}



#Preview("Adaptive Navigation Titles in SwiftUI") {
    AdaptativeNavTitleDemo()
}


struct Book: Identifiable {
    let id = UUID()
    let title: String
    let cover: String
}


struct BookCategory: Identifiable {
    let id = UUID()
    let name: String
    let books: [Book]
    let color: Color
}

struct FavoriteBooksDemo: View {
    
    let favoriteBooks: [BookCategory] = [
        BookCategory(name: "Software", books: [
            Book(title: "Book1", cover: "Book1"),
            Book(title: "Book2", cover: "Book2"),
            Book(title: "Book6", cover: "Book6"),
            Book(title: "Book18", cover: "Book18"),
            Book(title: "Book19", cover: "Book19"),
            Book(title: "Book20", cover: "Book20")
        ], color: .purple),
        
        BookCategory(name: "Language", books: [
            Book(title: "Book3", cover: "Book3"),
            Book(title: "Book4", cover: "Book4"),
            Book(title: "Book5", cover: "Book5"),
            Book(title: "Book15", cover: "Book15"),
            Book(title: "Book16", cover: "Book16")
        ], color: .blue),
        
        BookCategory(name: "Sci-Fi", books: [
            Book(title: "Book7", cover: "Book7"),
            Book(title: "Book8", cover: "Book8"),
            Book(title: "Book9", cover: "Book9"),
            Book(title: "Book10", cover: "Book10"),
            Book(title: "Book21", cover: "Book21"),
            Book(title: "Book22", cover: "Book22")
        ], color: .green),
        
        BookCategory(name: "Digital Design", books: [
            Book(title: "Book11", cover: "Book11"),
            Book(title: "Book12", cover: "Book12"),
            Book(title: "Book13", cover: "Book13"),
            Book(title: "Book14", cover: "Book14"),
            Book(title: "Book17", cover: "Book17")
        ], color: .orange),
        
        BookCategory(name: "Cuisine", books: [
            Book(title: "Book23", cover: "Book23"),
            Book(title: "Book24", cover: "Book24"),
            Book(title: "Book25", cover: "Book25")
        ], color: .yellow)
    ]
    
    var body: some View {
        VStack {
            
            BooksContainerView {
                
                ForEach(favoriteBooks) { category in
                    Section(header: Text(category.name)) {
                        ForEach(category.books) { book in
                            VStack(alignment: .center) {
                                Rectangle()
                                    .fill(.quinary)
                                    .frame(width: 100, height: 150)
                                    .overlay {
                                        Image(book.cover)
                                            .resizable()
                                            .scaledToFill()
                                    }
                                    .clipped()
                                    .clipShape(.rect(cornerRadius: 4))
//                                Text(book.title)
//                                    .font(.caption)
//                                    .lineLimit(2, reservesSpace: true)

                            }
                        }
                    }
                    .expandAction {
                        print("press more \(category.name)")
                    }
                    .containerValue(\.categoryColor, category.color)

                }

                
            }
            
        }
    }
}

#Preview {
    FavoriteBooksDemo()
}

// MARK: Content Values
typealias ExpandAction = () -> Void

extension ContainerValues {
    @Entry var expandAction: ExpandAction?
}

extension View {
    func expandAction(_ action: ExpandAction?) -> some View {
        containerValue(\.expandAction, action)
    }
}

// For category color
extension ContainerValues {
    @Entry var categoryColor: Color = .blue
}


// MARK: Book Section Header
struct BookSectionHeader<Content: View>: View {
    @ViewBuilder var content: Content
    var expandAction: ExpandAction?
    
    var body: some View {
        HStack {
            content
                .font(.headline.bold())
            
            Spacer()
            
            Button("more") {
                expandAction?()
            }
            .font(.caption)
        }
        .padding(.horizontal)
    }
}

// MARK: Book Section Content
struct BookSectionContainer<Content: View>: View {
    let color: Color
    
    @ViewBuilder var content: Content
    
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(subviews: content) { subview in
                    subview
                        .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 16)

                }
            }

        }
        .contentMargins(16, for: .scrollContent)
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .frame(height: 48)
                .glassEffect(.regular.tint(color.opacity(0.3)), in: .rect(cornerRadius: 8))
                .overlay {
                    HStack {
                        Circle().fill(.secondary).frame(width: 8)
                        Spacer()
                        Circle().fill(.secondary).frame(width: 8)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
        }
    }
}

// MARK: List of Books
struct BooksContainerView<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
            LazyVStack(spacing: 32) {
                ForEach(sections: content) { section in
                    VStack(spacing: 0) {
                        if !section.header.isEmpty {
                            let values = section.containerValues
                            
                            BookSectionHeader {
                                section.header
                            } expandAction: {
                                if let expandAction = values.self.expandAction {
                                    expandAction()
                                }
                            }
                        }
                        BookSectionContainer(
                            color: section.containerValues.categoryColor) {
                            section.content
                        }
                        
                    }
                }
            }

        
    }
}
