//
//  ECDirectoryTableViewDataSource.h
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSFileManager.h>
@class ECDirectoryPresenter, NSIndexSet, NSURL, NSOperationQueue;

@protocol ECDirectoryPresenterDelegate <NSObject>

@optional
/// Because of how NSFileCoordinator works for now, this also gets called when the directory is deleted
- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter directoryDidMoveToURL:(NSURL *)dstURL;

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didInsertFileURLsAtIndexes:(NSIndexSet *)insertIndexes removeFileURLsAtIndexes:(NSIndexSet *)removeIndexes changeFileURLsAtIndexes:(NSIndexSet *)changeIndexes;

@end

/// Provides the contents of a directory, updating in response to file system events
@interface ECDirectoryPresenter : NSObject <NSFastEnumeration>

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options;

- (id<ECDirectoryPresenterDelegate>)delegate;
- (void)setDelegate:(id<ECDirectoryPresenterDelegate>)delegate;

- (NSOperationQueue *)delegateOperationQueue;
- (void)setDelegateOperationQueue:(NSOperationQueue *)delegateOperationQueue;

/// Directory presented.
- (NSURL *)directoryURL;

/// An array of presented file URLs
/// Affected by the directory that is presented and options
- (NSArray *)fileURLs;

/// Options for customizing the file URLs that are presented
- (NSDirectoryEnumerationOptions)options;
- (void)setOptions:(NSDirectoryEnumerationOptions)options;

@end

@interface ECSmartFilteredDirectoryPresenter : ECDirectoryPresenter <ECDirectoryPresenterDelegate>

/// Smart filter string to apply to the file URLs
- (NSString *)filterString;
- (void)setFilterString:(NSString *)filterString;

/// Returns the hitmask for a certain filtered file URL
- (NSIndexSet *)hitMaskForFileURL:(NSURL *)fileURL;

@end
