//
//  SearchScopePlayground.swift
//  FieldsPlayground
//
//  Created by Codelaby on 9/11/24.
//
/*
He implementado un sistema de filtrado por alcance y búsqueda en Swift 6, utilizando Clean Architecture.
Para optimizar el rendimiento, he incorporado cancelación de tareas y semáforos para garantizar que la búsqueda solo se ejecute una vez que todos los datos estén cargados.
Esto proporciona una experiencia de usuario más fluida, evitando resultados parciales mientras se cargan los datos.
*/
//
//  SearchScopePlayground.swift
//  FieldsPlayground
//
//  Created by Codelaby on 9/11/24.
//

import SwiftUI

// MARK: Model
enum MusicGenre: String, Identifiable, CaseIterable, Hashable, Sendable, CustomStringConvertible {
    case classical = "Classical"
    case jazz = "Jazz"
    case rock = "Rock"
    case pop = "Pop"
    case electronic = "Electronic"
    case hipHop = "Hip Hop"
    case country = "Country"
    case folk = "Folk"
    case blues = "Blues"
    case reggae = "Reggae"
    case kpop = "K-pop"
    case trance = "Trance"
    
    var id: String { rawValue }
    
    // Custom description
    var description: String {
        switch self {
        case .classical: return "A timeless genre with rich harmonies and melodies."
        case .jazz: return "A genre known for improvisation and swing."
        case .rock: return "High-energy music with electric guitars and strong rhythms."
        case .pop: return "Catchy tunes that appeal to a broad audience."
        case .electronic: return "Music created with synthesizers and digital sounds."
        case .hipHop: return "Rhythmic music with rap and beats."
        case .country: return "Music with storytelling and acoustic instruments."
        case .folk: return "Traditional music with cultural roots."
        case .blues: return "Soulful music expressing deep emotions."
        case .reggae: return "Music with laid-back rhythms and Caribbean vibes."
        case .kpop: return "Korean pop music with catchy melodies and energetic performances."
        case .trance: return "A subgenre of electronic music with repetitive beats and synthesizer melodies."
        }
    }
}

struct SongModel: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let genres: [MusicGenre]
}


enum SearchScopeOption: Hashable {
    case all
    case genre(option: MusicGenre)
    
    var title: String {
        switch self {
        case .all:
            return "All"
        case let .genre(option):
            return option.rawValue
        }
    }
}



// MARK: Datasource
protocol SongDataSource: Sendable {
    func fetchAllSongs() async throws -> [SongModel]
}

final class SongLocalDataSource: SongDataSource {
    func fetchAllSongs() async throws -> [SongModel] {
        
        // Expensive processing
        let data = [
            SongModel(title: "Moonlight Sonata", genres: [.classical]),
            SongModel(title: "Take Five", genres: [.jazz]),
            SongModel(title: "Bohemian Rhapsody", genres: [.rock]),
            SongModel(title: "Thriller", genres: [.pop]),
            SongModel(title: "Sandstorm", genres: [.electronic]),
            SongModel(title: "Lose Yourself", genres: [.hipHop]),
            SongModel(title: "Jolene", genres: [.country]),
            SongModel(title: "Blowin' in the Wind", genres: [.folk]),
            SongModel(title: "The Thrill Is Gone", genres: [.blues]),
            SongModel(title: "No Woman, No Cry", genres: [.reggae]),
            SongModel(title: "Imagine", genres: [.pop, .rock]),
            SongModel(title: "Hey Jude", genres: [.rock]),
            SongModel(title: "Blue in Green", genres: [.jazz]),
            SongModel(title: "Für Elise", genres: [.classical]),
            SongModel(title: "Gangnam Style", genres: [.kpop]),
            SongModel(title: "Children", genres: [.electronic, .trance]),
            SongModel(title: "Dynamite", genres: [.kpop]),
            SongModel(title: "Sandstorm", genres: [.electronic, .trance]),
            SongModel(title: "Clair de Lune", genres: [.classical]),
            SongModel(title: "Butter", genres: [.kpop]),
            SongModel(title: "Mic Drop", genres: [.kpop]),
            SongModel(title: "DNA", genres: [.kpop]),
            SongModel(title: "Fake Love", genres: [.kpop]),
            SongModel(title: "Boy with Luv", genres: [.kpop]),
            SongModel(title: "Age of Love", genres: [.electronic, .trance]),
            SongModel(title: "Silence", genres: [.electronic, .trance]),
            SongModel(title: "For an Angel", genres: [.electronic, .trance]),
            SongModel(title: "Adagio for Strings", genres: [.electronic, .trance]),
            SongModel(title: "The Four Seasons", genres: [.classical]),
            SongModel(title: "Canon in D", genres: [.classical]),
            SongModel(title: "Swan Lake", genres: [.classical]),
            SongModel(title: "Ode to Joy", genres: [.classical]),
            SongModel(title: "Ave Maria", genres: [.classical])
        ]
        return data
    }
}



