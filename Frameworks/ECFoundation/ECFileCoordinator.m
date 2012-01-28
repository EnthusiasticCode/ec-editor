//
//  ECFileCoordinator.m
//  ECFoundation
//
//  Created by Uri Baghin on 12/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECFileCoordinator.h"
#import <ECFoundation/ECWeakArray.h>
#import "NSOperationQueue+ECAdditions.h"

static ECWeakArray *_filePresenters;
static dispatch_semaphore_t _fileCoordinationSemaphore;

@interface ECFileCoordinator ()
{
    id<NSFilePresenter>_filePresenterToIgnore;
}
- (void(^)(void))_prepareForReadingItemAtURL:(NSURL *)url options:(NSFileCoordinatorReadingOptions)options error:(NSError **)outError;
- (void(^)(void))_prepareForWritingItemAtURL:(NSURL *)url options:(NSFileCoordinatorWritingOptions)options error:(NSError **)outError;
@end

@implementation ECFileCoordinator

+ (void)initialize
{
    if (self != [ECFileCoordinator class])
        return;
    _filePresenters = [[ECWeakArray alloc] init];
    _fileCoordinationSemaphore = dispatch_semaphore_create(1);
}

+ (void)addFilePresenter:(id<NSFilePresenter>)filePresenter
{
    dispatch_semaphore_wait(_fileCoordinationSemaphore, DISPATCH_TIME_FOREVER);
    ECASSERT([filePresenter conformsToProtocol:@protocol(NSFilePresenter)]);
    [_filePresenters addObject:filePresenter];
    dispatch_semaphore_signal(_fileCoordinationSemaphore);
}

+ (void)removeFilePresenter:(id<NSFilePresenter>)filePresenter
{
    dispatch_semaphore_wait(_fileCoordinationSemaphore, DISPATCH_TIME_FOREVER);
    [_filePresenters removeObject:filePresenter];
    dispatch_semaphore_signal(_fileCoordinationSemaphore);
}

+ (NSArray *)filePresenters
{
    __block NSArray *filePresenters = nil;
    dispatch_semaphore_wait(_fileCoordinationSemaphore, DISPATCH_TIME_FOREVER);
    filePresenters = [_filePresenters copy];
    dispatch_semaphore_signal(_fileCoordinationSemaphore);
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
    void (^cleanup)(void) = [self _prepareForReadingItemAtURL:url options:options error:outError];
    reader(url);
    cleanup();
}

- (void)coordinateWritingItemAtURL:(NSURL *)url options:(NSFileCoordinatorWritingOptions)options error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *))writer
{
    void (^cleanup)(void) = [self _prepareForWritingItemAtURL:url options:options error:outError];
    writer(url);
    cleanup();
}

- (void)coordinateReadingItemAtURL:(NSURL *)readingURL options:(NSFileCoordinatorReadingOptions)readingOptions writingItemAtURL:(NSURL *)writingURL options:(NSFileCoordinatorWritingOptions)writingOptions error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *, NSURL *))readerWriter
{
    void (^cleanup1)(void) = [self _prepareForReadingItemAtURL:readingURL options:readingOptions error:outError];
    void (^cleanup2)(void) = [self _prepareForWritingItemAtURL:writingURL options:readingOptions error:outError];
    readerWriter(readingURL, writingURL);
    cleanup2();
    cleanup1();
}

- (void)coordinateWritingItemAtURL:(NSURL *)url1 options:(NSFileCoordinatorWritingOptions)options1 writingItemAtURL:(NSURL *)url2 options:(NSFileCoordinatorWritingOptions)options2 error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *, NSURL *))writer
{
    void (^cleanup1)(void) = [self _prepareForReadingItemAtURL:url1 options:options1 error:outError];
    void (^cleanup2)(void) = [self _prepareForWritingItemAtURL:url2 options:options2 error:outError];
    writer(url1, url2);
    cleanup2();
    cleanup1();
}

