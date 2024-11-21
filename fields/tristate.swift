//
//  TriStateToggle.swift
//  FieldsPlayground
//
//  Created by Gerard Coll Roma on 16/11/24.
//

import SwiftUI

// MARK: ToggleStyle

struct TriStateToggleStyle: ToggleStyle {
    
    enum TriState {
        case confirmed
        case denied
        case indeterminate
    }
    
    @Environment(\.controlSize) private var controlSize
    @Binding var state: TriState

    func makeBody(configuration: Configuration) -> some View {
        Button {
            switch state {
            case .confirmed:
                state = .denied
            case .denied:
                state = .indeterminate
            case .indeterminate:
                state = .confirmed
            }
        } label: {
            configuration.label
                .font(fontForControlSize)
                .foregroundStyle(colorForState(state))
                .strikethrough(state == .denied)
                .accessibility(label: Text(accessibilityLabelForState(state)))
        }
        .buttonStyle(.bordered)
        .contentShape(.capsule)
        .clipShape(.capsule)
        .overlay {
            Capsule()
                .modifiers(content: {
                    if state == .confirmed || state == .denied {
                        $0.stroke(.tint)
                    } else {
                        $0.stroke(.quaternary)
                    }
                })
        }
        .tint(tintColorForState(state))
    }

    private var fontForControlSize: Font {
        switch controlSize {
        case .mini:
            return .caption
        case .small:
            return .caption
        case .regular:
            return .body
        case .large:
            return .body
        case .extraLarge:
            return .body
        @unknown default:
            return .body
        }
    }

    private func colorForState(_ state: TriState) -> Color {
        switch state {
        case .confirmed:
            return .green
        case .denied:
            return .red
        case .indeterminate:
            return .primary
        }
    }

    private func tintColorForState(_ state: TriState) -> Color? {
        switch state {
        case .confirmed:
            return .green
        case .denied:
            return .red
        case .indeterminate:
            return nil
        }
    }

    private func accessibilityLabelForState(_ state: TriState) -> String {
        switch state {
        case .confirmed:
            return "Confirmed"
        case .denied:
            return "Denied"
        case .indeterminate:
            return "Indeterminate"
        }
    }
}





// MARK: Playground

struct TriStateTogglePlayground: View {
    
    @State private var triState: TriStateToggleStyle.TriState = .indeterminate

    var body: some View {
        Toggle("State", isOn: Binding(
            get: { triState == .confirmed },
            set: { _ in triState = .confirmed }
        ))
        .toggleStyle(TriStateToggleStyle(state: $triState))

        Text("Current State: \(stateDescription(triState))")
            .padding()
    }
    
    func stateDescription(_ state: TriStateToggleStyle.TriState) -> String {
        switch state {
        case .confirmed:
            return "Confirmed"
        case .denied:
            return "Denied"
        case .indeterminate:
            return "Indeterminate"
        }
    }
}

#Preview("TriState") {
    TriStateTogglePlayground()
}


// MARK: Playground
#Preview("TriState Group") {
    
    
    struct MusicCategory: Identifiable {
        
        let id = UUID()
        let name: String
        var state: TriStateToggleStyle.TriState = .indeterminate
    }

    
    struct MusicCategoryView: View {
        @Binding var category: MusicCategory

        var body: some View {
            Toggle(category.name, isOn: Binding(
                get: { category.state == .confirmed },
                set: { _ in category.state = .confirmed }
            ))
            .toggleStyle(TriStateToggleStyle(state: $category.state))
        }
    }
    
    struct PreviewWrapper: View {
        
        @State private var categories: [MusicCategory] = [
            MusicCategory(name: "Rock"),
            MusicCategory(name: "Pop"),
            MusicCategory(name: "Jazz"),
            MusicCategory(name: "Classical"),
            MusicCategory(name: "Electronic"),
            MusicCategory(name: "Metal"),
            MusicCategory(name: "K-pop")
            
            
            
        ]
        
        var body: some View {
            VStack {
                
                
                Text("Choice you music style").font(.title)
                FlowLayout(alignment: .leading) {
                    ForEach($categories) { $category in
                        MusicCategoryView(category: $category)
                    }
                }
                .padding(.horizontal)
                
                
                Button("Proceed") {
                    let confirmed = categories.filter { $0.state == .confirmed }
                    let denied = categories.filter { $0.state == .denied}
                    
                    print("✅", confirmed)
                    print("❌ ", denied)
                    
                }
                
            }
        }
        
        
    }
    
    return VStack {
        SampleTitleView(title: "Tri-State Multi-Select Picker in SwiftUI", summary: "Build flexible multi-select pickers with tri-state control.")
        Spacer()
        
        PreviewWrapper()
        
        Spacer()
        CreditsView()
    }
    
}


