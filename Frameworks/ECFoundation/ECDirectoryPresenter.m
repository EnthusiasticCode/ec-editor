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
#import <objc/runtime.h>

@interface ECDirectoryPresenter ()
{
    NSDirectoryEnumerationOptions _options;
    NSOperationQueue *_presentedItemOperationQueue;
    BOOL _isBatchUpdating;
    NSMutableArray *_batchInsertFileURLs;
    NSMutableArray *_batchRemoveFileURLs;
    
    @package
    
    id<ECDirectoryPresenterDelegate>_delegate;
    NSMutableArray *_mutableFileURLs;
    dispatch_queue_t _internalAccessQueue;
    struct
    {
        unsigned accommodateDeletion : 1;
        unsigned didMove : 1;
        unsigned didInsertRemoveChange : 1;
        unsigned reserved : 5;
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
    _options = options;
    _internalAccessQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
    _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
    _mutableFileURLs = [[NSMutableArray alloc] init];
    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:directoryURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *fileURL in [fileManager enumeratorAtURL:newURL includingPropertiesForKeys:nil options:options errorHandler:nil])
            [_mutableFileURLs addObject:fileURL];
        [ECFileCoordinator addFilePresenter:self];
    }];
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
        _delegateFlags.didInsertRemoveChange = [delegate respondsToSelector:@selector(directoryPresenter:didInsertFileURLsAtIndexes:removeFileURLsAtIndexes:changeFileURLsAtIndexes:)];
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
    
    for (NSURL *fileURL in _batchRemoveFileURLs)
    {
        NSUInteger index = [self _indexOfFileURL:fileURL options:0];
        ECASSERT(index != NSNotFound);
        [indexesOfRemovedFileURLs addIndex:index];
    }
    [_mutableFileURLs removeObjectsAtIndexes:indexesOfRemovedFileURLs];
    [_batchInsertFileURLs sortUsingComparator:[self _fileURLComparatorBlock]];
    for (NSURL *fileURL in _batchInsertFileURLs)
    {
        ECASSERT([self _indexOfFileURL:fileURL options:0] == NSNotFound);
        NSUInteger index = [self _indexOfFileURL:fileURL options:NSBinarySearchingInsertionIndex];
        index == [_mutableFileURLs count] ? [_mutableFileURLs addObject:fileURL] : [_mutableFileURLs insertObject:fileURL atIndex:index];
        [indexesOfInsertedFileURLs addIndex:index];
    }
    if (_delegateFlags.didInsertRemoveChange)
        [[_delegate delegateOperationQueue] addOperationWithBlock:^{
            [_delegate directoryPresenter:self didInsertFileURLsAtIndexes:indexesOfInsertedFileURLs removeFileURLsAtIndexes:indexesOfRemovedFileURLs changeFileURLsAtIndexes:nil];
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
        if (_delegateFlags.accommodateDeletion)
            [[_delegate delegateOperationQueue] addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                [_delegate accommodateDirectoryDeletionForDirectoryPresenter:self];
            }]] waitUntilFinished:YES];
        if ([_mutableFileURLs count] && _delegateFlags.didInsertRemoveChange)
        {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_mutableFileURLs count])];
            [_mutableFileURLs removeAllObjects];
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self didInsertFileURLsAtIndexes:nil removeFileURLsAtIndexes:indexSet changeFileURLsAtIndexes:nil];
            }];
        }
        else
        {
            [_mutableFileURLs removeAllObjects];
        }
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

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    __block NSUInteger count;
    dispatch_sync(_internalAccessQueue, ^{
        count = [_mutableFileURLs countByEnumeratingWithState:state objects:buffer count:len];
    });
    return count;
}

@end

@interface ECSmartFilteredDirectoryPresenter ()
{
    ECDirectoryPresenter *_directoryPresenter;
    NSOperationQueue *_delegateQueue;
    NSString *_filterString;
    const void *_scoreAssociationKey;
    const void *_hitMaskAssociationKey;
    NSComparisonResult (^__fileURLComparatorBlock)(id, id);
}
@end

@implementation ECSmartFilteredDirectoryPresenter

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options
{
    ECASSERT(directoryURL);
    self = [super init];
    if (!self)
        return nil;
    _directoryPresenter = [[ECDirectoryPresenter alloc] initWithDirectoryURL:directoryURL options:options];
    ECASSERT(_directoryPresenter);
    _directoryPresenter.delegate = self;
    _internalAccessQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    _delegateQueue = [[NSOperationQueue alloc] init];
    _mutableFileURLs = [[NSMutableArray alloc] init];
    return self;
}

- (NSDirectoryEnumerationOptions)options
{
    return _directoryPresenter.options;
}