// MARK: Repository
protocol MusicRepository: Sendable {
    func fetchAllSongs() async throws -> [SongModel]
}

actor MusicRepositoryImpl: MusicRepository {
    
    private let dataSource: SongDataSource
    
    private let cacheKey: Int = 1
    private(set) var cache = [Int: [SongModel]]()
    
    init(dataSource: SongDataSource) {
        self.dataSource = dataSource
    }
    
    func fetchAllSongs() async throws -> [SongModel] {
        let key = cacheKey
        if let cachedData = cache[key] {
            print("🛟 fetch all data from cache", cachedData.count)
            return cachedData
            //return .success(cachedData)
            //return cachedData
        } else {
            print("☁️ fetch all data from source")
            
            print("⏳ Whait 5 seconds")
            try await Task.sleep(for: .seconds(5)) // Simulate a network delay
            
            let processedData = try! await dataSource.fetchAllSongs()
            cache[key] = processedData
            print("✅ Fetched data")
            return processedData
            //return processedData
        }
        
    }
    
}


// MARK: Use Case

enum MusicError: Error {
    case cancellationError
}

protocol MusicUseCase: Sendable {
    var repository: MusicRepository { get }
    func execute(for scope:  SearchScopeOption, with searchText: String) async -> Result<[SongModel], Error>
    init(repository: MusicRepository)
}

final class MusicUseCaseImpl: MusicUseCase {
    let repository: MusicRepository
    private let semaphore = AsyncSemaphore(value: 1)

    init(repository: MusicRepository) {
        self.repository = repository
    }

    func execute(for scope: SearchScopeOption, with searchText: String) async -> Result<[SongModel], Error> {
        print("usecase: MusicUseCase.execute", "for: \(scope)", "with:\(searchText)")
        do {
            await semaphore.wait() // Wait for the semaphore to become available, limiting concurrent executions to one
            print("usecase", "🚥 run race")
            print("⏳ Simulating network delay...")
            try await Task.sleep(for: .seconds(1))

            let data = try await repository.fetchAllSongs()
            
            let filteredData = filterByScopeAndTerm(from: data, scope: scope, searchText: searchText)

            defer { semaphore.signal() } // Release the semaphore to allow other tasks to proceed
            print("usecase", "🏁 end race")

            return .success(filteredData)
        } catch is CancellationError {
            print("usecase:", "✋ Cancellation requested: releasing the 🚦 and returning a cancellation error")
            defer { semaphore.signal() } // send signal for run other task
            return .failure(MusicError.cancellationError)
        } catch {
            print("usecase:", "❗️An unexpected error occurred: releasing the 🚦 and returning the error")
            defer { semaphore.signal() } // send signal for run other task
            return .failure(error)
        }
    }

    /// Filters the songs based on scope and search text.
    private func filterByScopeAndTerm(from data: [SongModel], scope: SearchScopeOption, searchText: String) -> [SongModel] {
        let scopeFiltered = filterByScope(from: data, for: scope)
        return filterByTerm(from: scopeFiltered, searchText: searchText)
    }

    /// Filters songs by scope.
    private func filterByScope(from data: [SongModel], for scope: SearchScopeOption) -> [SongModel] {
        return data.filter { song in
            switch scope {
            case .all:
                return true
            case .genre(let genre):
                return song.genres.contains(genre)
            }
        }
    }

