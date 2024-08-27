import SwiftUI

struct User: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
}

class UserViewModel: ObservableObject {
    @Published var users: [User] = []

    init() {
        fetchUsers()
    }

    func fetchUsers() {
        //simulate get list
        self.users = [
            User(name: "Alice", age: 25),
            User(name: "Bob", age: 30),
            User(name: "Charlie", age: 35)
        ]
    }
    
}

struct ContentView: View {
    @ObservedObject var viewModel = UserViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.users) { user in
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.headline)
                    Text("Age: \(user.age)")
                        .font(.subheadline)
                }
            }
            .navigationTitle("Users")
        }
    }
}

#Preview {
    ContentView()
}
