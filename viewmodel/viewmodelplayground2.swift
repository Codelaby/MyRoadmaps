import SwiftUI

@main
struct MVVMPlaygroundApp: App {
    @StateObject private var viewModel = TimestampViewModel()
 
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

//----

struct Timestamp: Identifiable {
    let id = UUID()
    let date: Date
}

class TimestampViewModel: ObservableObject {
    @Published var timestamps: [Timestamp] = []
 
    func addTimestamp() {
        let newTimestamp = Timestamp(date: Date())
        timestamps.append(newTimestamp)
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: AddTimeStampView()) {
                    Text("Add Timestamps")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                NavigationLink(destination: ListStampView()) {
                    Text("List Timestamps")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Timestamps")
        }
    }
}

struct AddTimeStampView: View {
    @EnvironmentObject var viewModel: TimestampViewModel
 
    var body: some View {
        VStack {
            List(viewModel.timestamps) { timestamp in
                Text(timestamp.date, format: .dateTime.year().month().day().hour().minute().second())
                    .font(.headline)
            }
            Button(action: {
                viewModel.addTimestamp()
            }) {
                Text("Add Timestamp")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Add Timestamps")
    
    }
}

struct ListStampView: View {
    @EnvironmentObject var viewModel: TimestampViewModel

    var body: some View {
        VStack {
            if viewModel.timestamps.isEmpty {
                Text("No timestamps available.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(viewModel.timestamps) { timestamp in
                    Text(timestamp.date, format: .dateTime.year().month().day().hour().minute().second())
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Timestamps")
    }
}

#Preview {
    ContentView()
        .environmentObject(TimestampViewModel())
}

#Preview("Add") {
    AddTimeStampView()
        .environmentObject(TimestampViewModel())
}
#Preview("List") {
    ListStampView()
        .environmentObject(TimestampViewModel())
}