    /// Filters songs by search term.
    private func filterByTerm(from data: [SongModel], searchText: String) -> [SongModel] {
        guard !searchText.isEmpty else { return data }
        return data.filter { song in
            song.title.localizedCaseInsensitiveContains(searchText) ||
            song.genres.map(\.rawValue).joined(separator: ", ").localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: Result Types

enum DataListState<T: Sendable>: Sendable {
    case firstLoading
    case working
    case failure(Error)
    case success(T)
    
    mutating func startWorking() {
        if !isFirstLoading() && !isWorking() {
            self = .working
        }
    }
    
    func isFirstLoading() -> Bool {
        if case .firstLoading = self {
            return true
        }
        return false
    }
    
    func isWorking() -> Bool {
        if case .working = self {
            return true
        }
        return false
    }
    
    func isSuccess() -> Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

// MARK: ViewModel

@MainActor
@Observable
final class MusicViewModel { //: @unchecked Sendable
    private let repository: MusicRepository
    
    private(set) var filteredMusic: DataListState<[SongModel]> = .firstLoading
    private(set) var availableGenres: [SearchScopeOption] = [.all] // Empieza con "All"
    
    private(set) var lastSearchTerm: String = ""
    
    //use case
    let getMusicUseCase: MusicUseCase
    

    
    init(repository: MusicRepository) {
        self.repository = repository
        self.getMusicUseCase = MusicUseCaseImpl(repository: repository)
    }
    
    
    //@MainActor
    func filterSongs(for scope: SearchScopeOption, searchText: String) async throws {
        print("vm: filterSongs")
        print("🔎 filterSongs", scope.title, searchText)
        
        filteredMusic.startWorking()

        let result = await getMusicUseCase.execute(for: scope, with: searchText)
        
        switch(result) {
        case .success(let songs):
            print("vm:", "👉 candidates \(songs.count)")
            
            // For generate genres scope search
            if availableGenres.count <= 1 {
                let genres = Set(songs.flatMap { $0.genres })
                let candidates: [SearchScopeOption] = [.all] + genres.map {.genre(option: $0) }.sorted { $0.title < $1.title }
                
                Task { @MainActor in // Update genres
                    
                    availableGenres = candidates
                }
            }
            
            Task { @MainActor in
                lastSearchTerm = searchText
                filteredMusic = .success(songs)
            }
            
        case .failure(let error):
            if Task.isCancelled {
                //repository.semaphore.signal()
                print("vm: ✋ last task was cancelled", error)
            } else {
                Task { @MainActor in
                    filteredMusic = .failure(error)
                }
            }
            //filteredMusic = .failure(error)
        }
        
    }
    
}

// MARK: List View
struct MusicListView: View {
    @State private var viewModel: MusicViewModel
    
    @State private var isPresented = false
    @State private var searchText: String = ""

    @State private var selectedScope: SearchScopeOption = .all // Scope seleccionado
    
    
    init() {
        let localDataSource = SongLocalDataSource()
        let repository = MusicRepositoryImpl(dataSource: localDataSource)
        
        _viewModel = State(wrappedValue: MusicViewModel(repository: repository))
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel //if need bindable data in viewModel
        
        NavigationStack {
            CustomScopeSearch()
                .redacted(reason: viewModel.filteredMusic.isFirstLoading() ? .placeholder : .invalidated)
            
            Group {
                switch viewModel.filteredMusic {
                case .firstLoading, .working:
                    // Loading State
                    ProgressView()
                    
                case .failure(let error):
                    // Failure State
                    ContentUnavailableView(
                        "Failed to load songs",
                        systemImage: "exclamationmark.circle.fill",
                        description: Text("Failed to load songs.\(error.localizedDescription)")
                    )
                case .success(let songs) where songs.isEmpty:
                    let _ = Self._printChanges()
                    // Handle empty state
                    if viewModel.lastSearchTerm.isEmpty {
                        ContentUnavailableView(
                            "No songs available.",
                            systemImage: "exclamationmark.circle.fill",
                            description: Text("No songs available.")
                        )
                    } else {
                        ContentUnavailableView
                            .search(text: viewModel.lastSearchTerm)
                    }
                    
                    
                case .success(let songs):
                    
                    List(songs, id: \.self) { song in
                        VStack(alignment: .leading) {
                            Text(song.title)
                                .font(.headline)
                            Text(song.genres.map(\.rawValue).joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .scrollDismissesKeyboard(.automatic)

                }
            }
            .searchable(text: $searchText, isPresented: $isPresented, placement: .toolbar, prompt:  Text("Search"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Songs")
            .animation(.smooth, value: viewModel.filteredMusic.isSuccess())
            .task(id: selectedScope, priority: .background) {
                do {
                    try await performSearch(scope: selectedScope, query: searchText)
                } catch {
                    print("✋ Cancelled last search")
                    print()
                }
            }
            .task(id: searchText, duration: .milliseconds(500)) {
                
                //await print("perform search", searchText)
                do {
                    
                    try await performSearch(scope: selectedScope, query: searchText)
                } catch {
                    print("✋ Cancelled last search")
                    print()
                }
                
            }
            
        }
        
    }
    
    func performSearch(scope: SearchScopeOption, query: String) async throws {
        try await viewModel.filterSongs(for: selectedScope, searchText: query)
    }
    
    
    @ViewBuilder
    private func CustomScopeSearch() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                
                ForEach(viewModel.availableGenres, id: \.self) { scope in
                    
                    Button(scope.title) {
                        selectedScope = scope
                    }
                    .modifiers { view in
                        if selectedScope == scope {
                            view.buttonStyle(.borderedProminent)
                        } else {
                            view.buttonStyle(.bordered)
                        }
                    }
                    .accentColor(selectedScope == scope ? Color.accentColor : .none)
                    .clipShape(.capsule)
                }
            }
        }
        .contentMargins(.horizontal, 16)
        
    }
    
}

#Preview {
    MusicListView()
}
