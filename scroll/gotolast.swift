import SwiftUI
import Combine

struct MessageModel: Identifiable, Hashable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let user: String
}

class ChatViewModel: ObservableObject {
    @Published var messages: [MessageModel] = []
    private var timer: AnyCancellable?
    
    let possibleUserList = [
            "Xi Jinping",
            "Narendra Modi",
            "Kim Jong-un",
            "Vladímir Putin",
            "Pedro Sánchez",
            "Emmanuel Macron",
            "Ursula von der Leyen"
        ]

    
    init() {
        //startTimer()
        let count = 100
        for _ in 0..<count {
            let randomMessageNumber = Int.random(in: 1...1000)
            addMessage("New message \(randomMessageNumber)") // Assuming addMessage exists
        }

    }
    
    deinit {
       // timer?.cancel()
    }
    
    func addMessage(_ content: String) {
        let newMessage = MessageModel(
            content: content,
            timestamp: Date(),
            user: possibleUserList.randomElement() ?? "Unknown"
        )
        messages.append(newMessage)
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.addMessage("New message \(Int.random(in: 1...1000))")
        }
    }
}



struct ScrollToLast: View {
        @StateObject private var viewModel = ChatViewModel()
        @State private var message: String = ""
        
        var body: some View {
            ScrollViewReader { proxy in
                VStack {
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.messages) { message in
                                MessageRow(message: message)
                                    .id(message.id)
                            }
                        }
                    }
//                    .onChange(of: viewModel.messages) { oldValue, newValue in
//                        withAnimation {
//                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
//                        }
//                    }
                    
                    // Text and send button
                    HStack {
                        TextField("Send a message", text: $message)
                            .textFieldStyle(.roundedBorder)

                        Button("", systemImage: "paperplane.fill", action: {
                            viewModel.addMessage(message)
                            message = ""
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.smooth) {
                                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                                }
                            }
                            
                        })
                        .buttonStyle(BorderedButtonStyle())
                        .labelStyle(.iconOnly)
                        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)

                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    withAnimation(.smooth) {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    struct MessageRow: View {
        let message: MessageModel
        let possibleColors: [UIColor] = [
            .blue,
            .orange,
            .red,
            .green,
            .purple
        ]
        
        private func generateRandomColor() -> UIColor {
            let randomInt = Int.random(in: 0..<possibleColors.count)
            return possibleColors[randomInt]
        }
        
        var body: some View {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(generateRandomColor()))
                VStack(alignment: .leading) {
                    
                    HStack {
                        Text(message.user + ": ")
                            .foregroundColor(Color(generateRandomColor()))
                            .font(.footnote)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(message.timestamp, formatter: dateFormatter)")
                            .foregroundStyle(Color.gray)
                            .font(.caption)
                    }

                    Text(message.content)
                        .font(.body)
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    


#Preview {
    ScrollToLast()
}
