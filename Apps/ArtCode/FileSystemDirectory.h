//
//  FileSystemDirectory.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"

@interface FileSystemDirectory : FileSystemItem

/// Returns a subscribable that sends the contents of the directory as it changes.
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
/// This subscribable does not complete.
- (id<RACSubscribable>)content;

/// Returns a subscribable that sends the content of the directory as it changes.
/// This subscribable does not complete.
- (id<RACSubscribable>)contentWithOptions:(NSDirectoryEnumerationOptions)options;

@end
