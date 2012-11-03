//
//  TextFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileSystemItem.h"
@class RACPropertySyncSubject;


@interface FileSystemFile (TextFile)

- (id<RACSubscribable>)explicitSyntaxIdentifierSource;

- (id<RACSubscriber>)explicitSyntaxIdentifierSink;

- (id<RACSubscribable>)explicitEncodingSource;

- (id<RACSubscriber>)explicitEncodingSink;

- (id<RACSubscribable>)bookmarksSource;

- (id<RACSubscriber>)bookmarksSink;

@end
