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


@interface ACProject (Bookmarks)

- (void)removeBookmark:(ACProjectFileBookmark *)bookmark;

@end


@implementation ACProjectFileBookmark

@synthesize file = _file, bookmarkPoint = _bookmarkPoint;

#pragma mark - Plist Internal Methods

- (id)initWithProject:(ACProject *)project file:(ACProjectFile *)file bookmarkPoint:(id)bookmarkPoint
{
    self = [super initWithProject:project propertyListDictionary:nil];
    if (!self)
        return nil;
    
    if (!file || file.type != ACPFile || !bookmarkPoint)
        return nil;
    
    _file = file;
    _bookmarkPoint = bookmarkPoint;
    
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
    id uuid = [plistDictionary objectForKey:@"file"];
    if (!uuid)
        return nil;
    return [self initWithProject:project file:(ACProjectFile *)[project itemWithUUID:uuid] bookmarkPoint:[plistDictionary objectForKey:@"point"]];
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
    [self.project removeBookmark:self];
}

@end
