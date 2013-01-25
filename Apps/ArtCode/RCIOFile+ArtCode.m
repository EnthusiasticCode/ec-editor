//
//  TextFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RCIOFile+ArtCode.h"

static NSString * const explicitSyntaxIdentifierKey = @"com.enthusiasticcode.artcode.ExplicitSyntaxIdentifier";
static NSString * const explicitEncodingKey = @"com.enthusiasticcode.artcode.ExplicitEncoding";
static NSString * const bookmarksKey = @"com.enthusiasticcode.artcode.Bookmarks";

@implementation RCIOFile (ArtCode)

- (RACPropertySubject *)explicitSyntaxIdentifierSubject {
  return [self extendedAttributeSubjectForKey:explicitSyntaxIdentifierKey];
}

- (RACPropertySubject *)explicitEncodingSubject {
  return [self extendedAttributeSubjectForKey:explicitEncodingKey];
}

- (RACPropertySubject *)bookmarksSubject {
  return [self extendedAttributeSubjectForKey:bookmarksKey];
}

@end
