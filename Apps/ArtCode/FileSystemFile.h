//
//  FileSystemFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"

@interface FileSystemFile : FileSystemItem

/// Subscribes the receiver to \a contentSubscribable, updating it's content as needed.
/// The returned subscribable sends content updates triggered by other means.
- (id<RACSubscribable>)bindContentTo:(id<RACSubscribable>)contentSubscribable;

/// Returns a subscribable that sends the value of the extended attribute for \a key as it changes.
/// This subscribable does not complete.
- (id<RACSubscribable>)extendedAttributeValueForKey:(NSString *)key;

/// Subscribes the receiver to \a contentSubscribable, updating the extended attribute as needed.
/// The returned subscribable sends content updates triggered by other means.
- (id<RACSubscribable>)bindExtendedAttributeForKey:(NSString *)key to:(id<RACSubscribable>)extendedAttributeSubscribable;

@end
