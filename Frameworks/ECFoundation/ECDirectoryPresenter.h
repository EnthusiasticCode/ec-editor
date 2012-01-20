//
//  ECDirectoryTableViewDataSource.h
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECDirectoryPresenter;

@protocol ECDirectoryPresenterDelegate <NSObject>

@required
/// This method can be called from any queue, at any time.
/// All other delegate methods will be called on the returned queue.
- (NSOperationQueue *)delegateOperationQueue;

/// All the "will" methods are blocking, so return from them as soon as possible. There's also a high chance they will cause a deadlock if they're not implemented with care.
/// All the "did" methods are asynchronous and aren't coalesced, so they may be called multiple times in succession, and not immediately after the change has gone through.

@optional
- (void)accommodateDirectoryDeletionForDirectoryPresenter:(ECDirectoryPresenter *)directoryPresenter;
- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter directoryDidMoveToURL:(NSURL *)dstURL;

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didInsertFileURLsAtIndexes:(NSIndexSet *)indexes;
- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didRemoveFileURLsAtIndexes:(NSIndexSet *)indexes;
- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didInsertFilteredFileURLsAtIndexes:(NSIndexSet *)indexes;
- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didRemoveFilteredFileURLsAtIndexes:(NSIndexSet *)indexes;
- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didChangeHitMasksAtIndexes:(NSIndexSet *)indexes;

@end

@interface ECDirectoryPresenter : NSObject <NSFilePresenter>

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options;

- (id<ECDirectoryPresenterDelegate>)delegate;
- (void)setDelegate:(id<ECDirectoryPresenterDelegate>)delegate;

/// Directory presented.
- (NSURL *)directoryURL;

/// An array of presented file URLs
/// Affected by the directory that is presented and options
- (NSArray *)fileURLs;

/// Options for customizing the file URLs that are presented
- (NSDirectoryEnumerationOptions)options;
- (void)setOptions:(NSDirectoryEnumerationOptions)options;

/// An array of filtered file URLs
/// Affected by the directory, options and filter
/// Returns all file URLs if not set
- (NSArray *)filteredFileURLs;

/// Smart filter string to apply to the filtered file URLs
- (NSString *)filterString;
- (void)setFilterString:(NSString *)filterString;

/// Array of NSIndexSets representing the filter hitmasks of the file URLs.
/// Mapped 1:1 to the filtered file URLs array
/// Returns nil if the filter string is not set
- (NSArray *)filterHitMasks;

@end
