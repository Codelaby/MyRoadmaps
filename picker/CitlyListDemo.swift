import SwiftUI
import Foundation

// MARK: - Core Architecture Components

// MARK: - Data Models
struct WorldCity: Identifiable, Codable, Sendable, Hashable {
    var id = UUID()
    let name: String
    let country: String
    let subcountry: String
    let geonameid: String
    let timezone: String
    
    nonisolated init(from csvRow: [String]) throws {
        guard csvRow.count >= 5 else {
            throw DataError.invalidRowFormat
        }
        
        self.name = csvRow[0].trimmingCharacters(in: .whitespacesAndNewlines)
        self.country = csvRow[1].trimmingCharacters(in: .whitespacesAndNewlines)
        self.subcountry = csvRow[2].trimmingCharacters(in: .whitespacesAndNewlines)
        self.geonameid = csvRow[3].trimmingCharacters(in: .whitespacesAndNewlines)
        self.timezone = csvRow[4].trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Search Scope
enum SearchScope: Hashable, Sendable, CaseIterable {
    case all
    case country(String)
    case timezone(String)
    
    var title: String {
        switch self {
        case .all:
            return "All"
        case .country(let country):
            return country
        case .timezone(let tz):
            return tz
        }
    }
    
    static var allCases: [SearchScope] {
        return [.all]
    }
}

// MARK: - Error Handling
enum DataError: Error, LocalizedError, Sendable {
    case fileNotFound
    case invalidEncoding
    case invalidRowFormat
    case emptyFile
    case cancellationError
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "CSV file not found"
        case .invalidEncoding:
            return "Unable to read file with UTF-8 encoding"
        case .invalidRowFormat:
            return "Invalid CSV row format"
        case .emptyFile:
            return "CSV file is empty"
        case .cancellationError:
            return "Operation was cancelled"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}


// MARK: - Data Source Layer
@globalActor actor DataSourceActor: GlobalActor {
    static let shared = DataSourceActor()
}

protocol CityDataSource: Sendable {
    func fetchAllCities() async throws -> [WorldCity]
}

@DataSourceActor
final class CSVCityDataSource: CityDataSource {
    static let shared = CSVCityDataSource()
    
    private init() {}
    
    func fetchAllCities() async throws -> [WorldCity] {
        let csvContent = try await readCSVFile(filename: "world-cities")
        return try await parseCSV(content: csvContent)
    }
    
    private func readCSVFile(filename: String) async throws -> String {
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "csv") else {
            throw DataError.fileNotFound
        }
        
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            throw DataError.invalidEncoding
        }
        
        guard !content.isEmpty else {
            throw DataError.emptyFile
        }
        
        return content
    }
    
    private func parseCSV(content: String) throws -> [WorldCity] {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw DataError.emptyFile
        }
        
        // Skip header row if it exists
        let dataLines = lines.first?.contains("name,country") == true ? Array(lines.dropFirst()) : lines
        
        return try dataLines.compactMap { line in
            let columns = parseCSVLine(line)
            guard !columns.isEmpty else { return nil }
            return try WorldCity(from: columns)
        }
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
            
            i = line.index(after: i)
        }
        
        result.append(current)
        return result
    }
}

// MARK: - Repository Layer
protocol CityRepository: Sendable {
    func fetchAllCities() async throws -> [WorldCity]
}

actor CityRepositoryImpl: CityRepository {
    private let dataSource: CityDataSource
    private let semaphore = AsyncSemaphore(value: 1)
    private let cacheKey: Int = 1
    private(set) var cache = [Int: [WorldCity]]()
    
    init(dataSource: CityDataSource) {
        self.dataSource = dataSource
    }
    
    func fetchAllCities() async throws -> [WorldCity] {
        let TAG = "Repository"
        
        do {
            print(TAG, "🚥", semaphore.signalCount > 0 ? "🫡 Ready to proceed" : "💤 Waiting for slot")
            await semaphore.wait()
            
            let key = cacheKey
            if let cachedData = cache[key] {
                print(TAG, "🛟 Using cached data (\(cachedData.count) cities)")
                defer { semaphore.signal() }
                return cachedData
            } else {
                print(TAG, "📥 Fetching from data source")
                //                print(TAG, "⏳ Simulating network delay...")
                //                try await Task.sleep(for: .seconds(7))
                
                let cities = try await dataSource.fetchAllCities()
                cache[key] = cities
                print(TAG, "✅ Fetched \(cities.count) cities")
                
                defer { semaphore.signal() }
                return cities
            }
            
        } catch is CancellationError {
            print(TAG, "✋ Operation cancelled")
            defer { semaphore.signal() }
            throw DataError.cancellationError
        } catch {
            print(TAG, "❗️ Error occurred: \(error)")
            defer { semaphore.signal() }
            throw error
        }
    }
}

// MARK: - Use Case Layer
protocol SearchCitiesUseCase: Sendable {
    func execute(scope: SearchScope, searchText: String) async -> Result<[WorldCity], Error>
}

final class SearchCitiesUseCaseImpl: SearchCitiesUseCase {
    private let repository: CityRepository
    
