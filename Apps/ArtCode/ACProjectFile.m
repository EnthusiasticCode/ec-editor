//
//  ACProjectFile.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFile.h"
#import "ACProjectFileSystemItem+Internal.h"

#import "ACProject.h"
#import "ACProjectFolder.h"

@interface ACProjectFile ()

@end

@interface ACProject (Bookmarks)

- (void)addNewBookmarkWithFile:(ACProjectFile *)file point:(id)point;
- (NSArray *)bookmarksForFile:(ACProjectFile *)file;

@end

@implementation ACProjectFile

- (NSFileWrapper *)defaultContents
{
    NSFileWrapper *contents = [[NSFileWrapper alloc] initRegularFileWithContents:nil];
    contents.preferredFilename = self.name;
    return contents;
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
