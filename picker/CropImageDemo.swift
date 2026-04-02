//
//  CropImageDemo.swift
//  Mi Baliza V16
//
//  Created by Codelaby on 02/04/2026.
//

// https://github.com/benedom/SwiftyCrop

import SwiftUI
#if os(macOS)
import AppKit
internal import UniformTypeIdentifiers
#else
import UIKit
#endif

public enum MaskShape: CaseIterable {
    case circle, square, rectangle
}

// MARK: SwiftyCropConfiguration
/// `SwiftyCropConfiguration` is a struct that defines the configuration for cropping behavior.
public struct SwiftyCropConfiguration {
    public let maxMagnificationScale: CGFloat
    public let maskRadius: CGFloat
    public let cropImageCircular: Bool
    public let rotateImage: Bool
    public let zoomSensitivity: CGFloat
    public let rectAspectRatio: CGFloat
    public let texts: Texts
    public let fonts: Fonts
    public let colors: Colors

    public struct Texts {
        public init(
            // We cannot use the localized values here because module access is not given in init
            cancelButton: String? = nil,
            interactionInstructions: String? = nil,
            saveButton: String? = nil
        ) {
            self.cancelButton = cancelButton
            self.interactionInstructions = interactionInstructions
            self.saveButton = saveButton
        }
        
        public let cancelButton: String?
        public let interactionInstructions: String?
        public let saveButton: String?
    }

    public struct Fonts {
        public init(
            cancelButton: Font? = nil,
            interactionInstructions: Font? = nil,
            saveButton: Font? = nil
        ) {
            self.cancelButton = cancelButton
            self.interactionInstructions = interactionInstructions ?? .system(size: 16, weight: .regular)
            self.saveButton = saveButton
        }

        public let cancelButton: Font?
        public let interactionInstructions: Font
        public let saveButton: Font?
    }
    
    public struct Colors {
        public init(
            cancelButton: Color = .white,
            interactionInstructions: Color = .white,
            saveButton: Color = .white,
            background: Color = .black
        ) {
            self.cancelButton = cancelButton
            self.interactionInstructions = interactionInstructions
            self.saveButton = saveButton
            self.background = background
        }

        public let cancelButton: Color
        public let interactionInstructions: Color
        public let saveButton: Color
        public let background: Color
    }

    /// Creates a new instance of `SwiftyCropConfiguration`.
    ///
    /// - Parameters:
    ///   - maxMagnificationScale: The maximum scale factor that the image can be magnified while cropping.
    ///                            Defaults to `4.0`.
    ///   - maskRadius: The radius of the mask used for cropping.
    ///                            Defaults to `130`.
    ///   - cropImageCircular: Option to enable circular crop.
    ///                            Defaults to `false`.
    ///   - rotateImage: Option to rotate image.
    ///                            Defaults to `false`.
    ///   - zoomSensitivity: Sensitivity when zooming. Default is `1.0`. Decrease to increase sensitivity.
    ///
    ///   - rectAspectRatio: The aspect ratio to use when a `.rectangle` mask shape is used. Defaults to `4:3`.
    ///
    ///   - texts: `Texts` object when using custom texts for the cropping view.
    ///
    ///   - fonts: `Fonts` object when using custom fonts for the cropping view. Defaults to system.
    ///
    ///   - colors: `Colors` object when using custom colors for the cropping view. Defaults to white text and black background.
    public init(
        maxMagnificationScale: CGFloat = 4.0,
        maskRadius: CGFloat = 130,
        cropImageCircular: Bool = false,
        rotateImage: Bool = false,
        zoomSensitivity: CGFloat = 1,
        rectAspectRatio: CGFloat = 4/3,
        texts: Texts = Texts(),
        fonts: Fonts = Fonts(),
        colors: Colors = Colors()
    ) {
        self.maxMagnificationScale = maxMagnificationScale
        self.maskRadius = maskRadius
        self.cropImageCircular = cropImageCircular
        self.rotateImage = rotateImage
        self.zoomSensitivity = zoomSensitivity
        self.rectAspectRatio = rectAspectRatio
        self.texts = texts
        self.fonts = fonts
        self.colors = colors
    }
}

