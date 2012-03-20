//
//  ACProjectFileSystemItem_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@interface ACProjectFileSystemItem (Internal)

/// File URL of the file system item. Must be accessed from the project's file access coordination queue
@property (nonatomic, strong, readonly) NSURL *fileURL;

/// The content modification date should be updated whenever the file system item's in memory representation is changed
@property (nonatomic, strong) NSDate *contentModificationDate;

/// Designated initializer, both fileURL and originalURL are required, even if they're the same
- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent fileURL:(NSURL *)fileURL originalURL:(NSURL *)originalURL ;

/// Force a write to the specified URL. Must be called on the project's file access coordination queue
- (BOOL)writeToURL:(NSURL *)url;

@end
