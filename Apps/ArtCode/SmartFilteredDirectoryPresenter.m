//
//  SmartFilteredDirectoryPresenter.m
//  ArtCode
//
//  Created by Uri Baghin on 1/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SmartFilteredDirectoryPresenter.h"
#import "NSString+ScoreForAbbreviation.h"
#import "NSURL+Compare.h"
#import <objc/runtime.h>

static void * _directoryObservingContext;

@interface SmartFilteredDirectoryPresenter ()
{
    NSMutableArray *_mutableFileURLs;
    const void *_scoreAssociationKey;
    const void *_hitMaskAssociationKey;
    NSComparisonResult (^__fileURLComparatorBlock)(id, id);
}
@property (nonatomic, strong) DirectoryPresenter *directoryPresenter;
- (void)_setScore:(float)score hitMask:(NSIndexSet *)hitMask forFileURL:(NSURL *)fileURL;
- (NSComparisonResult(^)(id, id))_fileURLComparatorBlock;
- (NSUInteger)_indexOfFileURL:(NSURL *)fileURL options:(NSBinarySearchingOptions)options;
- (NSMutableIndexSet *)_indexesOfInsertedFileURLs:(NSMutableArray *)fileURLsToInsert inArray:(NSMutableArray *)fileURLs;
@end

@implementation SmartFilteredDirectoryPresenter

@synthesize directoryPresenter = _directoryPresenter, filterString = _filterString;

- (NSURL *)directoryURL
{
    return self.directoryPresenter.directoryURL;
}

+ (NSSet *)keyPathsForValuesAffectingDirectoryURL
{
    return [NSSet setWithObject:@"directoryPresenter.directoryURL"];
}

- (NSDirectoryEnumerationOptions)options
{
    return self.directoryPresenter.options;
}

- (void)setOptions:(NSDirectoryEnumerationOptions)options
{
    self.directoryPresenter.options = options;
}

+ (NSSet *)keyPathsForValuesAffectingOptions
{
    return [NSSet setWithObject:@"directoryPresenter.options"];
}

