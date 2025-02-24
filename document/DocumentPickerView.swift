struct DocumentPickerView: View {
    
    @State private var selectedFileData: Data? = nil
    @State private var selectedFileName: String = ""
    @State private var isImporting: Bool = false
    @State private var error: Error?
    
    var body: some View {
        VStack {
            if let data = selectedFileData {
                Text("Selected file: \(selectedFileName)")
                    .padding()
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    Text(jsonString)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding()
                }
            }
            
            if let error = error {
                Text("Failed to load file: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button("Import file", systemImage: "square.and.arrow.down") {
                isImporting = true
            }
            
        }
        .frame(minWidth: 300, minHeight: 300)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json] // file support type
        ) { result in
            switch result {
            case .success(let url):
                let result = read(from: url)
                switch result {
                case .success(let data):
                    self.selectedFileData = data
                    self.selectedFileName = url.lastPathComponent
                case .failure(let error):
                    self.error = error
                }
            case .failure(let error):
                self.error = error
            }
        }
    }
    
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
