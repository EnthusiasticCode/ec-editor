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

/// Returns a subscribable that sends an existing item at \a URL, then completes
+ (id<RACSubscribable>)readItemAtURL:(NSURL *)url;

/// Returns a subscribable that sends a new file item created at \a URL, then completes
+ (id<RACSubscribable>)createFileAtURL:(NSURL *)url;

/// Returns a subscribable that sends a new directory item created at \a URL, then completes
+ (id<RACSubscribable>)createDirectoryAtURL:(NSURL *)url;

/// Returns a subscribable that sends the URL of the item as it changes.
/// This subscribable does not complete.
- (id<RACSubscribable>)itemURL;

/// Returns a subscribable that sends the \c NSURLFileResourceTypeKey value of the receiver, then completes
- (id<RACSubscribable>)itemType;

/// Attempts to save the receiver to disk, within a certain time, then sends error or completed to the returned subscribable
- (id<RACSubscribable>)save;

@end

@interface FileSystemItem (File)

/// Returns a RACPropertySyncSubject for the content of the file as an NSString
- (RACPropertySyncSubject *)stringContent;

@end

@interface FileSystemItem (Directory)

/// Returns a subscribable that sends the contents of the directory as it changes.
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
/// This subscribable does not complete.
- (id<RACSubscribable>)children;

/// Returns a subscribable that sends the content of the directory as it changes.
/// This subscribable does not complete.
- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options;

/// Returns a subscribable that sends the contents of the directory as it changes filtered by the abbreviations sent by \a abbreviationSubscribable.
/// Sends tuples where the first element is the url and the second element is the filter hitmask, if applicable
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles filteredByAbbreviation:abbreviationSubscribable
/// This subscribable does not complete.
- (id<RACSubscribable>)childrenFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

/// Returns a subscribable that sends the content of the directory as it changes filtered by the abbreviations sent by \a abbreviationSubscribable.
/// Sends tuples where the first element is the url and the second element is the filter hitmask, if applicable
/// This subscribable does not complete.
- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

@end

@interface FileSystemItem (FileManagement)

/// Attempts to move the receiver to the destination, then sends error or completed to the returned subscribable.
- (id<RACSubscribable>)moveTo:(FileSystemItem *)destination;

/// Attempts to copy the receiver to the destination, then sends error or completed to the returned subscribable.
- (id<RACSubscribable>)copyTo:(FileSystemItem *)destination;

/// Attempts to rename or create a renamed copy of the receiver, then sends error or completed to the returned subscribable.
- (id<RACSubscribable>)renameTo:(NSString *)newName copy:(BOOL)copy;

/// Attempts to export the receiver or a copy of the receiver to the given destination directory, then sends error or completed to the returned subscribable.
- (id<RACSubscribable>)exportTo:(NSURL *)destination copy:(BOOL)copy;

/// Attempts to delete the receiver, then sends error or completed to the returned subscribable.
- (id<RACSubscribable>)delete;

@end

@interface FileSystemItem (ExtendedAttributes)

/// Returns a RACPropertySyncSubject for the extended attribute identified by the given key
- (RACPropertySyncSubject *)extendedAttributeForKey:(NSString *)key;

@end
