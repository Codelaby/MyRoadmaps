//
//  LinkPreviewDemo.swift
//  ios19
//
//  Created by Codelaby on 1/8/25.
//

import SwiftUI
import LinkPresentation
import UniformTypeIdentifiers

// https://medium.com/gitconnected/swiftui-rich-links-two-ways-054ee9f94038
// https://blog.stackademic.com/rich-link-representation-in-swiftui-2f155689fe62




private struct CustomLinkView: View {
    let url: URL
    
    @Binding var errorMessage: String?
    
    // title, icon, image
    @State private var metadata: (String?, UIImage?, UIImage?)? = nil
    
    private var defaultTitle: String {
        url.host() ?? url.absoluteString
    }
    
    var body: some View {
        ZStack {
            LPLinkViewRepresentable(url: self.url)
            
            HStack(spacing: 16) {
                if let metadata {
                    let (title, icon, image) = metadata
                    
                    ZStack(alignment: .bottomLeading) {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        HStack(spacing: 8) {
                            if let icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            }
                            Text(title ?? self.defaultTitle)
                        }
                    }
                } else {
                    
                    Text(url.host() ?? url.absoluteString)
                    Image(systemName: "safari")
                }
            }
            .font(.system(size: 16))
            .foregroundStyle(.black.opacity(0.7))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.all, 16)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .fill(.yellow.opacity(0.2))
            )
            .allowsHitTesting(false)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard let metadata = await self.loadMetadata() else {return}
            Task { @MainActor in
                let icon = await self.getImage(metadata.iconProvider)
                let image = await self.getImage(metadata.imageProvider)
                let title = metadata.title
                self.metadata = (title, icon, image)
            }
        }

    }
    
    
    private func loadMetadata() async -> LPLinkMetadata? {
        let metadataProvider = LPMetadataProvider()
        do {
            let result = try await metadataProvider.startFetchingMetadata(for: url)
            return result
        } catch(let error) {
            if let error = error as? LPError {
                self.errorMessage = error.description
            } else {
                self.errorMessage = error.localizedDescription
            }
            return nil
        }
    }
    
    private nonisolated func getImage(_ itemProvider: NSItemProvider?) async -> UIImage? {
        guard let itemProvider else { return nil }
        let allowedType = UTType.image.identifier
        guard itemProvider.hasItemConformingToTypeIdentifier(allowedType) else { return nil }
        
        do {
            // Load the item directly
            let item = try await itemProvider.loadItem(forTypeIdentifier: allowedType)
            
            if let url = item as? URL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                return image
            }
            
            if let image = item as? UIImage {
                return image
            }
            
            if let data = item as? Data, let image = UIImage(data: data) {
                return image
            }
            
            return nil
        } catch {
            await MainActor.run {
                self.errorMessage = "Error getting image: \(error.localizedDescription)"
            }
            return nil
        }
    }
}

private struct LPLinkViewRepresentable: UIViewRepresentable {
    
    let url: URL
       
    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)
        return linkView
    }
    
    func updateUIView(_ linkView: LPLinkView, context: Context) {}

}

extension LPError: @preconcurrency @retroactive CustomStringConvertible {
    public var description: String {
        switch self.code {
        case .metadataFetchCancelled:
            return "Metadata fetch cancelled."
            
        case .metadataFetchFailed:
            return "Metadata fetch failed."
            
        case .metadataFetchTimedOut:
            return "Metadata fetch timed out."
            
        case .unknown:
            return "Metadata fetch unknown."
            
        case .metadataFetchNotAllowed:
            return "Metadata fetch not allowed."
            
        @unknown default:
          return "Metadata fetch failed with unknown error."
        }
    }
}

// MARK: Demo
struct LinkPreviewDemo: View {
    private let url: URL = URL(string: "https://swiftuisnippets.wordpress.com/2025/07/31/static-maps-in-swiftui-darkmode-support/")!
//    private let url: URL = URL(string: "https://medium.com")!
    @State private var errorMessage: String? = nil
    @State private var showAlert: Bool = false
    
