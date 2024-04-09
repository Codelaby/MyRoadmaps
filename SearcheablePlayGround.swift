import SwiftUI

//https://swiftwithmajid.com/2022/06/28/the-power-of-task-view-modifier-in-swiftui/
struct DebouncingTaskViewModifier<ID: Equatable>: ViewModifier {
    let id: ID
    let priority: TaskPriority
    let duration: Duration
    let task: @Sendable () async -> Void
    
    init(
        id: ID,
        priority: TaskPriority = .userInitiated,
        duration: Duration = .nanoseconds(0),
        task: @Sendable @escaping () async -> Void
    ) {
        self.id = id
        self.priority = priority
        self.duration = duration
        self.task = task
    }
    
    func body(content: Content) -> some View {
        content.task(id: id, priority: priority) {
            do {
                try await Task.sleep(for: duration)
                await task()
            } catch {
                // Ignore cancellation
            }
        }
    }
}

extension View {
    func task<ID: Equatable>(
        id: ID,
        priority: TaskPriority = .userInitiated,
        duration: Duration = .nanoseconds(0),
        task: @Sendable @escaping () async -> Void
    ) -> some View {
        modifier(
            DebouncingTaskViewModifier(
                id: id,
                priority: priority,
                duration: duration,
                task: task
            )
        )
    }
}

//
struct Book: Identifiable {
    var id: UUID = UUID.init()
    var title: String
    var author: String
}

enum ViewState {
    case content([Book])
    case firstLoading
    case error
}



struct SearcheablePlayGround: View {
    
    @State var state = ViewState.firstLoading
    
    @State var searchText: String = ""
    @State var isFiltering: Bool = false
    
    var body: some View {
        
        NavigationSplitView {
            
            Group {
                switch state {
                case .content(let books) where books.isEmpty:
                    Spacer()
                    Text("Empty")
                    Spacer()
                case .content(let books):
                    List {
                        ForEach(books, id:\.id) { book in
                            
                            ZStack {
                                Text(book.title)
                                NavigationLink(destination: DetailBook(item: book)) {
                                    EmptyView()
                                }
                                .opacity(0.0)
                                
                            }
                        }
                        
                    }
                    .redacted(reason: isFiltering ? /*@START_MENU_TOKEN@*/.placeholder/*@END_MENU_TOKEN@*/ : .invalidated)
                case .firstLoading:
                    Spacer()
                    Text("Loading...")
                    Spacer()
                case .error:
                    Spacer()
                    Text("Error")
                    Spacer()
                }
                
            }
            
        } detail: {
            Text("Please select a row")
        }
        .searchable(text: $searchText)
        .task(id: searchText, duration: .milliseconds(500)) {
            
            print("perform search", searchText)
            do {
                try await taskLong(query: searchText)
            } catch {
                print("✋ Cancelled last search")
                print()
            }
            
        }
        
    }
    
    
    func taskLong(query: String) async throws  {
        
        isFiltering = true
        
        do {
            
            var data: [Book] = []
            
            for i in 0..<100 {
                try await Task.sleep(for: .milliseconds(10))
                data.append(Book(title: "title \(i)", author: "author \(i)"))
                print("👉 Processed element \(i)")
            }
            
            // Filter data based on query
            let filteredData: [Book] = data.filter { book in
                query.isEmpty ||
                    book.title.lowercased().contains(query.lowercased()) ||
                    book.author.lowercased().contains(query.lowercased())
            }
            
            state = .content(filteredData)
            isFiltering = false

        } catch is CancellationError {
            print("‼️ Handle cancelation task")
        } catch(let error) {
            print("🐞 Oups", error.localizedDescription)
            isFiltering = false
        }
    }
    
    
}

struct DetailBook: View {
    
    var item: Book
    
    var body: some View {
        VStack {
            Text(item.title)
            Text(item.author)
        }
    }
}


#Preview {
    SearcheablePlayGround()
}