// MARK: Protocol ImageProcessor
protocol ImageProcessor {
    associatedtype ImageType
    static func cropToCircle(_ image: ImageType, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> ImageType?
    static func cropToSquare(_ image: ImageType, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> ImageType?
    static func cropToRectangle(_ image: ImageType, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> ImageType?
    static func rotate(_ image: ImageType, angle: Angle) -> ImageType?
}



#if os(iOS)
// MARK: ImageProcessorIOS
final class ImageProcessorIOS: ImageProcessor {
    typealias ImageType = UIImage
    
    static func cropToCircle(_ image: UIImage, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> UIImage? {
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: maskSize))
        return crop(image, shape: path, maskSize: maskSize, imageSizeInView: imageSizeInView, scale: scale, offset: offset)
    }

    static func cropToSquare(_ image: UIImage, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> UIImage? {
        return crop(image, shape: nil, maskSize: maskSize, imageSizeInView: imageSizeInView, scale: scale, offset: offset)
    }

    static func cropToRectangle(_ image: UIImage, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> UIImage? {
        return crop(image, shape: nil, maskSize: maskSize, imageSizeInView: imageSizeInView, scale: scale, offset: offset)
    }

    static func rotate(_ image: UIImage, angle: Angle) -> UIImage? {
        guard let cgImage = image.correctlyOriented?.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter.straightenFilter(image: ciImage, radians: angle.radians),
              let output = filter.outputImage else { return nil }

        let context = CIContext()
        guard let result = context.createCGImage(output, from: output.extent) else { return nil }

        return UIImage(cgImage: result)
    }

    private static func crop(_ image: UIImage, shape: UIBezierPath?, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> UIImage? {
        guard let orientedImage = image.correctlyOriented,
              let cgImage = orientedImage.cgImage else { return nil }

        let factor = min((orientedImage.size.width / imageSizeInView.width),
                         (orientedImage.size.height / imageSizeInView.height))

        let cropSize = CGSize(width: (maskSize.width * factor) / scale,
                              height: (maskSize.height * factor) / scale)

        let center = CGPoint(x: orientedImage.size.width / 2, y: orientedImage.size.height / 2)
        let offsetX = offset.width * factor / scale
        let offsetY = offset.height * factor / scale
        let origin = CGPoint(x: center.x - cropSize.width / 2 - offsetX,
                             y: center.y - cropSize.height / 2 - offsetY)

        let cropRect = CGRect(origin: origin, size: cropSize)

        if let shape = shape {
            let renderer = UIGraphicsImageRenderer(size: cropRect.size)
            return renderer.image { _ in
                shape.addClip()
                let drawRect = CGRect(origin: CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y),
                                      size: orientedImage.size)
                orientedImage.draw(in: drawRect)
            }
        } else {
            guard let cropped = cgImage.cropping(to: cropRect) else { return nil }
            return UIImage(cgImage: cropped)
        }
    }
}

fileprivate extension UIImage {
    /**
     A UIImage instance with corrected orientation.
     If the instance's orientation is already `.up`, it simply returns the original.
     - Returns: An optional UIImage that represents the correctly oriented image.
     */
    var correctlyOriented: UIImage? {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage
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

#endif

#if os(macOS)
// MARK: ImageProcessorMacOS
final class ImageProcessorMacOS: ImageProcessor {
    typealias ImageType = NSImage

    static func cropToCircle(_ image: NSImage, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> NSImage? {
        let path = NSBezierPath(ovalIn: CGRect(origin: .zero, size: maskSize))
        return crop(image, shape: path, maskSize: maskSize, imageSizeInView: imageSizeInView, scale: scale, offset: offset)
    }

    static func cropToSquare(_ image: NSImage, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> NSImage? {
        return crop(image, shape: nil, maskSize: maskSize, imageSizeInView: imageSizeInView, scale: scale, offset: offset)
    }

    static func cropToRectangle(_ image: NSImage, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> NSImage? {
        return crop(image, shape: nil, maskSize: maskSize, imageSizeInView: imageSizeInView, scale: scale, offset: offset)
    }

    // Rotation on macOS using Core Image
    static func rotate(_ image: NSImage, angle: Angle) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let ciImage = CIImage(cgImage: cgImage)

        // Use the CIAffineTransform filter for rotation
        guard let filter = CIFilter(name: "CIAffineTransform") else { return nil }

        let transform = NSAffineTransform()
        transform.rotate(byDegrees: CGFloat(angle.degrees))

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(transform, forKey: kCIInputTransformKey)

        guard let outputImage = filter.outputImage else { return nil }

        // Render the output image to a new CGImage
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        // Create a new NSImage from the rotated CGImage
        let rotatedNSImage = NSImage(cgImage: outputCGImage, size: outputImage.extent.size)

        return rotatedNSImage
    }

    private static func crop(_ image: NSImage, shape: NSBezierPath?, maskSize: CGSize, imageSizeInView: CGSize, scale: CGFloat, offset: CGSize) -> NSImage? {
        // NSImage doesn't have a direct 'correctlyOriented' property like UIImage.
        // Orientation handling in AppKit is often managed differently,
        // sometimes at the `NSImageView` level or during drawing.
        // For cropping, we'll work with the CGImage representation, which is usually orientation-aware.
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

        let factor = min((imageSize.width / imageSizeInView.width),
                         (imageSize.height / imageSizeInView.height))

        let cropSize = CGSize(width: (maskSize.width * factor) / scale,
                              height: (maskSize.height * factor) / scale)

        let center = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
        let offsetX = offset.width * factor / scale
        let offsetY = offset.height * factor / scale
        let origin = CGPoint(x: center.x - cropSize.width / 2 - offsetX,
                             y: center.y - cropSize.height / 2 - offsetY)

        let cropRect = CGRect(origin: origin, size: cropSize)

        // Ensure the cropRect is within the bounds of the image
        let boundedCropRect = cropRect.intersection(CGRect(origin: .zero, size: imageSize))

        guard let croppedCGImage = cgImage.cropping(to: boundedCropRect) else { return nil }

        if let shape = shape {
            // For shaped crops, we need to draw into a new context
            let croppedNSImage = NSImage(cgImage: croppedCGImage, size: boundedCropRect.size)
            let shapedImageSize = boundedCropRect.size // The size of the image after initial crop

            let resultImage = NSImage(size: shapedImageSize)
            resultImage.lockFocus()

            // Create a graphics context
            guard let context = NSGraphicsContext.current?.cgContext else {
                resultImage.unlockFocus()
                return nil
            }

            context.saveGState()

            // Translate the context so the shape drawing aligns with the cropped image
            context.translateBy(x: -boundedCropRect.origin.x, y: -boundedCropRect.origin.y)

            // Add the shape path to the context and clip
            shape.addClip()

            // Draw the cropped image
            croppedNSImage.draw(in: CGRect(origin: boundedCropRect.origin, size: shapedImageSize))

            context.restoreGState()
            resultImage.unlockFocus()

            return resultImage

        } else {
            // For square/rectangle crops, just convert the cropped CGImage back to NSImage
            let croppedNSImage = NSImage(cgImage: croppedCGImage, size: boundedCropRect.size)
            return croppedNSImage
        }
    }
}

// NSBezierPath doesn't have addClip() directly on the path object in this context,
// we use the NSGraphicsContext.
fileprivate extension NSBezierPath {
    func addClip() {
        self.setClip()
    }
}

#endif


// MARK: Union Platform
#if os(iOS)
typealias CurrentImageProcessor = ImageProcessorIOS
#elseif os(macOS)
typealias CurrentImageProcessor = ImageProcessorMacOS
#endif

// MARK: Crop View Model
@Observable
class CropViewModel {
    // Constantes: @ObservationIgnored es opcional pero recomendable
    @ObservationIgnored private let maskRadius: CGFloat
    @ObservationIgnored private let maxMagnificationScale: CGFloat
    @ObservationIgnored private let maskShape: MaskShape
    @ObservationIgnored private let rectAspectRatio: CGFloat

    // Sin @Published — @Observable los observa todos automáticamente
    var imageSizeInView: CGSize = .zero
    var maskSize: CGSize = .zero
    var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var angle: Angle = .degrees(0)
    var lastAngle: Angle = .degrees(0)

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

    func updateMaskDimensions(for imageSizeInView: CGSize) {
        self.imageSizeInView = imageSizeInView
        updateMaskSize(for: imageSizeInView)
    }

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

    func calculateDragGestureMax() -> CGPoint {
        let xLimit = max(0, ((imageSizeInView.width / 2) * scale) - (maskSize.width / 2))
        let yLimit = max(0, ((imageSizeInView.height / 2) * scale) - (maskSize.height / 2))
        return CGPoint(x: xLimit, y: yLimit)
    }

    func calculateMagnificationGestureMaxValues() -> (CGFloat, CGFloat) {
        guard imageSizeInView.width > 0, imageSizeInView.height > 0 else {
            return (1.0, maxMagnificationScale)
        }
        let minScale = max(maskSize.width / imageSizeInView.width, maskSize.height / imageSizeInView.height)
        return (minScale, maxMagnificationScale)
    }

#if os(iOS)
    // MARK: IOS utils
    func cropImage(_ image: UIImage) -> UIImage? {
        switch maskShape {
        case .circle:
            return CurrentImageProcessor.cropToCircle(
                image,
                maskSize: maskSize,
                imageSizeInView: imageSizeInView,
                scale: scale,
                offset: offset
            )
        case .square:
            return CurrentImageProcessor.cropToSquare(
                image,
                maskSize: maskSize,
                imageSizeInView: imageSizeInView,
                scale: scale,
                offset: offset
            )
        case .rectangle:
            return CurrentImageProcessor.cropToRectangle(
                image,
                maskSize: maskSize,
                imageSizeInView: imageSizeInView,
                scale: scale,
                offset: offset
            )
        }
    }

    func rotateImage(_ image: UIImage) -> UIImage? {
        return CurrentImageProcessor.rotate(image, angle: angle)
    }
    
#elseif os(macOS)
    // MARK: macOS utils
    func cropImage(_ image: NSImage) -> NSImage? {
         switch maskShape {
         case .circle:
             return CurrentImageProcessor.cropToCircle(
                 image,
                 maskSize: maskSize,
                 imageSizeInView: imageSizeInView,
                 scale: scale,
                 offset: offset
             )
         case .square:
             return CurrentImageProcessor.cropToSquare(
                 image,
                 maskSize: maskSize,
                 imageSizeInView: imageSizeInView,
                 scale: scale,
                 offset: offset
             )
         case .rectangle:
             return CurrentImageProcessor.cropToRectangle(
                 image,
                 maskSize: maskSize,
                 imageSizeInView: imageSizeInView,
                 scale: scale,
                 offset: offset
             )
         }
     }

     func rotateImage(_ image: NSImage) -> NSImage? {
         return CurrentImageProcessor.rotate(image, angle: angle)
     }
#endif
}



#if os(iOS)

struct CropView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CropViewModel

    private let image: UIImage
    private let maskShape: MaskShape
    private let configuration: SwiftyCropConfiguration
    private let onComplete: (UIImage?) -> Void
    private let localizableTableName: String

    init(
        image: UIImage,
        maskShape: MaskShape,
        configuration: SwiftyCropConfiguration,
        onComplete: @escaping (UIImage?) -> Void
    ) {
        self.image = image
        self.maskShape = maskShape
        self.configuration = configuration
        self.onComplete = onComplete
        _viewModel = State(initialValue:  CropViewModel(
                maskRadius: configuration.maskRadius,
                maxMagnificationScale: configuration.maxMagnificationScale,
                maskShape: maskShape,
                rectAspectRatio: configuration.rectAspectRatio
            )
        )
        localizableTableName = "Localizable"
    }

    var body: some View {
        let magnificationGesture = MagnificationGesture()
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

        let dragGesture = DragGesture()
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

        let rotationGesture = RotationGesture()
            .onChanged { value in
                viewModel.angle = viewModel.lastAngle + value
            }
            .onEnded { _ in
                viewModel.lastAngle = viewModel.angle
            }

        VStack {
            Text(
                configuration.texts.interactionInstructions ??
                NSLocalizedString("interaction_instructions", tableName: localizableTableName, bundle: .main, comment: "")
            )
            .font(configuration.fonts.interactionInstructions)
            .foregroundColor(configuration.colors.interactionInstructions)
            .padding(.top, 30)
            .zIndex(1)

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(viewModel.angle)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .opacity(0.5)
                    .overlay(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    viewModel.updateMaskDimensions(for: geometry.size)
                                }
                        }
                    )

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(viewModel.angle)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .mask(
                        MaskShapeView(maskShape: maskShape)
                            .frame(width: viewModel.maskSize.width, height: viewModel.maskSize.height)
                    )
                
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text(
                                configuration.texts.cancelButton ??
                                NSLocalizedString("cancel_button", tableName: localizableTableName, bundle: .main, comment: "")
                            )
                            .padding()
                            .font(configuration.fonts.cancelButton)
                            .foregroundColor(configuration.colors.cancelButton)
                        }
                        .padding()
                        
                        Spacer()

                        Button {
                            onComplete(cropImage())
                            dismiss()
                        } label: {
                            Text(
                                configuration.texts.saveButton ??
                                NSLocalizedString("save_button", tableName: localizableTableName, bundle: .main, comment: "")
                            )
                            .padding()
                            .font(configuration.fonts.saveButton)
                            .foregroundColor(configuration.colors.saveButton)
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(configuration.rotateImage ? rotationGesture : nil)
        }
        .background(configuration.colors.background)
    }

    private func updateOffset() {
        let maxOffsetPoint = viewModel.calculateDragGestureMax()
        let newX = min(max(viewModel.offset.width, -maxOffsetPoint.x), maxOffsetPoint.x)
        let newY = min(max(viewModel.offset.height, -maxOffsetPoint.y), maxOffsetPoint.y)
        viewModel.offset = CGSize(width: newX, height: newY)
        viewModel.lastOffset = viewModel.offset
    }

    private func cropImage() -> UIImage? {
        var editedImage: UIImage = image
        if configuration.rotateImage {
            if let rotatedImage: UIImage = viewModel.rotateImage(editedImage) {
                editedImage = rotatedImage
            }
        }
        return viewModel.cropImage(editedImage)
    }

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

/// `SwiftyCropView` is a SwiftUI view for cropping images.
///
/// You can customize the cropping behavior using a `SwiftyCropConfiguration` instance and a completion handler.
///
/// - Parameters:
///   - imageToCrop: The image to be cropped.
///   - maskShape: The shape of the mask used for cropping.
///   - configuration: The configuration for the cropping behavior. If nothing is specified, the default is used.
///   - onComplete: A closure that's called when the cropping is complete. This closure returns the cropped `UIImage?`.
///     If an error occurs the return value is nil.
public struct SwiftyCropView: View {
    private let imageToCrop: UIImage
    private let maskShape: MaskShape
    private let configuration: SwiftyCropConfiguration
    private let onComplete: (UIImage?) -> Void

    public init(
        imageToCrop: UIImage,
        maskShape: MaskShape,
        configuration: SwiftyCropConfiguration = SwiftyCropConfiguration(),
        onComplete: @escaping (UIImage?) -> Void
    ) {
        self.imageToCrop = imageToCrop
        self.maskShape = maskShape
        self.configuration = configuration
        self.onComplete = onComplete
    }

    public var body: some View {
        CropView(
            image: imageToCrop,
            maskShape: maskShape,
            configuration: configuration,
            onComplete: onComplete
        )
    }
}

struct ExampleView: View {
    @State private var showImageCropper: Bool = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack {
            Button("Crop downloaded image") {
                Task {
                    if let image = await downloadExampleImage() {
                        selectedImage = image
                    }
                }
            }
            
            Button("open") {
                showImageCropper = true

            }
            if let selectedImage = selectedImage {
                SwiftyCropView(
                    imageToCrop: selectedImage,
                    maskShape: .circle
                ) { croppedImage in
                    // Do something with the returned, cropped image
                    showImageCropper = false
                }
            } else {
                // This should theoretically never be shown now
                ProgressView()
            }
            
            
        }

    }

    private func downloadExampleImage() async -> UIImage? {
        let urlString = "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fwallpaperaccess.com%2Ffull%2F10536890.png&f=1&nofb=1&ipt=5543408206548f2b668d9d9dead17ca225fd9f79a15c65c724c0018f015fb714"
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data)
        else { return nil }

        return image
    }
}

#Preview {
    
    ExampleView()
    
}
#endif

#if os(macOS)

struct CropView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CropViewModel

    private let image: NSImage
    private let maskShape: MaskShape
    private let configuration: SwiftyCropConfiguration
    private let onComplete: (NSImage?) -> Void
    private let localizableTableName: String

    init(
        image: NSImage,
        maskShape: MaskShape,
        configuration: SwiftyCropConfiguration,
        onComplete: @escaping (NSImage?) -> Void
    ) {
        self.image = image
        self.maskShape = maskShape
        self.configuration = configuration
        self.onComplete = onComplete
        _viewModel = State(initialValue: CropViewModel(
            maskRadius: configuration.maskRadius,
            maxMagnificationScale: configuration.maxMagnificationScale,
            maskShape: maskShape,
            rectAspectRatio: configuration.rectAspectRatio
        ))
        localizableTableName = "Localizable"
    }

    var body: some View {
        let magnificationGesture = MagnificationGesture()
            .onChanged { value in
                let sensitivity: CGFloat = 0.1 * configuration.zoomSensitivity
                let scaledValue = (value.magnitude - 1) * sensitivity + 1

                let maxScaleValues = viewModel.calculateMagnificationGestureMaxValues()
                viewModel.scale = min(
                    max(scaledValue * viewModel.lastScale, maxScaleValues.0),
                    maxScaleValues.1
                )
                updateOffset()
            }
            .onEnded { _ in
                viewModel.lastScale = viewModel.scale
                viewModel.lastOffset = viewModel.offset
            }

        // macOS no tiene DragGesture con la misma API táctil,
        // pero sí funciona con trackpad/ratón
        let dragGesture = DragGesture()
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

        let rotationGesture = RotationGesture()
            .onChanged { value in
                viewModel.angle = viewModel.lastAngle + value
            }
            .onEnded { _ in
                viewModel.lastAngle = viewModel.angle
            }

        VStack(spacing: 0) {
            // Barra superior con instrucciones
            Text(
                configuration.texts.interactionInstructions ??
                NSLocalizedString("interaction_instructions", tableName: localizableTableName, bundle: .main, comment: "")
            )
            .font(configuration.fonts.interactionInstructions)
            .foregroundColor(configuration.colors.interactionInstructions)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Área de crop
            ZStack {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(viewModel.angle)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .opacity(0.5)
                    .overlay(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    viewModel.updateMaskDimensions(for: geometry.size)
                                }
                        }
                    )

                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(viewModel.angle)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .mask(
                        MaskShapeView(maskShape: maskShape)
                            .frame(width: viewModel.maskSize.width, height: viewModel.maskSize.height)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(configuration.rotateImage ? rotationGesture : nil)
            .overlay(
                ScrollWheelReader { deltaY in
                    let sensitivity: CGFloat = 0.005 * configuration.zoomSensitivity
                    let maxScaleValues = viewModel.calculateMagnificationGestureMaxValues()
                    viewModel.scale = min(
                        max(viewModel.scale - deltaY * sensitivity, maxScaleValues.0),
                        maxScaleValues.1
                    )
                    viewModel.lastScale = viewModel.scale
                    updateOffset()
                }
            )

            // Barra inferior con botones
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text(
                        configuration.texts.cancelButton ??
                        NSLocalizedString("cancel_button", tableName: localizableTableName, bundle: .main, comment: "")
                    )
                    .font(configuration.fonts.cancelButton)
                    .foregroundColor(configuration.colors.cancelButton)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    onComplete(cropImage())
                    dismiss()
                } label: {
                    Text(
                        configuration.texts.saveButton ??
                        NSLocalizedString("save_button", tableName: localizableTableName, bundle: .main, comment: "")
                    )
                    .font(configuration.fonts.saveButton)
                    .foregroundColor(configuration.colors.saveButton)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(configuration.colors.background)
        // Tamaño mínimo razonable para una ventana macOS
        .frame(minWidth: 500, minHeight: 500)
    }

    private func updateOffset() {
        let maxOffsetPoint = viewModel.calculateDragGestureMax()
        let newX = min(max(viewModel.offset.width, -maxOffsetPoint.x), maxOffsetPoint.x)
        let newY = min(max(viewModel.offset.height, -maxOffsetPoint.y), maxOffsetPoint.y)
        viewModel.offset = CGSize(width: newX, height: newY)
        viewModel.lastOffset = viewModel.offset
    }

    private func cropImage() -> NSImage? {
        var editedImage: NSImage = image
        if configuration.rotateImage {
            if let rotatedImage = viewModel.rotateImage(editedImage) {
                editedImage = rotatedImage
            }
        }
        return viewModel.cropImage(editedImage)
    }

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

/// `SwiftyCropView` is a SwiftUI view for cropping images.
///
/// - Parameters:
///   - imageToCrop: The image to be cropped.
///   - maskShape: The shape of the mask used for cropping.
///   - configuration: The configuration for the cropping behavior.
///   - onComplete: A closure called when cropping completes, returning the cropped `NSImage?`.
public struct SwiftyCropView: View {
    private let imageToCrop: NSImage
    private let maskShape: MaskShape
    private let configuration: SwiftyCropConfiguration
    private let onComplete: (NSImage?) -> Void

    public init(
        imageToCrop: NSImage,
        maskShape: MaskShape,
        configuration: SwiftyCropConfiguration = SwiftyCropConfiguration(),
        onComplete: @escaping (NSImage?) -> Void
    ) {
        self.imageToCrop = imageToCrop
        self.maskShape = maskShape
        self.configuration = configuration
        self.onComplete = onComplete
    }

    public var body: some View {
        CropView(
            image: imageToCrop,
            maskShape: maskShape,
            configuration: configuration,
            onComplete: onComplete
        )
    }
}

struct ExampleView: View {
    @State private var selectedImage: NSImage?
    @State private var croppedImage: NSImage?

    var body: some View {
        VStack(spacing: 16) {
            Button("Seleccionar imagen…") {
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

#Preview {
    ExampleView()
}

// Inserted ScrollWheelReader implementation as requested
private struct ScrollWheelReader: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    init(onScroll: @escaping (CGFloat) -> Void) {
        self.onScroll = onScroll
    }

    func makeNSView(context: Context) -> NSScrollWheelView {
        let v = NSScrollWheelView()
        v.onScroll = onScroll
        return v
    }

    func updateNSView(_ nsView: NSScrollWheelView, context: Context) {
        nsView.onScroll = onScroll
    }
}

private final class NSScrollWheelView: NSView {
    var onScroll: ((CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        onScroll?(event.scrollingDeltaY)
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}

#endif
struct CropImageDemo: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    CropImageDemo()
}

