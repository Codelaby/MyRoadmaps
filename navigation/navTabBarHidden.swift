//
//  NavSimpleStructDemo.swift
//  IOS18Playground
//
//  Created by Codelaby on 25/10/24.
//

import SwiftUI

// MARK: Dependencies

extension View {
    @ViewBuilder func `if`<Content: View>(
        _ condition: Bool, transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

//https://holyswift.app/triggering-an-action-only-first-time-a-view-appears-in-swiftui/
public struct OnFirstAppearModifier: ViewModifier {

    private let onFirstAppearAction: () -> Void
    @State private var hasAppeared = false

    public init(_ onFirstAppearAction: @escaping () -> Void) {
        self.onFirstAppearAction = onFirstAppearAction
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                onFirstAppearAction()
            }
    }
}

extension View {
    func onFirstAppear(_ onFirstAppearAction: @escaping () -> Void) -> some View
    {
        return modifier(OnFirstAppearModifier(onFirstAppearAction))
    }
}

// MARK: View router manager

@Observable
final class ViewRouterManager {
    @MainActor static let shared = ViewRouterManager()

    var navBooksPath = NavigationPath()
    var navMoviewsPath = NavigationPath()

    var isShowNavigationBar = true

    func navigateToRoot() {
        navBooksPath.removeLast(navBooksPath.count)
        navMoviewsPath.removeLast(navMoviewsPath.count)
    }
    
    func showNavBar(_ value: Bool) {
        withAnimation {
            isShowNavigationBar = value
        }
        
    }
    
    var screen: ViewRouterScreen = .splash
    var fullScreen: ViewRouterFullScreen = .none
    var sheet: ViewRouterSheet = .none
    
    init() {
        let randomNumber = arc4random_uniform(UInt32.max)
        print("init viewRoute instance: \(randomNumber)")
    }
    
}

struct RouterView: View {
    
    @State var viewRouter = ViewRouterManager.shared
    
    @State private var showFullScreen = false
    @State private var showSheet = false
    
    var body: some View {
        viewRouter
            .screen
            .view
            .sheet(isPresented: $showSheet, onDismiss: { viewRouter.sheet = .none }, content: { viewRouter.sheet.view })
#if os(iOS)
            .fullScreenCover(isPresented: $showFullScreen, onDismiss: { viewRouter.fullScreen = .none }, content: { viewRouter.fullScreen.view })
#endif
            .onChange(of: viewRouter.fullScreen, { oldValue, newValue in
                showFullScreen = newValue != .none
            })
            .onChange(of: viewRouter.sheet, { oldValue, newValue in
                showSheet = newValue != .none
            })
            .environment(viewRouter)
    }
    
}

// MARK: Onboarding Manager

final class OnboardingManager {
    static let onboardingKey = "hasShownOnboarding"

    static func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static func isNeedOnboardingShow() -> Bool {
        print("\(onboardingKey)_\(getAppVersion())")
         let defaults = UserDefaults.standard
         return !defaults.bool(forKey: "\(onboardingKey)_\(getAppVersion())")
     }
     
     static func completeOnboarding() {
         let defaults = UserDefaults.standard
         defaults.set(true, forKey: "\(onboardingKey)_\(getAppVersion())")
     }
    
}





// MARK: Define enum Views

//viewRouter.screen = .main
enum ViewRouterScreen {
    
    case splash
    case main
    
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
        case .splash: LaunchScreenView()
        case .main: MainContentView()
        }
    }
    
}

//viewRouter.fullScreen = .settings
enum ViewRouterFullScreen {
    
    case none
    
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
            case .none: EmptyView()
        }
    }
    
}

//viewRouter.sheet = .welcome
enum ViewRouterSheet: Equatable {
    case none
    case onboarding
    case readBook(BookItem)  // Incluye una instancia de BookItem en el caso

    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
            case .none:
                EmptyView()
            case .onboarding:
                OnboardingView()
            case .readBook(let item):  // Usa 'let' para obtener la instancia de BookItem
                ReadBookView(item: item)
        }
    }
}

// MARK: Define global routes
enum DestinationRoute: Identifiable, Codable, Hashable {
    var id: Self { self }
    
    case settings
    
    @MainActor
    @ViewBuilder
    static func handleRoute(_ route: DestinationRoute) -> some View {
        switch route {
            case .settings:
                SettingsView()
        }
    }
}

// MARK: Define Child routes

enum BooksRoute: Identifiable, Codable, Hashable {
    var id: Self { self }
    
    //case list
    //case create
    case detail(item: BookItem)
    
    @MainActor
    @ViewBuilder
    static func handleRoute(_ route: BooksRoute) -> some View {
        switch route {
            case .detail(item: let book):
                DetailBookView(item: book)
        }
    }
}

enum MoviesRoute: Identifiable, Codable, Hashable {
    var id: Self { self }
    
    //case list
    //case create
    case detail(item: MovieItem)
    
