//
//  FileSystemItem+ExtendedAttributes.h
//  ArtCode
//
//  Created by Uri Baghin on 10/4/12.
//
//

#import "FileSystemItem.h"

@interface FileSystemItem (ExtendedAttributes)

/// Returns a subscribable that sends the value of the extended attribute for \a key as it changes.
/// This subscribable does not complete.
- (id<RACSubscribable>)extendedAttributeForKey:(NSString *)key;

/// Subscribes the receiver to \a contentSubscribable, updating the extended attribute as needed.
/// The returned subscribable sends content updates triggered by other means.
- (id<RACSubscribable>)bindExtendedAttributeForKey:(NSString *)key to:(id<RACSubscribable>)extendedAttributeSubscribable;

@end
