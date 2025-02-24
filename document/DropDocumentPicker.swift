import SwiftUI
import UniformTypeIdentifiers

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
            
            // Vista para arrastrar y soltar archivos
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay(
                    Text("Arrastra y suelta archivos aquí")
                        .foregroundColor(.secondary)
                )
                .onDrop(of: [.fileURL], isTargeted: nil) { providers -> Bool in
                    handleDrop(providers: providers)
                    return true
                }
        }
        .frame(minWidth: 300, minHeight: 300)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json], // Tipo de archivo permitido
            allowsMultipleSelection: true // Permitir múltiples archivos
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
    
    // Función para manejar el arrastre y suelta de archivos
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            // Verificar si el proveedor puede cargar un URL
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        DispatchQueue.main.async {
                            let result = read(from: url)
                            switch result {
                            case .success(let data):
                                self.selectedFilesData.append(data)
                                self.selectedFileNames.append(url.lastPathComponent)
                            case .failure(let error):
                                self.error = error
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    // Función para leer el contenido de un archivo
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
