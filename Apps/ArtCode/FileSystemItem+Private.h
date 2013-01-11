//
//  FileSystemItem+Private.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemItem.h"

@class RACScheduler;

#if DEBUG
#define ASSERT_FILE_SYSTEM_SCHEDULER() ASSERT(currentScheduler() == fileSystemScheduler())
#else
#define ASSERT_FILE_SYSTEM_SCHEDULER()
#endif

// All filesystem accesses must be on this scheduler.
RACScheduler *fileSystemScheduler();

// All values sent by returned signals must be sent on the calling scheduler.
RACScheduler *currentScheduler();

// Accesses to the cache must be on `fileSystemScheduler()`.
NSMutableDictionary *fileSystemItemCache();

@interface FileSystemItem ()

// Designated initializer.
//
// There shouldn't necessarily be something to load from `url`, nor should the
// item write anything to it at first.
- (instancetype)initWithURL:(NSURL *)url;

// Called after the receiver has been moved.
- (void)didMoveToURL:(NSURL *)url;

// Called after the receiver has been copied.
- (void)didCopyToURL:(NSURL *)url;

// Called after the receiver has been deleted.
- (void)didDelete;

@end
