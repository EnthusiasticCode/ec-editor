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

/// Return a subscribable that sends the file item with the given URL, then completes
+ (id<RACSubscribable>)fileWithURL:(NSURL *)url;

/// Return a subscribable that sends the directory item with the given URL, then completes
+ (id<RACSubscribable>)directoryWithURL:(NSURL *)url;

/// Returns a subscribable that sends the name of the item
- (id<RACSubscribable>)name;

/// Returns a subscribable that sends the URL of the item
- (id<RACSubscribable>)url;

/// Returns a subscribable that sends the \c NSURLFileResourceTypeKey value of the receiver
- (id<RACSubscribable>)type;

/// Returns a subscribable that sends the parent directory of the receiver
- (id<RACSubscribable>)parent;

/// Attempts to create the receiver, then sends a next and an error or completed to the returned subscribable
- (id<RACSubscribable>)create;

/// Attempts to save the receiver to disk, then sends a next and an error or completed to the returned subscribable
- (id<RACSubscribable>)save;

/// Attempts to duplicate the receiver, then sends a next and an error or completed to the returned subscribable
- (id<RACSubscribable>)duplicate;

@end

@interface FileSystemItem (File)

/// Returns a RACPropertySyncSubject for the content of the file as an NSString
- (RACPropertySyncSubject *)stringContent;

@end

@interface FileSystemItem (Directory)

/// Returns a subscribable that sends the contents of the directory as it changes.
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
- (id<RACSubscribable>)children;

/// Returns a subscribable that sends the content of the directory as it changes.
- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options;

/// Returns a subscribable that sends the contents of the directory as it changes filtered by the abbreviations sent by \a abbreviationSubscribable.
/// Sends tuples where the first element is the url and the second element is the filter hitmask, if applicable
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles filteredByAbbreviation:abbreviationSubscribable
- (id<RACSubscribable>)childrenFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

/// Returns a subscribable that sends the content of the directory as it changes filtered by the abbreviations sent by \a abbreviationSubscribable.
/// Sends tuples where the first element is the url and the second element is the filter hitmask, if applicable
- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

@end

@interface FileSystemItem (FileManagement)

/// Attempts to move the receiver to the destination, then sends a next and an error or completed to the returned subscribable.
- (id<RACSubscribable>)moveTo:(FileSystemItem *)destination;

/// Attempts to copy the receiver to the destination, then sends a next and an error or completed to the returned subscribable.
- (id<RACSubscribable>)copyTo:(FileSystemItem *)destination;

/// Attempts to rename or create a renamed copy of the receiver, then sends a next and an error or completed to the returned subscribable.
- (id<RACSubscribable>)renameTo:(NSString *)newName copy:(BOOL)copy;

/// Attempts to export the receiver or a copy of the receiver to the given destination directory, then sends a next and an error or completed to the returned subscribable.
- (id<RACSubscribable>)exportTo:(NSURL *)destination copy:(BOOL)copy;

/// Attempts to delete the receiver, then sends a next and an error or completed to the returned subscribable.
- (id<RACSubscribable>)delete;

@end

@interface FileSystemItem (ExtendedAttributes)

/// Returns a RACPropertySyncSubject for the extended attribute identified by the given key
- (RACPropertySyncSubject *)extendedAttributeForKey:(NSString *)key;

@end
