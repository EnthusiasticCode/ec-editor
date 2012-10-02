//
//  FileSystemItem_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"

@interface FileSystemItem ()

// All filesystem operations and accesses to the FileSystem instances' state must be done on this scheduler
+ (RACScheduler *)fileSystemScheduler;

// Wrap the subscribable so it's run on the fileSystemScheduler
+ (id<RACSubscribable>)coordinateSubscribable:(id<RACSubscribable>)subscribable;

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong) NSURL *itemURLBacking;

// Only called on fileSystemScheduler
- (instancetype)initByReadingItemAtURL:(NSURL *)url;

// Only called on fileSystemScheduler
- (instancetype)initByCreatingItemAtURL:(NSURL *)url;

@end
