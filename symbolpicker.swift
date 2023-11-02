

import SwiftUI
import Combine

struct SymbolModel: Identifiable {
    var name: String
    var desc: String?
    
    var id: String {
        name
    }
}


class SymbolViewModel: ObservableObject {
    @Published var searchTerm: String = ""
    @Published var filteredResult: DataListState<[String]> = .idle
    
    private var cancellables = Set<AnyCancellable>()
    
    private var currentSearchTask: Task<Void, Error>?
    private var systemSymbols: [String] = []
    
    init() {
        print("init")
        setupSearchPublisher()
    }
    
    func loadSymbols() {
        Task {
            filteredResult = .working

            do {
                systemSymbols = try await loadSymbolsFromSystem()
                
                filteredResult = systemSymbols.isEmpty ? .emptyData : .success(systemSymbols)
            } catch {
                print("Failed to load symbols: \(error)")
            }
        }
    }
    
    func setupSearchPublisher() {
        $searchTerm
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] term in
                self?.performSearch(with: term)
            }
            .store(in: &cancellables)
    }
    
    
    private func performSearch(with term: String) {
        if term.isEmpty {
            filteredResult = .success(systemSymbols)
        } else {
            filteredResult = .working
            if let existingTask = currentSearchTask {
                existingTask.cancel()
            }
            print("perform search: \(term)")
            currentSearchTask = Task {
                do {
                    //try await Task.sleep(nanoseconds: 2_000_000_000)
                    
                    let results = try await searchSymbols(for: term)
                    filteredResult = results.isEmpty ? .emptyData : .success(results)
                    print("perform search ended: \(term)")
                    
                } catch {
                    if currentSearchTask?.isCancelled ?? false {
                        print("Task was cancelled")
                    } else {
                        filteredResult = .failure(error)
                    }
                }
            }
        }
    }
    
    
    
    @Sendable
    private func searchSymbols(for term: String) async throws -> [String] {
        return systemSymbols.filter { $0.lowercased().contains(term.lowercased()) }
    }
    
    
    private func loadSymbolsFromSystem() async throws -> [String] {
        var symbols = [String]()
        if let bundle = Bundle(identifier: "com.apple.CoreGlyphs"),
           let resourcePath = bundle.path(forResource: "name_availability", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: resourcePath),
           let plistSymbols = plist["symbols"] as? [String: String]
        {
            symbols = Array(plistSymbols.keys)
            
        }
        return symbols
    }
    
}


struct Sample_SymbolPicker: View {
    @StateObject var symbolViewModel = SymbolViewModel()

    @State var animateDate: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {

                    switch symbolViewModel.filteredResult {
                    case .idle, .working:
                        ProgressView()
                    case .failure(let error):
                        Text("Error: \(error.localizedDescription)")
                    case .success(let results):
                        
                        ScrollView(.vertical) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 68))], spacing: 16) {
                                ForEach(results, id: \.self) { result in
                                    SymbolIcon(icon: result)
                                }
                            }
                            
                        }
                        
                    case .emptyData:
                        Text("No results found")
                    }
                
            }
            .animation(.easeIn, value: symbolViewModel.filteredResult.isWorking())
            .navigationTitle("Symbol Picker")
            .searchable(text: $symbolViewModel.searchTerm)
        }
        .onAppear {
            symbolViewModel.loadSymbols()
        }


    }
    
    
    
}


struct SymbolIcon: View {
    
    let icon: String
    //@Binding var selection: String
    
    var body: some View {
        Image(systemName: icon)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            //.foregroundStyle(self.selection == icon ? Color.accentColor : Color.primary)
            .onTapGesture {
//                withAnimation {
//                    self.selection = icon
//                }
            }
    }
    
}

#Preview {
    Sample_SymbolPicker()
}
