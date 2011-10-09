//
//  ECDirectoryTableViewDataSource.m
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDirectoryPresenter.h"

@interface ECDirectoryPresenter ()
{
    NSOperationQueue *_presentedItemOperationQueue;
}
@property (nonatomic, strong) NSOrderedSet *fileURLs;
- (NSUInteger)insertionPointForFileURL:(NSURL *)fileURL;
- (BOOL)fileURLIsDirectDescendant:(NSURL *)fileURL;
@end

@implementation ECDirectoryPresenter

#pragma mark - Properties

@synthesize directory = _directory;
@synthesize fileURLs = _fileURLs;

- (void)setDirectory:(NSURL *)directory
{
    if (directory == _directory)
        return;
    [self willChangeValueForKey:@"directory"];
    _directory = directory;
    if (directory)
    {
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
        [fileCoordinator coordinateReadingItemAtURL:self.directory options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSArray *fileURLs = [fileManager contentsOfDirectoryAtURL:newURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants error:NULL];
            self.fileURLs = [NSMutableOrderedSet orderedSetWithArray:fileURLs];
        }];
    }
    else
        self.fileURLs = nil;
    [self didChangeValueForKey:@"directory"];
}

- (NSOrderedSet *)fileURLs
{
    return [_fileURLs copy];
}

- (void)insertFileURLs:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [[self mutableOrderedSetValueForKey:@"fileURLs"] insertObjects:array atIndexes:indexes];
}

- (void)replaceFileURLsAtIndexes:(NSIndexSet *)indexes withFileURLs:(NSArray *)array
{
    [[self mutableOrderedSetValueForKey:@"fileURLs"] replaceObjectsAtIndexes:indexes withObjects:array];
}

#pragma mark - General methods

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    [NSFileCoordinator addFilePresenter:self];
    return self;
}

- (void)dealloc
{
    [NSFileCoordinator removeFilePresenter:self];
}

- (NSUInteger)insertionPointForFileURL:(NSURL *)fileURL
{
    return [self.fileURLs indexOfObject:fileURL inSortedRange:NSMakeRange(0, [self.fileURLs count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 lastPathComponent] compare:[obj2 lastPathComponent]];
    }];
}

- (BOOL)fileURLIsDirectDescendant:(NSURL *)fileURL
{
    return [[fileURL pathComponents] count] == [[self.directory pathComponents] count] + 1;
}

#pragma mark - NSFilePresenter protocol

- (NSURL *)presentedItemURL
{
    return self.directory;
}

+ (NSSet *)keyPathsForValuesAffectingPresentedItemURL
{
    return [NSSet setWithObject:@"directory"];
}

- (NSOperationQueue *)presentedItemOperationQueue
{
    if (!_presentedItemOperationQueue)
    {
        _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
        _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _presentedItemOperationQueue;
}

- (void)presentedItemDidChange
{
    ECASSERT(NO);
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    ECASSERT(NO);
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateReadingItemAtURL:newURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        self.directory = newURL;
    }];
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    ECASSERT(NO);
    self.directory = nil;
    completionHandler(nil);
}

- (void)presentedSubitemDidAppearAtURL:(NSURL *)url
{
    ECASSERT(NO);
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        if (![self fileURLIsDirectDescendant:newURL])
            return;
        NSUInteger insertionPoint = [self insertionPointForFileURL:newURL];
        [[self mutableOrderedSetValueForKey:@"fileURLs"] insertObject:newURL atIndex:insertionPoint];
    }];
}

- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler
{
    ECASSERT(NO);
    if (![self fileURLIsDirectDescendant:url])
        return completionHandler(nil);
    [[self mutableOrderedSetValueForKey:@"fileURLs"] removeObject:url];
    completionHandler(nil);
}

- (void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    ECASSERT(NO);
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateReadingItemAtURL:newURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        if ([self fileURLIsDirectDescendant:oldURL])
        {
            if ([self fileURLIsDirectDescendant:newURL])
            {
                NSUInteger index = [self.fileURLs indexOfObject:oldURL];
                [[self mutableOrderedSetValueForKey:@"fileURLs"] replaceObjectAtIndex:index withObject:newURL];
                [[self mutableOrderedSetValueForKey:@"fileURLs"] moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:index] toIndex:[self insertionPointForFileURL:newURL]];
            }
            else
            {
                [[self mutableOrderedSetValueForKey:@"fileURLs"] removeObject:oldURL];
            }
        }
        else if ([self fileURLIsDirectDescendant:newURL])
        {
            NSUInteger insertionPoint = [self insertionPointForFileURL:newURL];
            [[self mutableOrderedSetValueForKey:@"fileURLs"] insertObject:newURL atIndex:insertionPoint];
        }
    }];
}

@end
