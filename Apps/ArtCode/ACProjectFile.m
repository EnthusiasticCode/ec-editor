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

@interface ACProject (Bookmarks)

- (void)addNewBookmarkWithFile:(ACProjectFile *)file point:(id)point;
- (NSArray *)bookmarksForFile:(ACProjectFile *)file;

@end

@interface ACProjectFile ()
{
    NSFileWrapper *_contents;
}
@end

@implementation ACProjectFile

- (NSFileWrapper *)defaultContents
{
    NSFileWrapper *contents = [[NSFileWrapper alloc] initRegularFileWithContents:nil];
    contents.preferredFilename = self.name;
    return contents;
}

@end
