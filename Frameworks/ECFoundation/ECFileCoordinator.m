//
//  ECFileCoordinator.m
//  ECFoundation
//
//  Created by Uri Baghin on 12/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECFileCoordinator.h"

static dispatch_queue_t _fileCoordinationDispatchQueue;
static dispatch_queue_t _filePresentersDispatchQueue;
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
    _fileCoordinationDispatchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    _filePresentersDispatchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    _filePresenters = [[NSMutableArray alloc] init];
}

+ (void)addFilePresenter:(id<NSFilePresenter>)filePresenter
{
    dispatch_barrier_async(_filePresentersDispatchQueue, ^{
        ECASSERT([filePresenter conformsToProtocol:@protocol(NSFilePresenter)]);
        [_filePresenters addObject:filePresenter];
    });
}

+ (void)removeFilePresenter:(id<NSFilePresenter>)filePresenter
{
    dispatch_barrier_sync(_filePresentersDispatchQueue, ^{
        ECASSERT([_filePresenters containsObject:filePresenter]);
        [_filePresenters removeObject:filePresenter];
    });
}

+ (NSArray *)filePresenters
{
    __block NSArray *filePresenters = nil;
    dispatch_barrier_sync(_filePresentersDispatchQueue, ^{
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
        NSMutableDictionary *reaquirers = [[NSMutableDictionary alloc] init];
        for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
        {
            if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL])
                continue;
            NSURL *filePresenterURL = filePresenter.presentedItemURL;
            if (![[filePresenterURL absoluteString] isEqualToString:[url absoluteString]])
                continue;
            [affectedFilePresenters addObject:filePresenter];
            if ([filePresenter respondsToSelector:@selector(relinquishPresentedItemToReader:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter relinquishPresentedItemToReader:^(void(^reaquirer)(void)) {
                        if (reaquirer)
                            [reaquirers setObject:filePresenter forKey:reaquirer];
                    }];
                }]] waitUntilFinished:YES];
        }
        if (!(options & NSFileCoordinatorReadingWithoutChanges))
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        reader(url);
        [reaquirers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [[obj presentedItemOperationQueue] addOperations:[NSArray arrayWithObject:key] waitUntilFinished:YES];
        }];
    });
}

- (void)coordinateWritingItemAtURL:(NSURL *)url options:(NSFileCoordinatorWritingOptions)options error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *))writer
{
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    dispatch_sync(_fileCoordinationDispatchQueue, ^{
        NSMutableArray *affectedFilePresenters = [[NSMutableArray alloc] init];
        NSMutableArray *affectedSubitemPresenters = [[NSMutableArray alloc] init];
        NSMutableArray *affectedAncestorDirectoryPresenters = [[NSMutableArray alloc] init];
        NSMutableDictionary *reaquirers = [[NSMutableDictionary alloc] init];
        for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
        {
            if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL])
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
            if ([filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter relinquishPresentedItemToWriter:^(void(^reaquirer)(void)) {
                        if (reaquirer)
                            [reaquirers setObject:filePresenter forKey:reaquirer];
                    }];
                }]] waitUntilFinished:YES];
        }
        if (options & (NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedSubitemPresenters)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        }
        else if (options & (NSFileCoordinatorWritingForReplacing | NSFileCoordinatorWritingForDeleting))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedSubitemPresenters)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedSubitemDeletionAtURL:completionHandler:)])
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
                if ([filePresenter respondsToSelector:@selector(presentedItemDidChange)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter presentedItemDidChange];
                    }]] waitUntilFinished:YES];
            if (fileExisted)
            {
                for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters)
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidChangeAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                            [filePresenter presentedSubitemDidChangeAtURL:url];
                        }]] waitUntilFinished:YES];
            }
            else
            {
                for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters)
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidAppearAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                            [filePresenter presentedSubitemDidAppearAtURL:url];
                        }]] waitUntilFinished:YES];
            }
        }
        [reaquirers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [[obj presentedItemOperationQueue] addOperations:[NSArray arrayWithObject:key] waitUntilFinished:YES];
        }];
    });
}

