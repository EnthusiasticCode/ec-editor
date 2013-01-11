//
//  TextFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileSystemFile+TextFile.h"

static NSString * const _explicitSyntaxIdentifierKey = @"com.enthusiasticcode.artcode.TextFile.ExplicitSyntaxIdentifier";
static NSString * const _explicitEncodingKey = @"com.enthusiasticcode.artcode.TextFile.ExplicitEncoding";
static NSString * const _bookmarksKey = @"com.enthusiasticcode.artcode.TextFile.Bookmarks";

@implementation FileSystemFile (TextFile)

- (RACPropertySubject *)explicitSyntaxIdentifier {
  return [self extendedAttributeForKey:_explicitSyntaxIdentifierKey];
}

- (RACPropertySubject *)explicitEncoding {
  return [self extendedAttributeForKey:_explicitEncodingKey];
}

- (RACPropertySubject *)bookmarks {
  return [self extendedAttributeForKey:_bookmarksKey];
}

@end
