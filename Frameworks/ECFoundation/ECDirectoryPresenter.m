//
//  ECDirectoryTableViewDataSource.m
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDirectoryPresenter.h"
#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECFoundation/NSString+ECAdditions.h>

@interface ECDirectoryPresenter ()
{
    id<ECDirectoryPresenterDelegate>_delegate;
    NSDirectoryEnumerationOptions _options;
    NSMutableArray *_mutableFileURLs;
    NSMutableArray *_mutableFilteredFileURLs;
    NSString *_filterString;
    NSMutableArray *_mutableFilterHitMasks;
    dispatch_queue_t _internalAccessQueue;
    NSOperationQueue *_presentedItemOperationQueue;
    BOOL _isBatchUpdating;
    NSMutableArray *_batchInsertFileURLs;
    NSMutableArray *_batchRemoveFileURLs;
    struct
    {
        unsigned accommodateDeletion : 1;
        unsigned didMove : 1;
        unsigned didInsert : 1;
        unsigned didRemove : 1;
        unsigned didInsertFiltered : 1;
        unsigned didRemoveFiltered : 1;
        unsigned didChangeHitMasks : 1;
        unsigned reserved : 1;
    } _delegateFlags;
}
@property (atomic, strong) NSURL *directoryURL;
- (void)_beginUpdates;
- (void)_endUpdates;
- (void)_insertFileURL:(NSURL *)fileURL;
- (void)_removeFileURL:(NSURL *)fileURL;
- (BOOL)_shouldIgnoreFileURL:(NSURL *)fileURL;
- (NSComparisonResult(^)(id, id))_fileURLComparatorBlock;
- (NSUInteger)_indexOfFileURL:(NSURL *)fileURL options:(NSBinarySearchingOptions)options;
- (NSUInteger)_indexOfFilteredFileURL:(NSURL *)fileURL options:(NSBinarySearchingOptions)options;
@end

@implementation ECDirectoryPresenter

@synthesize directoryURL = _directoryURL;

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
    _mutableFilteredFileURLs = [[NSMutableArray alloc] init];
    _mutableFilterHitMasks = [[NSMutableArray alloc] init];
    _internalAccessQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
    _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
    return self;
}

- (void)dealloc
{
    [ECFileCoordinator removeFilePresenter:self];
}

- (id<ECDirectoryPresenterDelegate>)delegate
{
    __block id<ECDirectoryPresenterDelegate>delegate;
    dispatch_sync(_internalAccessQueue, ^{
        delegate = _delegate;
    });
    return delegate;
}

- (void)setDelegate:(id<ECDirectoryPresenterDelegate>)delegate
{
    dispatch_barrier_async(_internalAccessQueue, ^{
        if (delegate == _delegate)
            return;
        _delegate = delegate;
        _delegateFlags.accommodateDeletion = [delegate respondsToSelector:@selector(accommodateDirectoryDeletionForDirectoryPresenter:)];
        _delegateFlags.didMove = [delegate respondsToSelector:@selector(directoryPresenter:directoryDidMoveToURL:)];
        _delegateFlags.didInsert = [delegate respondsToSelector:@selector(directoryPresenter:didInsertFileURLsAtIndexes:)];
        _delegateFlags.didRemove = [delegate respondsToSelector:@selector(directoryPresenter:didRemoveFileURLsAtIndexes:)];
        _delegateFlags.didInsertFiltered = [delegate respondsToSelector:@selector(directoryPresenter:didInsertFilteredFileURLsAtIndexes:)];
        _delegateFlags.didRemoveFiltered = [delegate respondsToSelector:@selector(directoryPresenter:didRemoveFilteredFileURLsAtIndexes:)];
        _delegateFlags.didChangeHitMasks = [delegate respondsToSelector:@selector(directoryPresenter:didChangeHitMasksAtIndexes:)];
    });
}

- (NSArray *)fileURLs
{
    __block NSArray *fileURLs;
    dispatch_sync(_internalAccessQueue, ^{
        fileURLs = [_mutableFileURLs copy];
    });
    return fileURLs;
}

- (NSDirectoryEnumerationOptions)options
{
    __block NSDirectoryEnumerationOptions options;
    dispatch_sync(_internalAccessQueue, ^{
        options = _options;
    });
    return options;
}

