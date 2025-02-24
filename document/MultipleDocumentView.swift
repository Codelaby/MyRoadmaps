struct DocumentPickerView: View {
    
    @State private var selectedFilesData: [Data] = []
    @State private var selectedFileNames: [String] = []
    @State private var isImporting: Bool = false
    @State private var error: Error?
    
    var body: some View {
        VStack {
            if !selectedFilesData.isEmpty {
                List {
                    ForEach(Array(zip(selectedFilesData, selectedFileNames)), id: \.1) { data, name in
                        VStack(alignment: .leading) {
                            Text("Selected file: \(name)")
                                .padding()
                            
                            if let jsonString = String(data: data, encoding: .utf8) {
                                Text(jsonString)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .padding()
                            }
                        }
                    }
                }
            }
            
            if let error = error {
                Text("Failed to load file: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button("Import files", systemImage: "square.and.arrow.down") {
                isImporting = true
            }
            
        }
        .frame(minWidth: 300, minHeight: 300)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json], // file support type
            allowsMultipleSelection: true // Allow multiple files
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    let result = read(from: url)
                    switch result {
                    case .success(let data):
                        self.selectedFilesData.append(data)
                        self.selectedFileNames.append(url.lastPathComponent)
                    case .failure(let error):
                        self.error = error
                    }
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


#Preview {
    DocumentPickerView()
}
