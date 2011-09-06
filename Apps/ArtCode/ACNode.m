//
//  ACNode.m
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNode.h"
#import "ACGroup.h"
#import "ACURL.h"

@implementation ACNode

@dynamic name;
@dynamic path;
@dynamic tag;
@dynamic parent;

- (NSURL *)URL
{
    return [self.parent.URL URLByAppendingPathComponent:self.name];
}

- (NSURL *)fileURL
{
    if (!self.concrete)
        return nil;
    return [self.parent.fileURL URLByAppendingPathComponent:self.name];
}

- (BOOL)isConcrete
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    return [fileManager fileExistsAtPath:[[self.parent.fileURL URLByAppendingPathComponent:self.name] path]];
}

+ (NSSet *)keyPathsForValuesAffectingURL {
    return [NSSet setWithObjects:@"name", @"parent.URL", nil];
}

+ (NSSet *)keyPathsForValuesAffectingFileURL {
    return [NSSet setWithObjects:@"name", @"parent.fileURL", @"concrete", nil];
}

- (NSString *)nodeType
{
    return [self.entity name];
}

@end