- (void)setOptions:(NSDirectoryEnumerationOptions)options
{
    dispatch_barrier_async(_internalAccessQueue, ^{
        if (options == _options)
            return;
        NSDirectoryEnumerationOptions fileURLsToInsert = options - (options & _options);
        NSDirectoryEnumerationOptions fileURLsToRemove = _options - (_options & options);
        NSURL *directoryURL = self.directoryURL;
        [self _beginUpdates];
        if (fileURLsToInsert)
            for (NSURL *fileURL in [[[NSFileManager alloc] init] enumeratorAtURL:directoryURL includingPropertiesForKeys:nil options:0 errorHandler:nil])
                if (((fileURLsToInsert & NSDirectoryEnumerationSkipsHiddenFiles) && ([fileURL isHidden] || [fileURL isHiddenDescendant])) ||
                    ((fileURLsToInsert & NSDirectoryEnumerationSkipsPackageDescendants) && [fileURL isPackageDescendant]) ||
                    ((fileURLsToInsert & NSDirectoryEnumerationSkipsSubdirectoryDescendants) && [fileURL isSubdirectoryDescendantOfDirectoryAtURL:directoryURL]))
                    [self _insertFileURL:fileURL];
        if (fileURLsToRemove)
            for (NSURL *fileURL in _mutableFileURLs)
                if (((fileURLsToInsert & NSDirectoryEnumerationSkipsHiddenFiles) && ([fileURL isHidden] || [fileURL isHiddenDescendant])) ||
                    ((fileURLsToInsert & NSDirectoryEnumerationSkipsPackageDescendants) && [fileURL isPackageDescendant]) ||
                    ((fileURLsToInsert & NSDirectoryEnumerationSkipsSubdirectoryDescendants) && [fileURL isSubdirectoryDescendantOfDirectoryAtURL:directoryURL]))
                    [self _removeFileURL:fileURL];
        [self _endUpdates];
        _options = options;
    });
}

- (NSArray *)filteredFileURLs
{
    __block NSArray *filteredFileURLs = nil;
    dispatch_sync(_internalAccessQueue, ^{
        if (![_filterString length])
            return;
        filteredFileURLs = [_mutableFilteredFileURLs copy];
    });
    return filteredFileURLs;
}

- (NSString *)filterString
{
    __block NSString *filterString;
    dispatch_sync(_internalAccessQueue, ^{
        filterString = _filterString;
    });
    return filterString;
}

- (void)setFilterString:(NSString *)filterString
{
    dispatch_barrier_async(_internalAccessQueue, ^{
        if (filterString == _filterString || [filterString isEqualToString:_filterString])
            return;
        NSMutableIndexSet *indexesOfInsertedFilteredFileURLs = [[NSMutableIndexSet alloc] init];
        NSMutableIndexSet *indexesOfRemovedFilteredFileURLs = [[NSMutableIndexSet alloc] init];
        NSMutableIndexSet *indexesOfChangedHitmasks = [[NSMutableIndexSet alloc] init];
        NSUInteger index = 0;
        for (NSURL *fileURL in _mutableFilteredFileURLs)
        {
            NSIndexSet *hitMask;
            if (![[fileURL lastPathComponent] scoreForAbbreviation:filterString hitMask:&hitMask])
                [indexesOfRemovedFilteredFileURLs addIndex:index];
            else
                [_mutableFilterHitMasks replaceObjectAtIndex:index withObject:hitMask];
            ++index;
        }
        [_mutableFilteredFileURLs removeObjectsAtIndexes:indexesOfRemovedFilteredFileURLs];
        [_mutableFilterHitMasks removeObjectsAtIndexes:indexesOfRemovedFilteredFileURLs];
        for (NSURL *fileURL in _mutableFileURLs)
        {
            NSIndexSet *hitMask;
            if (![[fileURL lastPathComponent] scoreForAbbreviation:filterString hitMask:&hitMask])
                continue;
            index = [self _indexOfFilteredFileURL:fileURL options:0];
            if (index == NSNotFound)
            {
                [_mutableFilteredFileURLs insertObject:fileURL atIndex:index];
                [indexesOfInsertedFilteredFileURLs addIndex:index];
            }
            else
            {
                [_mutableFilterHitMasks replaceObjectAtIndex:index withObject:hitMask];
            }
        }
        [indexesOfChangedHitmasks addIndexesInRange:NSMakeRange(0, [_mutableFilteredFileURLs count])];
        [indexesOfChangedHitmasks removeIndexes:indexesOfInsertedFilteredFileURLs];
        if (_delegateFlags.didInsertFiltered && [indexesOfInsertedFilteredFileURLs count])
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self didInsertFilteredFileURLsAtIndexes:indexesOfInsertedFilteredFileURLs];
            }];
        if (_delegateFlags.didRemoveFiltered && [indexesOfRemovedFilteredFileURLs count])
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self didRemoveFilteredFileURLsAtIndexes:indexesOfRemovedFilteredFileURLs];
            }];
        if (_delegateFlags.didChangeHitMasks && [indexesOfChangedHitmasks count])
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self didChangeHitmasksAtIndexes:indexesOfChangedHitmasks];
            }];
    });
}

