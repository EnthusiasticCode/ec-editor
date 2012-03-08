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

@implementation ACProjectFileBookmark

@synthesize file = _file, bookmarkPoint = _bookmarkPoint;

#pragma mark - Plist Internal Methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self)
        return nil;
    id item = [plistDictionary objectForKey:@"file"];
    if (!item)
        return nil;
    item = [project itemWithUUID:item];
    if (!item || ![item isKindOfClass:[ACProjectFile class]])
        return nil;
    _file = (ACProjectFile *)item;
    _bookmarkPoint = [plistDictionary objectForKey:@"point"];
    if (!_bookmarkPoint)
        return nil;
    return self;
}

- (NSDictionary *)propertyListDictionary
{
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    
    [plist setObject:self.file.UUID forKey:@"file"];
    [plist setObject:_bookmarkPoint forKey:@"point"];
    
    return plist;
}

#pragma mark - Item methods

- (NSURL *)URL
{
    return [self.file.URL URLByAppendingFragmentDictionary:[NSDictionary dictionaryWithObject:self.bookmarkPoint forKey:([self.bookmarkPoint isKindOfClass:[NSNumber class]] ? @"line" : @"symbol")]];
}

- (ACProjectItemType)type
{
    return ACPFileBookmark;
}

@end
