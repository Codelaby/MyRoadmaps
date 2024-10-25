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

    var navPath = NavigationPath()

    func navigateToRoot() {
        navPath.removeLast(navPath.count)
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
enum ViewRouterSheet {
    
    case none
    case onboarding
    
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
            case .none: EmptyView()
            case .onboarding: OnboardingView()
            
        }
    }
    
}

// MARK: Define Root Views

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
    var body: some View {
        Text("Settings View")
            .font(.largeTitle)
            .padding()
    }
}


// MARK: Define destination routes
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

// MARK: Model and DataViewModel

struct BookItem: Decodable, Encodable, Equatable, Hashable {
    var id: UUID = UUID.init()
    var title: String
    var author: String
}


@Observable
final class MyViewModel {
    @MainActor static let shared = MyViewModel()
   
    var books: [BookItem] = []
       
       init() {
           // Inicializamos algunos libros de ejemplo
           books.append(BookItem(title: "El Alquimista", author: "Paulo Coelho"))
           books.append(BookItem(title: "Cien años de soledad", author: "Gabriel García Márquez"))
           books.append(BookItem(title: "Don Quijote de la Mancha", author: "Miguel de Cervantes"))
       }
}

// MARK: Define DetailView for Books

struct DetailView: View {
    
    //@EnvironmentObject private var viewRouter: ViewRouterManager
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    @State var item: BookItem
    
    var body: some View {
        VStack {
            Text("Detail uid: \(item.id)")
            Text("title:\(item.title)")
        }
    }
}

#Preview("Detail") {
    DetailView(item: BookItem(title: "sample book", author: "sample author"))
        .environment(ViewRouterManager())
}

// MARK: Define Nesteed destination routes

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
                DetailView(item: book)
        }
    }
}


// MARK: Define Root main View
struct MainContentView: View {
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager

    @State var viewModel = MyViewModel.shared

    var body: some View {

        @Bindable var viewRouter = viewRouter  //for Observable $viewRouter

        NavigationStack(path: $viewRouter.navPath) {

            List(viewModel.books, id: \.id) { book in

                NavigationLink(
                    book.title,
                    value: BooksRoute.detail(item: book)
                )

            }
            .toolbar {
                settingsButtonToolbar
            }
            .navigationDestination(for: DestinationRoute.self) { target in
                DestinationRoute.handleRoute(target)
            }
            .navigationDestination(for: BooksRoute.self) { target in
                BooksRoute.handleRoute(target)
            }
        }
        .onChange(of: viewRouter.navPath) { oldValue, newValue in
            print("change path", newValue.count)
        }
        .onFirstAppear {
            if OnboardingManager.isNeedOnboardingShow() {
                viewRouter.sheet = .onboarding
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


struct NavSimpleStructDemo: View {
    var body: some View {
        RouterView()
    }
}

// MARK: Preview zone

#Preview {
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