- (void)setFilterString:(NSString *)filterString
{
    if (filterString == _filterString || [filterString isEqualToString:_filterString])
        return;
    NSMutableIndexSet *indexesOfInsertedFileURLs = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *indexesOfRemovedFileURLs = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *indexesOfReplacedFileURLs = [[NSMutableIndexSet alloc] init];
    NSMutableArray *newFileURLs = [_mutableFileURLs mutableCopy];
    
    NSInteger index = 0;
    NSURL *previousFileURL = nil;
    for (NSURL *fileURL in newFileURLs)
    {
        NSIndexSet *hitMask = nil;
        float score = [[fileURL lastPathComponent] scoreForAbbreviation:filterString hitMask:&hitMask];
        if (!score)
            [indexesOfRemovedFileURLs addIndex:index];
        else
        {
            [self _setScore:score hitMask:hitMask forFileURL:fileURL];
            if (previousFileURL && [self _fileURLComparatorBlock](previousFileURL, fileURL) == NSOrderedDescending)
                [indexesOfRemovedFileURLs addIndex:index];
            else
            {
                previousFileURL = fileURL;
                [indexesOfReplacedFileURLs addIndex:index];
            }
        }
        ++index;
    }
    [newFileURLs removeObjectsAtIndexes:indexesOfRemovedFileURLs];
    
    NSMutableArray *fileURLsToInsert = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in self.directoryPresenter.fileURLs)
    {
        NSIndexSet *hitMask = nil;
        float score = [[fileURL lastPathComponent] scoreForAbbreviation:filterString hitMask:&hitMask];
        if (!score)
            continue;
        [self _setScore:score hitMask:hitMask forFileURL:fileURL];
        NSUInteger indexOfExistingFileURL = [self _indexOfFileURL:fileURL options:0];
        if (indexOfExistingFileURL == NSNotFound)
            [fileURLsToInsert addObject:fileURL];
    }
    
    indexesOfInsertedFileURLs = [self _indexesOfInsertedFileURLs:fileURLsToInsert inArray:newFileURLs];
        
    indexesOfInsertedFileURLs = [indexesOfInsertedFileURLs copy];
    indexesOfRemovedFileURLs = [indexesOfRemovedFileURLs copy];
    indexesOfReplacedFileURLs = [indexesOfReplacedFileURLs copy];
    
    [self willChangeValueForKey:@"filterString"];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexesOfRemovedFileURLs forKey:@"fileURLs"];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexesOfReplacedFileURLs forKey:@"fileURLs"];
    [_mutableFileURLs removeObjectsAtIndexes:indexesOfRemovedFileURLs];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexesOfRemovedFileURLs forKey:@"fileURLs"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexesOfReplacedFileURLs forKey:@"fileURLs"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexesOfInsertedFileURLs forKey:@"fileURLs"];
    _mutableFileURLs = newFileURLs;
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexesOfInsertedFileURLs forKey:@"fileURLs"];
    _filterString = filterString;
    [self didChangeValueForKey:@"filterString"];
}

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options
{
    ECASSERT(directoryURL);
    self = [super init];
    if (!self)
        return nil;
    _directoryPresenter = [[DirectoryPresenter alloc] initWithDirectoryURL:directoryURL options:options];
    ECASSERT(_directoryPresenter);
    [_directoryPresenter addObserver:self forKeyPath:@"fileURLs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:&_directoryObservingContext];
    _mutableFileURLs = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
    [_directoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&_directoryObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &_directoryObservingContext)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if ([[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue])
        return [self willChange:[[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue] valuesAtIndexes:[change objectForKey:NSKeyValueChangeIndexesKey] forKey:@"fileURLs"];
    NSKeyValueChange kind = [[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
    switch (kind) {
        case NSKeyValueChangeInsertion:
        {
            NSMutableArray *fileURLsToInsert = [[[change objectForKey:NSKeyValueChangeNewKey] objectsAtIndexes:[change objectForKey:NSKeyValueChangeIndexesKey]] mutableCopy];
            NSMutableIndexSet *indexes = [self _indexesOfInsertedFileURLs:fileURLsToInsert inArray:_mutableFileURLs];
            if ([indexes count])
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"fileURLs"];
            return;
        }
        case NSKeyValueChangeRemoval:
        {
            NSArray *fileURLsToRemove = [[change objectForKey:NSKeyValueChangeOldKey] objectsAtIndexes:[change objectForKey:NSKeyValueChangeIndexesKey]];
            NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
            for (NSURL *fileURL in fileURLsToRemove)
            {
                float score = [[fileURL lastPathComponent] scoreForAbbreviation:self.filterString hitMask:NULL];
                if (!score)
                    continue;
                [self _setScore:score hitMask:nil forFileURL:fileURL];
                [indexes addIndex:[self _indexOfFileURL:fileURL options:0]];
            }
            ECASSERT(![indexes containsIndex:NSNotFound] && "if a fileURL has a non-zero score, and was removed, it should have been there");
            if ([indexes count])
                [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"fileURLs"];
            return;
        }
        default:
        {
            ECASSERT(NO && "directory presenter's fileURLs should never call a KVO change that isn't insert or remove");
        }
    }
}

- (NSIndexSet *)hitMaskForFileURL:(NSURL *)fileURL
{
    return objc_getAssociatedObject(fileURL, &_hitMaskAssociationKey);
}

#pragma mark - Private methods

- (void)_setScore:(float)score hitMask:(NSIndexSet *)hitMask forFileURL:(NSURL *)fileURL
{
    objc_setAssociatedObject(fileURL, &_scoreAssociationKey, [NSNumber numberWithFloat:score], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (hitMask)
        objc_setAssociatedObject(fileURL, &_hitMaskAssociationKey, hitMask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSComparisonResult (^)(id, id))_fileURLComparatorBlock
{
    if (!__fileURLComparatorBlock)
    {
        __weak SmartFilteredDirectoryPresenter *weakSelf = self;
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
            return [fileURL1 compare:fileURL2];
        };
    }
    return __fileURLComparatorBlock;
}

- (NSUInteger)_indexOfFileURL:(NSURL *)fileURL options:(NSBinarySearchingOptions)options
{
    return [_mutableFileURLs indexOfObject:fileURL inSortedRange:NSMakeRange(0, [_mutableFileURLs count]) options:options usingComparator:[self _fileURLComparatorBlock]];
}

- (NSMutableIndexSet *)_indexesOfInsertedFileURLs:(NSMutableArray *)fileURLsToInsert inArray:(NSMutableArray *)fileURLs
{
    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
    [fileURLsToInsert sortUsingComparator:[self _fileURLComparatorBlock]];
    NSUInteger fileURLsCount = [fileURLs count];
    for (NSUInteger index = 0; index < fileURLsCount; ++index)
    {
        if (![fileURLsToInsert count])
            break;
        if ([self _fileURLComparatorBlock]([fileURLs objectAtIndex:index], [fileURLsToInsert objectAtIndex:0]) == NSOrderedAscending)
            continue;
        [fileURLs insertObject:[fileURLsToInsert objectAtIndex:0] atIndex:index];
        ++fileURLsCount;
        [fileURLsToInsert removeObjectAtIndex:0];
        [indexes addIndex:index];
    }
    if ([fileURLsToInsert count])
    {
        [indexes addIndexesInRange:NSMakeRange([fileURLs count], [fileURLsToInsert count])];
        [fileURLs addObjectsFromArray:fileURLsToInsert];
    }
    return indexes;
}

@end
