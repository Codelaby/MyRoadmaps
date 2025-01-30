//
//  FontFamilyView.swift
//  DevFontExplorer
//
//  Created by Codelaby on 28/1/25.
//

import SwiftUI

// MARK: Dependencies
struct InspectorViewModifier<Item: Equatable & Sendable, InspectorView: View>: ViewModifier {
    @Binding var item: Item?
    @ViewBuilder var inspectorContent: (Item) -> InspectorView
    
    func body(content: Content) -> some View {
        let isPresented = Binding<Bool>(
            get: { item != nil },
            set: { if !$0 { item = nil } }
        )
        
        return content
            .inspector(isPresented: isPresented) {
                if let item = item {
                    inspectorContent(item)
                }
            }
    }
}

extension View {
    func inspector<Item: Equatable & Sendable, InspectorContent: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> InspectorContent) -> some View {
        self.modifier(InspectorViewModifier(item: item, inspectorContent: content))
    }
}

////fised: Capture of 'currentValue' with non-sendable type 'Value' in a `@Sendable` closure
extension Binding {
    func map<T>(to: @escaping @Sendable (Value) -> T, from: @escaping @Sendable (T) -> Value) -> Binding<T> where Value: Sendable {
        return Binding<T>(
            get: { to(self.wrappedValue) },
            set: { newValue in self.wrappedValue = from(newValue) }
        )
    }
}



// MARK: Models
struct FontFamilyModel: Identifiable, Hashable, Equatable {
    let id: UUID = UUID()
    let name: String
    var fonts: [FontModel]
    
    var fontCount: Int {
        fonts.count
    }
    
    // Hashable conformances
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(fonts)
    }

    // Equatable conformance
    static func == (lhs: FontFamilyModel, rhs: FontFamilyModel) -> Bool {
        lhs.name == rhs.name && lhs.fonts == rhs.fonts
    }
}

struct FontModel: Identifiable, Hashable, Equatable {
    let id: UUID = UUID()
    let fontName: String
    let traits: Set<TraitType>
    
    enum TraitType: String, Hashable, CaseIterable {
        case bold
        case italic
        case condensed
        case monospaced
        case expanded
        case vertical
        case tightLeading
    }
}

// MARK: FontActor
actor FontActor {
    static let shared = FontActor()

    func loadFontFamilies() -> [FontFamilyModel] {
        var families: [FontFamilyModel] = []
        
        for family in UIFont.familyNames {
            var fonts: [FontModel] = []
            for fontName in UIFont.fontNames(forFamilyName: family) {
                if let font = UIFont(name: fontName, size: 17) {
                    let traits = extractTraits(from: font.fontDescriptor.symbolicTraits)
                    let fontModel = FontModel(fontName: fontName, traits: traits)
                    fonts.append(fontModel)
                }
            }
            let familyModel = FontFamilyModel(name: family, fonts: fonts)
            families.append(familyModel)
        }
        return families
    }

    private func extractTraits(from symbolicTraits: UIFontDescriptor.SymbolicTraits) -> Set<FontModel.TraitType> {
        var traits: Set<FontModel.TraitType> = []
        if symbolicTraits.contains(.traitBold) { traits.insert(.bold) }
        if symbolicTraits.contains(.traitItalic) { traits.insert(.italic) }
        if symbolicTraits.contains(.traitCondensed) { traits.insert(.condensed) }
        if symbolicTraits.contains(.traitExpanded) { traits.insert(.expanded) }
        if symbolicTraits.contains(.traitMonoSpace) { traits.insert(.monospaced) }
        if symbolicTraits.contains(.traitVertical) { traits.insert(.vertical) }
        if symbolicTraits.contains(.traitTightLeading) { traits.insert(.tightLeading) }
        return traits
    }
}


// MARK: FontFamilyView
struct FontFamilyView: View {
    @State private var selectedFamily: FontFamilyModel?
    @State private var fontFamilies: [FontFamilyModel] = []
    @State private var sortOrder: SortOrder = .byName

    enum SortOrder {
        case byName
        case byCount
    }

    var body: some View {
        NavigationSplitView {
            FontFamilyListView(
                fontFamilies: fontFamilies,
                selectedFamily: $selectedFamily,
                sortOrder: $sortOrder
            )
        } detail: {
            if let selectedFamily = selectedFamily {
                FontFamilyOverView(selectedFamily: selectedFamily)
            } else {
                Text("Select a font family")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadFonts()
        }
    }

    private func loadFonts() async {
        fontFamilies = await FontActor.shared.loadFontFamilies()
    }
}

// MARK: FontFamilyListView

struct FontFamilyListView: View {
    var fontFamilies: [FontFamilyModel]
    @Binding var selectedFamily: FontFamilyModel?
    @Binding var sortOrder: FontFamilyView.SortOrder

