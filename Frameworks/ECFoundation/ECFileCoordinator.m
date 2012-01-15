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
    if (self != [ECFileCoordinator class])
        return;
    _fileCoordinationDispatchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    _filePresenters = [[NSMutableArray alloc] init];
}

+ (void)addFilePresenter:(id<NSFilePresenter>)filePresenter
{
    dispatch_barrier_async(_fileCoordinationDispatchQueue, ^{
        ECASSERT([filePresenter conformsToProtocol:@protocol(NSFilePresenter)]);
        [_filePresenters addObject:filePresenter];
    });
}

+ (void)removeFilePresenter:(id<NSFilePresenter>)filePresenter
{
    dispatch_barrier_sync(_fileCoordinationDispatchQueue, ^{
        ECASSERT([_filePresenters containsObject:filePresenter]);
        [_filePresenters removeObject:filePresenter];
    });
}

+ (NSArray *)filePresenters
{
    __block NSArray *filePresenters = nil;
    dispatch_barrier_sync(_fileCoordinationDispatchQueue, ^{
        filePresenters = [_filePresenters copy];
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
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    dispatch_sync(_fileCoordinationDispatchQueue, ^{
        NSMutableArray *affectedFilePresenters = [[NSMutableArray alloc] init];
        NSMutableArray *reaquirers = [[NSMutableArray alloc] init];
        for (id<NSFilePresenter>filePresenter in _filePresenters)
        {
            if (filePresenter == _filePresenterToIgnore || ![filePresenter respondsToSelector:@selector(relinquishPresentedItemToReader:)])
                continue;
            NSURL *filePresenterURL = filePresenter.presentedItemURL;
            if (![[filePresenterURL absoluteString] isEqualToString:[url absoluteString]])
                continue;
            [affectedFilePresenters addObject:filePresenter];
            [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                [filePresenter relinquishPresentedItemToReader:^(void(^reaquirer)(void)) {
                    if (reaquirer)
                        [reaquirers addObject:reaquirer];
                }];
            }]] waitUntilFinished:YES];
        }
        if (!(options & NSFileCoordinatorReadingWithoutChanges))
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                    }];
                }]] waitUntilFinished:YES];
        reader(url);
        for (void(^reaquirer)(void) in reaquirers)
            reaquirer();
    });
}

- (void)coordinateWritingItemAtURL:(NSURL *)url options:(NSFileCoordinatorWritingOptions)options error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *))writer
{
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    dispatch_barrier_sync(_fileCoordinationDispatchQueue, ^{
        NSMutableArray *affectedFilePresenters = [[NSMutableArray alloc] init];
        NSMutableArray *affectedSubitemPresenters = [[NSMutableArray alloc] init];
        NSMutableArray *affectedAncestorDirectoryPresenters = [[NSMutableArray alloc] init];
        NSMutableArray *reaquirers = [[NSMutableArray alloc] init];
        for (id<NSFilePresenter>filePresenter in _filePresenters)
        {
            if (filePresenter == _filePresenterToIgnore || ![filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
                continue;
            NSURL *filePresenterURL = filePresenter.presentedItemURL;
            if ([[filePresenterURL absoluteString] isEqualToString:[url absoluteString]])
                [affectedFilePresenters addObject:filePresenter];
            else if ([[url absoluteString] hasPrefix:[filePresenterURL absoluteString]])
                [affectedAncestorDirectoryPresenters addObject:filePresenter];
            else if (options & (NSFileCoordinatorWritingForDeleting | NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForReplacing) && [[filePresenterURL absoluteString] hasPrefix:[url absoluteString]])
                [affectedSubitemPresenters addObject:filePresenter];
            else
                continue;
            [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                [filePresenter relinquishPresentedItemToWriter:^(void(^reaquirer)(void)) {
                    if (reaquirer)
                        [reaquirers addObject:reaquirer];
                }];
            }]] waitUntilFinished:YES];
        }
        if (options & (NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                    }];
                }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedSubitemPresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                    }];
                }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                    }];
                }]] waitUntilFinished:YES];
        }
        else if (options & (NSFileCoordinatorWritingForReplacing | NSFileCoordinatorWritingForDeleting))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                    }];
                }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedSubitemPresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                    }];
                }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter accommodatePresentedSubitemDeletionAtURL:url completionHandler:^(NSError *errorOrNil) {
                        ECASSERT(!errorOrNil); // TODO: forward error
                    }];
                }]] waitUntilFinished:YES];
        }
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        BOOL fileExisted = [fileManager fileExistsAtPath:[url path]];
        writer(url);
        if (!(options & (NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForDeleting)))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter presentedItemDidChange];
                }]] waitUntilFinished:YES];
            if (fileExisted)
                for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters)
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter presentedSubitemDidChangeAtURL:url];
                    }]] waitUntilFinished:YES];
            else
                for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters)
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter presentedSubitemDidAppearAtURL:url];
                    }]] waitUntilFinished:YES];
        }
        for (void(^reaquirer)(void) in reaquirers)
            reaquirer();
    });
}

- (void)coordinateReadingItemAtURL:(NSURL *)readingURL options:(NSFileCoordinatorReadingOptions)readingOptions writingItemAtURL:(NSURL *)writingURL options:(NSFileCoordinatorWritingOptions)writingOptions error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *, NSURL *))readerWriter
{
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    UNIMPLEMENTED_VOID();
}

- (void)coordinateWritingItemAtURL:(NSURL *)url1 options:(NSFileCoordinatorWritingOptions)options1 writingItemAtURL:(NSURL *)url2 options:(NSFileCoordinatorWritingOptions)options2 error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *, NSURL *))writer
{
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    UNIMPLEMENTED_VOID();
}

- (void)prepareForReadingItemsAtURLs:(NSArray *)readingURLs options:(NSFileCoordinatorReadingOptions)readingOptions writingItemsAtURLs:(NSArray *)writingURLs options:(NSFileCoordinatorWritingOptions)writingOptions error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(void (^)(void)))batchAccessor
{
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    UNIMPLEMENTED_VOID();
}

- (void)itemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    ECASSERT(dispatch_get_current_queue() == _fileCoordinationDispatchQueue);
    for (id<NSFilePresenter>filePresenter in _filePresenters)
    {
        if (filePresenter == _filePresenterToIgnore || ![filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
            continue;
        NSURL *filePresenterURL = filePresenter.presentedItemURL;
        if ([[filePresenterURL absoluteString] isEqualToString:[oldURL absoluteString]])
            [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                [filePresenter presentedItemDidMoveToURL:newURL];
            }]] waitUntilFinished:YES];            
        else if ([[oldURL absoluteString] hasPrefix:[filePresenterURL absoluteString]])
            [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                [filePresenter presentedSubitemAtURL:oldURL didMoveToURL:newURL];
            }]] waitUntilFinished:YES];            
        else if ([[filePresenterURL absoluteString] hasPrefix:[oldURL absoluteString]])
            [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                NSString *subitemPath = [[filePresenterURL absoluteString] substringFromIndex:[[oldURL absoluteString] length]];
                [filePresenter presentedItemDidMoveToURL:[newURL URLByAppendingPathComponent:subitemPath]];
            }]] waitUntilFinished:YES];
    }
}

- (void)cancel
{
    UNIMPLEMENTED_VOID();
}

@end
