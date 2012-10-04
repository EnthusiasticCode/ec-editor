//
//  TextFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileSystemItem+File.h"


@interface FileSystemItem (TextFile)

- (id<RACSubscribable>)explicitSyntaxIdentifier;
- (id<RACSubscribable>)bindExplicitSyntaxIdentifierTo:(id<RACSubscribable>)explicitSyntaxIdentifierSubscribable;

- (id<RACSubscribable>)explicitEncoding;
- (id<RACSubscribable>)bindExplicitEncodingTo:(id<RACSubscribable>)explicitEncodingSubscribable;

- (id<RACSubscribable>)bookmarks;
- (id<RACSubscribable>)bindBookmarksTo:(id<RACSubscribable>)bookmarksSubscribable;

@end
