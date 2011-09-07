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
#import "ACURL.h"

@implementation ACProject

@dynamic bookmarks;
@dynamic tabs;

@synthesize URL = _URL;
@synthesize fileURL = _fileURL;

- (NSString *)name
{
    return [[self.URL lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)setName:(NSString *)name
{
    ECASSERT(name);
    self.URL = [[self.URL URLByDeletingLastPathComponent] URLByAppendingPathComponent:name];
}

+ (NSSet *)keyPathsForValuesAffectingName
{
    return [NSSet setWithObject:@"URL"];
}

+ (NSSet *)keyPathsForValuesAffectingURL {
    return [NSSet set];
}

+ (NSSet *)keyPathsForValuesAffectingFileURL {
    return [NSSet set];
}

- (ACNode *)nodeWithURL:(NSURL *)URL
{
    if ([URL isEqual:self.URL])
        return self;
    if (![URL isDescendantOfACURL:self.URL])
        return nil;
    NSArray *pathComponents = [URL pathComponents];
    NSUInteger pathComponentsCount = [pathComponents count];
    ACNode *node = self;
    for (NSUInteger currentPathComponent = 2; currentPathComponent < pathComponentsCount; ++currentPathComponent)
        node = [node childWithName:[pathComponents objectAtIndex:currentPathComponent]];
    return node;
}

@end
