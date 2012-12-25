//
//  TextFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileSystemItem+TextFile.h"

static NSString * const _explicitSyntaxIdentifierKey = @"com.enthusiasticcode.artcode.TextFile.ExplicitSyntaxIdentifier";
static NSString * const _explicitEncodingKey = @"com.enthusiasticcode.artcode.TextFile.ExplicitEncoding";
static NSString * const _bookmarksKey = @"com.enthusiasticcode.artcode.TextFile.Bookmarks";

@implementation FileSystemFile (TextFile)

- (RACSignal *)explicitSyntaxIdentifierSource {
  return [self extendedAttributeSourceForKey:_explicitSyntaxIdentifierKey];
}

- (id<RACSubscriber>)explicitSyntaxIdentifierSink {
  return [self extendedAttributeSinkForKey:_explicitSyntaxIdentifierKey];
}

- (RACSignal *)explicitEncodingSource {
  return [self extendedAttributeSourceForKey:_explicitEncodingKey];
}

- (id<RACSubscriber>)explicitEncodingSink {
  return [self extendedAttributeSinkForKey:_explicitEncodingKey];
}

- (RACSignal *)bookmarksSource {
  return [self extendedAttributeSourceForKey:_bookmarksKey];
}

- (id<RACSubscriber>)bookmarksSink {
  return [self extendedAttributeSinkForKey:_bookmarksKey];
}

@end
