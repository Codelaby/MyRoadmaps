// 7 april 2025

import SwiftUI
import UniformTypeIdentifiers

// MARK: Model
struct DocumentModel: Identifiable, Equatable, Hashable, Sendable {
    var id: UUID = .init()
    var fileName: String
    var filePath: String? // Add this property to store the file path
    var data: Data
}

extension Data {
    /// Convierte `Data` a una cadena (`String`) en formato UTF-8.
    /// - Returns: Una cadena si la conversión es exitosa, o `nil` si falla.
    func toString(encoding: String.Encoding = .utf8) -> String? {
        return String(data: self, encoding: encoding)
    }
}

// MARK: Manager
actor DocumentModelManager {
    private var docs: [DocumentModel] = []
    
    // Method to add a new DocumentModel to the collection
    func addDocument(_ data: DocumentModel) {
        docs.append(data)
    }
    
    // Method to retrieve all DocumentModel instances
    func getDocuments() -> [DocumentModel] {
        return docs
    }
    
    // Method to retrieve a filename by document ID
    func getFilename(by id: UUID) -> String? {
        return docs.first { $0.id == id }?.fileName
    }
    
    // Method to retrieve a file path by document ID
    func getFilePath(by id: UUID) -> String? {
        return docs.first { $0.id == id }?.filePath
    }
}


enum DocumentHandlerError: Error, LocalizedError {
    case invalidFileCount(min: Int, max: Int)
    case fileReadError(underlyingError: Error)
    case unsupportedFileType
    
    var errorDescription: String? {
        switch self {
        case .invalidFileCount(let min, let max):
            if min == max {
                return String(localized: "Please select exactly \(min) file(s).")
            } else {
                return String(localized: "Please select between \(min) and \(max) files.")
            }
        case .fileReadError(let underlyingError):
            return String(localized: "Failed to read file: \(underlyingError.localizedDescription)")
        case .unsupportedFileType:
            return String(localized: "Unsupported file type. Please select a JSON file.")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidFileCount:
            return String(localized: "Try selecting a different number of files.")
        case .fileReadError:
            return String(localized: "Check if the file is accessible and try again.")
        case .unsupportedFileType:
            return String(localized: "Only JSON files are supported.")
        }
    }
}

extension DocumentHandlerError {
    static func fromRange(_ range: any RangeExpression<Int>, count: Int) -> DocumentHandlerError {
        switch range {
        case let closedRange as ClosedRange<Int>:
            return .invalidFileCount(min: closedRange.lowerBound, max: closedRange.upperBound)
        case let partialFrom as PartialRangeFrom<Int>:
            return .invalidFileCount(min: partialFrom.lowerBound, max: Int.max)
        case let partialThrough as PartialRangeThrough<Int>:
            return .invalidFileCount(min: 1, max: partialThrough.upperBound)
        case let partialUpTo as PartialRangeUpTo<Int>:
            return .invalidFileCount(min: 1, max: partialUpTo.upperBound - 1)
        default:
            return .invalidFileCount(min: 1, max: 1)
        }
    }
}

// MARK: View Model
@MainActor
@Observable
final class DocumentHandlerVM {
    private(set) var documents: [DocumentModel] = []
    
    let allowedTypes: [UTType] = [.json] // Mime types supported
    /// Between 1 and 3 files 1...3
    /// Minimum 2 files (no maximum) 2...
    /// Maximum 3 files (with an implicit minimum of 1) ...3
    /// Less than 4 files (1, 2 or 3) ..<4
    let fileSelectionRange: any RangeExpression<Int> = ...3
    
    private(set) var isLoading: Bool = false
    private(set) var error: Error?
    
    private let documentManager = DocumentModelManager()
    
    // Computed property to determine if multiple selection is allowed
    var allowsMultipleSelection: Bool {
        switch fileSelectionRange {
        case let closedRange as ClosedRange<Int>:
            return closedRange.upperBound > 1
            
        case let partialFrom as PartialRangeFrom<Int>:
            // Multiple selection allowed if minimum is <=1 (can select 1 or more)
            // or if minimum >1 (must select multiple)
            return true
            
        case let partialThrough as PartialRangeThrough<Int>:
            return partialThrough.upperBound > 1
            
        case let partialUpTo as PartialRangeUpTo<Int>:
            // For ..<n, multiple allowed if n > 2 (since ..<3 allows 1-2 files)
            return partialUpTo.upperBound > 2
            
        default:
            return false
        }
    }
    
    // Function to validate the file count
    private func isValidFileCount(_ count: Int) -> Bool {
        fileSelectionRange.contains(count)
    }
    
