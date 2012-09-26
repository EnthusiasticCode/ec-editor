//
//  FileSystemFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"

@interface FileSystemFile : FileSystemItem

/// Attempts to set the content of the file, then sends error or completed to the returned subscribable.
- (id<RACSubscribable>)setContent:(NSData *)content;

@end