    @MainActor
    @ViewBuilder
    static func handleRoute(_ route: MoviesRoute) -> some View {
        switch route {
            case .detail(item: let book):
                DetailMovieView(item: book)
        }
    }
}



// MARK: Root Views

struct LaunchScreenView: View {
    
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    var body: some View {
        Text("Launch Screen")
            .font(.largeTitle)
            .padding()
        
        Button("Continue") {
            viewRouter.screen = .main
        }
    }
}

struct OnboardingView: View {
    
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    var body: some View {
        Text("Onboarding View")
            .font(.largeTitle)
            .padding()
        
        Button("Go ready") {
            OnboardingManager.completeOnboarding()
            viewRouter.sheet = .none
        }
    }
}

struct SettingsView: View {
    
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    var body: some View {
        
        VStack {
            Text("Settings View")
                .font(.largeTitle)
                .padding()
            
        }


    }
}




// MARK: Model and DataViewModel

struct BookItem: Decodable, Encodable, Equatable, Hashable {
    var id: UUID = UUID.init()
    var title: String
    var author: String
}


struct MovieItem: Decodable, Encodable, Equatable, Hashable {
    var id: UUID = UUID.init()
    var title: String
    var director: String
    var year: Date
}

@Observable
final class MyViewModel {
    @MainActor static let shared = MyViewModel()

    var books: [BookItem] = []
    var movies: [MovieItem] = []

    init() {
        // Initialize some example books from around the world
        books.append(BookItem(title: "One Hundred Years of Solitude", author: "Gabriel García Márquez"))
        books.append(BookItem(title: "The Alchemist", author: "Paulo Coelho"))
        books.append(BookItem(title: "Don Quixote", author: "Miguel de Cervantes"))
        books.append(BookItem(title: "War and Peace", author: "Leo Tolstoy"))
        books.append(BookItem(title: "Pride and Prejudice", author: "Jane Austen"))
        books.append(BookItem(title: "The Great Gatsby", author: "F. Scott Fitzgerald"))
        books.append(BookItem(title: "The Catcher in the Rye", author: "J.D. Salinger"))
        books.append(BookItem(title: "To Kill a Mockingbird", author: "Harper Lee"))
        books.append(BookItem(title: "1984", author: "George Orwell"))
        books.append(BookItem(title: "The Lord of the Rings", author: "J.R.R. Tolkien"))

        // Initialize some example movies
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"

        movies.append(MovieItem(title: "Inception", director: "Christopher Nolan", year: formatter.date(from: "2010/07/16")!))
        movies.append(MovieItem(title: "The Shawshank Redemption", director: "Frank Darabont", year: formatter.date(from: "1994/09/23")!))
        movies.append(MovieItem(title: "Pulp Fiction", director: "Quentin Tarantino", year: formatter.date(from: "1994/10/14")!))
        movies.append(MovieItem(title: "The Dark Knight", director: "Christopher Nolan", year: formatter.date(from: "2008/07/18")!))
        movies.append(MovieItem(title: "Fight Club", director: "David Fincher", year: formatter.date(from: "1999/10/15")!))
    }
}

// MARK: Destination Views

struct ProfileView: View {
    
    //@EnvironmentObject private var viewRouter: ViewRouterManager
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Profile")
            }
            .navigationTitle("Profile")
        }
    }
}


struct ListBookView: View {
    
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager
    @State private var viewModel = MyViewModel.shared
    
    var body: some View {
        @Bindable var viewRouter = viewRouter  //for Observable $viewRouter

        NavigationStack(path: $viewRouter.navBooksPath) {
            
            List(viewModel.books, id: \.id) { book in
                
                NavigationLink(
                    book.title,
                    value: BooksRoute.detail(item: book)
                )
                
            }
            .toolbar {
                settingsButtonToolbar
            }
            .navigationTitle("Books")
 //           .toolbarTitleDisplayMode(.inline)
            .navigationDestination(for: DestinationRoute.self) { target in
                DestinationRoute.handleRoute(target)

            }
            .navigationDestination(for: BooksRoute.self) { target in
                BooksRoute.handleRoute(target)

            }
        }

    }
    
    @ToolbarContentBuilder
    private var settingsButtonToolbar: some ToolbarContent {
        ToolbarItem(
            placement: .confirmationAction,
            content: {
                NavigationLink(
                    value: DestinationRoute.settings,
                    label: {
                        Image(systemName: "gear")
                    })
            })
    }
}

struct DetailBookView: View {
    
    //@EnvironmentObject private var viewRouter: ViewRouterManager
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    @State var item: BookItem
    
    var body: some View {
        VStack {
            Text("Detail uid: \(item.id)")
            Text("title:\(item.title)")
            
            Button("Read") {
                viewRouter.sheet = .readBook(item)
            }
        }
        .navigationTitle("Book")

    }
}

struct ReadBookView: View {
    
    //@EnvironmentObject private var viewRouter: ViewRouterManager
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    @State var item: BookItem
    
