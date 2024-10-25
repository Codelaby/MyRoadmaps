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


// MARK: Define neested routes
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

// MARK: Define Views

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


struct MainContentView: View {
    @Environment(ViewRouterManager.self) private var viewRouter: ViewRouterManager
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Main Content")
                    .font(.largeTitle)
                    .padding()
                
                
            }
            .navigationTitle("Main")
            .toolbar {
                    settingsButtonToolbar
                }
                .navigationDestination(for: DestinationRoute.self) { target in
                    DestinationRoute.handleRoute(target)
                }
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


//Application
import SwiftUI

@main
struct NavigationSimple: App {
    
    var body: some Scene {
        WindowGroup {
            RouterView()
                .environment(viewModel)
        }
    }
}
