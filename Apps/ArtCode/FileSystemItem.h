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

/// Return a subscribable that sends the item with the given URL, then completes
/// Note that if the item doesn't exist on the file system, it won't be possible to create it with the item returned from this call
+ (id<RACSubscribable>)itemWithURL:(NSURL *)url;

/// Returns a subscribable that sends the URL of the item
- (id<RACSubscribable>)url;

/// Returns a subscribable that sends the \c NSURLFileResourceTypeKey value of the receiver
- (id<RACSubscribable>)type;

/// Returns a subscribable that sends the name of the item
- (id<RACSubscribable>)name;

/// Returns a subscribable that sends the parent directory of the receiver
- (id<RACSubscribable>)parent;

/// Attempts to save the receiver to disk, then sends the item and completed, or an error, to the returned subscribable
- (id<RACSubscribable>)save;

@end

@interface FileSystemFile : FileSystemItem

/// Return a subscribable that sends the file item with the given URL, then completes
+ (id<RACSubscribable>)fileWithURL:(NSURL *)url;

/// Attempts to create a new file at the given url, then sends the created file and completed, or an error, to the returned subscribable
+ (id<RACSubscribable>)createFileWithURL:(NSURL *)url;

/// Returns a RACPropertySyncSubject for the content of the file as an NSString
@property (nonatomic, strong, readonly) RACPropertySyncSubject *stringContent;

@end

@interface FileSystemDirectory : FileSystemItem

/// Return a subscribable that sends the directory item with the given URL, then completes
+ (id<RACSubscribable>)directoryWithURL:(NSURL *)url;

/// Attempts to create a new directory at the given url, then sends the created directory and completed, or an error, to the returned subscribable
+ (id<RACSubscribable>)createDirectoryWithURL:(NSURL *)url;

/// Returns a subscribable that sends the children of the directory as they change.
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
- (id<RACSubscribable>)children;

/// Returns a subscribable that sends the children of the directory as they change.
- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options;

/// Returns a subscribable that sends the children of the directory as they change filtered by the abbreviations sent by \a abbreviationSubscribable.
/// Sends tuples where the first element is the child and the second element is the filter hitmask, if applicable
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles filteredByAbbreviation:abbreviationSubscribable
- (id<RACSubscribable>)childrenFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

/// Returns a subscribable that sends the children of the directory as they change filtered by the abbreviations sent by \a abbreviationSubscribable.
/// Sends tuples where the first element is the child and the second element is the filter hitmask, if applicable
- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

@end

@interface FileSystemItem (FileManagement)

/// Attempts to move the receiver to the destination, then sends the item and completed, or an error, to the returned subscribable.
- (id<RACSubscribable>)moveTo:(FileSystemDirectory *)destination;

/// Attempts to copy the receiver to the destination, then sends the copy and completed, or an error, to the returned subscribable.
- (id<RACSubscribable>)copyTo:(FileSystemDirectory *)destination;

/// Attempts to rename or create a renamed copy of the receiver, then sends the item and completed, or an error, to the returned subscribable.
- (id<RACSubscribable>)renameTo:(NSString *)newName copy:(BOOL)copy;

/// Attempts to duplicate the receiver, then sends the duplicate and completed, or an error, to the returned subscribable
- (id<RACSubscribable>)duplicate;

/// Attempts to export the receiver or a copy of the receiver to the given destination directory, then sends the destination url and completed, or an error, to the returned subscribable.
- (id<RACSubscribable>)exportTo:(NSURL *)destination copy:(BOOL)copy;

/// Attempts to delete the receiver, then sends the item and completed, or an error, to the returned subscribable.
- (id<RACSubscribable>)delete;

@end

@interface FileSystemItem (ExtendedAttributes)

/// Returns a RACPropertySyncSubject for the extended attribute identified by the given key
- (RACPropertySyncSubject *)extendedAttributeForKey:(NSString *)key;

@end
