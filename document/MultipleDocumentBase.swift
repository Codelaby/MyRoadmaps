import SwiftUI
import UniformTypeIdentifiers


// MARK: Model
struct DocumentModel : Identifiable, Equatable, Hashable, Sendable {
    var id: UUID = .init()
    var fileName: String
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
    func getDocument() -> [DocumentModel] {
        return docs
    }
}

// MARK: View Model
@MainActor
@Observable
final class DocumentHandlerVM {
    private(set) var documents: [DocumentModel] = []
    
    let allowedTypes: [UTType] = [.json] // Mine types supported
    let allowsMultipleSelection: Bool = false // Multiple selection file
    
    var error: Error?
    
    private let documentManager = DocumentModelManager()
    
    // For process file dropped
    func handleDrop(providers: [NSItemProvider]) async {
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
                                    
                                    //print("priority", Task.basePriority?.description)
                                    try await Task.sleep(for: .seconds(3)) // Simulated sleep task
                                    let result = await self.read(from: url) // read data from file
                                    switch result {
                                    case .success(let data):
                                        let document = DocumentModel(fileName: url.lastPathComponent, data: data)
                                        Task { @MainActor in // Use MainActor for notify change
                                            await self.documentManager.addDocument(document)
                                            self.documents = await self.documentManager.getDocument()
                                        }
                                    case .failure(let error):
                                        Task { @MainActor in // Use MainActor for notify error
                                            self.error = error
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
            for url in urls {
                let result = self.read(from: url)
                switch result {
                case .success(let data):
                    let document = DocumentModel(fileName: url.lastPathComponent, data: data)
                    Task { @MainActor in
                        await self.documentManager.addDocument(document)
                        self.documents = await self.documentManager.getDocument()
                    }
                case .failure(let error):
                    self.error = error
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
                        }
                    }
                }
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
            }
            
            if let error = viewModel.error {
                Text("Failed to load file: \(error.localizedDescription)")
                    .foregroundColor(.red)
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
