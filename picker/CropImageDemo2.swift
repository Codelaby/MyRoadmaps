//
//  CropImageDemo.swift
//  Mi Baliza V16
//
//  Created by Codelaby on 02/04/2026.
//

// https://github.com/benedom/SwiftyCrop

import CoreGraphics
import SwiftUI
#if os(macOS)
import AppKit
internal import UniformTypeIdentifiers
internal import Combine
#else
import UIKit
import PhotosUI
#endif

#if canImport(UIKit)
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
#endif

public enum MaskShape: CaseIterable {
    case circle, square, rectangle
}

// MARK: CropViewModel
@Observable
class CropViewModel {
    private let maskRadius: CGFloat
    private let maxMagnificationScale: CGFloat // The maximum allowed scale factor for image magnification.
    private let maskShape: MaskShape // The shape of the mask used for cropping.
    private let rectAspectRatio: CGFloat // The aspect ratio for rectangular masks.
    
    var imageSizeInView: CGSize = .zero // The size of the image as displayed in the view.
    var maskSize: CGSize = .zero // The size of the mask used for cropping. This is updated based on the mask shape and available space.
    var scale: CGFloat = 1.0 // The current scale factor of the image.
    var lastScale: CGFloat = 1.0 // The previous scale factor of the image.
    var offset: CGSize = .zero // The current offset of the image.
    var lastOffset: CGSize = .zero // The previous offset of the image.
    var angle: Angle = Angle(degrees: 0) // The current rotation angle of the image.
    var lastAngle: Angle = Angle(degrees: 0) // The previous rotation angle of the image.
    
    init(
        maskRadius: CGFloat,
        maxMagnificationScale: CGFloat,
        maskShape: MaskShape,
        rectAspectRatio: CGFloat
    ) {
        self.maskRadius = maskRadius
        self.maxMagnificationScale = maxMagnificationScale
        self.maskShape = maskShape
        self.rectAspectRatio = rectAspectRatio
    }
    
    /**
     Updates the mask size based on the given size and mask shape.
     - Parameter size: The size to base the mask size calculations on.
     */
    private func updateMaskSize(for size: CGSize) {
        switch maskShape {
        case .circle, .square:
            let diameter = min(maskRadius * 2, min(size.width, size.height))
            maskSize = CGSize(width: diameter, height: diameter)
        case .rectangle:
            let maxWidth = min(size.width, maskRadius * 2)
            let maxHeight = min(size.height, maskRadius * 2)
            if maxWidth / maxHeight > rectAspectRatio {
                maskSize = CGSize(width: maxHeight * rectAspectRatio, height: maxHeight)
            } else {
                maskSize = CGSize(width: maxWidth, height: maxWidth / rectAspectRatio)
            }
        }
    }
    
    /**
     Updates the mask dimensions based on the size of the image in the view.
     - Parameter imageSizeInView: The size of the image as displayed in the view.
     */
    func updateMaskDimensions(for imageSizeInView: CGSize) {
        self.imageSizeInView = imageSizeInView
        updateMaskSize(for: imageSizeInView)
    }
    
    /**
     Calculates the maximum allowed offset for dragging the image.
     - Returns: A CGPoint representing the maximum x and y offsets.
     */
    func calculateDragGestureMax() -> CGPoint {
        let radians = angle.radians
        let cosA = abs(cos(radians))
        let sinA = abs(sin(radians))

        // Tamaño efectivo de la imagen tras la rotación
        let rotatedWidth = imageSizeInView.width * cosA + imageSizeInView.height * sinA
        let rotatedHeight = imageSizeInView.width * sinA + imageSizeInView.height * cosA

        let xLimit = max(0, ((rotatedWidth / 2) * scale) - (maskSize.width / 2))
        let yLimit = max(0, ((rotatedHeight / 2) * scale) - (maskSize.height / 2))
        return CGPoint(x: xLimit, y: yLimit)
    }
    
    /**
     Calculates the minimum and maximum allowed scale values for image magnification.
     - Returns: A tuple containing the minimum and maximum scale values.
     */
    func calculateMagnificationGestureMaxValues() -> (CGFloat, CGFloat) {
        let minScale = max(maskSize.width / imageSizeInView.width, maskSize.height / imageSizeInView.height)
        return (minScale, maxMagnificationScale)
    }
    
