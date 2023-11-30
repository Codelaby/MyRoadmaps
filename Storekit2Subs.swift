
/*
 
 https://betterprogramming.pub/meet-storekit-subscriptionstoreview-in-ios-17-bdbe7a827a9
 https://santoshbotre01.medium.com/storekit-views-apis-with-ios-17-a4dd26a1029
 https://www.revenuecat.com/blog/engineering/storekit-views-guide-paywall-swift-ui/
 https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-in-app-purchases-in-swiftui
 https://blog.stackademic.com/elevating-subscription-apps-the-power-of-storekit-2-views-in-swiftui-3bee9c79239f
 */
import SwiftUI
import StoreKit

struct PaywallStorekit2SubsView: View {
    @State private var showingSignIn = false
    
    var body: some View {
        //SubscriptionStoreView(groupID: "163005DB", visibleRelationships: .current)
        SubscriptionStoreView(productIDs: ["Codelaby.Paywall.Montly","Codelaby.Paywall.Yearly"], marketingContent: {
            VStack {
                PaywallHeader()
                FeatureTable()
            }
            .padding(.horizontal, 32)
            //            .containerBackground(for: .subscriptionStoreFullHeight) {
            //                LinearGradient(colors: [.blue, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
            //            }
        })
        .storeButton(.visible, for: .restorePurchases, .redeemCode, .policies)
        .subscriptionStorePolicyDestination(for: .privacyPolicy) {
            Text("Privacy policy here")
        }
        .subscriptionStorePolicyDestination(for: .termsOfService) {
            Text("Terms of service here")
        }
        .subscriptionStoreSignInAction {
            showingSignIn = true
        }
        .sheet(isPresented: $showingSignIn) {
            Text("Sign in here")
        }
        .subscriptionStoreControlStyle(.picker)
        .subscriptionStoreButtonLabel(.multiline)
        //.backgroundStyle(.clear)
        //.subscriptionStorePickerItemBackground(.thinMaterial)
        .onInAppPurchaseStart { product in
            print("User has started buying \(product.id)")
        }
        .onInAppPurchaseCompletion { product, result in
            if case .success(.success(let transaction)) = result {
                print("Purchased successfully: \(transaction.signedDate)")
            } else {
                print("Something else happened")
            }
        }
    }
    
}


struct StoreKit2Demo: View {
    @State var showPaywall = false
    var body: some View {
        NavigationStack {
            VStack {
                Button("Go upgrade premium", action: {
                    showPaywall.toggle()
                })
            }
            .navigationTitle("Sample Storekit 2 - Subscriptions")
        }
        .sheet(isPresented: $showPaywall, content: {
            PaywallStorekit2SubsView()
        })
    }
}

#Preview {
    StoreKit2Demo()
}