    init(repository: CityRepository) {
        self.repository = repository
    }
    
    func execute(scope: SearchScope, searchText: String) async -> Result<[WorldCity], Error> {
        let TAG = "UseCase: \(abs(scope.hashValue + searchText.hashValue).toHexString())"
        
        print(TAG, "🔍 Searching for '\(searchText)' in scope '\(scope.title)'")
        
        do {
            print(TAG, "⏳ Processing search...")
            //try await Task.sleep(for: .seconds(1)) // Simulate processing time
            
            let allCities = try await repository.fetchAllCities()
            let filteredCities = filterCities(allCities, scope: scope, searchText: searchText)
            
            print(TAG, "🔦 Found \(filteredCities.count) cities")
            return .success(filteredCities)
            
        } catch is CancellationError {
            print(TAG, "✋ Search cancelled")
            return .failure(DataError.cancellationError)
        } catch {
            print(TAG, "❗️ Search failed: \(error)")
            return .failure(error)
        }
    }
    
    private func filterCities(_ cities: [WorldCity], scope: SearchScope, searchText: String) -> [WorldCity] {
        let scopeFiltered = filterByScope(cities, scope: scope)
        return filterBySearchText(scopeFiltered, searchText: searchText)
    }
    
    private func filterByScope(_ cities: [WorldCity], scope: SearchScope) -> [WorldCity] {
        switch scope {
        case .all:
            return cities
        case .country(let country):
            return cities.filter { $0.country.localizedCaseInsensitiveContains(country) }
        case .timezone(let timezone):
            return cities.filter { $0.timezone.localizedCaseInsensitiveContains(timezone) }
        }
    }
    
    private func filterBySearchText(_ cities: [WorldCity], searchText: String) -> [WorldCity] {
        guard !searchText.isEmpty else { return cities }
        return cities.filter { city in
            city.name.localizedCaseInsensitiveContains(searchText) ||
            city.country.localizedCaseInsensitiveContains(searchText) ||
            city.subcountry.localizedCaseInsensitiveContains(searchText)
        }
    }
}


// MARK: - State Management
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

// MARK: - View Model
@Observable
final class WorldCitiesViewModel: Sendable {
    private let repository: CityRepository
    private let searchUseCase: SearchCitiesUseCase
    
    private(set) var citiesState: DataListState<[WorldCity]> = .firstLoading
    private(set) var availableScopes: [SearchScope] = [.all]
    private(set) var lastSearchTerm: String = ""
    
    var selectedScope: SearchScope = .all
    var searchText: String = ""
    
    
    private var lastFingerPrint: Int = 0
    private var activeTasksCount: Int = 0
    
    init(repository: CityRepository) {
        self.repository = repository
        self.searchUseCase = SearchCitiesUseCaseImpl(repository: repository)
    }
    
    // MARK: - Search cities
    @concurrent
    func searchCities() async throws {
        let scope = await self.selectedScope
        let searchText = await self.searchText
        let currentFingerPrint = await abs(scope.hashValue + searchText.hashValue)
        
        let previousFingerPrint = await MainActor.run { lastFingerPrint }
        guard currentFingerPrint != previousFingerPrint else { return }
        
        await MainActor.run { lastFingerPrint = currentFingerPrint }
        await MainActor.run { activeTasksCount += 1 }
        
        print("VM:", "🔍 Starting search for '\(searchText)' in scope '\(await scope.title)'")
        print("VM:", "🏎️ \(await currentFingerPrint.toHexString()) Active searches: \(await activeTasksCount)")
        
        Task { @MainActor in
            citiesState.startWorking()
        }
        
        let result = await searchUseCase.execute(scope: scope, searchText: searchText)
        
        switch result {
        case .success(let cities):
            let shouldUpdateAvailableScopes = await MainActor.run { availableScopes.count <= 1 }
            if shouldUpdateAvailableScopes {
                await updateAvailableScopes(from: cities)
            }
            
            await MainActor.run { activeTasksCount -= 1 }
            
            let activeCount = await MainActor.run { activeTasksCount }
            if activeCount == 0 {
                print("VM:", "📦 Updating UI with \(cities.count) cities (\(await currentFingerPrint.toHexString()))")
                await MainActor.run { lastSearchTerm = searchText }
                Task { @MainActor in
                    citiesState = .success(cities)
                }
            }
            
        case .failure(let error):
            await MainActor.run { activeTasksCount -= 1 }
            
            if Task.isCancelled {
                print("VM:", "🫸 Search cancelled for '\(searchText)'")
            } else {
                print("VM:", "⚠️ Error searching cities: \(error)")
                Task { @MainActor in
                    citiesState = .failure(error)
                }
            }
        }
    }
    
    // MARK: - Scope collection
    private func updateAvailableScopes(from cities: [WorldCity]) {
        let uniqueCountries = Set(cities.map { $0.country }).sorted()
        let countryScopes = uniqueCountries.map { SearchScope.country($0) }
        //Task { @MainActor in
        availableScopes = [.all] + countryScopes
        //}
    }
}

// MARK: - Views
struct WorldCitiesView: View {
    @State private var viewModel: WorldCitiesViewModel?
    @State private var isSearchPresented = false
    
