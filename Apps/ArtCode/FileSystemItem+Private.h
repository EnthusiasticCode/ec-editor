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

#define CANCELLATION_DISPOSABLE(NAME) \
_CANCELLATION_FLAG; \
RACDisposable *NAME = _CANCELLATION_DISPOSABLE

#define CANCELLATION_COMPOUND_DISPOSABLE(NAME) \
_CANCELLATION_FLAG; \
RACCompoundDisposable *NAME = [RACCompound compoundDisposable]; \
[NAME addDisposable:_CANCELLATION_DISPOSABLE]

#define _CANCELLATION_FLAG \
__block uint32 __isCancelled = 0

#define _CANCELLATION_DISPOSABLE \
[RACDisposable disposableWithBlock:^{ \
OSAtomicOrBarrier(1, &__isCancelled); \
}]

#define IF_CANCELLED_RETURN(VALUE) \
if (__isCancelled != 0) return VALUE

#define IF_CANCELLED_BREAK() \
if (__isCancelled != 0) break


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
