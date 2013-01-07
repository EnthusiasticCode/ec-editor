//
//  FileSystemItem.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import <Foundation/Foundation.h>
@class RACPropertySyncSubject;


@interface FileSystemItem : NSObject

/// Return a signal that sends the item with the given URL, then completes
/// Note that if the item doesn't exist on the file system, it won't be possible to create it with the item returned from this call
+ (RACSignal *)itemWithURL:(NSURL *)url;

/// Returns a signal that sends the URL of the item
- (RACSignal *)url;

/// Returns a signal that sends the `NSURLFileResourceTypeKey` value of the receiver
- (RACSignal *)type;

/// Returns a signal that sends the name of the item
- (RACSignal *)name;

/// Returns a signal that sends the parent directory of the receiver
- (RACSignal *)parent;

@end

@interface FileSystemFile : FileSystemItem

/// Return a signal that sends the file item with the given URL, then completes
+ (RACSignal *)fileWithURL:(NSURL *)url;

/// Attempts to create a new file at the given url, then sends the created file and completed, or an error, to the returned signal
+ (RACSignal *)createFileWithURL:(NSURL *)url;

/// Returns a source that sends the file's encoding
- (RACSignal *)encodingSignal;

/// Binds the encoding of the file as an NSStringEncoding. Returns a disposable to dispose the binding.
- (RACDisposable *)bindEncodingToObject:(id)target withKeyPath:(NSString *)keyPath;

/// Returns a source that sends the contents of the file encoded as a string with it's encoding
- (RACSignal *)contentSignal;

/// Binds the content of the file as a NSString. Returns a disposable to dispose the binding.
- (RACDisposable *)bindContentToObject:(id)target withKeyPath:(NSString *)keyPath;

/// Attempts to save the receiver to disk, then sends the item and completed, or an error, to the returned signal
- (RACSignal *)save;

@end

@interface FileSystemDirectory : FileSystemItem

/// Return a signal that sends the directory item with the given URL, then completes
+ (RACSignal *)directoryWithURL:(NSURL *)url;

/// Attempts to create a new directory at the given url, then sends the created directory and completed, or an error, to the returned signal
+ (RACSignal *)createDirectoryWithURL:(NSURL *)url;

/// Returns a signal that filters `childrenSignal` by the abbreviations sent by `abbreviationSignal`.
/// Sends tuples where the first element is the child and the second element is the filter hitmask, if applicable.
+ (RACSignal *)filterChildren:(RACSignal *)childrenSignal byAbbreviation:(RACSignal *)abbreviationSignal;

/// Returns a signal that sends the children of the directory as they change.
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
- (RACSignal *)children;

/// Returns a signal that sends the children of the directory as they change.
/// Doesn't support NSDirectoryEnumerationSkipsPackageDescendants
- (RACSignal *)childrenWithOptions:(NSDirectoryEnumerationOptions)options;

@end

@interface FileSystemItem (FileManagement)

// Moves the receiver to the given directory and generates a new FileSystemItem.
//
// destination:		The FileSystemDirectory in which to copy the receiver.
// newName:				A name to give to the copyied file. It can be nil to keep the
//								current name.
// shouldReplace:	Indicates if the peration should replace any existing file.
//
// Returns a signal that sends the moved FileSystemItem and completes.
- (RACSignal *)moveTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace;

// Calls -moveTo:destination withName:nil replaceExisting:YES.
- (RACSignal *)moveTo:(FileSystemDirectory *)destination;

// Copy the receiver to the given directory and generates a new FileSystemItem.
//
// destination:		The FileSystemDirectory in which to copy the receiver.
// newName:				A name to give to the copyied file. It can be nil to keep the
//								current name.
// shouldReplace:	Indicates if the peration should replace any existing file.
//
// Returns a signal that sends the newly copied FileSystemItem and completes.
- (RACSignal *)copyTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace;

// Calls -copyTo:destination withName:nil replaceExisting:YES.
- (RACSignal *)copyTo:(FileSystemDirectory *)destination;

/// Attempts to rename or create a renamed copy of the receiver, then sends the item and completed, or an error, to the returned signal.
- (RACSignal *)renameTo:(NSString *)newName;

/// Attempts to duplicate the receiver, then sends the duplicate and completed, or an error, to the returned signal
- (RACSignal *)duplicate;

/// Attempts to export the receiver or a copy of the receiver to the given destination location, then sends the destination url and completed, or an error, to the returned signal.
- (RACSignal *)exportTo:(NSURL *)destination copy:(BOOL)copy;

/// Attempts to delete the receiver, then sends the item and completed, or an error, to the returned signal.
- (RACSignal *)delete;

@end

@interface FileSystemItem (ExtendedAttributes)

/// Returns a source that sends the extended attribute identified by \a key
- (RACSignal *)extendedAttributeSourceForKey:(NSString *)key;

/// Returns a sink that receives the extended attribute identified by \a key
- (id<RACSubscriber>)extendedAttributeSinkForKey:(NSString *)key;

@end