    /**
     Crops the given image to a rectangle based on the current mask size and position.
     - Parameter image: The PlatformImage to crop.
     - Returns: A cropped PlatformImage, or nil if cropping fails.
     */
    func cropToRectangle(_ image: PlatformImage) -> PlatformImage? {
        guard let orientedImage = image.correctlyOriented else { return nil }
        
        let cropRect = calculateCropRect(orientedImage)
        
#if canImport(UIKit)
        guard let cgImage = orientedImage.cgImage,
              let result = cgImage.cropping(to: cropRect) else {
            return nil
        }
        return UIImage(cgImage: result)
#elseif canImport(AppKit)
        guard let cgImage = orientedImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return nil
        }
        return NSImage(cgImage: croppedCGImage, size: cropRect.size)
#endif
    }
    
    /**
     Crops the given image to a square based on the current mask size and position.
     - Parameter image: The PlatformImage to crop.
     - Returns: A cropped PlatformImage, or nil if cropping fails.
     */
    func cropToSquare(_ image: PlatformImage) -> PlatformImage? {
        guard let orientedImage = image.correctlyOriented else { return nil }
        
        let cropRect = calculateCropRect(orientedImage)
        
#if canImport(UIKit)
        guard let cgImage = orientedImage.cgImage,
              let result = cgImage.cropping(to: cropRect) else {
            return nil
        }
        return UIImage(cgImage: result)
#elseif canImport(AppKit)
        guard let cgImage = orientedImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return nil
        }
        return NSImage(cgImage: croppedCGImage, size: cropRect.size)
#endif
    }
    
    /**
     Crops the given image to a circle based on the current mask size and position.
     - Parameter image: The PlatformImage to crop.
     - Returns: A cropped PlatformImage, or nil if cropping fails.
     */
    func cropToCircle(_ image: PlatformImage) -> PlatformImage? {
        guard let orientedImage = image.correctlyOriented else { return nil }
        
        let cropRect = calculateCropRect(orientedImage)
        
#if canImport(UIKit)
        let imageRendererFormat = orientedImage.imageRendererFormat
        imageRendererFormat.opaque = false
        
        let circleCroppedImage = UIGraphicsImageRenderer(
            size: cropRect.size,
            format: imageRendererFormat).image { _ in
                let drawRect = CGRect(origin: .zero, size: cropRect.size)
                UIBezierPath(ovalIn: drawRect).addClip()
                let drawImageRect = CGRect(
                    origin: CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y),
                    size: orientedImage.size
                )
                orientedImage.draw(in: drawImageRect)
            }
        
        return circleCroppedImage
#elseif canImport(AppKit)
        let circleCroppedImage = NSImage(size: cropRect.size)
        circleCroppedImage.lockFocus()
        let drawRect = NSRect(origin: .zero, size: cropRect.size)
        NSBezierPath(ovalIn: drawRect).addClip()
        let drawImageRect = NSRect(
            origin: NSPoint(x: -cropRect.origin.x, y: -cropRect.origin.y),
            size: orientedImage.size
        )
        orientedImage.draw(in: drawImageRect)
        circleCroppedImage.unlockFocus()
        return circleCroppedImage
#endif
    }
    
    /**
     Rotates the given image by the specified angle.
     - Parameter image: The PlatformImage to rotate.
     - Parameter angle: The Angle to rotate the image by.
     - Returns: A rotated PlatformImage, or nil if rotation fails.
     */
    func rotate(_ image: PlatformImage, _ angle: Angle) -> PlatformImage? {
        guard let orientedImage = image.correctlyOriented else { return nil }
        
#if canImport(UIKit)
        guard let cgImage = orientedImage.cgImage else { return nil }
#elseif canImport(AppKit)
        guard let cgImage = orientedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
#endif
        
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter.straightenFilter(image: ciImage, radians: angle.radians),
              let output = filter.outputImage else { return nil }
        
        let context = CIContext()
        guard let result = context.createCGImage(output, from: output.extent) else { return nil }
        
#if canImport(UIKit)
        return UIImage(cgImage: result)
#elseif canImport(AppKit)
        return NSImage(cgImage: result, size: NSSize(width: result.width, height: result.height))
#endif
    }
    
    /**
     Calculates the rectangle to use for cropping the image based on the current mask size, scale, and offset.
     - Parameter orientedImage: The correctly oriented PlatformImage to calculate the crop rect for.
     - Returns: A CGRect representing the area to crop from the original image.
     */
    private func calculateCropRect(_ orientedImage: PlatformImage) -> CGRect {
        let factor = min(
            (orientedImage.size.width / imageSizeInView.width),
            (orientedImage.size.height / imageSizeInView.height)
        )
        let centerInOriginalImage = CGPoint(
            x: orientedImage.size.width / 2,
            y: orientedImage.size.height / 2
        )
        let cropSizeInOriginalImage = CGSize(
            width: (maskSize.width * factor) / scale,
            height: (maskSize.height * factor) / scale
        )

        // Proyectar el offset de pantalla al espacio original (sin rotación)
        let radians = angle.radians
        let rotatedOffsetX = offset.width * cos(-radians) - offset.height * sin(-radians)
        let rotatedOffsetY = offset.width * sin(-radians) + offset.height * cos(-radians)

        let offsetX = rotatedOffsetX * factor / scale
        let offsetY = rotatedOffsetY * factor / scale

        let cropRectX = (centerInOriginalImage.x - cropSizeInOriginalImage.width / 2) - offsetX
        let cropRectY = (centerInOriginalImage.y - cropSizeInOriginalImage.height / 2) - offsetY

        return CGRect(
            origin: CGPoint(x: cropRectX, y: cropRectY),
            size: cropSizeInOriginalImage
        )
    }
}

