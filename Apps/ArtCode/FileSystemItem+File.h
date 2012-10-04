//
//  FileSystemFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"

@interface FileSystemItem (File)

/// Returns a subscribable that sends the content of the item as it changes.
/// This subscribable does not complete.
- (id<RACSubscribable>)content;

/// Subscribes the receiver to \a contentSubscribable, updating it's content as needed.
/// The returned subscribable sends content updates triggered by other means.
- (id<RACSubscribable>)bindContentTo:(id<RACSubscribable>)contentSubscribable;

- (id<RACSubscribable>)contentWithDefaultEncoding;
- (id<RACSubscribable>)contentWithEncoding:(NSStringEncoding)encoding;
- (id<RACSubscribable>)bindContentWithDefaultEncodingTo:(id<RACSubscribable>)contentSubscribable;
- (id<RACSubscribable>)bindContentWithEncoding:(NSStringEncoding)encoding to:(id<RACSubscribable>)contentSubscribable;

@end
