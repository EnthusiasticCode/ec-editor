//
//  ACProjectFileSystemItem_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@interface ACProjectFileSystemItem (Internal)

- (id)initWithName:(NSString *)name parent:(ACProjectFileSystemItem *)parent contents:(NSFileWrapper *)contents;
- (NSFileWrapper *)contents;

@end