extension PlatformImage {
    /**
     A PlatformImage instance with corrected orientation.
     For UIImage, if the instance's orientation is already `.up`, it simply returns the original.
     For NSImage, it returns self as macOS doesn't have orientation issues.
     - Returns: An optional PlatformImage that represents the correctly oriented image.
     */
    var correctlyOriented: PlatformImage? {
#if canImport(UIKit)
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage
#elseif canImport(AppKit)
        return self
#endif
    }
}

fileprivate extension CIFilter {
    /**
     Creates the straighten filter.
     - Parameters:
     - inputImage: The CIImage to use as an input image
     - radians: An angle in radians
     - Returns: A generated CIFilter.
     */
    static func straightenFilter(image: CIImage, radians: Double) -> CIFilter? {
        let angle: Double = radians != 0 ? -radians : 0
        guard let filter = CIFilter(name: "CIStraightenFilter") else {
            return nil
        }
        filter.setDefaults()
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(angle, forKey: kCIInputAngleKey)
        return filter
    }
}

// MARK: SwiftyCropConfiguration
/// `SwiftyCropConfiguration` is a struct that defines the configuration for cropping behavior and the UI.
public struct SwiftyCropConfiguration {
    public let maxMagnificationScale: CGFloat
    public let maskRadius: CGFloat
    public let cropImageCircular: Bool
    public let rotateImage: Bool
    public let zoomSensitivity: CGFloat
    public let rectAspectRatio: CGFloat

    /// Creates a new instance of `SwiftyCropConfiguration`.
    ///
    /// - Parameters:
    ///   - maxMagnificationScale: The maximum scale factor that the image can be magnified while cropping. Defaults to `4.0`.
    ///
    ///   - maskRadius: The radius of the mask used for cropping. Defaults to `140`.
    ///
    ///   - cropImageCircular: Option to enable circular crop. Defaults to `false`.
    ///
    ///   - rotateImage: Option to rotate image. Defaults to `false`.
    ///
    ///   - zoomSensitivity: Sensitivity when zooming. Default is `1.0`. Decrease to increase sensitivity.
    ///
    ///   - rectAspectRatio: The aspect ratio to use when a `.rectangle` mask shape is used. Defaults to `4:3`.

