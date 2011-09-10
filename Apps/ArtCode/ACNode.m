//
//  ACNode.m
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNode.h"
#import "ACGroup.h"

#import "ECCodeUnit.h"
#import "ECCodeIndex.h"

@implementation ACNode

@dynamic name;
@dynamic tag;
@dynamic parent;

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

+ (NSSet *)keyPathsForValuesAffectingFileURL {
    return [NSSet setWithObjects:@"name", @"parent.fileURL", @"concrete", nil];
}

- (NSString *)nodeType
{
    return [self.entity name];
}

@end
