//
//  ECFileCoordinator.m
//  ECFoundation
//
//  Created by Uri Baghin on 12/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECFileCoordinator.h"

static dispatch_queue_t _fileCoordinationDispatchQueue;
static NSMutableArray *_filePresenters;

@interface ECFileCoordinator ()
{
    id<NSFilePresenter>_filePresenterToIgnore;
}
@end

@implementation ECFileCoordinator

+ (void)initialize
{
    _fileCoordinationDispatchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    _filePresenters = [[NSMutableArray alloc] init];
}

+ (void)addFilePresenter:(id<NSFilePresenter>)filePresenter
{
    dispatch_barrier_async(_fileCoordinationDispatchQueue, ^{
        ECASSERT([filePresenter conformsToProtocol:@protocol(NSFilePresenter)]);
        @try {
            [_filePresenters addObject:filePresenter];
        }
        @catch (NSException *exception) {
            ECASSERT(NO);
        }
    });
}

+ (void)removeFilePresenter:(id<NSFilePresenter>)filePresenter
{
    dispatch_barrier_sync(_fileCoordinationDispatchQueue, ^{
        ECASSERT([_filePresenters containsObject:filePresenter]);
        @try {
            [_filePresenters removeObject:filePresenter];
        }
        @catch (NSException *exception) {
            ECASSERT(NO);
        }
    });
}

+ (NSArray *)filePresenters
{
    __block NSArray *filePresenters = nil;
    dispatch_barrier_sync(_fileCoordinationDispatchQueue, ^{
        @try {
            filePresenters = [_filePresenters copy];
        }
        @catch (NSException *exception) {
            ECASSERT(NO);
        }
    });
    return filePresenters;
}

- (id)initWithFilePresenter:(id<NSFilePresenter>)filePresenterOrNil
{
    self = [super initWithFilePresenter:filePresenterOrNil];
    if (!self)
        return nil;
    _filePresenterToIgnore = filePresenterOrNil;
    return self;
}

- (void)coordinateReadingItemAtURL:(NSURL *)url options:(NSFileCoordinatorReadingOptions)options error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *))reader
{
    dispatch_sync(_fileCoordinationDispatchQueue, ^{
        @try {
            NSMutableArray *affectedFilePresenters = [[NSMutableArray alloc] init];
            for (id<NSFilePresenter>filePresenter in _filePresenters)
            {
                if (filePresenter == _filePresenterToIgnore || ![filePresenter respondsToSelector:@selector(relinquishPresentedItemToReader:)])
                    continue;
                NSURL *filePresenterURL = filePresenter.presentedItemURL;
                if (![[filePresenterURL absoluteString] isEqualToString:[url absoluteString]])
                    continue;
                [affectedFilePresenters addObject:filePresenter];
            }
            NSMutableArray *reaquirers = [[NSMutableArray alloc] init];
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter relinquishPresentedItemToReader:^(void(^reaquirer)(void)) {
                        if (reaquirer)
                            [reaquirers addObject:reaquirer];
                    }];
                }]] waitUntilFinished:YES];
            reader(url);
            for (void(^reaquirer)(void) in reaquirers)
                reaquirer();
        }
        @catch (NSException *exception) {
            ECASSERT(NO);
        }
    });
}

- (void)coordinateWritingItemAtURL:(NSURL *)url options:(NSFileCoordinatorWritingOptions)options error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *))writer
{
    UNIMPLEMENTED_VOID();
}

- (void)coordinateReadingItemAtURL:(NSURL *)readingURL options:(NSFileCoordinatorReadingOptions)readingOptions writingItemAtURL:(NSURL *)writingURL options:(NSFileCoordinatorWritingOptions)writingOptions error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *, NSURL *))readerWriter
{
    UNIMPLEMENTED_VOID();
}

- (void)coordinateWritingItemAtURL:(NSURL *)url1 options:(NSFileCoordinatorWritingOptions)options1 writingItemAtURL:(NSURL *)url2 options:(NSFileCoordinatorWritingOptions)options2 error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *, NSURL *))writer
{
    UNIMPLEMENTED_VOID();
}

- (void)prepareForReadingItemsAtURLs:(NSArray *)readingURLs options:(NSFileCoordinatorReadingOptions)readingOptions writingItemsAtURLs:(NSArray *)writingURLs options:(NSFileCoordinatorWritingOptions)writingOptions error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(void (^)(void)))batchAccessor
{
    UNIMPLEMENTED_VOID();
}

- (void)itemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    UNIMPLEMENTED_VOID();
}

- (void)cancel
{
    UNIMPLEMENTED_VOID();
}

@end
