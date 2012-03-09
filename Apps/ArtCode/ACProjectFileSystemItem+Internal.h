//
//  ACProjectFileSystemItem_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@interface ACProjectFileSystemItem (Internal)

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents;

/// The file wrapper that handles the content of the item.
- (NSFileWrapper *)contents;

/// The file wrapper for a new item.
- (NSFileWrapper *)defaultContents;

@end
