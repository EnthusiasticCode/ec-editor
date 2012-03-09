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

/// Project internal methods to manage bookarks
@interface ACProject (Bookmarks)

- (void)didAddBookmarkWithFile:(ACProjectFile *)file point:(id)point;
- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark;
- (NSArray *)implBookmarksForFile:(ACProjectFile *)file;

@end

@implementation ACProjectFile {
    NSArray *_bookmarksCache;
}

#pragma mark - Properties

@synthesize fileEncoding = _fileEncoding, codeFileExplicitSyntaxIdentifier = _codeFileExplicitSyntaxIdentifier;
@synthesize codeFileBuffer = _codeFileBuffer;

- (NSArray *)bookmarks
{
    if (!_bookmarksCache)
        _bookmarksCache = [self.project implBookmarksForFile:self];
    return _bookmarksCache;
}

#pragma mark - Initialization and serialization

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent contents:contents];
    if (!self)
        return nil;
    _fileEncoding = [plistDictionary objectForKey:_plistFileEncodingKey] ? [[plistDictionary objectForKey:_plistFileEncodingKey] unsignedIntegerValue] : NSUTF8StringEncoding;
    _codeFileExplicitSyntaxIdentifier = [plistDictionary objectForKey:_plistExplicitSyntaxKey];
    return self;
}

- (NSDictionary *)propertyListDictionary
{
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    [plist setObject:[NSNumber numberWithUnsignedInteger:self.fileEncoding] forKey:_plistFileEncodingKey];
    if (self.codeFileExplicitSyntaxIdentifier)
        [plist setObject:self.codeFileExplicitSyntaxIdentifier forKey:_plistExplicitSyntaxKey];
    return plist;
}

#pragma mark - Public Methods

- (void)addBookmarkWithPoint:(id)point
{
    _bookmarksCache = nil;
    [self.project didAddBookmarkWithFile:self point:point];
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

#pragma mark - Internal Methods

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark
{
    _bookmarksCache = nil;
    [self.project didRemoveBookmark:bookmark];
}

- (NSFileWrapper *)defaultContents
{
    NSFileWrapper *contents = [[NSFileWrapper alloc] initRegularFileWithContents:nil];
    contents.preferredFilename = self.name;
    return contents;
}

@end
