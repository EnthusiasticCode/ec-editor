//
//  FileSystemItem+Private.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemItem.h"

#import <libkern/OSAtomic.h>

@class RACScheduler;

#if DEBUG
#define ASSERT_FILE_SYSTEM_SCHEDULER() ASSERT(currentScheduler() == fileSystemScheduler())
#else
#define ASSERT_FILE_SYSTEM_SCHEDULER()
#endif

#define CANCELLATION_DISPOSABLE(NAME) \
_CANCELLATION_FLAG; \
RACCompoundDisposable *NAME = [RACCompoundDisposable compoundDisposable]; \
[NAME addDisposable:_CANCELLATION_DISPOSABLE]

#define IF_CANCELLED_RETURN(VALUE) \
if (__isCancelled != 0) return VALUE

#define IF_CANCELLED_BREAK() \
if (__isCancelled != 0) break

#define CANCELLATION_FLAG \
&__isCancelled

#define _CANCELLATION_FLAG \
__block volatile uint32_t __isCancelled = 0

#define _CANCELLATION_DISPOSABLE \
[RACDisposable disposableWithBlock:^{ \
OSAtomicOr32Barrier(1, &__isCancelled); \
}]

// All filesystem accesses must be on this scheduler.
RACScheduler *fileSystemScheduler();

// All values sent by returned signals must be sent on the calling scheduler.
RACScheduler *currentScheduler();

// Accesses to the cache must be on `fileSystemScheduler()`.
NSMutableDictionary *fileSystemItemCache();

@interface FileSystemItem ()

@property (atomic, strong) NSURL *urlBacking;

// Designated initializer.
//
// There shouldn't necessarily be something to load from `url`, nor should the
// item write anything to it at first.
- (instancetype)initWithURL:(NSURL *)url;

// Called after the receiver has been created.
- (void)didCreate;

// Called after the receiver has been moved.
- (void)didMoveToURL:(NSURL *)url;

// Called after the receiver has been copied.
- (void)didCopyToURL:(NSURL *)url;

// Called after the receiver has been deleted.
- (void)didDelete;

@end