- (void)coordinateReadingItemAtURL:(NSURL *)readingURL options:(NSFileCoordinatorReadingOptions)readingOptions writingItemAtURL:(NSURL *)writingURL options:(NSFileCoordinatorWritingOptions)writingOptions error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *, NSURL *))readerWriter
{
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    dispatch_sync(_fileCoordinationDispatchQueue, ^{
        NSMutableArray *affectedReadingFilePresenters = [[NSMutableArray alloc] init];
        NSMutableDictionary *readingReaquirers = [[NSMutableDictionary alloc] init];
        for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
        {
            if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL])
                continue;
            NSURL *filePresenterURL = filePresenter.presentedItemURL;
            if (![[filePresenterURL absoluteString] isEqualToString:[readingURL absoluteString]])
                continue;
            [affectedReadingFilePresenters addObject:filePresenter];
            if ([filePresenter respondsToSelector:@selector(relinquishPresentedItemToReader:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter relinquishPresentedItemToReader:^(void(^reaquirer)(void)) {
                        if (reaquirer)
                            [readingReaquirers setObject:filePresenter forKey:reaquirer];
                    }];
                }]] waitUntilFinished:YES];
        }
        if (!(readingOptions & NSFileCoordinatorReadingWithoutChanges))
            for (id<NSFilePresenter>filePresenter in affectedReadingFilePresenters)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        NSMutableArray *affectedWritingFilePresenters = [[NSMutableArray alloc] init];
        NSMutableArray *affectedWritingSubitemPresenters = [[NSMutableArray alloc] init];
        NSMutableArray *affectedWritingAncestorDirectoryPresenters = [[NSMutableArray alloc] init];
        NSMutableDictionary *writingReaquirers = [[NSMutableDictionary alloc] init];
        for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
        {
            if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL])
                continue;
            NSURL *filePresenterURL = filePresenter.presentedItemURL;
            if ([[filePresenterURL absoluteString] isEqualToString:[writingURL absoluteString]])
                [affectedWritingFilePresenters addObject:filePresenter];
            else if ([[writingURL absoluteString] hasPrefix:[filePresenterURL absoluteString]])
                [affectedWritingAncestorDirectoryPresenters addObject:filePresenter];
            else if (writingOptions & (NSFileCoordinatorWritingForDeleting | NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForReplacing) && [[filePresenterURL absoluteString] hasPrefix:[writingURL absoluteString]])
                [affectedWritingSubitemPresenters addObject:filePresenter];
            else
                continue;
            if ([filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter relinquishPresentedItemToWriter:^(void(^reaquirer)(void)) {
                        if (reaquirer)
                            [writingReaquirers setObject:filePresenter forKey:reaquirer];
                    }];
                }]] waitUntilFinished:YES];
        }
        if (writingOptions & (NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving))
        {
            for (id<NSFilePresenter>filePresenter in affectedWritingFilePresenters)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedWritingSubitemPresenters)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedWritingAncestorDirectoryPresenters)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        }
        else if (writingOptions & (NSFileCoordinatorWritingForReplacing | NSFileCoordinatorWritingForDeleting))
        {
            for (id<NSFilePresenter>filePresenter in affectedWritingFilePresenters)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedWritingSubitemPresenters)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedWritingAncestorDirectoryPresenters)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedSubitemDeletionAtURL:completionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedSubitemDeletionAtURL:writingURL completionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        }
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        BOOL fileExisted = [fileManager fileExistsAtPath:[writingURL path]];
        readerWriter(readingURL, writingURL);
        if (!(writingOptions & (NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForDeleting)))
        {
            for (id<NSFilePresenter>filePresenter in affectedWritingFilePresenters)
                if ([filePresenter respondsToSelector:@selector(presentedItemDidChange)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter presentedItemDidChange];
                    }]] waitUntilFinished:YES];
            if (fileExisted)
            {
                for (id<NSFilePresenter>filePresenter in affectedWritingAncestorDirectoryPresenters)
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidChangeAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                            [filePresenter presentedSubitemDidChangeAtURL:writingURL];
                        }]] waitUntilFinished:YES];
            }
            else
            {
                for (id<NSFilePresenter>filePresenter in affectedWritingAncestorDirectoryPresenters)
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidAppearAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                            [filePresenter presentedSubitemDidAppearAtURL:writingURL];
                        }]] waitUntilFinished:YES];
            }
        }
        [writingReaquirers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [[obj presentedItemOperationQueue] addOperations:[NSArray arrayWithObject:key] waitUntilFinished:YES];
        }];
        [readingReaquirers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [[obj presentedItemOperationQueue] addOperations:[NSArray arrayWithObject:key] waitUntilFinished:YES];
        }];
    });
    
}