    var body: some View {
        VStack {
            Button("Close") {
                viewRouter.sheet = .none
            }
            Text("Read 5 pages").font(.largeTitle)
            Text("Detail uid: \(item.id)")
            Text("title:\(item.title)")
        }
    }
}

struct ListMovieView: View {

    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager
    @State private var viewModel = MyViewModel.shared

    var body: some View {
        @Bindable var viewRouter = viewRouter  //for Observable $viewRouter

        NavigationStack(path: $viewRouter.navMoviewsPath) {
            
            List(viewModel.movies, id: \.id) { movie in
                NavigationLink(
                    movie.title,
                    value: MoviesRoute.detail(item: movie)
                )
            }
            .navigationTitle("Movies")
  //          .toolbarTitleDisplayMode(.inline)
            .toolbar {
                settingsButtonToolbar
            }
            .navigationDestination(for: DestinationRoute.self) { target in
                DestinationRoute.handleRoute(target)
            }
            .navigationDestination(for: MoviesRoute.self) { target in
                MoviesRoute.handleRoute(target)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var settingsButtonToolbar: some ToolbarContent {
        ToolbarItem(
            placement: .confirmationAction,
            content: {
                NavigationLink(
                    value: DestinationRoute.settings,
                    label: {
                        Image(systemName: "gear")
                    })
            })
    }
}


struct DetailMovieView: View {

    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    @State var item: MovieItem

    var body: some View {
        VStack {
            Text("Detail uid: \(item.id)")
            Text("Title: \(item.title)")
            Text("Director: \(item.director)")
            Text("Year: \(item.year, formatter: dateFormatter)")


        }
        .navigationTitle("Movie")

    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}



// MARK: Main View

struct MainContentView: View {

    enum TabEnum: String, CaseIterable, Identifiable, CustomStringConvertible {
        case listBooks = "book.fill"
        case listMovies = "movieclapper.fill"

        case profile = "person.fill"
        
        var id: Self { self }
        
        var description: String {
            
            return switch self {
            case .listBooks:
                "Books"
            case .listMovies:
                "Movies"
            case .profile:
                "Profile"

            }
        }
    }

    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    @State private var selectedTab: TabEnum = .listBooks

    @State var viewModel = MyViewModel.shared

    
    var body: some View {
        
        @Bindable var viewRouter = viewRouter  //for Observable $viewRouter
        
        VStack {
            TabView(selection: $selectedTab) {
                
                // Pestaña para ListBookView
                ListBookView()
                    .tabItem {
                        Label(TabEnum.listBooks.description, systemImage: TabEnum.listBooks.rawValue)
                    }
                    .tag(TabEnum.listBooks)
#if os(iOS)
                    .toolbar(viewRouter.isShowNavigationBar ? .visible : .hidden, for: .tabBar)
#endif
                
                ListMovieView()
                    .tabItem {
                        Label(TabEnum.listMovies.description, systemImage: TabEnum.listMovies.rawValue)
                    }
                    .tag(TabEnum.listMovies)
                
                
                // Pestaña para el perfil
                ProfileView()
                    .tabItem {
                        Label(TabEnum.profile.description, systemImage: TabEnum.profile.rawValue)
                    }
                    .tag(TabEnum.profile)
                
            }

#if os(iOS)
            .onChange(of: viewRouter.navBooksPath) { oldValue, newValue in
                withAnimation {
                    viewRouter.isShowNavigationBar = newValue.isEmpty ? true : false
                }
            }
            .onChange(of: viewRouter.navMoviewsPath) { oldValue, newValue in
                withAnimation {
                    viewRouter.isShowNavigationBar = newValue.isEmpty ? true : false
                }
            }
#endif
            .onChange(of: selectedTab) { oldValue, newValue in
                viewRouter.navigateToRoot()
            }
            
        }


    }
    
}


struct NavSimpleStructDemo: View {
    var body: some View {
        RouterView()
    }
}

// MARK: Preview zone

#Preview("Nav") {
    NavSimpleStructDemo()
}

#Preview("LaunchScreen") {
    LaunchScreenView()
        .environment(ViewRouterManager())
}

#Preview("SettingsView") {
    SettingsView()
        .environment(ViewRouterManager())
}

#Preview("MainContentView") {
    MainContentView()
        .environment(ViewRouterManager())
}

#Preview("OnboardingView") {
    
    OnboardingView()
        .environment(ViewRouterManager())
}

#Preview("Profile View") {
    ProfileView()
        .environment(ViewRouterManager())
}

#Preview("List Book") {
    ListBookView()
        .environment(ViewRouterManager())
}

#Preview("Detail Book") {
    DetailBookView(item: BookItem(title: "sample book", author: "sample author"))
        .environment(ViewRouterManager())
}

#Preview("Read book") {
    ReadBookView(item: BookItem(title: "sample book", author: "sample author"))
        .environment(ViewRouterManager())
}
