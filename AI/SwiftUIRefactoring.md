# Leveraging AI to Refactor SwiftUI

## Introducing AI-Assisted Refactoring
AI can provide valuable insights into code structure and dependencies. Here’s how you can leverage AI to separate your list and detail views:

## Prompt
Separate individual struct, List and Detail "paste code"

### Sample

Separate individual struct, List and Detail
```swift
truct FontFamilyView: View {
@State private var selectedFamily: FontFamilyModel?
@State private var fontFamilies: [FontFamilyModel] = []
@State private var sortOrder: SortOrder = .byName


enum SortOrder {
    case byName
    case byCount
}

var body: some View {
    NavigationSplitView {
        //List(fontFamilies,  id: \.self, selection: \$selectedFamily) { family in

        List(fontFamilies.sorted(by: { sortPredicate(lhs: \$0, rhs: \$1) }), id: \.self, selection: \$selectedFamily) { family in
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
    } detail: {
        if let selectedFamily = selectedFamily {
            List(selectedFamily.fonts) { font in
                VStack(alignment: .leading) {
                    Text(font.fontName)
                        .font(Font.custom(font.fontName, size: 20))
                    TraitView(for: font.traits)
                }
            }
            .navigationTitle(selectedFamily.name)
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

@ViewBuilder
private func TraitView(for traits: Set<FontModel.TraitType>) -> some View {
    HStack {
        ForEach(traits.sorted(by: { \$0.rawValue < \$1.rawValue }), id: \.self) { trait in
            Text(trait.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 4)
                .background(Color.gray.tertiary)
                .cornerRadius(4)
        }
    }
}

private func loadFonts() async {
    fontFamilies = await FontActor.shared.loadFontFamilies()
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
```

### Result

To separate the `FontFamilyView` into individual structs for the list and detail views, we can create three separate structs: `FontFamilyListView`, `FontFamilyDetailView`, and `FontFamilyView`. This will help in organizing the code better and make it more modular.

Here's how you can refactor the code:

```swift
import SwiftUI

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
                fontFamilies: $fontFamilies,
                selectedFamily: $selectedFamily,
                sortOrder: $sortOrder
            )
        } detail: {
            FontFamilyDetailView(selectedFamily: selectedFamily)
        }
        .task {
            await loadFonts()
        }
    }

    private func loadFonts() async {
        fontFamilies = await FontActor.shared.loadFontFamilies()
    }
}

struct FontFamilyListView: View {
    @Binding var fontFamilies: [FontFamilyModel]
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

struct FontFamilyDetailView: View {
    var selectedFamily: FontFamilyModel?

    var body: some View {
        if let selectedFamily = selectedFamily {
            List(selectedFamily.fonts) { font in
                VStack(alignment: .leading) {
                    Text(font.fontName)
                        .font(Font.custom(font.fontName, size: 20))
                    TraitView(for: font.traits)
                }
            }
            .navigationTitle(selectedFamily.name)
        } else {
            Text("Select a font family")
                .font(.headline)
                .foregroundColor(.secondary)
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
```

### Explanation:
1. **FontFamilyView**: This is the main view that contains the `NavigationSplitView` and manages the state for `fontFamilies`, `selectedFamily`, and `sortOrder`. It also handles loading the fonts.
2. **FontFamilyListView**: This view is responsible for displaying the list of font families. It takes bindings for `fontFamilies`, `selectedFamily`, and `sortOrder` to manage the list and sorting.
3. **FontFamilyDetailView**: This view is responsible for displaying the details of the selected font family. It takes the `selectedFamily` as a parameter and displays the fonts and their traits.

This refactoring makes the code more modular and easier to manage. Each view has a single responsibility, making the codebase cleaner and more maintainable.
