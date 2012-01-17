//
//  ECDirectoryTableViewDataSource.m
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDirectoryPresenter.h"
#import <ECFoundation/NSURL+ECAdditions.h>

@interface ECDirectoryPresenter ()
{
    NSMutableArray *_mutableFileURLs;
    NSOperationQueue *_presentedItemOperationQueue;
}
@property (atomic, strong) NSURL *directoryURL;
- (void)_insertFileURL:(NSURL *)fileURL;
- (void)_removeFileURL:(NSURL *)fileURL;
- (BOOL)_shouldIgnoreFileURL:(NSURL *)fileURL;
- (NSComparisonResult(^)(id, id))_fileURLComparatorBlock;
- (NSUInteger)_indexOfFileURL:(NSURL *)fileURL options:(NSBinarySearchingOptions)options;
@end

@implementation ECDirectoryPresenter

#pragma mark - Properties

@synthesize directoryURL = _directoryURL;
@synthesize options = _options;

- (NSArray *)fileURLs
{
    return [_mutableFileURLs copy];
}

#pragma mark - General methods

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options
{
    ECASSERT(directoryURL);
    self = [super init];
    if (!self)
        return nil;
    _directoryURL = directoryURL;
    _mutableFileURLs = [[NSMutableArray alloc] init];
    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:directoryURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *fileURL in [fileManager enumeratorAtURL:newURL includingPropertiesForKeys:nil options:options errorHandler:nil])
            [_mutableFileURLs addObject:fileURL];
        [ECFileCoordinator addFilePresenter:self];
    }];
    _options = options;
    _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
    _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
    return self;
}

- (void)dealloc
{
    [ECFileCoordinator removeFilePresenter:self];
}

#pragma mark - Private methods

- (void)_insertFileURL:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    if ([self _shouldIgnoreFileURL:fileURL])
        return;
    NSUInteger index = [self _indexOfFileURL:fileURL options:NSBinarySearchingInsertionIndex];
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"fileURLs"];
    [_mutableFileURLs insertObject:fileURL atIndex:index];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"fileURLs"];
}

- (void)_removeFileURL:(NSURL *)fileURL
{
    NSUInteger index = [self _indexOfFileURL:fileURL options:0];
    if (index == NSNotFound)
        return;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"fileURLs"];
    [_mutableFileURLs removeObjectAtIndex:index];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"fileURLs"];
}

- (BOOL)_shouldIgnoreFileURL:(NSURL *)fileURL
{
    NSDirectoryEnumerationOptions options = self.options;
    if (options & NSDirectoryEnumerationSkipsHiddenFiles && ([fileURL isHidden] || [fileURL isHiddenDescendant]))
        return YES;
    if (options & NSDirectoryEnumerationSkipsPackageDescendants && [fileURL isPackageDescendant])
        return YES;
    if (options & NSDirectoryEnumerationSkipsSubdirectoryDescendants && [fileURL isSubdirectoryDescendantOfDirectoryAtURL:self.directoryURL])
        return YES;
    return NO;
}

- (NSComparisonResult (^)(id, id))_fileURLComparatorBlock
{
    static NSComparisonResult (^fileURLComparatorBlock)(id, id) = ^NSComparisonResult(id obj1, id obj2) {
        NSArray *pathComponents1 = [obj1 pathComponents];
        NSArray *pathComponents2 = [obj2 pathComponents];
        if ([pathComponents1 count] < [pathComponents2 count])
            return NSOrderedAscending;
        else if ([pathComponents1 count] > [pathComponents2 count])
            return NSOrderedDescending;
        
        __block NSComparisonResult result = NSOrderedSame;
        [pathComponents1 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            result = [(NSString *)obj compare:[pathComponents2 objectAtIndex:idx]];
            if (result != NSOrderedSame)
                *stop = YES;
        }];
        return result;
    };
    return fileURLComparatorBlock;
}

- (NSUInteger)_indexOfFileURL:(NSURL *)fileURL options:(NSBinarySearchingOptions)options
{
    return [_mutableFileURLs indexOfObject:fileURL inSortedRange:NSMakeRange(0, [_mutableFileURLs count]) options:options usingComparator:[self _fileURLComparatorBlock]];
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
    return _presentedItemOperationQueue;
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    self.directoryURL = newURL;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    self.directoryURL = nil;
    if (![_mutableFileURLs count])
        return;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_mutableFileURLs count])];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"fileURLs"];
    [_mutableFileURLs removeAllObjects];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"fileURLs"];
    completionHandler(nil);
}

- (void)presentedSubitemDidAppearAtURL:(NSURL *)url
{
    [self _insertFileURL:url];
}

- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler
{
    [self _removeFileURL:url];
    completionHandler(nil);
}

- (void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    [self _removeFileURL:oldURL];
    [self _insertFileURL:newURL];
}

@end