- (void)prepareForReadingItemsAtURLs:(NSArray *)readingURLs options:(NSFileCoordinatorReadingOptions)readingOptions writingItemsAtURLs:(NSArray *)writingURLs options:(NSFileCoordinatorWritingOptions)writingOptions error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(void (^)(void)))batchAccessor
{
    
}

- (void)itemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
    {
        if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL] || ![filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
            continue;
        NSURL *filePresenterURL = filePresenter.presentedItemURL;
        if ([[filePresenterURL absoluteString] isEqualToString:[oldURL absoluteString]])
        {
            if ([filePresenter respondsToSelector:@selector(presentedItemDidMoveToURL:)])
                [filePresenter.presentedItemOperationQueue addOperationWithBlockWaitUntilFinished:^{
                    [filePresenter presentedItemDidMoveToURL:newURL];
                }];
        }
        else if ([[oldURL absoluteString] hasPrefix:[filePresenterURL absoluteString]])
        {
            if ([filePresenter respondsToSelector:@selector(presentedSubitemAtURL:didMoveToURL:)])
                [filePresenter.presentedItemOperationQueue addOperationWithBlockWaitUntilFinished:^{
                    [filePresenter presentedSubitemAtURL:oldURL didMoveToURL:newURL];
                }];
        }
        else if ([[filePresenterURL absoluteString] hasPrefix:[oldURL absoluteString]])
        {
            if ([filePresenter respondsToSelector:@selector(presentedItemDidMoveToURL:)])
                [filePresenter.presentedItemOperationQueue addOperationWithBlockWaitUntilFinished:^{
                    NSString *subitemPath = [[filePresenterURL absoluteString] substringFromIndex:[[oldURL absoluteString] length]];
                    [filePresenter presentedItemDidMoveToURL:[newURL URLByAppendingPathComponent:subitemPath]];
                }];
        }
    }
}

- (void)cancel
{
    UNIMPLEMENTED_VOID();
}

#pragma mark - Private methods

