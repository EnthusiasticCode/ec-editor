//
//  FileSystemTextFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemFile.h"

@interface FileSystemTextFile : FileSystemFile

/// Subscribes the receiver to \a contentSubscribable, updating it's content as needed.
/// The returned subscribable sends content updates triggered by other means.
- (id<RACSubscribable>)subscribeToContent:(id<RACSubscribable>)contentSubscribable;

@end
