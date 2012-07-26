//
//  DirectoryTableViewDataSource.m
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DirectoryPresenter.h"
#import "NSTimer+BlockTimer.h"
#import "NSURL+Compare.h"

@interface DirectoryPresenter () {
  NSURL *_presentedItemURL;
  NSThread *_homeThread;
  NSMutableArray *_mutableFileURLs;
  NSOperationQueue *_internalAccessQueue;
  __weak NSTimer *_updateCoalescingTimer;
}
@property (atomic) NSURL *presentedItemURL;
- (void)_enqueueUpdate;
- (void)_updateFileURLs;
@end

@implementation DirectoryPresenter

@synthesize presentedItemURL = _presentedItemURL, options = _options;

#pragma mark - General methods

- (NSArray *)fileURLs
{
  return [_mutableFileURLs copy];
}

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options
{
  self = [super init];
  if (!self)
    return nil;
  _presentedItemURL = [directoryURL standardizedURL];
  _options = options;
  _internalAccessQueue = [[NSOperationQueue alloc] init];
  _internalAccessQueue.maxConcurrentOperationCount = 1;
  _homeThread = [NSThread currentThread];
  _mutableFileURLs = [[NSMutableArray alloc] init];
  if (_presentedItemURL) {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:_presentedItemURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
      [NSFileCoordinator addFilePresenter:self];
    }];
    [self _updateFileURLs];
  }
  return self;
}

- (void)dealloc
{
  [_updateCoalescingTimer invalidate];
  [NSFileCoordinator removeFilePresenter:self];
}

#pragma mark - Private methods

- (void)_enqueueUpdate
{
  [_updateCoalescingTimer invalidate];
  _updateCoalescingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 usingBlock:^(NSTimer *timer) {
    [self _updateFileURLs];
  } repeats:NO];
}

- (void)_updateFileURLs
{
  NSMutableIndexSet *indexesOfInsertedFileURLs = [[NSMutableIndexSet alloc] init];
  NSMutableIndexSet *indexesOfRemovedFileURLs = [[NSMutableIndexSet alloc] init];
  NSMutableArray *newFileURLs = [[NSMutableArray alloc] init];
  NSURL *directoryURL = self.presentedItemURL;
  NSDirectoryEnumerationOptions options = self.options;
  if (directoryURL)
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:directoryURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
      for (NSURL *fileURL in [[[NSFileManager alloc] init] enumeratorAtURL:newURL includingPropertiesForKeys:nil options:options errorHandler:nil])
        [newFileURLs addObject:fileURL];
    }];
  
  NSUInteger index = 0, newIndex = 0, count = [_mutableFileURLs count], newCount = [newFileURLs count];
  while (index < count && newIndex < newCount)
  {
    NSComparisonResult result = [(NSURL *)[_mutableFileURLs objectAtIndex:index] compare:[newFileURLs objectAtIndex:newIndex]];
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
  if (index < count)
    [indexesOfRemovedFileURLs addIndexesInRange:NSMakeRange(index, count - index)];
  if (newIndex < newCount)
    [indexesOfInsertedFileURLs addIndexesInRange:NSMakeRange(newIndex, newCount - newIndex)];
  indexesOfInsertedFileURLs = [indexesOfInsertedFileURLs copy];
  indexesOfRemovedFileURLs = [indexesOfRemovedFileURLs copy];
  if ([indexesOfRemovedFileURLs count])
  {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexesOfRemovedFileURLs forKey:@"fileURLs"];
    [_mutableFileURLs removeObjectsAtIndexes:indexesOfRemovedFileURLs];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexesOfRemovedFileURLs forKey:@"fileURLs"];
  }
  if ([indexesOfInsertedFileURLs count])
  {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexesOfInsertedFileURLs forKey:@"fileURLs"];
    _mutableFileURLs = newFileURLs;
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexesOfInsertedFileURLs forKey:@"fileURLs"];
  }
}

#pragma mark - NSFilePresenter protocol

- (NSOperationQueue *)presentedItemOperationQueue
{
  return _internalAccessQueue;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
  ASSERT(NSOperationQueue.currentQueue == _internalAccessQueue);
  self.presentedItemURL = nil;
  [self performSelector:@selector(_enqueueUpdate) onThread:_homeThread withObject:nil waitUntilDone:NO];
  completionHandler(nil);
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
  ASSERT(NSOperationQueue.currentQueue == _internalAccessQueue);
  self.presentedItemURL = newURL;
}

- (void)presentedItemDidChange
{
  ASSERT(NSOperationQueue.currentQueue == _internalAccessQueue);
  [self performSelector:@selector(_enqueueUpdate) onThread:_homeThread withObject:nil waitUntilDone:NO];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
  return [_mutableFileURLs countByEnumeratingWithState:state objects:buffer count:len];
}

@end
