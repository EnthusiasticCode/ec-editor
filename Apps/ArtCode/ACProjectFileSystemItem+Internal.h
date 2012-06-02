//
//  ACProjectFileSystemItem_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@interface ACProjectFileSystemItem ()

@property (nonatomic, weak) ACProjectFolder *parentFolder;

/// A fileWrapper of the file system item's content
@property (nonatomic, strong) NSFileWrapper *fileWrapper;

/// Designated initializer.
- (id)initWithProject:(ACProject *)project parent:(ACProjectFolder *)parent fileWrapper:(NSFileWrapper *)fileWrapper propertyListDictionary:(NSDictionary *)plistDictionary;

@end