- (void)setOptions:(NSDirectoryEnumerationOptions)options
{
    _directoryPresenter.options = options;
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
        NSMutableIndexSet *indexesOfInsertedFileURLs = [[NSMutableIndexSet alloc] init];
        NSMutableIndexSet *indexesOfRemovedFileURLs = [[NSMutableIndexSet alloc] init];
        NSMutableIndexSet *indexesOfChangedFileURLs = [[NSMutableIndexSet alloc] init];
        
        NSInteger index = 0;
        NSURL *previousFileURL = nil;
        for (NSURL *fileURL in _mutableFileURLs)
        {
            NSIndexSet *hitMask = nil;
            float score = [[fileURL lastPathComponent] scoreForAbbreviation:filterString hitMask:&hitMask];
            if (!score)
                [indexesOfRemovedFileURLs addIndex:index];
            else
            {
                objc_setAssociatedObject(fileURL, &_scoreAssociationKey, [NSNumber numberWithFloat:score], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(fileURL, &_hitMaskAssociationKey, hitMask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                ECASSERT(objc_getAssociatedObject(fileURL, &_scoreAssociationKey));
                if (previousFileURL && [self _fileURLComparatorBlock](previousFileURL, fileURL) == NSOrderedDescending)
                    [indexesOfRemovedFileURLs addIndex:index];
                else
                {
                    previousFileURL = fileURL;
                    [indexesOfChangedFileURLs addIndex:index];
                }
            }
            ++index;
        }
        [_mutableFileURLs removeObjectsAtIndexes:indexesOfRemovedFileURLs];
        
        NSMutableArray *fileURLsToInsert = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in _directoryPresenter.fileURLs)
        {
            NSIndexSet *hitMask = nil;
            float score = [[fileURL lastPathComponent] scoreForAbbreviation:filterString hitMask:&hitMask];
            if (!score)
                continue;
            objc_setAssociatedObject(fileURL, &_scoreAssociationKey, [NSNumber numberWithFloat:score], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(fileURL, &_hitMaskAssociationKey, hitMask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            ECASSERT(objc_getAssociatedObject(fileURL, &_scoreAssociationKey));
            NSUInteger indexOfExistingFileURL = [self _indexOfFileURL:fileURL options:0];
            if (indexOfExistingFileURL == NSNotFound)
                [fileURLsToInsert addObject:fileURL];
        }
        [fileURLsToInsert sortUsingComparator:[self _fileURLComparatorBlock]];
        NSUInteger fileURLsCount = [_mutableFileURLs count];
        for (index = 0; index < fileURLsCount; ++index)
        {
            if (![fileURLsToInsert count])
                break;
            if ([self _fileURLComparatorBlock]([_mutableFileURLs objectAtIndex:index], [fileURLsToInsert objectAtIndex:0]) == NSOrderedAscending)
                continue;
            [_mutableFileURLs insertObject:[fileURLsToInsert objectAtIndex:0] atIndex:index];
            [fileURLsToInsert removeObjectAtIndex:0];
            [indexesOfInsertedFileURLs addIndex:index];
        }
        if ([fileURLsToInsert count])
        {
            [indexesOfInsertedFileURLs addIndexesInRange:NSMakeRange([_mutableFileURLs count], [fileURLsToInsert count])];
            [_mutableFileURLs addObjectsFromArray:fileURLsToInsert];
        }
        
        _filterString = filterString;
        
        if (_delegateFlags.didInsertRemoveChange)
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self didInsertFileURLsAtIndexes:indexesOfInsertedFileURLs removeFileURLsAtIndexes:indexesOfRemovedFileURLs changeFileURLsAtIndexes:indexesOfChangedFileURLs];
            }];
    });
}

- (NSIndexSet *)hitMaskForFileURL:(NSURL *)fileURL
{
    __block NSIndexSet *hitMask;
    dispatch_sync(_internalAccessQueue, ^{
        hitMask = objc_getAssociatedObject(fileURL, &_hitMaskAssociationKey);
    });
    return hitMask;
}

#pragma mark - Private methods

- (NSComparisonResult (^)(id, id))_fileURLComparatorBlock
{
    ECASSERT(dispatch_get_current_queue() == _internalAccessQueue);
    if (!__fileURLComparatorBlock)
    {
        __weak ECSmartFilteredDirectoryPresenter *weakSelf = self;
        NSComparisonResult (^superComparator)(id, id) = [super _fileURLComparatorBlock];
        __fileURLComparatorBlock = ^NSComparisonResult(NSURL *fileURL1, NSURL *fileURL2){
            NSNumber *associatedScore1 = objc_getAssociatedObject(fileURL1, &(weakSelf->_scoreAssociationKey));
            NSNumber *associatedScore2 = objc_getAssociatedObject(fileURL2, &(weakSelf->_scoreAssociationKey));
            ECASSERT(associatedScore1 && associatedScore2);
            float score1 = [associatedScore1 floatValue];
            float score2 = [associatedScore2 floatValue];
            if (score1 > score2)
                return NSOrderedAscending;
            else if (score1 < score2)
                return NSOrderedDescending;
            return superComparator(fileURL1, fileURL2);
        };
    }
    return __fileURLComparatorBlock;
}

