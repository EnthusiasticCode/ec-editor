//
//  FileSystemItem.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import <Foundation/Foundation.h>

@interface FileSystemItem : NSObject

/// Returns a subscribable that sends an existing item at \a URL, then completes
+ (id<RACSubscribable>)readItemAtURL:(NSURL *)url;

/// Returns a subscribable that sends a new item created at \a URL, then completes
+ (id<RACSubscribable>)createItemAtURL:(NSURL *)url;

/// Returns a subscribable that sends an item at \a URL, if it exists, or a newly created item then completes
+ (id<RACSubscribable>)readOrCreateItemAtURL:(NSURL *)url;

/// Returns a subscribable that sends the URL of the item as it changes.
/// This subscribable does not complete.
- (id<RACSubscribable>)itemURL;

/// Returns a subscribable that sends the \c NSURLFileResourceTypeKey value of the receiver, then completes
- (id<RACSubscribable>)itemType;

/// Attempts to delete the receiver, then sends error or completed to the returned subscribable.
- (id<RACSubscribable>)delete;

@end