#Preview("Tri state Filter Group") {

    struct TagOption: Identifiable, Hashable, Sendable {
        let id = UUID()
        let name: String
        var state: TriStateToggleStyle.TriState = .indeterminate
    }

    enum FilterTagOption: Identifiable, Hashable, CustomStringConvertible {
        case all
        case label(option: TagOption)

        var id: Self {
            self
        }

        var description: String {
            switch self {
            case .all:
                return "All"
            case let .label(option):
                return option.name
            }
        }

        var tagOption: TagOption? {
            switch self {
            case .all:
                return nil
            case let .label(option):
                return option
            }
        }
    }
    
    struct FilterTagView: View {
        @Binding var label: TagOption

        var body: some View {
            Toggle(label.name, isOn: Binding(
                get: { label.state == .confirmed },
                set: { _ in label.state = .confirmed }
            ))
            .toggleStyle(TriStateToggleStyle(state: $label.state))
        }
    }

    
    struct PreviewWrapper: View {
        let movieTags: [TagOption]
        @State private var filterTags: [FilterTagOption]
        @State private var allSelected: Bool = false

        init() {
            // Create a list of TagOption instances
            self.movieTags = [
                TagOption(name: "Horror"),
                TagOption(name: "All Audiences"),
                TagOption(name: "Adults Only"),
                TagOption(name: "Parental Advisory"),
                TagOption(name: "Adventure"),
                TagOption(name: "Comedy"),
                TagOption(name: "Drama"),
                TagOption(name: "Sci-Fi"),
                TagOption(name: "Action"),
                TagOption(name: "Romance")
            ]

            // Create a list of FilterTagOption instances using .map
            self.filterTags = [.all] + movieTags.map { .label(option: $0) }
        }

        var body: some View {
            FlowLayout(alignment: .leading) {
                ForEach($filterTags) { $item in
                    if let tagOption = item.tagOption {
                        FilterTagView(label: Binding(
                            get: { tagOption },
                            set: { newValue in
                                updateTagOptionState(item: item, newValue: newValue)
                                allSelected = false
                            }
                        ))
                    } else {
                        Toggle(item.description, isOn: $allSelected)
                            .onChange(of: allSelected) { oldValue, newValue in
                                if newValue {
                                    setAllTagsToIndeterminate()
                                }
                            }
                    }
                }
            }
            .padding(.horizontal)
        }

        private func updateTagOptionState(item: FilterTagOption, newValue: TagOption) {
            if case let .label(existingOption) = item {
                var updatedOption = existingOption
                updatedOption.state = newValue.state
                if let index = filterTags.firstIndex(where: { $0.id == item.id }) {
                    filterTags[index] = .label(option: updatedOption)
                }
            }
        }

        private func setAllTagsToIndeterminate() {
            for index in filterTags.indices {
                if case let .label(existingOption) = filterTags[index] {
                    var updatedOption = existingOption
                    updatedOption.state = .indeterminate
                    filterTags[index] = .label(option: updatedOption)
                }
            }
        }
    
    }
    
    return PreviewWrapper()
}