#pragma mark - ECDirectoryPresenter delegate

- (NSOperationQueue *)delegateOperationQueue
{
    return _delegateQueue;
}

- (void)accommodateDirectoryDeletionForDirectoryPresenter:(ECDirectoryPresenter *)directoryPresenter
{
    dispatch_barrier_sync(_internalAccessQueue, ^{
        if (_delegateFlags.accommodateDeletion)
            [[_delegate delegateOperationQueue] addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                [_delegate accommodateDirectoryDeletionForDirectoryPresenter:self];
            }]] waitUntilFinished:YES];
    });
}

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter directoryDidMoveToURL:(NSURL *)dstURL
{
    dispatch_async(_internalAccessQueue, ^{
        if (_delegateFlags.didMove)
            [[_delegate delegateOperationQueue] addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
                [_delegate directoryPresenter:self directoryDidMoveToURL:dstURL];
            }]] waitUntilFinished:YES];
    });
}

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didInsertFileURLsAtIndexes:(NSIndexSet *)insertIndexes removeFileURLsAtIndexes:(NSIndexSet *)removeIndexes changeFileURLsAtIndexes:(NSIndexSet *)changeIndexes
{
    dispatch_barrier_async(_internalAccessQueue, ^{
        NSMutableIndexSet *indexesOfInsertedFileURLs = [[NSMutableIndexSet alloc] init];
        NSMutableIndexSet *indexesOfRemovedFileURLs = [[NSMutableIndexSet alloc] init];

        NSArray *newFileURLs = nil;
        
        if ([removeIndexes count])
        {
            if (!newFileURLs)
                newFileURLs = _directoryPresenter.fileURLs;
            NSRange range = NSMakeRange(0, [newFileURLs count]);
            NSUInteger index = 0;
            for (NSURL *fileURL in _mutableFileURLs)
            {
                if ([newFileURLs indexOfObject:fileURL inSortedRange:range options:0 usingComparator:[super _fileURLComparatorBlock]] == NSNotFound)
                    [indexesOfRemovedFileURLs addIndex:index];
                ++index;
            }
            [_mutableFileURLs removeObjectsAtIndexes:indexesOfRemovedFileURLs];
        }
        if ([insertIndexes count])
        {
            if (!newFileURLs)
                newFileURLs = _directoryPresenter.fileURLs;
            NSMutableArray *fileURLsToInsert = [[NSMutableArray alloc] init];
            [insertIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                NSURL *fileURL = [newFileURLs objectAtIndex:idx];
                NSIndexSet *hitMask = nil;
                float score = [[fileURL lastPathComponent] scoreForAbbreviation:_filterString hitMask:&hitMask];
                if (!score)
                    return;
                objc_setAssociatedObject(fileURL, &_scoreAssociationKey, [NSNumber numberWithFloat:score], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(fileURL, &_hitMaskAssociationKey, hitMask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                ECASSERT(objc_getAssociatedObject(fileURL, &_scoreAssociationKey));                
                [fileURLsToInsert addObject:fileURL];
            }];            
            [fileURLsToInsert sortUsingComparator:[self _fileURLComparatorBlock]];
            NSUInteger fileURLsCount = [_mutableFileURLs count];
            for (NSUInteger index = 0; index < fileURLsCount; ++index)
            {
                if (![fileURLsToInsert count])
                    break;
                if ([self _fileURLComparatorBlock]([_mutableFileURLs objectAtIndex:index], [fileURLsToInsert objectAtIndex:0]) == NSOrderedAscending)
                    continue;
                [_mutableFileURLs insertObject:[fileURLsToInsert objectAtIndex:0] atIndex:index];
                [fileURLsToInsert removeObjectAtIndex:0];
                [indexesOfInsertedFileURLs addIndex:index];
            }
            if ([fileURLsToInsert count])
            {
                [indexesOfInsertedFileURLs addIndexesInRange:NSMakeRange([_mutableFileURLs count], [fileURLsToInsert count])];
                [_mutableFileURLs addObjectsFromArray:fileURLsToInsert];
            }
        }
        if (_delegateFlags.didInsertRemoveChange)
            [[_delegate delegateOperationQueue] addOperationWithBlock:^{
                [_delegate directoryPresenter:self didInsertFileURLsAtIndexes:indexesOfInsertedFileURLs removeFileURLsAtIndexes:indexesOfRemovedFileURLs changeFileURLsAtIndexes:nil];
            }];
    });
}

@end