- (NSArray *)filterHitMasks
{
    __block NSArray *filterHitMasks = nil;
    dispatch_sync(_internalAccessQueue, ^{
        if (![_filterString length])
            return;
        filterHitMasks = [_mutableFilterHitMasks copy];
    });
    return filterHitMasks;
}

#pragma mark - Private methods

- (void)_beginUpdates
{
    ECASSERT(dispatch_get_current_queue() == _internalAccessQueue);
    ECASSERT(!_isBatchUpdating);
    _isBatchUpdating = YES;
    _batchInsertFileURLs = [[NSMutableArray alloc] init];
    _batchRemoveFileURLs = [[NSMutableArray alloc] init];
}

- (void)_endUpdates
{
    ECASSERT(dispatch_get_current_queue() == _internalAccessQueue);
    ECASSERT(_isBatchUpdating);
    ECASSERT([_batchInsertFileURLs count] == [[[NSSet alloc] initWithArray:_batchInsertFileURLs] count]);
    ECASSERT([_batchRemoveFileURLs count] == [[[NSSet alloc] initWithArray:_batchRemoveFileURLs] count]);
    
    NSMutableIndexSet *indexesOfInsertedFileURLs = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *indexesOfRemovedFileURLs = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *indexesOfInsertedFilteredFileURLs = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *indexesOfRemovedFilteredFileURLs = [[NSMutableIndexSet alloc] init];
    
    for (NSURL *fileURL in _batchInsertFileURLs)
    {
        ECASSERT([self _indexOfFileURL:fileURL options:0] == NSNotFound);
        NSUInteger index = [self _indexOfFileURL:fileURL options:NSBinarySearchingInsertionIndex];
        [_mutableFileURLs insertObject:fileURL atIndex:index];
        [indexesOfInsertedFileURLs addIndex:index];
        NSIndexSet *hitMask;
        if (![_filterString length])
            continue;
        if (![[fileURL lastPathComponent] scoreForAbbreviation:_filterString hitMask:&hitMask])
            continue;
        ECASSERT([self _indexOfFilteredFileURL:fileURL options:0] == NSNotFound);
        NSUInteger filteredIndex = [self _indexOfFilteredFileURL:fileURL options:NSBinarySearchingInsertionIndex];
        [_mutableFilteredFileURLs insertObject:fileURL atIndex:filteredIndex];
        [_mutableFilterHitMasks insertObject:hitMask atIndex:filteredIndex];
        [indexesOfInsertedFilteredFileURLs addIndex:filteredIndex];
    }
    for (NSURL *fileURL in _batchRemoveFileURLs)
    {
        NSUInteger index = [self _indexOfFileURL:fileURL options:0];
        ECASSERT(index != NSNotFound);
        [_mutableFileURLs removeObjectAtIndex:index];
        [indexesOfRemovedFileURLs addIndex:index];
        NSIndexSet *hitMask;
        if (![_filterString length])
            continue;
        if (![[fileURL lastPathComponent] scoreForAbbreviation:_filterString hitMask:&hitMask])
            continue;
        NSUInteger filteredIndex = [self _indexOfFilteredFileURL:fileURL options:0];
        [_mutableFilteredFileURLs removeObjectAtIndex:filteredIndex];
        [_mutableFilterHitMasks removeObjectAtIndex:filteredIndex];
        [indexesOfRemovedFilteredFileURLs addIndex:filteredIndex];
    }
    if (_delegateFlags.didInsert && [indexesOfInsertedFileURLs count])
        [[_delegate delegateOperationQueue] addOperationWithBlock:^{
            [_delegate directoryPresenter:self didInsertFileURLsAtIndexes:indexesOfInsertedFileURLs];
        }];
    if (_delegateFlags.didRemove && [indexesOfRemovedFileURLs count])
        [[_delegate delegateOperationQueue] addOperationWithBlock:^{
            [_delegate directoryPresenter:self didRemoveFileURLsAtIndexes:indexesOfRemovedFileURLs];
        }];
    if (_delegateFlags.didInsertFiltered && [indexesOfInsertedFilteredFileURLs count])
        [[_delegate delegateOperationQueue] addOperationWithBlock:^{
            [_delegate directoryPresenter:self didInsertFilteredFileURLsAtIndexes:indexesOfInsertedFilteredFileURLs];
        }];
    if (_delegateFlags.didRemoveFiltered && [indexesOfRemovedFilteredFileURLs count])
        [[_delegate delegateOperationQueue] addOperationWithBlock:^{
            [_delegate directoryPresenter:self didRemoveFilteredFileURLsAtIndexes:indexesOfRemovedFilteredFileURLs];
        }];
    _batchInsertFileURLs = nil;
    _batchRemoveFileURLs = nil;
    _isBatchUpdating = NO;
}

