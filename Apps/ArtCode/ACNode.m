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

- (ACNode *)childWithName:(NSString *)name
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Node"];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"%K == %@", @"parent", self], [NSPredicate predicateWithFormat:@"%K == %@", @"name", name], nil]];
    [fetchRequest setPredicate:predicate];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    if (![results count])
        return nil;
    return [results objectAtIndex:0];
}

@end
