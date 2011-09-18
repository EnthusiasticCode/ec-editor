//
//  ACNode.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNode.h"
#import "ACGroup.h"
#import "ACFile.h"

#import "ECCodeUnit.h"
#import "ECCodeIndex.h"

#import "ECURL.h"
#import "ECArchive.h"

@implementation ACNode

@dynamic name;
@dynamic tag;
@dynamic expanded;
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

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [[self mutableOrderedSetValueForKey:@"children"] moveObjectsAtIndexes:indexes toIndex:index];
}

- (void)exchangeChildAtIndex:(NSUInteger)fromIndex withChildAtIndex:(NSUInteger)toIndex
{
    [[self mutableOrderedSetValueForKey:@"children"] exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
}

- (void)importFileFromURL:(NSURL *)fileURL
{
    // TODO: check for existing files, add import step to undo history
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    id isDirectoryValue;
    [fileURL getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:NULL];
    BOOL isDirectory = [isDirectoryValue boolValue];
    if (!isDirectory)
    {
        [fileManager copyItemAtURL:fileURL toURL:[self.fileURL URLByAppendingPathComponent:[fileURL lastPathComponent]] error:NULL];
        [self insertChildFileWithName:[fileURL lastPathComponent] atIndex:NSNotFound];
    }
    else
    {
        [fileManager createDirectoryAtURL:[self.fileURL URLByAppendingPathComponent:[fileURL lastPathComponent]] withIntermediateDirectories:YES attributes:nil error:NULL];
        ACGroup *childGroup = [self insertChildGroupWithName:[fileURL lastPathComponent] atIndex:NSNotFound];
        for (NSURL *fileInSubdirectoryURL in [fileManager contentsOfDirectoryAtURL:fileURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:NULL])
            [childGroup importFileFromURL:fileInSubdirectoryURL];
    }
}

- (void)importFilesFromZIP:(NSURL *)ZIPFileURL
{
    NSURL *tempDirectory = [NSURL temporaryDirectory];
    ECArchive *archive = [[ECArchive alloc] initWithFileURL:ZIPFileURL];
    [archive extractToDirectory:tempDirectory];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:tempDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:NULL])
        [self importFileFromURL:fileURL];
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

- (ACGroup *)insertChildGroupWithName:(NSString *)name atIndex:(NSUInteger)index
{
    ECASSERT(name);
    ECASSERT(![self childWithName:name]);
    ACGroup *childGroup = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:self.managedObjectContext];
    childGroup.parent = self;
    childGroup.name = name;
    return childGroup;
}

- (ACFile *)insertChildFileWithName:(NSString *)name atIndex:(NSUInteger)index
{
    ECASSERT(name);
    ECASSERT(![self childWithName:name]);
    ACFile *childFile = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:self.managedObjectContext];
    childFile.parent = self;
    childFile.name = name;
    return childFile;
}

@end
