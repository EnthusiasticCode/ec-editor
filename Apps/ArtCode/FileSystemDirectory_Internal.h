//
//  FileSystemDirectory_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 9/27/12.
//
//

#import "FileSystemDirectory.h"

@interface FileSystemDirectory ()

- (id<RACSubscribable>)internalContent;

- (id<RACSubscribable>)internalContentWithOptions:(NSDirectoryEnumerationOptions)options;

@end
