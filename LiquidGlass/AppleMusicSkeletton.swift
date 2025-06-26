//
//  AppleMusicSkeletton.swift
//  ios19
//
//  Created by Codelaby on 21/6/25.
//

import SwiftUI

#if os(iOS)

// Define your tab enum
enum MusicAppTab: Int, Equatable, Hashable, Identifiable, CaseIterable , CustomStringConvertible {
    case home
    case new
    case radio
    case library
    case search
    
    var id: Int { self.rawValue }
    
    // SF Symbol name for each tab
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .new: return "square.grid.2x2.fill"
        case .radio: return "dot.radiowaves.left.and.right"
        case .library: return "square.stack.fill"
        case .search: return "magnifyingglass"
        }
    }
    
    // Description for each tab
    var description: String {
        switch self {
        case .home: return "Home"
        case .new: return "News"
        case .radio: return "Radio"
        case .library: return "Library"
        case .search: return "Search"
        }
    }
    
    // Associated view for each tab
    @MainActor
    @ViewBuilder
    func view(searchText: Binding<String>) -> some View {
        switch self {
        case .home:
            Text("Home")
        case .new:
            Text("News")
        case .radio:
            Text("Radio")
        case .library:
            DummyListView(title: "Library")

        case .search:
            NavigationStack {
                List {
                    // Your search results would go here
                }
                .navigationTitle("Search")
                .searchable(text: searchText, placement: .toolbar, prompt: Text("search..."))
            }
        }
    }
}


struct AppleMusicSkeletton: View {
    @State private var selectedTab: MusicAppTab = .home
    @State private var searchText: String = ""
    @State private var expandMiniPlayer: Bool = false
    @Namespace private var animation
    var body: some View {
        
        TabView(selection: $selectedTab) {
            ForEach(MusicAppTab.allCases) { tab in
                Tab(value: tab, role: tab == MusicAppTab.search ? .search : .none) {
                    // Display the content view for each tab
                    tab.view(searchText: $searchText)
                    
                } label: {
                    // Tab bar item with icon and title
                    Label(tab.description, systemImage: tab.icon)
                    
                }
            }
        }
        .tabViewBottomAccessory {
            MiniPlayerInfo()
                .matchedTransitionSource(id: "MINIPLAYER", in: animation)
                .onTapGesture {
                    expandMiniPlayer.toggle()
                }
        }
        .fullScreenCover(isPresented: $expandMiniPlayer) {
            FullPlayerInfo()
        }
    }
    
    @ViewBuilder
    private func MiniPlayerInfo() -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.gradient)
                .aspectRatio(1, contentMode: .fit)
                .padding(4)
            VStack(alignment: .leading) {
                Text("Music Song title").font(.callout)
                
                Text("Song artist name").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Play", systemImage: "play.fill") {
                print("play")
            }
            Button("Play", systemImage: "forward.fill") {
                print("forward")
                
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func FullPlayerInfo() -> some View {
        
        ScrollView {
            
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack {
                Capsule()
                    .fill(.primary.secondary)
                    .frame(width: 38, height: 4)
                
                MiniPlayerInfo()
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
            }
            .navigationTransition(.zoom(sourceID: "MINIPLAYER", in: animation))
        }
        // To avoid transparency
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        //        VStack {
        //            RoundedRectangle(cornerRadius: 8)
        //                .fill(.blue.gradient)
        //                .aspectRatio(1, contentMode: .fit)
        //                .padding(4)
        //                .padding(.leading, 16)
        //            VStack(alignment: .leading) {
        //                Text("Song title").font(.callout)
        //
        //                Text("Song artist name").font(.caption2).foregroundStyle(.secondary)
        //            }
        //            .frame(maxWidth: .infinity, alignment: .leading)
        //
        //            Button("Play", systemImage: "play.fill") {
        //                print("play")
        //            }
        //            Button("Play", systemImage: "forward.fill") {
        //                print("forward")
        //
        //            }
        //        }
    }
    
    
}

struct DummyListView: View {
    let title: String
    var body: some View {
        NavigationStack {
            List(0..<100, id: \.self) { i in
                Text("Item \(i)")
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.blue.opacity(0.3)
                        .hueRotation(.degrees(Double(i) * 3.6))
                    )
                
            }
            .navigationTitle(title)
            .scrollEdgeEffectStyle(.soft, for: .vertical)
            .toolbarTitleDisplayMode(.inlineLarge)

        }
    }
}

#Preview {
    AppleMusicSkeletton()
}
#endif
