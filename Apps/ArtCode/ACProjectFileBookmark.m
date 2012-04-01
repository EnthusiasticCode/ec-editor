//
//  ACProjectFileBookmark.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileBookmark.h"
#import "ACProjectItem+Internal.h"

#import "ACProject.h"
#import "ACProjectFolder.h"
#import "ACProjectFile.h"

#import "NSURL+Utilities.h"


@interface ACProjectFile (Bookmarks)

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark;

@end


@implementation ACProjectFileBookmark

@synthesize file = _file, bookmarkPoint = _bookmarkPoint;

- (NSString *)description
{
  if ([_bookmarkPoint isKindOfClass:[NSNumber class]])
    return [NSString stringWithFormat:@"%@: Line %u", _file.name, [_bookmarkPoint unsignedIntValue]];
  return [NSString stringWithFormat:@"%@: %@", _file.name, _bookmarkPoint];
}

#pragma mark - Plist Internal Methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary file:(ACProjectFile *)file bookmarkPoint:(id)bookmarkPoint
{
  self = [super initWithProject:project propertyListDictionary:plistDictionary];
  if (!self)
    return nil;
  
  if (!file || file.type != ACPFile || !bookmarkPoint)
    return nil;
  
  _file = file;
  _bookmarkPoint = bookmarkPoint;
  
  return self;
}

#pragma mark - Item methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
  return [self initWithProject:project propertyListDictionary:plistDictionary file:nil bookmarkPoint:nil];
}

- (NSURL *)artCodeURL
{
  return [self.file.artCodeURL URLByAppendingFragmentDictionary:[NSDictionary dictionaryWithObject:self.bookmarkPoint forKey:([self.bookmarkPoint isKindOfClass:[NSNumber class]] ? @"line" : @"symbol")]];
}

- (ACProjectItemType)type
{
  return ACPFileBookmark;
}

- (void)remove
{
  [self.file didRemoveBookmark:self];
}

@end
