//
//  QRCodeZoomDemo.swift
//  IOS18Playground
//
//  Created by Codelaby on 20/12/24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: QRCodeModel
struct QRCodeModel: Identifiable {
    let id: UUID
    let string: String
    let qrCode: UIImage
    
    init(id: UUID = UUID(), string: String, qrCode: UIImage) {
        self.id = id
        self.string = string
        self.qrCode = qrCode
    }
}

// MARK: QRGenerator
class QRCodeViewModel: ObservableObject {
    @Published var qrCodeModel: QRCodeModel?
    
    func generateQRCode(from string: String) {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                let qrCode = UIImage(cgImage: cgimg)
                self.qrCodeModel = QRCodeModel(string: string, qrCode: qrCode)
            }
        }
    }
}

// MARK: Playground
struct QRCodeZoomDemo: View {
    @Namespace var namespace
    @StateObject private var viewModel = QRCodeViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if let qrCodeModel = viewModel.qrCodeModel {
                    NavigationLink(value: qrCodeModel.id) {
                        Image(uiImage: qrCodeModel.qrCode)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .padding()
                            .background(.thinMaterial, in: .rect(cornerRadius: 8))
                            .matchedTransitionSource(id: qrCodeModel.id, in: namespace)
                    }
                }
                Spacer()
            }
            .navigationTitle("QRCode Demo")
            .navigationDestination(for: UUID.self) { id in
                if let qrCodeModel = viewModel.qrCodeModel, qrCodeModel.id == id {
                    QRCodeZDetail(qrCodeModel: qrCodeModel, namespace: namespace)
                }
            }
            .onAppear {
                viewModel.generateQRCode(from: "https://apple.com")
            }
        }
    }
}

struct QRCodeZDetail: View {
    var qrCodeModel: QRCodeModel
    var namespace: Namespace.ID
    
    var body: some View {
        VStack {
            Image(uiImage: qrCodeModel.qrCode)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .navigationTransition(.zoom(sourceID: qrCodeModel.id, in: namespace))
            Text(qrCodeModel.string)
        }
    }
}

#Preview {
    QRCodeZoomDemo()
}