    public init(
        maxMagnificationScale: CGFloat = 4.0,
        maskRadius: CGFloat = 130,
        cropImageCircular: Bool = false,
        rotateImage: Bool = false,
        zoomSensitivity: CGFloat = 1,
        rectAspectRatio: CGFloat = 4/3,
    ) {
        self.maxMagnificationScale = maxMagnificationScale
        self.maskRadius = maskRadius
        self.cropImageCircular = cropImageCircular
        self.rotateImage = rotateImage
        self.zoomSensitivity = zoomSensitivity
        self.rectAspectRatio = rectAspectRatio
    }
}
// MARK: CropImageView
struct CropImageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CropViewModel
    
    @State private var isCropping: Bool = false
    
    private let image: PlatformImage
    private let maskShape: MaskShape
    private let configuration: SwiftyCropConfiguration
    private let onCancel: (() -> Void)?
    private let onComplete: (PlatformImage?) -> Void
    
    init(
        image: PlatformImage,
        maskShape: MaskShape,
        configuration: SwiftyCropConfiguration,
        onCancel: (() -> Void)? = nil,
        onComplete: @escaping (PlatformImage?) -> Void
    ) {
        self.image = image
        self.maskShape = maskShape
        self.configuration = configuration
        self.onCancel = onCancel
        self.onComplete = onComplete
        
        _viewModel = State(
            wrappedValue: CropViewModel(
                maskRadius: configuration.maskRadius,
                maxMagnificationScale: configuration.maxMagnificationScale,
                maskShape: maskShape,
                rectAspectRatio: configuration.rectAspectRatio
            )
        )
    }
    
    // MARK: - Body
    var body: some View {
        
        VStack {
            Button(role: .cancel) {
              //  dismiss()
                onCancel?()
            }
            Button(role: .confirm) {
                Task {
                    await MainActor.run {
                        isCropping = true
                    }
                    let result = cropImage()
                    await MainActor.run {
                        onComplete(result)
                      //  dismiss()
                        isCropping = false
                    }
                }
            }
            HStack {
                Button("Rotate left", systemImage: "rotate.left") {
                    withAnimation {
                        viewModel.angle.degrees -= 90
                        viewModel.lastAngle = viewModel.angle
                        updateOffset() // ← añadir esto
                    }
                }

                Button("Rotate right", systemImage: "rotate.right") {
                    withAnimation {
                        viewModel.angle.degrees += 90
                        viewModel.lastAngle = viewModel.angle
                        updateOffset() // ← añadir esto
                    }
                }
            }
            
            cropImageView
                .overlay {
                    if isCropping {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                .allowsHitTesting(!isCropping)
        }

    }
 
    
    // MARK: - Gestures
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let sensitivity: CGFloat = 0.1 * configuration.zoomSensitivity
                let scaledValue = (value.magnitude - 1) * sensitivity + 1
                
                let maxScaleValues = viewModel.calculateMagnificationGestureMaxValues()
                viewModel.scale = min(max(scaledValue * viewModel.lastScale, maxScaleValues.0), maxScaleValues.1)
                
                updateOffset()
            }
            .onEnded { _ in
                viewModel.lastScale = viewModel.scale
                viewModel.lastOffset = viewModel.offset
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let maxOffsetPoint = viewModel.calculateDragGestureMax()
                let newX = min(
                    max(value.translation.width + viewModel.lastOffset.width, -maxOffsetPoint.x),
                    maxOffsetPoint.x
                )
                let newY = min(
                    max(value.translation.height + viewModel.lastOffset.height, -maxOffsetPoint.y),
                    maxOffsetPoint.y
                )
                viewModel.offset = CGSize(width: newX, height: newY)
            }
            .onEnded { _ in
                viewModel.lastOffset = viewModel.offset
            }
    }
    
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                viewModel.angle = viewModel.lastAngle + value
            }
            .onEnded { _ in
                viewModel.lastAngle = viewModel.angle
            }
    }
    
    // MARK: - UI Components
    private var cropImageView: some View {
        ZStack {
            PlatformImageView(image: image)
                .rotationEffect(viewModel.angle)
                .scaleEffect(viewModel.scale)
                .offset(viewModel.offset)
                .overlay(
                    GeometryReader { geometry in
                        Color.black.opacity(0.7)
                            .onAppear {
                                viewModel.updateMaskDimensions(for: geometry.size)
                            }
                    }
                )

            PlatformImageView(image: image)
                .rotationEffect(viewModel.angle)
                .scaleEffect(viewModel.scale)
                .offset(viewModel.offset)
                .mask(
                    MaskShapeView(maskShape: maskShape)
                        .frame(width: viewModel.maskSize.width, height: viewModel.maskSize.height)
                )
            Group {
                switch maskShape {
                case .circle:
                    Circle()
                        .stroke(.black, lineWidth: 2)
                    
                case .square, .rectangle:
                    Rectangle()
                        .stroke(.black, lineWidth: 2)
                    
                }
            }
            .frame(width: viewModel.maskSize.width, height: viewModel.maskSize.height)

            
        }
        .clipped()
        .background(.black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .simultaneousGesture(magnificationGesture)
        .simultaneousGesture(dragGesture)
        .simultaneousGesture(configuration.rotateImage ? rotationGesture : nil)
    }
    
    // MARK: - Helpers
    private func updateOffset() {
        let maxOffsetPoint = viewModel.calculateDragGestureMax()
        let newX = min(max(viewModel.offset.width, -maxOffsetPoint.x), maxOffsetPoint.x)
        let newY = min(max(viewModel.offset.height, -maxOffsetPoint.y), maxOffsetPoint.y)
        viewModel.offset = CGSize(width: newX, height: newY)
        viewModel.lastOffset = viewModel.offset
    }
    
    private func cropImage() -> PlatformImage? {
        var editedImage: PlatformImage = image
        if configuration.rotateImage {
            if let rotatedImage: PlatformImage = viewModel.rotate(
                editedImage,
                viewModel.lastAngle
            ) {
                editedImage = rotatedImage
            }
        }
        if configuration.cropImageCircular && maskShape == .circle {
            return viewModel.cropToCircle(editedImage)
        } else if maskShape == .rectangle {
            return viewModel.cropToRectangle(editedImage)
        } else {
            return viewModel.cropToSquare(editedImage)
        }
    }
    
    // MARK: - Mask Shape View
    private struct MaskShapeView: View {
        let maskShape: MaskShape
        
        var body: some View {
            Group {
                switch maskShape {
                case .circle:
                    Circle()
                case .square, .rectangle:
                    Rectangle()
                }
            }
        }
    }
}

