//
//  DirectoryTableViewDataSource.m
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DirectoryPresenter.h"
#import "NSOperationQueue+BlockWait.h"
#import "NSTimer+BlockTimer.h"
#import "NSURL+Compare.h"
#import <objc/runtime.h>

@interface DirectoryPresenter () <NSFilePresenter>
{
    NSOperationQueue *_homeQueue;
    NSMutableArray *_mutableFileURLs;
    NSOperationQueue *_internalAccessQueue;
    __weak NSTimer *_updateCoalescingTimer;
}
@property (atomic, strong) NSURL *directoryURL;
- (void)_updateFileURLs;
@end

@implementation DirectoryPresenter

@synthesize directoryURL = _directoryURL, options = _options;

#pragma mark - General methods

- (NSArray *)fileURLs
{
    __block NSArray *fileURLs = nil;
    if ([NSOperationQueue currentQueue] == _internalAccessQueue)
    {
        fileURLs = [_mutableFileURLs copy];
    }
    else
    {
        __weak DirectoryPresenter *weakSelf = self;
        [_internalAccessQueue addOperationWithBlockWaitUntilFinished:^{
            __strong DirectoryPresenter *safeWeakSelf = weakSelf;
            if (safeWeakSelf)
                fileURLs = [safeWeakSelf->_mutableFileURLs copy];
        }];
    }
    return fileURLs;
}

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options
{
    ECASSERT(directoryURL);
    self = [super init];
    if (!self)
        return nil;
    _directoryURL = [directoryURL standardizedURL];
    _options = options;
    _internalAccessQueue = [[NSOperationQueue alloc] init];
    _internalAccessQueue.maxConcurrentOperationCount = 1;
    _homeQueue = [NSOperationQueue currentQueue];
    _mutableFileURLs = [[NSMutableArray alloc] init];
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:_directoryURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
        [NSFileCoordinator addFilePresenter:self];
    }];
    [_internalAccessQueue addOperationWithBlockWaitUntilFinished:^{
        [[NSRunLoop currentRunLoop] run];
    }];
    __weak DirectoryPresenter *weakSelf = self;
    [_internalAccessQueue addOperationWithBlock:^{
        __strong DirectoryPresenter *safeWeakSelf = weakSelf;
        if (safeWeakSelf)
            safeWeakSelf->_updateCoalescingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 usingBlock:^(NSTimer *timer) {
                [safeWeakSelf _updateFileURLs];
            } repeats:NO];
    }];
    return self;
}

- (void)dealloc
{
    [NSFileCoordinator removeFilePresenter:self];
}

#pragma mark - Private methods

- (void)_updateFileURLs
{
    ECASSERT([NSOperationQueue currentQueue] == _internalAccessQueue);
    
    NSMutableIndexSet *indexesOfInsertedFileURLs = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *indexesOfRemovedFileURLs = [[NSMutableIndexSet alloc] init];
    NSMutableArray *newFileURLs = [[NSMutableArray alloc] init];
    NSURL *directoryURL = self.directoryURL;
    NSDirectoryEnumerationOptions options = self.options;
    if (directoryURL)
        [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:directoryURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
            for (NSURL *fileURL in [[[NSFileManager alloc] init] enumeratorAtURL:newURL includingPropertiesForKeys:nil options:options errorHandler:nil])
                [newFileURLs addObject:fileURL];
        }];
    
    NSUInteger count = [_mutableFileURLs count], newCount = [newFileURLs count];
    for (NSUInteger index = 0, newIndex = 0; index < count && newIndex < newCount;)
    {
        NSComparisonResult result = [[_mutableFileURLs objectAtIndex:index] compare:[newFileURLs objectAtIndex:newIndex]];
        if (result == NSOrderedAscending)
        {
            [indexesOfRemovedFileURLs addIndex:index];
            ++index;
        }
        else if (result == NSOrderedDescending)
        {
            [indexesOfInsertedFileURLs addIndex:newIndex];
            ++newIndex;
        }
        else
        {
            ++index;
            ++newIndex;
        }
    }
    indexesOfInsertedFileURLs = [indexesOfInsertedFileURLs copy];
    indexesOfRemovedFileURLs = [indexesOfRemovedFileURLs copy];
    __weak DirectoryPresenter *weakSelf = self;
    [_homeQueue addOperationWithBlockWaitUntilFinished:^{
        [weakSelf willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexesOfRemovedFileURLs forKey:@"fileURLs"];
    }];
    [_mutableFileURLs removeObjectsAtIndexes:indexesOfRemovedFileURLs];
    [_homeQueue addOperationWithBlockWaitUntilFinished:^{
        [weakSelf didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexesOfRemovedFileURLs forKey:@"fileURLs"];
        [weakSelf willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexesOfInsertedFileURLs forKey:@"fileURLs"];
    }];
    _mutableFileURLs = newFileURLs;
    [_homeQueue addOperationWithBlockWaitUntilFinished:^{
        [weakSelf didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexesOfInsertedFileURLs forKey:@"fileURLs"];
    }];
}

#pragma mark - NSFilePresenter protocol

- (NSURL *)presentedItemURL
{
    return self.directoryURL;
}

+ (NSSet *)keyPathsForValuesAffectingPresentedItemURL
{
    return [NSSet setWithObject:@"directoryURL"];
}

- (NSOperationQueue *)presentedItemOperationQueue
{
    return _internalAccessQueue;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == _internalAccessQueue);
    self.directoryURL = nil;
    [self _updateFileURLs];
    completionHandler(nil);
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    ECASSERT([NSOperationQueue currentQueue] == _internalAccessQueue);
    self.directoryURL = newURL;
}

- (void)presentedItemDidChange
{
    ECASSERT([NSOperationQueue currentQueue] == _internalAccessQueue);
    if (_updateCoalescingTimer)
        [_updateCoalescingTimer invalidate];
    _updateCoalescingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 usingBlock:^(NSTimer *timer) {
        [self _updateFileURLs];
    } repeats:NO];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    __block NSUInteger count = 0;
    if ([NSOperationQueue currentQueue] == _internalAccessQueue)
    {
        count = [_mutableFileURLs countByEnumeratingWithState:state objects:buffer count:len];
    }
    else
    {
        __weak DirectoryPresenter *weakSelf = self;
        [_internalAccessQueue addOperationWithBlockWaitUntilFinished:^{
            __strong DirectoryPresenter *safeWeakSelf = weakSelf;
            if (safeWeakSelf)
                count = [safeWeakSelf->_mutableFileURLs countByEnumeratingWithState:state objects:buffer count:len];
        }];
    }
    return count;
}

@end
