//
//  ACProjectFileBookmark.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileBookmark.h"
#import "ACProjectItem+Internal.h"

@implementation ACProjectFileBookmark

@synthesize file = _file, bookmarkPoint = _bookmarkPoint;

#pragma mark - Project Item Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self)
        return nil;
    // TODO setup file using something like [project.contentsFolder  fileSystemItemWithUUID:]
    _bookmarkPoint = [plistDictionary objectForKey:@"point"];
    return self;
}

- (NSDictionary *)propertyListDictionary
{
    // TODO save file uuid
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    [plist setObject:_bookmarkPoint forKey:@"point"];
    return plist;
}

@end