- (void)_insertFileURL:(NSURL *)fileURL
{
    ECASSERT(dispatch_get_current_queue() == _internalAccessQueue);
    ECASSERT(_isBatchUpdating);
    [_batchInsertFileURLs addObject:fileURL];
}

- (void)_removeFileURL:(NSURL *)fileURL
{
    ECASSERT(dispatch_get_current_queue() == _internalAccessQueue);
    ECASSERT(_isBatchUpdating);
    [_batchRemoveFileURLs addObject:fileURL];
}

- (BOOL)_shouldIgnoreFileURL:(NSURL *)fileURL
{
    ECASSERT(dispatch_get_current_queue() == _internalAccessQueue);
    if (_options & NSDirectoryEnumerationSkipsHiddenFiles && ([fileURL isHidden] || [fileURL isHiddenDescendant]))
        return YES;
    if (_options & NSDirectoryEnumerationSkipsPackageDescendants && [fileURL isPackageDescendant])
        return YES;
    if (_options & NSDirectoryEnumerationSkipsSubdirectoryDescendants && [fileURL isSubdirectoryDescendantOfDirectoryAtURL:self.directoryURL])
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
    ECASSERT(dispatch_get_current_queue() == _internalAccessQueue);
    return [_mutableFileURLs indexOfObject:fileURL inSortedRange:NSMakeRange(0, [_mutableFileURLs count]) options:options usingComparator:[self _fileURLComparatorBlock]];
}

- (NSUInteger)_indexOfFilteredFileURL:(NSURL *)fileURL options:(NSBinarySearchingOptions)options
{
    ECASSERT(dispatch_get_current_queue() == _internalAccessQueue);
    return [_mutableFilteredFileURLs indexOfObject:fileURL inSortedRange:NSMakeRange(0, [_mutableFilteredFileURLs count]) options:options usingComparator:[self _fileURLComparatorBlock]];
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
    dispatch_async(_internalAccessQueue, ^{
        if (_delegateFlags.didMove)
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self directoryDidMoveToURL:newURL];
            }];
    });
    self.directoryURL = newURL;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    dispatch_barrier_sync(_internalAccessQueue, ^{
        if ([_mutableFilteredFileURLs count] && _delegateFlags.didRemoveFiltered)
        {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_mutableFilteredFileURLs count])];
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self didRemoveFilteredFileURLsAtIndexes:indexSet];
            }];
        }
        [_mutableFilteredFileURLs removeAllObjects];
        [_mutableFilterHitMasks removeAllObjects];
        if ([_mutableFileURLs count] && _delegateFlags.didRemove)
        {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_mutableFileURLs count])];
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self didRemoveFileURLsAtIndexes:indexSet];
            }];
        }
        [_mutableFileURLs removeAllObjects];
    });
    self.directoryURL = nil;
    completionHandler(nil);
}

- (void)presentedSubitemDidAppearAtURL:(NSURL *)url
{
    dispatch_async(_internalAccessQueue, ^{
        if ([self _shouldIgnoreFileURL:url])
            return;
        [self _beginUpdates];
        [self _insertFileURL:url];
        [self _endUpdates];
    });
}

- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler
{
    dispatch_barrier_sync(_internalAccessQueue, ^{
        if ([self _shouldIgnoreFileURL:url])
            return;
        if ([self _indexOfFileURL:url options:0] == NSNotFound)
            return;
        [self _beginUpdates];
        [self _removeFileURL:url];
        [self _endUpdates];
    });
    completionHandler(nil);
}

- (void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    dispatch_barrier_async(_internalAccessQueue, ^{
        BOOL ignoreOldURL = [self _shouldIgnoreFileURL:oldURL];
        BOOL ignoreNewURL = [self _shouldIgnoreFileURL:newURL];
        if (ignoreOldURL && ignoreNewURL)
            return;
        [self _beginUpdates];
        if (!ignoreOldURL)
            [self _removeFileURL:oldURL];
        if (!ignoreNewURL)
            [self _insertFileURL:newURL];
        [self _endUpdates];
    });
}

@end
