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

@implementation ACProject {
    NSMutableArray *_remotes;
}

#pragma mark - Properties

@synthesize UUID = _UUID, labelColor = _labelColor;
@synthesize contentsFolder = _contentsFolder;
@synthesize bookmarks = _bookmarks, remotes = _remotes;

- (id)UUID
{
    if (!_UUID && self.documentState & UIDocumentStateClosed)
    {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
        _UUID = (__bridge NSString *)uuidString;
        CFRelease(uuidString);
        CFRelease(uuid);
    }
    return _UUID;
}

- (ACProjectFolder *)contentsFolder
{
    if (!_contentsFolder && self.documentState != UIDocumentStateClosed)
    {
        NSFileWrapper *contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        contents.preferredFilename = _contentsFolderName;
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:nil parent:nil contents:contents];
    }
    return _contentsFolder;
}

#pragma mark - UIDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSFileWrapper *bundleWrapper = (NSFileWrapper *)contents;
    __block NSFileWrapper *contentsWrapper = nil;
    __block NSDictionary *plist = nil;
    
    [[bundleWrapper fileWrappers] enumerateKeysAndObjectsUsingBlock:^(NSString *fileName, NSFileWrapper *fileWrapper, BOOL *stop) {
        if ([fileName isEqualToString:_projectPlistFileName])
        {
            ECASSERT([fileWrapper isRegularFile]);
            plist = [NSPropertyListSerialization propertyListWithData:[fileWrapper regularFileContents] options:NSPropertyListImmutable format:NULL error:outError];
        }
        else if([fileName isEqualToString:_contentsFolderName])
        {
            contentsWrapper = fileWrapper;
        }
    }];
    
    // Project's properties
    _UUID = [plist objectForKey:@"uuid"];
    if ([plist objectForKey:@"labelColor"])
        _labelColor = [UIColor colorWithHexString:[plist objectForKey:@"labelColor"]];
    
    // Project's content
    if (contentsWrapper)
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:[plist objectForKey:@"contents"] parent:nil contents:contentsWrapper];
    
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
    
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    // Creating project plist
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
    
    // Creating project contents wrapper
    NSFileWrapper *contentsWrapper = [self.contentsFolder contents];
    contentsWrapper.preferredFilename = _contentsFolderName;
    
    // Project properties
    if (self.UUID)
        [plist setObject:self.UUID forKey:@"uuid"];
    if (self.labelColor)
        [plist setObject:[self.labelColor hexString] forKey:@"labelColor"];
    
    // Filesystem content
    if (contentsWrapper)
    {
        NSDictionary *contentsPlist = self.contentsFolder.propertyListDictionary;
        if (contentsPlist)
            [plist setObject:contentsPlist forKey:@"contents"];
    }

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
    
    // Creating project plist wrapper
    NSFileWrapper *plistWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:outError]];
    plistWrapper.preferredFilename = _projectPlistFileName;
    
    
    // Creating project bundle wrapper
    NSFileWrapper *bundleWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    if (contentsWrapper)
        [bundleWrapper addFileWrapper:contentsWrapper];
    if (plistWrapper)
        [bundleWrapper addFileWrapper:plistWrapper];
    
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

#pragma mark - Public Methods

- (void)addRemoteWithName:(NSString *)name URL:(NSURL *)remoteURL
{
    if (!_remotes)
        _remotes = [NSMutableArray new];
    [_remotes addObject:[[ACProjectRemote alloc] initWithProject:self name:name URL:remoteURL]];
    [self updateChangeCount:UIDocumentChangeDone];
}

@end
