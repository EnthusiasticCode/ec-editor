//
//  ECFileObserver.m
//  ECFoundation
//
//  Created by Uri Baghin on 9/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECItemObserver.h"

@interface ECItemObserver ()
{
    NSOperationQueue *_presentedItemOperationQueue;
}
@property (atomic, strong) NSURL *observedItemURL;
@property (nonatomic, strong) NSDate *presentedItemLastModificationDate;
@end

@implementation ECItemObserver

@synthesize delegate = _delegate;
@synthesize observedItemURL = _observedItemURL;
@synthesize presentedItemLastModificationDate = _presentedItemLastModificationDate;

- (NSURL *)presentedItemURL
{
    return self.observedItemURL;
}

+ (NSSet *)keyPathsForValuesAffectingPresentedItemURL
{
    return [NSSet setWithObject:@"observedItemURL"];
}

- (NSOperationQueue *)presentedItemOperationQueue
{
    return _presentedItemOperationQueue;
}

- (id)initWithItemURL:(NSURL *)itemURL queue:(NSOperationQueue *)queue
{
    ECASSERT([itemURL isFileURL]);
    ECASSERT(queue);
    self = [super init];
    if (!self)
        return nil;
    _presentedItemOperationQueue = queue;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    __weak ECItemObserver *this = self;
    [fileCoordinator coordinateReadingItemAtURL:itemURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        this.observedItemURL = newURL;
        id lastModificationDate;
        [newURL getResourceValue:&lastModificationDate forKey:NSURLContentModificationDateKey error:NULL];
        this.presentedItemLastModificationDate = lastModificationDate;
        [NSFileCoordinator addFilePresenter:self];
    }];
    return self;
}

- (void)dealloc
{
    [NSFileCoordinator removeFilePresenter:self];
}

- (void)presentedItemDidChange
{
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    __weak ECItemObserver *this = self;
    [fileCoordinator coordinateReadingItemAtURL:self.observedItemURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        id lastModificationDate;
        [newURL getResourceValue:&lastModificationDate forKey:NSURLContentModificationDateKey error:NULL];
        if ([this.presentedItemLastModificationDate isEqualToDate:lastModificationDate])
            return;
        this.presentedItemLastModificationDate = lastModificationDate;
        if ([this.delegate respondsToSelector:@selector(contentsOfObservedItemDidChangeForItemObserver:)])
            [this.delegate contentsOfObservedItemDidChangeForItemObserver:this];
    }];
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    NSURL *oldURL = self.observedItemURL;
    self.observedItemURL = newURL;
    if ([self.delegate respondsToSelector:@selector(itemObserver:observedItemDidMoveFromURL:)])
        [self.delegate itemObserver:self observedItemDidMoveFromURL:oldURL];
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    if ([self.delegate respondsToSelector:@selector(itemObserver:accommodateObservedItemDeletionWithCompletionHandler:)])
        [self.delegate itemObserver:self accommodateObservedItemDeletionWithCompletionHandler:completionHandler];
}

@end
