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

- (RACSignal *)explicitSyntaxIdentifierSource;

- (id<RACSubscriber>)explicitSyntaxIdentifierSink;

- (RACSignal *)explicitEncodingSource;

- (id<RACSubscriber>)explicitEncodingSink;

- (RACSignal *)bookmarksSource;

- (id<RACSubscriber>)bookmarksSink;

@end