    var body: some View {
        List(fontFamilies.sorted(by: { sortPredicate(lhs: $0, rhs: $1) }), id: \.self, selection: $selectedFamily) { family in
            Text(family.name)
                .badge(family.fontCount)
        }
        .navigationTitle("Font Families")
        .toolbar {
            ToolbarItem {
                Menu("Sort") {
                    Button("By Name") { sortOrder = .byName }
                    Button("By Count") { sortOrder = .byCount }
                }
            }
        }
    }

    private func sortPredicate(lhs: FontFamilyModel, rhs: FontFamilyModel) -> Bool {
        switch sortOrder {
        case .byName:
            return lhs.name < rhs.name
        case .byCount:
            return lhs.fontCount > rhs.fontCount
        }
    }
}

// MARK: FontFamilyOverView
struct FontFamilyOverView: View {
    var selectedFamily: FontFamilyModel
    @State private var selectedFont: FontModel?

    var body: some View {
        List(selectedFamily.fonts) { font in
            HStack {
                VStack(alignment: .leading) {
                    Text(font.fontName)
                        .font(Font.custom(font.fontName, size: 20))
                    TraitView(for: font.traits)
                }
             Spacer()
                Button("Details", systemImage: "info.circle") {
                    selectedFont = font
                }
                .labelStyle(.iconOnly)
//                Button("Copy clipboard", systemImage: "document.on.document") {
//                    print(font.fontName)
//                    XPasteboard.general.copyText("some Text")
//                }
//                .labelStyle(.iconOnly)
            }
            .frame(idealHeight: 48)
        }
        .navigationTitle(selectedFamily.name)
        .inspector(item: $selectedFont) { font in
            FontDetailView(font: font)
        }
    }

    @ViewBuilder
    private func TraitView(for traits: Set<FontModel.TraitType>) -> some View {
        HStack {
            ForEach(traits.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { trait in
                Text(trait.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .background(Color.gray.tertiary)
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: FontDetailView
struct FontDetailView: View {
    let font: FontModel
    
    @State private var fontSize: CGFloat = 24
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                GroupBox("Properties") {
                    LabeledContent("Font name", value: font.fontName)
                    LabeledContent("Traits ", value: ListFormatter.localizedString(
                        byJoining: font.traits
                            .sorted(by: { $0.rawValue < $1.rawValue })
                            .map { $0.rawValue }
                    ))
                    //LabeledContent("Font type name", value: ".regular")
                    
                    Divider()
                    CopyCodeButton(code: font.fontName)
                        .controlSize(.extraLarge)
                        //.buttonStyle(.bordered)
                }
                    
                GroupBox("Sample & usage") {
                    Text(font.fontName)
                        .font(Font.custom(font.fontName, size: fontSize))
                        .frame(height: 128)
                    
                    //add slide change szie
                    Divider()
                    let swifFontCode = ".font(Font.custom(\(font.fontName), size: \(fontSize))"
                    
                    CopyCodeButton(code: swifFontCode)
                        .controlSize(.extraLarge)
                    
                }
                
                
                semanticSizes(fontName: font.fontName)

            }
            .padding()

        }
        .inspectorColumnWidth(min: 350, ideal: 400, max: 400)
    }
    
    
    @ViewBuilder
    private func semanticSizes(fontName: String) -> some View {
        GroupBox("Semantic sizes") {
            
            Text("Large Title")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize, relativeTo: .largeTitle))
            
            Text("Title")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .title1).pointSize, relativeTo: .title))
            
            Text("Title 2")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .title2).pointSize, relativeTo: .title2))
            
            Text("Title 3")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize, relativeTo: .title3))
            
            Text("Headline")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize, relativeTo: .headline))
            
            Text("Subheadline")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, relativeTo: .subheadline))
            
            Text("Body")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .body).pointSize, relativeTo: .body))
            
            Text("Callout")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .callout).pointSize, relativeTo: .callout))
            
            Text("Footnote")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .footnote).pointSize, relativeTo: .footnote))
            
            Text("Caption")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize, relativeTo: .caption))
            
            Text("Caption 2")
                .font(Font.custom(fontName, size: UIFont.preferredFont(forTextStyle: .caption2).pointSize, relativeTo: .caption2))
            
            Divider()
            

            CopyCodeButton(code: "print('Hello World')")
                .controlSize(.extraLarge)
                //.buttonStyle(.bordered)
                                
        }
    }
}

// MARK: Preview
#Preview {
    FontFamilyView()
}