    var body: some View {
            
        CustomLinkView(url: self.url, errorMessage: $errorMessage)
            .frame(width: 300, height: 200)
            .alert("Failed to Load Preview", isPresented: $showAlert, actions: {
                Button(role: .none, action: {
                    errorMessage = nil
                }, label: {
                    Text("Dismiss")
                })
    
            }, message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            })
            .onChange(of: errorMessage, {
                showAlert = errorMessage != nil
            })
    }
}


#Preview {
    LinkPreviewDemo()
}


/*
struct LinkPreviewDemo: View {
    @State private var links = [
        "https://not-valid-url",
        "https://developer.apple.com/tutorials/swiftui/",
        "https://expatexplore.com/blog/when-to-travel-weather-seasons/",
        "https://www.apple.com"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(links, id: \.self) { link in
                        LinkItemView(link: link)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Rich Links")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


enum ImageStatus {
    case loading
    case finished(Image)
    case failed(Error)
}

enum LoadingError: Error {
    case contentUnavailable
    case contentTypeNotSupported
}

struct LinkItemView: View {
    @State private var url: URL?
    @State private var isValidUrl = true
    @State private var metadata: LPLinkMetadata? = nil
    @State private var imageStatus: ImageStatus = .loading

    init(link: String) {
        _url = State(wrappedValue: URL(string: link))
    }

    var body: some View {
        VStack {
            if isValidUrl, let url {
                Link(destination: url) {
                    HStack(alignment: .center) {
                        VStack {
                            switch imageStatus {
                            case .loading:
                                ProgressView()
                            case .finished(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failed:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .padding()
                                    .foregroundStyle(.gray)
                            }
                        }
                        .clipped()
                        .frame(width: 90, height: 90)
                        .cornerRadius(15)

                        VStack(alignment: .leading) {
                            Text(metadata?.title ?? "url title placeholder")
                                .font(.body)
                                .redacted(reason: metadata == nil ? .placeholder : [])

                            Text(metadata?.url?.host ?? "url host placeholder")
                                .font(.footnote)
                                .foregroundStyle(.gray)
                                .redacted(reason: metadata == nil ? .placeholder : [])
                        }
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 8)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "circle.slash")
                        .foregroundStyle(.red)
                    Text("Provided link is invalid")
                        .font(.title3).bold()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(height: 90)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(.gray.opacity(0.2))
        }
        .task(id: url) {
            await fetchMetadata()
        }
    }

    private func fetchMetadata() async {
        guard let url else {
            await MainActor.run {
                self.isValidUrl = false
            }
            return
        }

        do {
            // 1. Fetch metadata
            let fetchedMetadata = try await LPMetadataProvider().startFetchingMetadata(for: url)

            // 2. Set @State values in MainActor
            await MainActor.run {
                self.metadata = fetchedMetadata
                self.isValidUrl = true
            }

            // 3. Extract imageProvider *inside* the MainActor to avoid Sendable violation
            let imageProvider = await MainActor.run { fetchedMetadata.imageProvider }

            // 4. Load image safely
            if let image = await loadImage(from: imageProvider) {
                await MainActor.run {
                    self.imageStatus = .finished(Image(uiImage: image))
                }
            } else {
                await MainActor.run {
                    self.imageStatus = .failed(LoadingError.contentUnavailable)
                }
            }

        } catch {
            print("Error fetching metadata: \(error.localizedDescription)")
            await MainActor.run {
                self.isValidUrl = false
                self.imageStatus = .failed(error)
            }
        }
    }


    private nonisolated func loadImage(from imageProvider: NSItemProvider?) async -> UIImage? {
        let imageType = UTType.image.identifier
        do {
            guard let imageProvider,
                  imageProvider.hasItemConformingToTypeIdentifier(imageType)
            else {
                return nil
            }

            let item = try await imageProvider.loadItem(forTypeIdentifier: imageType)

            if let image = item as? UIImage {
                return image
            } else if let url = item as? URL,
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) {
                return image
            } else if let data = item as? Data,
                      let image = UIImage(data: data) {
                return image
            }

            return nil
        } catch {
            return nil
        }
    }
}
*/
