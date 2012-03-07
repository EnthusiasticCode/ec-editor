//
//  ACProjectFileSystemItem.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectItem.h"
@class ACProjectFolder;

@interface ACProjectFileSystemItem : ACProjectItem

@property (nonatomic, weak, readonly) ACProjectFolder *parentFolder;
@property (nonatomic, strong) NSString *name;
- (BOOL)moveToFolder:(ACProjectFolder *)newParent error:(NSError **)error;
- (BOOL)copyToFolder:(ACProjectFolder *)copyParent error:(NSError **)error;

@end
