//
//  DirectoryTableViewDataSource.h
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Provides the contents of a directory, updating in response to file system events
@interface DirectoryPresenter : NSObject <NSFastEnumeration>

/// Directory presented.
@property (atomic, strong, readonly) NSURL *directoryURL;

/// An array of presented file URLs
/// Affected by the directory that is presented and options
@property (readonly) NSArray *fileURLs;

/// Options for customizing the file URLs that are presented
@property (atomic) NSDirectoryEnumerationOptions options;

- (id)initWithDirectoryURL:(NSURL *)directoryURL options:(NSDirectoryEnumerationOptions)options;

@end
