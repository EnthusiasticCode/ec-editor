//
//  ACProjectFile.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFile+Internal.h"
#import "ACProjectFileSystemItem+Internal.h"

#import "ACProject+Internal.h"
#import "ACProjectFolder.h"

#import "ACProjectFileBookmark+Internal.h"


@implementation ACProjectFile {
    NSMutableArray *_bookmarks;
}

@synthesize fileEncoding = _fileEncoding;

- (NSArray *)bookmarks
{
    return [_bookmarks copy];
}

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent contents:contents];
    if (!self)
        return nil;
    _fileEncoding = NSUTF8StringEncoding;
    _bookmarks = [[NSMutableArray alloc] init];
    return self;
}

- (NSFileWrapper *)defaultContents
{
    NSFileWrapper *contents = [[NSFileWrapper alloc] initRegularFileWithContents:nil];
    contents.preferredFilename = self.name;
    return contents;
}

- (void)addBookmarkWithPoint:(id)point
{
    ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self.project propertyListDictionary:nil file:self bookmarkPoint:point];
    if (!bookmark)
        return;
    [_bookmarks addObject:bookmark];
    [self.project didAddBookmark:bookmark];
}

#pragma mark - Item methods

- (NSURL *)URL
{
    return [self.parentFolder.URL URLByAppendingPathComponent:self.name];
}

- (ACProjectItemType)type
{
    return ACPFile;
}

#pragma mark - Internal methods

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark
{
    [_bookmarks removeObject:bookmark];
}

@end
