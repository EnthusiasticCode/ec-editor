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
+ (id<RACSignal>)itemWithURL:(NSURL *)url;

/// Returns a signal that sends the URL of the item
- (id<RACSignal>)url;

/// Returns a signal that sends the \c NSURLFileResourceTypeKey value of the receiver
- (id<RACSignal>)type;

/// Returns a signal that sends the name of the item
- (id<RACSignal>)name;

/// Returns a signal that sends the parent directory of the receiver
- (id<RACSignal>)parent;

@end

@interface FileSystemFile : FileSystemItem

/// Return a signal that sends the file item with the given URL, then completes
+ (id<RACSignal>)fileWithURL:(NSURL *)url;

/// Attempts to create a new file at the given url, then sends the created file and completed, or an error, to the returned signal
+ (id<RACSignal>)createFileWithURL:(NSURL *)url;

/// Returns a source that sends the file's encoding
- (id<RACSignal>)encodingSource;

/// Returns a sink that receives the file's encoding
- (id<RACSubscriber>)encodingSink;

/// Returns a source that sends the contents of the file encoded as a string with it's encoding
- (id<RACSignal>)contentSource;

/// Returns a sink that receives strings as the file's content
- (id<RACSubscriber>)contentSink;

/// Attempts to save the receiver to disk, then sends the item and completed, or an error, to the returned signal
- (id<RACSignal>)save;

@end

@interface FileSystemDirectory : FileSystemItem

/// Return a signal that sends the directory item with the given URL, then completes
+ (id<RACSignal>)directoryWithURL:(NSURL *)url;

/// Attempts to create a new directory at the given url, then sends the created directory and completed, or an error, to the returned signal
+ (id<RACSignal>)createDirectoryWithURL:(NSURL *)url;

/// Returns a signal that sends the children of the directory as they change.
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
- (id<RACSignal>)children;

/// Returns a signal that sends the children of the directory as they change.
/// Doesn't support NSDirectoryEnumerationSkipsPackageDescendants
- (id<RACSignal>)childrenWithOptions:(NSDirectoryEnumerationOptions)options;

/// Returns a signal that sends the children of the directory as they change filtered by the abbreviations sent by \a abbreviationSignal.
/// Sends tuples where the first element is the child and the second element is the filter hitmask, if applicable
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles filteredByAbbreviation:abbreviationSignal
- (id<RACSignal>)childrenFilteredByAbbreviation:(id<RACSignal>)abbreviationSignal;

/// Returns a signal that sends the children of the directory as they change filtered by the abbreviations sent by \a abbreviationSignal.
/// Sends tuples where the first element is the child and the second element is the filter hitmask, if applicable
/// Doesn't support NSDirectoryEnumerationSkipsPackageDescendants
- (id<RACSignal>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSignal>)abbreviationSignal;

@end

@interface FileSystemItem (FileManagement)

/// Attempts to move the receiver to the destination, then sends the item and completed, or an error, to the returned signal.
- (id<RACSignal>)moveTo:(FileSystemDirectory *)destination;
- (id<RACSignal>)moveTo:(FileSystemDirectory *)destination renameTo:(NSString *)newName;

/// Attempts to copy the receiver to the destination, then sends the copy and completed, or an error, to the returned signal.
- (id<RACSignal>)copyTo:(FileSystemDirectory *)destination;

/// Attempts to rename or create a renamed copy of the receiver, then sends the item and completed, or an error, to the returned signal.
- (id<RACSignal>)renameTo:(NSString *)newName;

/// Attempts to duplicate the receiver, then sends the duplicate and completed, or an error, to the returned signal
- (id<RACSignal>)duplicate;

/// Attempts to export the receiver or a copy of the receiver to the given destination location, then sends the destination url and completed, or an error, to the returned signal.
- (id<RACSignal>)exportTo:(NSURL *)destination copy:(BOOL)copy;

/// Attempts to delete the receiver, then sends the item and completed, or an error, to the returned signal.
- (id<RACSignal>)delete;

@end

@interface FileSystemItem (ExtendedAttributes)

/// Returns a source that sends the extended attribute identified by \a key
- (id<RACSignal>)extendedAttributeSourceForKey:(NSString *)key;

/// Returns a sink that receives the extended attribute identified by \a key
- (id<RACSubscriber>)extendedAttributeSinkForKey:(NSString *)key;

@end