- (void (^)(void))_prepareForReadingItemAtURL:(NSURL *)url options:(NSFileCoordinatorReadingOptions)options error:(NSError *__autoreleasing *)outError
{
    NSIndexSet *affectedFilePresenterIndexes = [[[self class] filePresenters] indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return obj != _filePresenterToIgnore && [[[obj presentedItemURL] absoluteString] isEqualToString:[url absoluteString]];
    }];
    NSArray *affectedFilePresenters = [[[self class] filePresenters] objectsAtIndexes:affectedFilePresenterIndexes];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSMutableDictionary *reaquirers = [[NSMutableDictionary alloc] init];
    for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
        if ([filePresenter respondsToSelector:@selector(relinquishPresentedItemToReader:)])
        {
            [filePresenter.presentedItemOperationQueue addOperationWithBlock:^{
                [filePresenter relinquishPresentedItemToReader:^(void(^reaquirer)(void)) {
                    if (reaquirer)
                        [reaquirers setObject:filePresenter forKey:reaquirer];
                    dispatch_semaphore_signal(semaphore);
                }];
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    if (!(options & NSFileCoordinatorReadingWithoutChanges))
        for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
            if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
            {
                [filePresenter.presentedItemOperationQueue addOperationWithBlock:^{
                    [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                        dispatch_semaphore_signal(semaphore);
                    }];
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
    dispatch_release(semaphore);
    return ^{
        [reaquirers enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id key, id obj, BOOL *stop) {
            [[obj presentedItemOperationQueue] addOperations:[NSArray arrayWithObject:key] waitUntilFinished:YES];
        }];
    };
}

- (void (^)(void))_prepareForWritingItemAtURL:(NSURL *)url options:(NSFileCoordinatorWritingOptions)options error:(NSError *__autoreleasing *)outError
{
    NSMutableArray *affectedFilePresenters = [[NSMutableArray alloc] init];
    NSMutableArray *filePresenters = [[NSMutableArray alloc] init];
    NSMutableArray *parentDirectoryPresenters = [[NSMutableArray alloc] init];
    NSMutableArray *subitemPresenters = [[NSMutableArray alloc] init];
    NSMutableDictionary *reaquirers = [[NSMutableDictionary alloc] init];
    
    for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
    {
        if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL])
            continue;
        NSURL *filePresenterURL = filePresenter.presentedItemURL;
        if ([[filePresenterURL absoluteString] isEqualToString:[url absoluteString]])
            [filePresenters addObject:filePresenter];
        else if ([[url absoluteString] hasPrefix:[filePresenterURL absoluteString]])
            [parentDirectoryPresenters addObject:filePresenter];
        else if (options & (NSFileCoordinatorWritingForDeleting | NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForReplacing) && [[filePresenterURL absoluteString] hasPrefix:[url absoluteString]])
            [subitemPresenters addObject:filePresenter];
        else
            continue;
        [affectedFilePresenters addObject:filePresenter];
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
        if ([filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
        {
            [filePresenter.presentedItemOperationQueue addOperationWithBlock:^{
                [filePresenter relinquishPresentedItemToWriter:^(void(^reaquirer)(void)) {
                    if (reaquirer)
                        [reaquirers setObject:filePresenter forKey:reaquirer];
                    dispatch_semaphore_signal(semaphore);
                }];
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    if (options & (NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving))
    {
        for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
            if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
            {
                [filePresenter.presentedItemOperationQueue addOperationWithBlock:^{
                    [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                        dispatch_semaphore_signal(semaphore);
                    }];
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
    }
    else if (options & (NSFileCoordinatorWritingForReplacing | NSFileCoordinatorWritingForDeleting))
    {
        for (id<NSFilePresenter>filePresenter in filePresenters)
            if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
            {
                [filePresenter.presentedItemOperationQueue addOperationWithBlock:^{
                    [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                        dispatch_semaphore_signal(semaphore);
                    }];
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        for (id<NSFilePresenter>filePresenter in parentDirectoryPresenters)
            if ([filePresenter respondsToSelector:@selector(accommodatePresentedSubitemDeletionAtURL:completionHandler:)])
            {
                [filePresenter.presentedItemOperationQueue addOperationWithBlock:^{
                    [filePresenter accommodatePresentedSubitemDeletionAtURL:url completionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                        dispatch_semaphore_signal(semaphore);
                    }];
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        for (id<NSFilePresenter>filePresenter in subitemPresenters)
            if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
            {
                [filePresenter.presentedItemOperationQueue addOperationWithBlock:^{
                    [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                        dispatch_semaphore_signal(semaphore);
                    }];
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
    }
    
    dispatch_release(semaphore);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL fileExisted = [fileManager fileExistsAtPath:[url path]];
    
    return ^{
        if (!(options & (NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForDeleting)))
            [filePresenters enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id<NSFilePresenter>filePresenter, NSUInteger idx, BOOL *stop) {
                if ([filePresenter respondsToSelector:@selector(presentedItemDidChange)])
                    [filePresenter.presentedItemOperationQueue addOperationWithBlockWaitUntilFinished:^{
                        [filePresenter presentedItemDidChange];
                    }];
            }];
        if (!(options & NSFileCoordinatorWritingForDeleting))
        {
            if (fileExisted)
                [parentDirectoryPresenters enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id<NSFilePresenter>filePresenter, NSUInteger idx, BOOL *stop) {
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidChangeAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperationWithBlockWaitUntilFinished:^{
                            [filePresenter presentedSubitemDidChangeAtURL:url];
                        }];
                }];
            else
                [parentDirectoryPresenters enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id<NSFilePresenter>filePresenter, NSUInteger idx, BOOL *stop) {
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidAppearAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperationWithBlockWaitUntilFinished:^{
                            [filePresenter presentedSubitemDidAppearAtURL:url];
                        }];
                }];
        }
        [reaquirers enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id key, id obj, BOOL *stop) {
            [[obj presentedItemOperationQueue] addOperations:[NSArray arrayWithObject:key] waitUntilFinished:YES];
        }];
    };
}

@end
