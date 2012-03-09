//
//  ACProjectFileBookmark.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileBookmark+Internal.h"
#import "ACProjectItem+Internal.h"

#import "ACProject+Internal.h"
#import "ACProjectFolder.h"
#import "ACProjectFile+Internal.h"

#import "NSURL+Utilities.h"

@implementation ACProjectFileBookmark

@synthesize file = _file, bookmarkPoint = _bookmarkPoint;

#pragma mark - Plist Internal Methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary file:(ACProjectFile *)file bookmarkPoint:(id)bookmarkPoint
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self)
        return nil;
    if (file)
    {
        _file = file;
    }
    else
    {
        id uuid = [plistDictionary objectForKey:@"file"];
        if (uuid)
            _file = (ACProjectFile *)[project itemWithUUID:uuid];
    }
    if (!_file || ![_file isKindOfClass:[ACProjectFile class]])
        return nil;
    
    if (bookmarkPoint)
        _bookmarkPoint = bookmarkPoint;
    else
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

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    return [self initWithProject:project propertyListDictionary:plistDictionary file:nil bookmarkPoint:nil];
}

- (NSURL *)URL
{
    return [self.file.URL URLByAppendingFragmentDictionary:[NSDictionary dictionaryWithObject:self.bookmarkPoint forKey:([self.bookmarkPoint isKindOfClass:[NSNumber class]] ? @"line" : @"symbol")]];
}

- (ACProjectItemType)type
{
    return ACPFileBookmark;
}

- (void)remove
{
    [self.file didRemoveBookmark:self];
    [self.project didRemoveBookmark:self];
    [super remove];
}

@end
