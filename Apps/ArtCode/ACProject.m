//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACBookmark.h"
#import "ACTab.h"

@implementation ACProject

@dynamic bookmarks;
@dynamic tabs;

@synthesize fileURL = _fileURL;

- (NSString *)name
{
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

+ (NSSet *)keyPathsForValuesAffectingFileURL {
    return [NSSet set];
}

@end
