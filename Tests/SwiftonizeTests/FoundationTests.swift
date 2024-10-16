//
//  File.swift
//  
//
//  Created by CodeBuilder on 16/09/2023.
//

import Foundation
import AVFoundation

//NSItemProvider
let nsItemProviderCode = """
import CoreFoundation

/*	NSItemProvider.h
		Copyright (c) 2013-2019, Apple Inc. All rights reserved.
*/

@available(macOS 10.13, *)
public enum NSItemProviderRepresentationVisibility : Int, @unchecked Sendable {

	
	case all = 0 // All processes can see this representation

	
	@available(macOS 10.13, *)
	case group = 2 // Only processes from the same group can see this representation

	case ownProcess = 3 // Ony the originator's process can see this representation
}

// The default behavior is to copy files.
@available(macOS 10.13, *)
public struct NSItemProviderFileOptions : OptionSet, @unchecked Sendable {

	public init(rawValue: Int)

	
	public static var openInPlace: NSItemProviderFileOptions { get }
}

// This protocol allows a class to export its data to a variety of binary representations.

@available(macOS 10.13, *)
public protocol NSItemProviderWriting : NSObjectProtocol {

	
	static var writableTypeIdentifiersForItemProvider: [String] { get }

	
	// If this method is not implemented, the class method will be consulted instead.
	optional var writableTypeIdentifiersForItemProvider: [String] { get }

	
	optional static func itemProviderVisibilityForRepresentation(withTypeIdentifier typeIdentifier: String) -> NSItemProviderRepresentationVisibility

	
	// If this method is not implemented, the class method will be consulted instead.
	optional func itemProviderVisibilityForRepresentation(withTypeIdentifier typeIdentifier: String) -> NSItemProviderRepresentationVisibility

	
	func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Progress? // One of writableTypeIdentifiersForItemProvider
}

// This protocol allows a class to be constructed from a variety of binary representations.

@available(macOS 10.13, *)
public protocol NSItemProviderReading : NSObjectProtocol {

	
	static var readableTypeIdentifiersForItemProvider: [String] { get }

	
	static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self
}
extension NSItemProvider {

	
	public typealias CompletionHandler = @Sendable (NSSecureCoding?, Error?) -> Void

	public typealias LoadHandler = @Sendable (NSItemProvider.CompletionHandler?, AnyClass?, [AnyHashable : Any]?) -> Void

	
	// An NSItemProvider is a high level abstraction for an item supporting multiple representations.
	
	// Register higher-fidelity types first, followed by progressively lower-fidelity ones. This ordering helps consumers get the best representation they can handle.
	
	// Registers a data-backed representation.
	
	// Registers a file-backed representation.
	// Set `coordinated` to YES if the returned file must be accessed using NSFileCoordinator.
	// If `NSItemProviderFileOptionOpenInPlace` is not provided, the file provided will be copied before the load handler returns.
	
	// Returns the list of registered type identifiers, in the order they were registered.
	
	// Returns YES if the item provider has at least one item that conforms to the supplied type identifier.
	
	// Copies the provided data into an NSData object.
	
	// Writes a copy of the data to a temporary file. This file will be deleted when the completion handler returns. Your program should copy or move the file within the completion handler.
	
	// Open the original file in place, if possible.
	// If a file is not available for opening in place, a copy of the file is written to a temporary location, and `isInPlace` is set to NO. Your program may then copy or move the file, or the system will delete this file at some point in the future.
	
	// Instantiate an NSItemProvider by querying an object for its eligible type identifiers via the NSItemProviderWriting protocol.
	
	// Add representations from an object using the NSItemProviderWriting protocol. Duplicate representations are ignored.
	
	// Add representations from a class, but defer loading the object until needed.
	
	// Instantiate an object using the NSItemProviderReading protocol.
	
	// These methods allow you to assign NSSecureCoding-compliant objects to certain UTIs, and retrieve either the original object, or a coerced variant
	// based on the following rules.
	//
	// If the object is retrieved using loadItemForTypeIdentifier:options:completionHandler, and the completion block signature contains a paramater of
	// the same class as the initial object (or a superclass), the original object is returned.
	//
	// If the completion block signature contains a parameter that is not the same class as `item`, some coercion may occur:
	//    Original class       Requested class          Coercion action
	//    -------------------  -----------------------  -------------------
	//    NSURL                NSData                   The contents of the URL is read and returned as NSData
	//    NSData               NSImage/UIImage          An NSImage (macOS) or UIImage (iOS) is constructed from the data
	//    NSURL                UIImage                  A UIImage is constructed from the file at the URL (iOS)
	//    NSImage              NSData                   A TIFF representation of the image is returned
	//
	// When providing or consuming data using this interface, a file may be opened in-place depending on the NSExtension context in which this object is used.
	//
	// If the item is retrieved using the binary interface described above, the original object will be retrieved and coerced to NSData.
	//
	// Items registered using the binary interface will appear as NSData with respect to the coercing interface.
	
	// Initialize an NSItemProvider with an object assigned to a single UTI. `item` is retained.
	
	// Initialize an NSItemProvider with load handlers for the given file URL, and the file content. A type identifier is inferred from the file extension.
	
	// Registers a load handler that returns an object, assigned to a single UTI.
	
	// Loads the best matching item for a type identifier. The returned object depends on the class specified for the completion handler's `item` parameter.
	// See the table above for coercion rules.
	
	// Common keys for the item provider options dictionary.
	// NSValue of CGSize or NSSize, specifies image size in pixels.
	
	// Some uses of NSItemProvider support the use of optional preview images.
	
	// Sets a custom preview image handler block for this item provider. The returned item should preferably be NSData or a file NSURL.
	
	// Loads the preview image for this item by either calling the supplied preview block or falling back to a QuickLook-based handler. This method, like loadItemForTypeIdentifier:options:completionHandler:, supports implicit type coercion for the item parameter of the completion block. Allowed value classes are: NSData, NSURL, UIImage/NSImage.
	
	// Keys used in property list items received from or sent to JavaScript code
	
	// If JavaScript code passes an object to its completionFunction, it will be placed into an item of type kUTTypePropertyList, containing an NSDictionary, under this key.
	
	// Arguments to be passed to a JavaScript finalize method should be placed in an item of type kUTTypePropertyList, containing an NSDictionary, under this key.
	
	// Constant used by NSError to distinguish errors belonging to the NSItemProvider domain
	@available(macOS 10.10, *)
	public class let errorDomain: String

	
	// NSItemProvider-related error codes
	@available(macOS 10.10, *)
	public enum ErrorCode : Int, @unchecked Sendable {

		
		case unknownError = -1

		case itemUnavailableError = -1000

		case unexpectedValueClassError = -1100

		@available(macOS 10.11, *)
		case unavailableCoercionError = -1200
	}
}
@available(macOS 10.10, *)
open class NSItemProvider : NSObject, NSCopying {

	public init()

	@available(macOS 10.13, *)
	open func registerDataRepresentation(forTypeIdentifier typeIdentifier: String, visibility: NSItemProviderRepresentationVisibility, loadHandler: @escaping @Sendable (@escaping (Data?, Error?) -> Void) -> Progress?)

	@available(macOS 10.13, *)
	open func registerFileRepresentation(forTypeIdentifier typeIdentifier: String, fileOptions: NSItemProviderFileOptions = [], visibility: NSItemProviderRepresentationVisibility, loadHandler: @escaping @Sendable (@escaping (URL?, Bool, Error?) -> Void) -> Progress?)

	open var registeredTypeIdentifiers: [String] { get }

	@available(macOS 10.13, *)
	open func registeredTypeIdentifiers(fileOptions: NSItemProviderFileOptions = []) -> [String]

	open func hasItemConformingToTypeIdentifier(_ typeIdentifier: String) -> Bool

	@available(macOS 10.13, *)
	open func hasRepresentationConforming(toTypeIdentifier typeIdentifier: String, fileOptions: NSItemProviderFileOptions = []) -> Bool

	@available(macOS 10.13, *)
	open func loadDataRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Progress

	@available(macOS 10.13, *)
	open func loadFileRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping @Sendable (URL?, Error?) -> Void) -> Progress

	@available(macOS 10.13, *)
	open func loadInPlaceFileRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping @Sendable (URL?, Bool, Error?) -> Void) -> Progress

	@available(macOS 10.14, *)
	open var suggestedName: String?

	@available(macOS 10.13, *)
	public convenience init(object: NSItemProviderWriting)

	@available(macOS 10.13, *)
	open func registerObject(_ object: NSItemProviderWriting, visibility: NSItemProviderRepresentationVisibility)

	@available(macOS 10.13, *)
	open func registerObject(ofClass aClass: NSItemProviderWriting.Type, visibility: NSItemProviderRepresentationVisibility, loadHandler: @escaping @Sendable (@escaping (NSItemProviderWriting?, Error?) -> Void) -> Progress?)

	@available(macOS 10.13, *)
	open func canLoadObject(ofClass aClass: NSItemProviderReading.Type) -> Bool

	@available(macOS 10.13, *)
	open func loadObject(ofClass aClass: NSItemProviderReading.Type, completionHandler: @escaping @Sendable (NSItemProviderReading?, Error?) -> Void) -> Progress

	public init(item: NSSecureCoding?, typeIdentifier: String?)

	public convenience init?(contentsOf fileURL: URL!)

	open func registerItem(forTypeIdentifier typeIdentifier: String, loadHandler: @escaping NSItemProvider.LoadHandler)

	open func loadItem(forTypeIdentifier typeIdentifier: String, options: [AnyHashable : Any]? = nil, completionHandler: NSItemProvider.CompletionHandler? = nil)

	open func loadItem(forTypeIdentifier typeIdentifier: String, options: [AnyHashable : Any]? = nil) async throws -> NSSecureCoding
}

@available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)
extension NSItemProvider {

	@available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)
	public func registerObject<T>(ofClass: T.Type, visibility: NSItemProviderRepresentationVisibility, loadHandler: @escaping ((T?, (Error)?) -> Void) -> Progress?) where T : _ObjectiveCBridgeable, T._ObjectiveCType : NSItemProviderWriting

	@available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)
	public func canLoadObject<T>(ofClass: T.Type) -> Bool where T : _ObjectiveCBridgeable, T._ObjectiveCType : NSItemProviderReading

	@available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)
	public func loadObject<T>(ofClass: T.Type, completionHandler: @escaping (T?, (Error)?) -> Void) -> Progress where T : _ObjectiveCBridgeable, T._ObjectiveCType : NSItemProviderReading
}

@available(*, unavailable)
extension NSItemProvider : @unchecked Sendable {
}
@available(macOS 10.10, *)
public let NSItemProviderPreferredImageSizeKey: String
extension NSItemProvider {

	@available(macOS 10.10, *)
	open var previewImageHandler: NSItemProvider.LoadHandler?

	@available(macOS 10.10, *)
	open func loadPreviewImage(options: [AnyHashable : Any]! = [:], completionHandler: NSItemProvider.CompletionHandler!)

	@available(macOS 10.10, *)
	open func loadPreviewImage(options: [AnyHashable : Any]! = [:]) async throws -> NSSecureCoding
}
@available(macOS 10.10, *)
public let NSExtensionJavaScriptPreprocessingResultsKey: String


"""