    var body: some View {
        
        NavigationStack {
            if let viewModel = viewModel {
                @Bindable var viewModel = viewModel //if need bindable data in viewModel
                
                ScrollView(.vertical) {
                    scopeSelectionView(viewModel: viewModel)
                        .redacted(reason: viewModel.citiesState.isFirstLoading() ? .placeholder : .invalidated)
                    
                    contentView(viewModel: viewModel)
                }
                .searchable(
                    text: $viewModel.searchText,
                    isPresented: $isSearchPresented,
                    placement: .toolbar,
                    prompt: Text("Search cities")
                )
                .navigationTitle("World Cities")
                .animation(.smooth, value: viewModel.citiesState.isSuccess())
                .task(id: viewModel.selectedScope, priority: .background) {
                    await performSearch(viewModel: viewModel)
                }
                .task(id: viewModel.searchText, duration: .milliseconds(500)) { [viewModel] in
                    await performSearch(viewModel: viewModel)
                }
                
            } else {
                // MARK: - Viewmodel loader
                ProgressView("Loading...")
                    .task {
                        if viewModel == nil {
                            let dataSource = await CSVCityDataSource.shared
                            let repository = CityRepositoryImpl(dataSource: dataSource)
                            await MainActor.run {
                                viewModel = WorldCitiesViewModel(repository: repository)
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Scope selection
    @ViewBuilder
    private func scopeSelectionView(viewModel: WorldCitiesViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.availableScopes, id: \.self) { scope in
                    Button(scope.title) {
                        viewModel.selectedScope = scope
                    }
                    //                    .buttonStyle(selectedScope == scope ? .borderedProminent : .bordered)
                    .clipShape(.capsule)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Hub view
    @ViewBuilder
    private func contentView(viewModel: WorldCitiesViewModel) -> some View {
        switch viewModel.citiesState {
        case .firstLoading, .working:
            loadingView
            
        case .failure(let error):
            errorView(error)
            
        case .success(let cities) where cities.isEmpty:
            emptyStateView(viewModel: viewModel)
            
        case .success(let cities):
            cityListView(cities)
        }
    }
    
    // MARK: - loading state view
    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Spacer().containerRelativeFrame([.horizontal, .vertical])
            ProgressView("Loading cities...")
        }
    }
    
    // MARK: - error state view
    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        ZStack {
            Spacer().containerRelativeFrame([.horizontal, .vertical])
            ContentUnavailableView(
                "Failed to load cities",
                systemImage: "exclamationmark.circle.fill",
                description: Text(error.localizedDescription)
            )
        }
    }
    
    // MARK: - Empty state view
    @ViewBuilder
    private func emptyStateView(viewModel: WorldCitiesViewModel) -> some View {
        ZStack {
            Spacer().containerRelativeFrame([.horizontal, .vertical])
            if viewModel.lastSearchTerm.isEmpty {
                ContentUnavailableView(
                    "No cities available",
                    systemImage: "globe.badge.chevron.backward"
                )
            } else {
                ContentUnavailableView.search(text: viewModel.lastSearchTerm)
            }
        }
    }
    
    // MARK: - City list
    @ViewBuilder
    private func cityListView(_ cities: [WorldCity]) -> some View {
        LazyVStack {
            
            ForEach(cities, id: \.self) { city in
                CityRowView(city: city)
                    .padding(.horizontal)
                    .id(city.id)
                Divider()
            }
        }
    }
    // MARK: - Perform Search
    private func performSearch(viewModel: WorldCitiesViewModel) async {
        do {
            try await viewModel.searchCities()
        } catch {
            print("✋ Search cancelled")
        }
    }
}

struct CityRowView: View {
    let city: WorldCity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let countryText = city.subcountry.isEmpty
            ? city.country
            : "\(city.country) • \(city.subcountry)"
            
            LabeledContent {
                Text(formattedUTCOffset(for: city.timezone) ?? "N/A")
            } label: {
                Text(city.name)
                    .lineLimit(1)
                Text(countryText)
                    .lineLimit(2)
            }
            
            LabeledContent {
                Text("ID: \(city.geonameid)")
            } label: {
                Label(city.timezone, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(.vertical, 2)
    }
    
    private func formattedUTCOffset(for identifier: String) -> String? {
        guard let tz = TimeZone(identifier: identifier) else {
            return nil
        }
        
        let offsetSeconds = tz.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600
        let offsetMinutes = abs(offsetSeconds % 3600) / 60
        
        if offsetSeconds == 0 {
            return "UTC+0"
        } else if offsetMinutes == 0 {
            return String(format: "UTC%+d", offsetHours)
        } else {
            return String(format: "UTC%+d:%02d", offsetHours, offsetMinutes)
        }
    }
}

// MARK: - Utilities
//extension Int {
//    func toHexString() -> String {
//        return String(format: "0x%02x", self)
//    }
//}
//extension Thread {
//    public static var currentThread: Thread {
//        return Thread.current
//    }
//}

// MARK: - Preview
#Preview {
    WorldCitiesView()
}
