//
//  NavigationBarDemo.swift
//  ios19
//
//  Created by Codelaby on 13/6/25.
//

import SwiftUI

// Define your tab enum
enum AppTab: Int, Equatable, Hashable, Identifiable, CaseIterable , CustomStringConvertible {
    case home
    case search
    case favorites
    case profile
    case settings
    
    var id: Int { self.rawValue }
    
    // SF Symbol name for each tab
    var icon: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .favorites: return "heart"
        case .profile: return "person"
        case .settings: return "gearshape"
        }
    }
    
    // Description for each tab
    var description: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .favorites: return "Favorites"
        case .profile: return "Profile"
        case .settings: return "Settings"
        }
    }
    
    // Associated view for each tab
    @ViewBuilder
    var view: some View {
        switch self {
        case .home:
            HomeView()
        case .search:
            SearchView()
        case .favorites:
            FavoritesView()
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: Tab views
// Example views for each tab (you would replace these with your actual views)
struct HomeView: View {
    var body: some View {
        Text("Home View")
            .font(.largeTitle)
            .foregroundColor(.primary)
    }
}

struct SearchView: View {
    var body: some View {
        NavigationStack {
            Text("Search View")
                .font(.largeTitle)
                .foregroundColor(.primary)
        }
    }
}

struct FavoritesView: View {
    var body: some View {
        Text("Favorites View")
            .font(.largeTitle)
            .foregroundColor(.primary)
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile View")
            .font(.largeTitle)
            .foregroundColor(.primary)
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings View")
            .font(.largeTitle)
            .foregroundColor(.primary)
    }
}


// MARK: Basic TabView
// Main app view with TabView
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tab.view
                    .tabItem {
                        Label(tab.description, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }
}

// MARK: TabView role
struct MainTabView2: View {
    @State private var selectedTab: AppTab = .home
    @State private var searchTerm: String = ""

    var body: some View {
        
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(value: tab, role: tab == AppTab.search ? .search : .none) {
                    // Display the content view for each tab
                    tab.view
                } label: {
                    // Tab bar item with icon and title
                    Label(tab.description, systemImage: tab.icon)
                    
                }
            }
        }
        .searchable(text: $searchTerm)
        
        
        
    }
    
}


/*
 struct MainTabView3: View {
 @State private var selectedTab: AppTab = .home
 
 var body: some View {
 TabView {
 Tab("Home", systemImage: "house") {
 HomeView()
 }
 
 Tab("Favorites", systemImage: "heart") {
 FavoritesView()
 }
 
 Tab("Profile", systemImage: "person") {
 ProfileView()
 }
 
 Tab("Settings", systemImage: "gearshape") {
 SettingsView()
 }
 
 Tab("search", systemImage: "magnifyingglass", role: .search) {
 SearchView()
 }
 }
 
 }
 
 
 }
 */


//MARK: Hack search role
/// Hack .search role for launch action or other view

// Define your tab enum
enum AppTab2: Int, Equatable, Hashable, Identifiable, CaseIterable , CustomStringConvertible {
    case home
    case share
    case favorites
    case profile
    case settings
    
    var id: Int { self.rawValue }
    
    // SF Symbol name for each tab
    var icon: String {
        switch self {
        case .home: return "house"
        case .share: return "square.and.arrow.up.fill"
        case .favorites: return "heart"
        case .profile: return "person"
        case .settings: return "gearshape"
        }
    }
    
    // Description for each tab
    var description: String {
        switch self {
        case .home: return "Home"
        case .share: return "Search"
        case .favorites: return "Favorites"
        case .profile: return "Profile"
        case .settings: return "Settings"
        }
    }
    
    // Associated view for each tab
    @ViewBuilder
    var view: some View {
        switch self {
        case .home:
            HomeView()
        case .share:
            ShareView()
        case .favorites:
            FavoritesView()
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        }
    }
}

struct ShareView: View {
    var body: some View {
        Text("Share View")
            .font(.largeTitle)
            .foregroundColor(.primary)
    }
}

struct MainTabView3: View {
    @State private var selectedTab: AppTab2 = .home
    @State private var showShareSheet: Bool = false
    @Namespace private var namespace
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            ForEach(AppTab2.allCases, id: \.id) { tab in
//                Tab(value: tab, role: tab == AppTab2.share ? .search : .none) {
//                    // Display the content view for each tab
//                    tab.view
//                } label: {
//                    // Tab bar item with icon and title
//                    Label(tab.description, systemImage: tab.icon)
//                    
//                }
                if tab == AppTab2.share {
                        Tab(value: tab, role: .search) {
                            // Display the content view for each tab
                            tab.view
                        } label: {
                            // Tab bar item with icon and title
                            Label(tab.description, systemImage: tab.icon)
                        }
                    

                } else {
                    Tab(value: tab) {
                        tab.view
                    } label: {
                        Label(tab.description, systemImage: tab.icon)
                    }
                }
                
            }
        }

        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .share {
                // Show sheet and revert to previous tab
                showShareSheet = true
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareView()
                .presentationDetents([.medium, .large])

        }
    }
    
}

// MARK: AccessoryContent

struct AccessoryContentDemo: View {
    var body: some View {
        TabView {
            Tab("home", systemImage: "house") {
                List {
                    ForEach(0..<100, id: \.self) {
                        Text("Item \($0)")
                    }
                }
            }
            
            Tab("profile", systemImage: "person") {
                Text("Profile")
            }
            
            Tab("settings", systemImage: "gearshape") {
                Text("Settings")
            }
        }
#if os(iOS)
        .tabBarMinimizeBehavior (.onScrollDown)
        .tabViewBottomAccessory {
            AccessoryContent()
        }
#endif
    }

}

struct AccessoryContent: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    
    var body: some View {
        switch placement {
        case .inline:
            Text("Inline")
        case .expanded:
            Text("Expanded")
        case .none:
            Text("none")
        case .some(_):
            Text("")
        }
    }
}



// MARK: Preview
#Preview {
    MainTabView()
}

#Preview {
    MainTabView2()
}

#Preview {
    MainTabView3()
}

#Preview {
    AccessoryContentDemo()
}

#Preview {
    @Previewable @State var searchText: String = ""
    TabView {
        Tab("One", systemImage: "1.circle") {
            
        }
        Tab("Two", systemImage: "2.circle") {
            
        }
        Tab("Three", systemImage: "3.circle") {
            
        }
        Tab("Four", systemImage: "4.circle", role: .search) {
            NavigationStack {
                Text("search view")
            }
        }
    }
    .searchable(text: $searchText)
}
