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

@implementation ACProjectFileBookmark

@synthesize file = _file, bookmarkPoint = _bookmarkPoint;

#pragma mark - Project Item Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self)
        return nil;
    id item = [plistDictionary objectForKey:@"file"];
    if (!item)
        return nil;
    item = [project.contentsFolder descendantItemWithUUID:item];
    if (!item)
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

@end
