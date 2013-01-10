//
//  FileSystemItem+Private.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemItem.h"

@interface FileSystemItem ()

// Designated initializer.
//
// There shouldn't necessarily be something to load from `url`, nor should the
// item write anything to it at first.
- (instancetype)initWithURL:(NSURL *)url;

// Called after the receiver has been moved.
- (void)didMoveFromURL:(NSURL *)url;

// Called after the receiver has been copied.
- (void)didCopyFromURL:(NSURL *)url;

// Called after the receiver has been deleted.
- (void)didDelete;

@end
