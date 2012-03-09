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

#import "ACProject+Internal.h"
#import "ACProjectFolder.h"

#import "ACProjectFileBookmark.h"

static NSString * const _plistFileEncodingKey = @"fileEncoding";
static NSString * const _plistExplicitSyntaxKey = @"explicitSyntax";

/// Project internal methods to manage bookarks
@interface ACProject (Bookmarks)

- (void)addBookmarkWithFile:(ACProjectFile *)file point:(id)point;
- (NSArray *)bookmarksForFile:(ACProjectFile *)file;

@end

@implementation ACProjectFile

#pragma mark - Properties

@synthesize fileEncoding = _fileEncoding, codeFileExplicitSyntaxIdentifier = _codeFileExplicitSyntaxIdentifier;
@synthesize codeFileBuffer = _codeFileBuffer;

- (NSArray *)bookmarks
{
    return [self.project bookmarksForFile:self];
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

- (NSFileWrapper *)defaultContents
{
    NSFileWrapper *contents = [[NSFileWrapper alloc] initRegularFileWithContents:nil];
    contents.preferredFilename = self.name;
    return contents;
}

- (void)addBookmarkWithPoint:(id)point
{
    [self.project addBookmarkWithFile:self point:point];
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

@end
