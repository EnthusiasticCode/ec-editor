//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACProjectFolder.h"
#import "ACProjectFileBookmark.h"
#import "ACProjectRemote.h"

#import "ACProjectItem+Internal.h"
#import "ACProjectFileSystemItem+Internal.h"

#import "NSURL+Utilities.h"
#import "UIColor+HexColor.h"

static NSString * const _projectsFolderName = @"LocalProjects";
static NSString * const _projectPlistFileName = @".acproj";
static NSString * const _contentsFolderName = @"Contents";

@interface ACProject ()

/// Encodes the project's property, content, bookmarks and remotes in a dictionary serializable as a plist.
- (NSDictionary *)propertyListDictionary;

/// Decodes the project's properties, content, bookmarks and remotes from a plist dictionary.
- (void)loadPropertyListDictionary:(NSDictionary *)plist;

@end

@implementation ACProject

@synthesize UUID = _UUID, labelColor = _labelColor;
@synthesize contentsFolder = _contentsFolder;
@synthesize bookmarks = _bookmarks, remotes = _remotes;

- (ACProjectFolder *)contentsFolder
{
    if (self.documentState == UIDocumentStateClosed)
        return nil;
    if (!_contentsFolder)
    {
        _contentsFolder = [[ACProjectFolder alloc] initWithName:_contentsFolderName parent:nil contents:nil];
    }
    return _contentsFolder;
}

#pragma mark - UIDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSFileWrapper *bundleWrapper = (NSFileWrapper *)contents;
    __block NSFileWrapper *contentsWrapper = nil;
    
    [[bundleWrapper fileWrappers] enumerateKeysAndObjectsUsingBlock:^(NSString *fileName, NSFileWrapper *fileWrapper, BOOL *stop) {
        if ([fileName isEqualToString:_projectPlistFileName])
        {
            ECASSERT([fileWrapper isRegularFile]);
            [self loadPropertyListDictionary:[NSPropertyListSerialization propertyListWithData:[fileWrapper regularFileContents] options:NSPropertyListImmutable format:NULL error:outError]];
        }
        else if([fileName isEqualToString:_contentsFolderName])
        {
            contentsWrapper = fileWrapper;
        }
    }];
    
    self.contentsFolder.contents = contentsWrapper;
    
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    // Creating project plist wrapper
    NSFileWrapper *plistWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSPropertyListSerialization dataWithPropertyList:[self propertyListDictionary] format:NSPropertyListBinaryFormat_v1_0 options:0 error:outError]];
    
    // Creating project bundle
    NSFileWrapper *bundleWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionaryWithObjectsAndKeys:plistWrapper, _projectPlistFileName, [self.contentsFolder contents], _contentsFolderName, nil]];
    return bundleWrapper;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    NSLog(@">>>>>>>>>>>>>>>>> %@", error);
}

#pragma mark - Class Methods

+ (NSURL *)projectsURL
{
    static NSURL *_projectsURL = nil;
    if (!_projectsURL)
        _projectsURL = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:_projectsFolderName isDirectory:YES];
    return _projectsURL;
}

+ (void)createProjectWithName:(NSString *)name importArchiveURL:(NSURL *)archiveURL completionHandler:(void (^)(ACProject *))completionHandler
{
    // Ensure that projects URL exists
    [[NSFileManager new] createDirectoryAtURL:[self projectsURL] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Create the project
    NSURL *projectURL = [[self projectsURL] URLByAppendingPathComponent:[name stringByAppendingPathExtension:@"acproj"]];
    ACProject *project = [[ACProject alloc] initWithFileURL:projectURL];
    [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        // Inform the completion handler
        if (completionHandler)
            completionHandler(success ? project : nil);
    }];
}

#pragma mark - Property List Methods

- (NSDictionary *)propertyListDictionary
{
    // Project properties
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.UUID, @"uuid", nil];
    if (self.labelColor)
        [plist setObject:[self.labelColor hexString] forKey:@"labelColor"];
    
    // Filesystem content
    [plist setObject:[self.contentsFolder propertyListDictionary] forKey:@"contents"];
    
    // Bookmarks
    if ([self.bookmarks count])
    {
        NSMutableArray *bookmarksPlist = [NSMutableArray arrayWithCapacity:[self.bookmarks count]];
        for (ACProjectFileBookmark *bookmark in self.bookmarks)
        {
            [bookmarksPlist addObject:[bookmark propertyListDictionary]];
        }
        [plist setObject:bookmarksPlist forKey:@"bookmarks"];
    }
    
    // Remotes
    if ([self.remotes count])
    {
        NSMutableArray *remotesPlist = [NSMutableArray arrayWithCapacity:[self.remotes count]];
        for (ACProjectFileBookmark *remote in self.remotes)
        {
            [remotesPlist addObject:[remote propertyListDictionary]];
        }
        [plist setObject:remotesPlist forKey:@"remotes"];
    }
    
    return plist;
}

- (void)loadPropertyListDictionary:(NSDictionary *)plist
{
    // Project's properties
    _UUID = [plist objectForKey:@"uuid"];
    if ([plist objectForKey:@"labelColor"])
        _labelColor = [UIColor colorWithHexString:[plist objectForKey:@"labelColor"]];
    
    // Project's content
    _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:[plist objectForKey:@"contents"]];
    
    // Bookmarks
    if ([plist objectForKey:@"bookmarks"])
    {
        NSMutableArray *bookmarksFromPlist = [NSMutableArray new];
        for (NSDictionary *bookmark in [plist objectForKey:@"bookmarks"])
        {
            [bookmarksFromPlist addObject:[[ACProjectFileBookmark alloc] initWithProject:self propertyListDictionary:bookmark]];
        }
        _bookmarks = [bookmarksFromPlist copy];
    }
    
    // Remotes
    if ([plist objectForKey:@"remotes"])
    {
        NSMutableArray *remotesFromPlist = [NSMutableArray new];
        for (NSDictionary *remote in [plist objectForKey:@"remotes"])
        {
            [remotesFromPlist addObject:[[ACProjectRemote alloc] initWithProject:self propertyListDictionary:remote]];
        }
        _remotes = [remotesFromPlist copy];
    }
}

@end
