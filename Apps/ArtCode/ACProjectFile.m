//
//  ACProjectFile.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFile.h"
#import "ACProjectFileSystemItem+Internal.h"
#import "ACProjectItem+Internal.h"

#import "ACProject.h"
#import "ACProjectFolder.h"

#import "ACProjectFileBookmark.h"

static NSString * const _plistFileEncodingKey = @"fileEncoding";
static NSString * const _plistExplicitSyntaxKey = @"explicitSyntax";
static NSString * const _plistBookmarksKey = @"bookmarks";

/// Project internal methods to manage bookarks
@interface ACProject (Bookmarks)

- (void)didAddBookmark:(ACProjectFileBookmark *)bookmark;
- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark;

@end

/// Bookmark internal initialization for creation
@interface ACProjectFileBookmark (Internal)

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary file:(ACProjectFile *)file bookmarkPoint:(id)bookmarkPoint;

@end

@implementation ACProjectFile
{
    NSMutableDictionary *_bookmarks;
}

#pragma mark - Properties

@synthesize fileEncoding = _fileEncoding, codeFileExplicitSyntaxIdentifier = _codeFileExplicitSyntaxIdentifier;

- (NSArray *)bookmarks
{
    return [_bookmarks allValues];
}

#pragma mark - Initialization and serialization

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent contents:contents];
    if (!self)
        return nil;
    _fileEncoding = [plistDictionary objectForKey:_plistFileEncodingKey] ? [[plistDictionary objectForKey:_plistFileEncodingKey] unsignedIntegerValue] : NSUTF8StringEncoding;
    _codeFileExplicitSyntaxIdentifier = [plistDictionary objectForKey:_plistExplicitSyntaxKey];
    _bookmarks = [[NSMutableDictionary alloc] init];
    [[plistDictionary objectForKey:_plistBookmarksKey] enumerateKeysAndObjectsUsingBlock:^(id point, NSDictionary *bookmarkPlist, BOOL *stop) {
        NSScanner *scanner = [NSScanner scannerWithString:point];
        NSInteger line;
        if ([scanner scanInteger:&line])
            point = [NSNumber numberWithInteger:line];
        ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:project propertyListDictionary:bookmarkPlist file:self bookmarkPoint:point];
        if (!bookmark)
            return;
        [_bookmarks setObject:bookmark forKey:point];
        [project didAddBookmark:bookmark];
    }];
    return self;
}

- (NSDictionary *)propertyListDictionary
{
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    [plist setObject:[NSNumber numberWithUnsignedInteger:self.fileEncoding] forKey:_plistFileEncodingKey];
    if (self.codeFileExplicitSyntaxIdentifier)
        [plist setObject:self.codeFileExplicitSyntaxIdentifier forKey:_plistExplicitSyntaxKey];
    NSMutableDictionary *bookmarks = [[NSMutableDictionary alloc] init];
    [_bookmarks enumerateKeysAndObjectsUsingBlock:^(id point, ACProjectFileBookmark *bookmark, BOOL *stop) {
        if ([point isKindOfClass:[NSNumber class]])
            point = [(NSNumber *)point stringValue];
        ECASSERT([point isKindOfClass:[NSString class]]);
        [bookmarks setObject:bookmark.propertyListDictionary forKey:point];
    }];
    [plist setObject:bookmarks forKey:_plistBookmarksKey];
    return plist;
}

#pragma mark - Public Methods

- (void)addBookmarkWithPoint:(id)point
{
    ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self.project propertyListDictionary:nil file:self bookmarkPoint:point];
    [_bookmarks setObject:bookmark forKey:point];
    [self.project didAddBookmark:bookmark];
    [self.project updateChangeCount:UIDocumentChangeDone];
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

- (void)remove
{
    for (ACProjectFileBookmark *bookmark in _bookmarks.allValues)
        [bookmark remove];
    [super remove];
}

#pragma mark - Internal Methods

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark
{
    [self willChangeValueForKey:@"bookmarks"];
    [_bookmarks removeObjectForKey:bookmark.bookmarkPoint];
    [self.project didRemoveBookmark:bookmark];
    [self didChangeValueForKey:@"bookmarks"];
}

- (NSFileWrapper *)defaultContents
{
    NSFileWrapper *contents = [[NSFileWrapper alloc] initRegularFileWithContents:nil];
    contents.preferredFilename = self.name;
    return contents;
}

@end
