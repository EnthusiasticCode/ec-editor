//
//  ECDirectoryTableViewDataSource.h
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECDirectoryPresenter : NSObject <NSFilePresenter>

/// Directory presented.
@property (atomic, strong, readonly) NSURL *directoryURL;

/// An array of presented file URLs
/// Affected by the directory that is presented and filters or options applied to it.
@property (nonatomic, readonly) NSArray *fileURLs;

/// Smart filter string to apply to the file URLs
@property (nonatomic, strong) NSString *filterString;

/// Array of NSIndexSets representing the filter hitmasks of the file URLs.
/// Mapped 1:1 to the file URLs array
/// Returns nil if the filter string is not set
@property (nonatomic, strong) NSArray *filterHitMasks;

/// Options for customizing the file URLs that are presented
@property (nonatomic) NSDirectoryEnumerationOptions options;

/// Designated initializer
/// While ECDirectoryPresenter is not threadsafe, it is thread agnostic
- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options;

@end