- (void)coordinateWritingItemAtURL:(NSURL *)url1 options:(NSFileCoordinatorWritingOptions)options1 writingItemAtURL:(NSURL *)url2 options:(NSFileCoordinatorWritingOptions)options2 error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(NSURL *, NSURL *))writer
{
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    dispatch_sync(_fileCoordinationDispatchQueue, ^{
        NSMutableArray *affectedFilePresenters1 = [[NSMutableArray alloc] init];
        NSMutableArray *affectedSubitemPresenters1 = [[NSMutableArray alloc] init];
        NSMutableArray *affectedAncestorDirectoryPresenters1 = [[NSMutableArray alloc] init];
        NSMutableDictionary *reaquirers1 = [[NSMutableDictionary alloc] init];
        for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
        {
            if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL])
                continue;
            NSURL *filePresenterURL = filePresenter.presentedItemURL;
            if ([[filePresenterURL absoluteString] isEqualToString:[url1 absoluteString]])
                [affectedFilePresenters1 addObject:filePresenter];
            else if ([[url1 absoluteString] hasPrefix:[filePresenterURL absoluteString]])
                [affectedAncestorDirectoryPresenters1 addObject:filePresenter];
            else if (options1 & (NSFileCoordinatorWritingForDeleting | NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForReplacing) && [[filePresenterURL absoluteString] hasPrefix:[url1 absoluteString]])
                [affectedSubitemPresenters1 addObject:filePresenter];
            else
                continue;
            if ([filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter relinquishPresentedItemToWriter:^(void(^reaquirer)(void)) {
                        if (reaquirer)
                            [reaquirers1 setObject:filePresenter forKey:reaquirer];
                    }];
                }]] waitUntilFinished:YES];
        }
        if (options1 & (NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters1)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedSubitemPresenters1)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters1)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        }
        else if (options1 & (NSFileCoordinatorWritingForReplacing | NSFileCoordinatorWritingForDeleting))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters1)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedSubitemPresenters1)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters1)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedSubitemDeletionAtURL:completionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedSubitemDeletionAtURL:url1 completionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        }
        NSMutableArray *affectedFilePresenters2 = [[NSMutableArray alloc] init];
        NSMutableArray *affectedSubitemPresenters2 = [[NSMutableArray alloc] init];
        NSMutableArray *affectedAncestorDirectoryPresenters2 = [[NSMutableArray alloc] init];
        NSMutableDictionary *reaquirers2 = [[NSMutableDictionary alloc] init];
        for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
        {
            if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL])
                continue;
            NSURL *filePresenterURL = filePresenter.presentedItemURL;
            if ([[filePresenterURL absoluteString] isEqualToString:[url2 absoluteString]])
                [affectedFilePresenters2 addObject:filePresenter];
            else if ([[url2 absoluteString] hasPrefix:[filePresenterURL absoluteString]])
                [affectedAncestorDirectoryPresenters2 addObject:filePresenter];
            else if (options2 & (NSFileCoordinatorWritingForDeleting | NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForReplacing) && [[filePresenterURL absoluteString] hasPrefix:[url2 absoluteString]])
                [affectedSubitemPresenters2 addObject:filePresenter];
            else
                continue;
            if ([filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter relinquishPresentedItemToWriter:^(void(^reaquirer)(void)) {
                        if (reaquirer)
                            [reaquirers2 setObject:filePresenter forKey:reaquirer];
                    }];
                }]] waitUntilFinished:YES];
        }
        if (options2 & (NSFileCoordinatorWritingForMerging | NSFileCoordinatorWritingForMoving))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters2)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedSubitemPresenters2)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters2)
                if ([filePresenter respondsToSelector:@selector(savePresentedItemChangesWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        }
        else if (options2 & (NSFileCoordinatorWritingForReplacing | NSFileCoordinatorWritingForDeleting))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters2)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedSubitemPresenters2)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedItemDeletionWithCompletionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedItemDeletionWithCompletionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
            for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters2)
                if ([filePresenter respondsToSelector:@selector(accommodatePresentedSubitemDeletionAtURL:completionHandler:)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter accommodatePresentedSubitemDeletionAtURL:url2 completionHandler:^(NSError *errorOrNil) {
                            ECASSERT(!errorOrNil); // TODO: forward error
                        }];
                    }]] waitUntilFinished:YES];
        }
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        BOOL fileExisted1 = [fileManager fileExistsAtPath:[url1 path]];
        BOOL fileExisted2 = [fileManager fileExistsAtPath:[url2 path]];
        writer(url1, url2);
        if (!(options2 & (NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForDeleting)))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters2)
                if ([filePresenter respondsToSelector:@selector(presentedItemDidChange)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter presentedItemDidChange];
                    }]] waitUntilFinished:YES];
            if (fileExisted2)
            {
                for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters2)
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidChangeAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                            [filePresenter presentedSubitemDidChangeAtURL:url2];
                        }]] waitUntilFinished:YES];
            }
            else
            {
                for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters2)
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidAppearAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                            [filePresenter presentedSubitemDidAppearAtURL:url2];
                        }]] waitUntilFinished:YES];
            }
        }
        if (!(options1 & (NSFileCoordinatorWritingForMoving | NSFileCoordinatorWritingForDeleting)))
        {
            for (id<NSFilePresenter>filePresenter in affectedFilePresenters1)
                if ([filePresenter respondsToSelector:@selector(presentedItemDidChange)])
                    [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                        [filePresenter presentedItemDidChange];
                    }]] waitUntilFinished:YES];
            if (fileExisted1)
            {
                for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters1)
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidChangeAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                            [filePresenter presentedSubitemDidChangeAtURL:url1];
                        }]] waitUntilFinished:YES];
            }
            else
            {
                for (id<NSFilePresenter>filePresenter in affectedAncestorDirectoryPresenters1)
                    if ([filePresenter respondsToSelector:@selector(presentedSubitemDidAppearAtURL:)])
                        [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                            [filePresenter presentedSubitemDidAppearAtURL:url1];
                        }]] waitUntilFinished:YES];
            }
        }
        [reaquirers2 enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [[obj presentedItemOperationQueue] addOperations:[NSArray arrayWithObject:key] waitUntilFinished:YES];
        }];
        [reaquirers1 enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [[obj presentedItemOperationQueue] addOperations:[NSArray arrayWithObject:key] waitUntilFinished:YES];
        }];
    });
}

