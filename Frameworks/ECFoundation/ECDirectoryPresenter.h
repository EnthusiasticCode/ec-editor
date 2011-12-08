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
@property (nonatomic, strong) NSURL *directory;

/// Files in the directory. This property will be automatically updated on file system changes. Thus a good target to be observed.
@property (nonatomic, strong, readonly) NSArray *fileURLs;

@end
