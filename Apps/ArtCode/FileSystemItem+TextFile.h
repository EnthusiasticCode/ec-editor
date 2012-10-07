//
//  TextFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileSystemItem.h"
@class RACPropertySyncSubject;


@interface FileSystemItem (TextFile)

- (RACPropertySyncSubject *)explicitSyntaxIdentifier;

- (RACPropertySyncSubject *)explicitEncoding;

- (RACPropertySyncSubject *)bookmarks;

@end