// MARK: - Platform Image View
struct PlatformImageView: View {
    let image: PlatformImage
    
    var body: some View {
#if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
#elseif canImport(AppKit)
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
#endif
    }
}

// MARK: Demo
/// `SwiftyCropView` is a SwiftUI view for cropping images.
///
/// You can customize the cropping behavior using a `SwiftyCropConfiguration` instance and a completion handler.
///
/// - Parameters:
///   - imageToCrop: The image to be cropped.
///   - maskShape: The shape of the mask used for cropping.
///   - configuration: The configuration for the cropping behavior. If nothing is specified, the default is used.
///   - onCancel: An optional closure that's called when the cropping is cancelled.
///   - onComplete: A closure that's called when the cropping is complete. This closure returns the cropped image.
///     If an error occurs the return value is nil.
struct SwiftyCropView: View {
    private let maskShape: MaskShape
    private let configuration: SwiftyCropConfiguration
    private let onCancel: (() -> Void)?
    
#if canImport(UIKit)
    private let imageToCrop: UIImage
    private let onComplete: (UIImage?) -> Void
    
    public init(
        imageToCrop: UIImage,
        maskShape: MaskShape,
        configuration: SwiftyCropConfiguration = SwiftyCropConfiguration(),
        onCancel: (() -> Void)? = nil,
        onComplete: @escaping (UIImage?) -> Void
    ) {
        self.imageToCrop = imageToCrop
        self.maskShape = maskShape
        self.configuration = configuration
        self.onCancel = onCancel
        self.onComplete = onComplete
    }
#elseif canImport(AppKit)
    private let imageToCrop: NSImage
    private let onComplete: (NSImage?) -> Void
    
    public init(
        imageToCrop: NSImage,
        maskShape: MaskShape,
        configuration: SwiftyCropConfiguration = SwiftyCropConfiguration(),
        onCancel: (() -> Void)? = nil,
        onComplete: @escaping (NSImage?) -> Void
    ) {
        self.imageToCrop = imageToCrop
        self.maskShape = maskShape
        self.configuration = configuration
        self.onCancel = onCancel
        self.onComplete = onComplete
    }
#endif
    
    public var body: some View {
        CropImageView(
            image: imageToCrop,
            maskShape: maskShape,
            configuration: configuration,
            onCancel: onCancel,
            onComplete: onComplete
        )
    }
}

#if canImport(UIKit)
// MARK: IOS
struct CropImageDemo: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var croppedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Select image…", systemImage: "photo")
                    .font(.headline)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
            
            if let selectedImage {
                SwiftyCropView(
                    imageToCrop: selectedImage,
                    maskShape: .circle
                ) { cropped in
                    croppedImage = cropped
                }
            }
            
            if let croppedImage {
                Image(uiImage: croppedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#else
// MARK: macOS
struct CropImageDemo: View {
    @State private var selectedImage: NSImage?
    @State private var croppedImage: NSImage?
    
    var body: some View {
        VStack(spacing: 16) {
            Button("Select image…") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.image]
                panel.allowsMultipleSelection = false
                if panel.runModal() == .OK, let url = panel.url {
                    selectedImage = NSImage(contentsOf: url)
                }
            }
            
            if let selectedImage {
                SwiftyCropView(
                    imageToCrop: selectedImage,
                    maskShape: .circle
                ) { cropped in
                    croppedImage = cropped
                }
            }
            
            if let croppedImage {
                Image(nsImage: croppedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            }
        }
        .padding()
        .frame(width: 600, height: 700)
    }
}

#endif

#Preview {
    CropImageDemo()
}

