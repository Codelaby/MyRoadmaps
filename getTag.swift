import Foundation

/// Represents a tag modifier on a view.
///
/// Replicates `SwiftUI.TagValueTraitKey<T>.Value.tagged`,
/// where `T` is the type of the tag which conforms to `Hashable`.
internal enum FakeTag<TagType: Hashable> {
    case tagged(TagType)

    var value: TagType {
        switch self {
        case let .tagged(value): return value
        }
    }
}
public enum TagError: Error, CustomStringConvertible {
    case notFound
    case other

    public var description: String {
        switch self {
        case .notFound: return "Not found"
        case .other: return "Other"
        }
    }
}

public extension View {
    /// Extracts the tag of the view. This can be used as a view modifier where
    /// the closure contains the tag's value. See `getTag()` for documentation.
    ///
    /// Example usage:
    ///
    ///     Text("Hello world!")
    ///         .tag("some tag")
    ///         .extractTag { (getTag: () throws -> String) in
    ///             // Method #1
    ///             do {
    ///                 let tag = try getTag()
    ///                 print("tag: \(tag)")
    ///             } catch {
    ///                 print("Tag error: \(error)")
    ///             }
    ///
    ///             // Method #2
    ///             let tag = try? getTag()
    ///             print("tag: \(tag)")
    ///         }
    ///
    /// - Returns: Self.
    func extractTag<TagType: Hashable>(_ closure: (() throws -> TagType) -> Void) -> Self {
        closure(getTag)
        return self
    }
}

public extension View {
    /// Gets the tag of the view. You can add a tag to a view like so using the `.tag(_:)` modifier:
    ///
    ///     Text("Hello world!")
    ///         .background(Color.red)
    ///         .tag("some tag")
    ///
    /// Example usage:
    ///
    ///     let view = Text("Hello world!").tag("some tag")
    ///
    ///     // Method #1
    ///     do {
    ///         let tag: String = try view.getTag()
    ///         print("tag: \(tag)")
    ///     } catch {
    ///         fatalError("Tag error: \(error)")
    ///     }
    ///
    ///     // Method #2
    ///     let tag: String? = try? view.getTag()
    ///     print("tag: \(tag)")
    ///
    /// This method extracts the tag from a view in the following cases:
    ///
    /// Case #1:
    ///
    ///     let view = Text("Hello world!").tag("some tag")
    ///
    /// Case #2:
    ///
    ///     struct CustomButton: View {
    ///         var body: some View {
    ///             Button("Button") {
    ///                 print("Action")
    ///             }
    ///             .tag("some tag")
    ///         }
    ///     }
    ///
    ///     let view = CustomButton()
    ///
    /// However, this does not work when the tag modifier is not attached to the top-level view. For
    /// example, adding a background modifier wraps the view (including the tag as the modifier) in
    /// a `SwiftUI.ModifiedContent` type.
    ///
    /// This view would fail to find the tag, and so will throw an error:
    ///
    ///     Text("Hello world!")
    ///         .tag("some tag")
    ///         .background(Color.red)
    ///
    /// - Returns: Value of tag.
    func getTag<TagType: Hashable>() throws -> TagType {
        // Mirror this view
        let mirror = Mirror(reflecting: self)

        // Get tag modifier
        guard let realTag = mirror.descendant("modifier", "value") else {
            // Not found tag modifier here, this could be composite
            // view. Check for modifier directly on the `body` if
            // not a primitive view type.
            guard Body.self != Never.self else {
                throw TagError.notFound
            }
            return try body.getTag()
        }

        // Bind memory to extract tag's value
        let fakeTag = try withUnsafeBytes(of: realTag) { ptr -> FakeTag<TagType> in
            let binded = ptr.bindMemory(to: FakeTag<TagType>.self)
            guard let mapped = binded.first else {
                throw TagError.other
            }
            return mapped
        }

        // Return tag's value
        return fakeTag.value
    }
}

