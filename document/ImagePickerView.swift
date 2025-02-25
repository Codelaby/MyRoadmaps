//
//  ImagePickerView.swift
//  FileOperationDemo
//
//  Created by Codelaby on 24/2/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImageModel : Identifiable, Equatable, Hashable, Sendable {
    var id: UUID = .init()
    var fileName: String
    //var data: UIImage
    var data: Data
}

extension Data {
    func toImage() -> Image? {
        #if os(iOS)
        return UIImage(data: self).map { Image(uiImage: $0) }
        #elseif os(macOS)
        return NSImage(data: self).map { Image(nsImage: $0) }
        #endif
    }
}

//extension UIImage: Sendable {}


actor ImageModelManager {
    private var images: [ImageModel] = []
    
    // Method to add a new ImageModel to the collection
    func addImage(_ image: ImageModel) {
        images.append(image)
    }
    
    // Method to retrieve all ImageModel instances
    func getImages() -> [ImageModel] {
        return images
    }
}

@MainActor
@Observable
final class ImageHandlerVM {
    private(set) var images: [ImageModel] = []
    var error: Error?
    
    private let imageManager = ImageModelManager()
    
    func handleDrop(providers: [NSItemProvider]) {
#if os(iOS)
        for provider in providers {
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let uiImage = image as? UIImage,
                      let imageData = uiImage.jpegData(compressionQuality: 0.6) else {
                    return
                }
                
                Task { @MainActor in
                    //let newImage = ImageModel(fileName: "aaaa", data: uiImage)
                    let newImage = ImageModel(fileName: "aaaa", data: imageData)
                    
                    await self.imageManager.addImage(newImage)
                    self.images = await self.imageManager.getImages()
                }
            }
        }
#elseif os(macOS)
        for provider in providers {
            provider.loadObject(ofClass: NSImage.self) { image, _ in
                guard let nsImage = image as? NSImage,
                                let imageData = nsImage.tiffRepresentation else {
                              return
                          }
                
                Task { @MainActor in
                    //let newImage = ImageModel(fileName: "aaaa", data: uiImage)
                    let newImage = ImageModel(fileName: "aaaa", data: imageData)
                    
                    await self.imageManager.addImage(newImage)
                    self.images = await self.imageManager.getImages()
                }
            }
        }
#endif

    }
  
}

struct ImagePickerView: View {
    
    @State private var viewModel: ImageHandlerVM = ImageHandlerVM()
    
    var body: some View {
        VStack {
            if !viewModel.images.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(viewModel.images, id: \.self) { image in
                            Text(image.fileName)
                            if let imageView = image.data.toImage() {
                                imageView
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                            } else {
                                // Manejar el caso en que la conversión falle
                                Text("Error loading image")
                                    .foregroundColor(.red)
                            }
                            
                            
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "Drag & Drop",
                    systemImage: "square.and.arrow.down",
                    description: Text("Tap to add an image.")
                )
                .frame(width: 300, height: 300)
                .overlay {
                    ContainerRelativeShape()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.gray)
                }
                .background(.thinMaterial, in: .rect(cornerRadius: 20, style: .continuous))
                .onDrop(of: [.image], isTargeted: nil) { providers -> Bool in
                    viewModel.handleDrop(providers: providers)
                    return true
                }
                
            }
            
            if let error = viewModel.error {
                Text("Failed to load image: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
      
    }
    
    
}

#Preview {
    ImagePickerView()
}
