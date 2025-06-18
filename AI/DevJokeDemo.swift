
import SwiftUI
import FoundationModels
import Observation

// Working swift 6
// Default actor insolate: noinsolated
struct DevJokesTool: Tool {
    
    var name: String = "devJokesTool"
    var description: String = "Generate developer jokes related to programming, coding languages, debugging, and tech culture. Perfect for lightening the mood during long coding sessions."
    
    @Generable
    struct Arguments {
        @Guide(description: "A natural language topic or keyword to base the dev joke on, such as 'JavaScript', 'debugging', or 'API'.")
        let naturalLanguageQuery: String
    }
    
    func call(arguments: Self.Arguments) async throws -> ToolOutput {
        let randomJoke = randomDadJoke()
        return ToolOutput(randomJoke)
    }
    
    private func randomDadJoke() -> String {
        let jokes = [
            "Why do programmers prefer dark mode? Because light attracts bugs.",
            "A SQL query walks into a bar, walks up to two tables and asks... 'Can I join you?'",
            "Why do Java developers wear glasses? Because they don’t C#.",
            "I told my computer I needed a break, and it said: 'Why not try recursion?'",
            "How many programmers does it take to change a light bulb? None, that’s a hardware problem.",
            "There are 10 types of people in this world: those who understand binary and those who don’t.",
            "What's a programmer's favorite hangout place? The Foo Bar.",
            "Debugging: being the detective in a crime movie where you are also the murderer.",
            //"Wy did the developer go broke? Because he used up all his cache.", // this setence no like a xcode
            "Why do Python devs make great comedians? They know how to handle exceptions."
        ]
        
        return jokes.randomElement() ?? "I'm all out of jokes... for now!"
    }
    
}

@Generable
struct Joke {
    let text: String
}

@Observable
@MainActor
class JokeMaker {
    
    let session: LanguageModelSession
    private(set) var joke: Joke.PartiallyGenerated?
    let dadJokesTool = DevJokesTool()
    
    init() {
        self.session = LanguageModelSession(tools: [dadJokesTool]) {
                """
                You are a professional joke writer. Your task is to generate short, clever, and family-friendly jokes on request. Keep the tone light and playful.
                """
            
                """
                Use the devJokesTool to create funny and family friendly dev jokes.
                """
        }
    }
    
    @concurrent
    func suggestJoke() async throws {
        
        let prompt = "Tell me a short, clever, and family-friendly joke "
        
        let stream = session.streamResponse(to: prompt, generating: Joke.self)
        
        for try await partial in stream {
            Task { @MainActor in
                self.joke = partial
            }
        }
    }
}

struct DevJokesDemo: View {
    @State private var jokeMaker: JokeMaker?
    
    var body: some View {
        
        
        
        VStack {
            if jokeMaker?.session.isResponding ?? true {
                Image(systemName: "ellipsis.message")
                    .symbolEffect(.variableColor)
            }
            
            Button("Get a joke") {
                Task {
                    try await jokeMaker?.suggestJoke()
                }
            }.disabled(jokeMaker?.session.isResponding ?? true)
                .buttonStyle(.bordered)
                .glassEffect()
            
            if let joke = jokeMaker?.joke {
                if let text = joke.text {
                    Text(text)
                }
            }
            
        }
        .padding()
        .task {
            jokeMaker = JokeMaker()
        }
    }
}

#Preview {
    DevJokesDemo()
}
