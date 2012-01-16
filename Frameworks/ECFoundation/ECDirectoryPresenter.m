//
//  ECDirectoryTableViewDataSource.m
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDirectoryPresenter.h"
#import <libkern/OSAtomic.h>

@interface ECDirectoryPresenter ()
{
    NSURL *_presentedItemURL;
    NSOperationQueue *_presentedItemOperationQueue;
}
@property (nonatomic, strong) NSArray *fileURLs;
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
    @synchronized(self)
    {
        _presentedItemURL = directory;
    }
    if (directory)
    {
        ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:self];
        [fileCoordinator coordinateReadingItemAtURL:self.directory options:0 error:NULL byAccessor:^(NSURL *newURL) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            self.fileURLs = [NSMutableArray arrayWithArray:[fileManager contentsOfDirectoryAtURL:newURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants error:NULL]];
        }];
    }
    else
        self.fileURLs = nil;
    [self didChangeValueForKey:@"directory"];
}

- (NSArray *)fileURLs
{
    return [_fileURLs copy];
}

- (void)insertFileURLs:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    ECASSERT(_fileURLs);
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"fileURLs"];
    [(NSMutableArray *)_fileURLs insertObjects:array atIndexes:indexes];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"fileURLs"];
}

- (void)removeFileURLsAtIndexes:(NSIndexSet *)indexes
{
    ECASSERT(_fileURLs);
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"fileURLs"];
    [(NSMutableArray *)_fileURLs removeObjectsAtIndexes:indexes];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"fileURLs"];
}

- (void)replaceFileURLsAtIndexes:(NSIndexSet *)indexes withFileURLs:(NSArray *)array
{
    ECASSERT(_fileURLs);
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"fileURLs"];
    [(NSMutableArray *)_fileURLs replaceObjectsAtIndexes:indexes withObjects:array];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"fileURLs"];
}

#pragma mark - General methods

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
    _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
    [ECFileCoordinator addFilePresenter:self];
    return self;
}

- (void)dealloc
{
    [ECFileCoordinator removeFilePresenter:self];
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
    NSURL *presentedItemURL = nil;
    @synchronized(self)
    {
        presentedItemURL = _presentedItemURL;
    }
    return presentedItemURL;
}

+ (NSSet *)keyPathsForValuesAffectingPresentedItemURL
{
    return [NSSet setWithObject:@"directory"];
}

- (NSOperationQueue *)presentedItemOperationQueue
{
    return _presentedItemOperationQueue;
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    ECASSERT(_fileURLs);
    self.directory = newURL;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    ECASSERT(_fileURLs);
    self.directory = nil;
    completionHandler(nil);
}

- (void)presentedSubitemDidAppearAtURL:(NSURL *)url
{
    ECASSERT(_fileURLs);
    if (![self fileURLIsDirectDescendant:url])
        return;
    NSUInteger insertionPoint = [self insertionPointForFileURL:url];
    [[self mutableArrayValueForKey:@"fileURLs"] insertObject:url atIndex:insertionPoint];
}

- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler
{
    ECASSERT(_fileURLs);
    if (![self fileURLIsDirectDescendant:url])
        return completionHandler(nil);
    [[self mutableArrayValueForKey:@"fileURLs"] removeObject:url];
    completionHandler(nil);
}

- (void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL
{
    ECASSERT(_fileURLs);
    if ([self fileURLIsDirectDescendant:oldURL])
    {
        if ([self fileURLIsDirectDescendant:newURL])
        {
            NSUInteger oldIndex = [self.fileURLs indexOfObject:oldURL];
            NSUInteger newIndex = [self insertionPointForFileURL:newURL];
            if (newIndex > oldIndex)
            {
                [[self mutableArrayValueForKey:@"fileURLs"] insertObject:newURL atIndex:newIndex];
                [[self mutableArrayValueForKey:@"fileURLs"] removeObjectAtIndex:oldIndex];
            }
            else
            {
                [[self mutableArrayValueForKey:@"fileURLs"] removeObjectAtIndex:oldIndex];
                [[self mutableArrayValueForKey:@"fileURLs"] insertObject:newURL atIndex:newIndex];
            }
        }
        else
        {
            [[self mutableArrayValueForKey:@"fileURLs"] removeObject:oldURL];
        }
    }
    else if ([self fileURLIsDirectDescendant:newURL])
        [[self mutableArrayValueForKey:@"fileURLs"] insertObject:newURL atIndex:[self insertionPointForFileURL:newURL]];
}

@end
