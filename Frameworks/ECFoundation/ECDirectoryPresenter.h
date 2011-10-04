//
//  ECDirectoryTableViewDataSource.h
//  ECUIKit
//
//  Created by Uri Baghin on 10/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECDirectoryPresenter : NSObject <NSFilePresenter>

@property (nonatomic, strong) NSURL *directory;

@property (nonatomic, strong, readonly) NSOrderedSet *fileURLs;

@end
