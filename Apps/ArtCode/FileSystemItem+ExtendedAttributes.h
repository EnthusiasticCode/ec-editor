//
//  FileSystemItem+ExtendedAttributes.h
//  ArtCode
//
//  Created by Uri Baghin on 10/4/12.
//
//

#import "FileSystemItem.h"
@class RACPropertySyncSubject;

@interface FileSystemItem (ExtendedAttributes)

/// Returns a RACPropertySyncSubject for the extended attribute identified by the given key
- (RACPropertySyncSubject *)extendedAttributeForKey:(NSString *)key;

@end