- (void)prepareForReadingItemsAtURLs:(NSArray *)readingURLs options:(NSFileCoordinatorReadingOptions)readingOptions writingItemsAtURLs:(NSArray *)writingURLs options:(NSFileCoordinatorWritingOptions)writingOptions error:(NSError *__autoreleasing *)outError byAccessor:(void (^)(void (^)(void)))batchAccessor
{
    ECASSERT(dispatch_get_current_queue() != _fileCoordinationDispatchQueue);
    UNIMPLEMENTED_VOID();
}

- (void)itemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    ECASSERT(dispatch_get_current_queue() == _fileCoordinationDispatchQueue);
    for (id<NSFilePresenter>filePresenter in [[self class] filePresenters])
    {
        if (filePresenter == _filePresenterToIgnore || ![filePresenter presentedItemURL] || ![filePresenter respondsToSelector:@selector(relinquishPresentedItemToWriter:)])
            continue;
        NSURL *filePresenterURL = filePresenter.presentedItemURL;
        if ([[filePresenterURL absoluteString] isEqualToString:[oldURL absoluteString]])
        {
            if ([filePresenter respondsToSelector:@selector(presentedItemDidMoveToURL:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter presentedItemDidMoveToURL:newURL];
                }]] waitUntilFinished:YES];
        }
        else if ([[oldURL absoluteString] hasPrefix:[filePresenterURL absoluteString]])
        {
            if ([filePresenter respondsToSelector:@selector(presentedSubitemAtURL:didMoveToURL:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    [filePresenter presentedSubitemAtURL:oldURL didMoveToURL:newURL];
                }]] waitUntilFinished:YES];
        }
        else if ([[filePresenterURL absoluteString] hasPrefix:[oldURL absoluteString]])
        {
            if ([filePresenter respondsToSelector:@selector(presentedItemDidMoveToURL:)])
                [filePresenter.presentedItemOperationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                    NSString *subitemPath = [[filePresenterURL absoluteString] substringFromIndex:[[oldURL absoluteString] length]];
                    [filePresenter presentedItemDidMoveToURL:[newURL URLByAppendingPathComponent:subitemPath]];
                }]] waitUntilFinished:YES];
        }
    }
}

- (void)cancel
{
    UNIMPLEMENTED_VOID();
}

@end
