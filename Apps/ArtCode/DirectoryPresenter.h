//
//  DirectoryTableViewDataSource.h
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DirectoryPresenter;

@protocol DirectoryPresenterDelegate <NSObject>

@optional
/// Because of how NSFileCoordinator works for now, this also gets called when the directory is deleted
- (void)directoryPresenter:(DirectoryPresenter *)directoryPresenter directoryDidMoveToURL:(NSURL *)dstURL;

- (void)directoryPresenter:(DirectoryPresenter *)directoryPresenter didInsertFileURLsAtIndexes:(NSIndexSet *)insertIndexes removeFileURLsAtIndexes:(NSIndexSet *)removeIndexes changeFileURLsAtIndexes:(NSIndexSet *)changeIndexes;

@end

/// Provides the contents of a directory, updating in response to file system events
@interface DirectoryPresenter : NSObject <NSFastEnumeration>

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options;

- (id<DirectoryPresenterDelegate>)delegate;
- (void)setDelegate:(id<DirectoryPresenterDelegate>)delegate;

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

@interface SmartFilteredDirectoryPresenter : DirectoryPresenter <DirectoryPresenterDelegate>

/// Smart filter string to apply to the file URLs
- (NSString *)filterString;
- (void)setFilterString:(NSString *)filterString;

/// Returns the hitmask for a certain filtered file URL
- (NSIndexSet *)hitMaskForFileURL:(NSURL *)fileURL;

@end