    // For process file dropped
    func handleDrop(providers: [NSItemProvider]) async {
        // Validate number of files
        if !fileSelectionRange.contains(providers.count) {
            self.error = DocumentHandlerError.fromRange(fileSelectionRange, count: providers.count)
            return
        }
        
        
        for provider in providers {
            
            for allowedType in allowedTypes {
                if provider.hasItemConformingToTypeIdentifier(allowedType.identifier) {
                    await withCheckedContinuation { continuation in
                        provider.loadItem(forTypeIdentifier: allowedType.identifier) { data, error in
                            Task { @MainActor in // Use MainActor for notify error
                                if let error = error {
                                    self.error = error
                                    continuation.resume()
                                    return
                                }
                            }
                            if let url = data as? URL {
                                Task(priority: .background) { // Running in the child thread
                                    
                                    Task { @MainActor in // Use MainActor for notify change
                                        self.isLoading = true
                                    }
                                    
                                    //print("priority", Task.basePriority?.description)
                                    try await Task.sleep(for: .seconds(3)) // Simulated sleep task
                                    let result = await self.read(from: url) // read data from file
                                    switch result {
                                    case .success(let data):
                                        //let document = DocumentModel(fileName: url.lastPathComponent, data: data)
                                        let document = DocumentModel(
                                            fileName: url.lastPathComponent,
                                            filePath: url.path,
                                            data: data
                                        )
                                        Task { @MainActor in // Use MainActor for notify change
                                            await self.documentManager.addDocument(document)
                                            self.documents = await self.documentManager.getDocuments()
                                            self.isLoading = false
                                            
                                        }
                                    case .failure(let error):
                                        Task { @MainActor in // Use MainActor for notify error
                                            //self.error = error
                                            self.error = DocumentHandlerError.fileReadError(underlyingError: error)
                                            self.isLoading = false
                                        }
                                    }
                                }
                            }
                            continuation.resume()
                        }
                    }
                }
                
                // If multiple selection is not allowed, break after processing the first provider
                if !allowsMultipleSelection {
                    break
                }
            }
            
            // If multiple selection is not allowed, break after processing the first provider
            if !allowsMultipleSelection {
                break
            }
        }
    }
    
    // For process file importer
    func handleFileImporter(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            // Validate number of files
            if !fileSelectionRange.contains(urls.count) {
                self.error = DocumentHandlerError.fromRange(fileSelectionRange, count: urls.count)
                
                return
            }
            
            for url in urls {
                
                Task { @MainActor in // Use MainActor for notify change
                    self.isLoading = true
                }
                
                
                let result = self.read(from: url)
                switch result {
                case .success(let data):
                    let document = DocumentModel(
                        fileName: url.lastPathComponent,
                        filePath: url.path,
                        data: data
                    )
                    Task { @MainActor in
                        await self.documentManager.addDocument(document)
                        self.documents = await self.documentManager.getDocuments()
                        self.isLoading = false
                    }
                case .failure(let error):
                    //self.error = error
                    self.error = DocumentHandlerError.fileReadError(underlyingError: error)
                    self.isLoading = false
                }
            }
        case .failure(let error):
            self.error = error
        }
    }
    
    // For read plain text content
    private func read(from url: URL) -> Result<Data, Error> {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return Result {
            try Data(contentsOf: url)
        }
    }
    
}

// MARK: Document Picker View
struct DocumentPickerView: View {
    @State private var isImporting: Bool = false
    @State private var isDropTargeted: Bool = false
    
    @State private var viewModel = DocumentHandlerVM()
    
    
    var body: some View {
        VStack {
            if !viewModel.documents.isEmpty {
                List {
                    ForEach(viewModel.documents) { document in
                        VStack(alignment: .leading) {
                            Text("Selected file: \(document.fileName)")
                                .padding()
                            
                            if let jsonString = document.data.toString() {
                                Text(jsonString)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .padding()
                            }
                            
                            if let filePath = document.filePath {
                                Text("File Path: \(filePath)")
                                    .padding()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                
                
            } else {
                if viewModel.isLoading {
                    ProgressView().controlSize(.regular)
                } else {
                    
                    ContentUnavailableView {
                        Label("Sin documentos", systemImage: "bookmark")
                    } description: {
                        Text("Drop json files here.")
                    } actions: {
                        
                        Button("Import files", systemImage: "square.and.arrow.down") {
                            isImporting = true
                        }
                        .controlSize(.extraLarge)
                        .buttonStyle(.borderedProminent)
                        
                    }
                    .background {
                        ContainerRelativeShape()
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(isDropTargeted ? .cyan : .gray)
                            .background(isDropTargeted ? Color.cyan.tertiary : Color.clear.tertiary)
                    }
                    .background(.thinMaterial, in: .rect(cornerRadius: 20, style: .continuous))
                    .onDrop(of: viewModel.allowedTypes, isTargeted: $isDropTargeted) { providers in
                        
                        Task {
                            await viewModel.handleDrop(providers: providers)
                        }
                        return true
                    }
                    .padding()
                }
            }
            
            if let error = viewModel.error {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error:")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .foregroundColor(.primary)
                    
                    if let recoverySuggestion = (error as? LocalizedError)?.recoverySuggestion {
                        Text(recoverySuggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding()
            }
        }
        .frame(minWidth: 300, minHeight: 300)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: viewModel.allowsMultipleSelection
        ) { result in
            viewModel.handleFileImporter(result: result)
        }
    }
}

// MARK: Preview
#Preview {
    DocumentPickerView()
}
