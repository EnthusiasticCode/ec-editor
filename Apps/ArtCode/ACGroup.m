//
//  ACGroup.m
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACGroup.h"
#import "ACNode.h"
#import "ACFile.h"
#import "ECArchive.h"
#import "ECURL.h"

@implementation ACGroup

@dynamic expanded;
@dynamic children;

@dynamic concrete;

- (NSURL *)fileURL
{
    NSURL *fileURL = self.parent.fileURL;
    if (self.concrete)
        fileURL = [fileURL URLByAppendingPathComponent:self.name];
    return fileURL;
}

- (void)setConcrete:(BOOL)concrete
{
    ECASSERT(NO); // NYI
}

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [[self mutableOrderedSetValueForKey:@"children"] moveObjectsAtIndexes:indexes toIndex:index];
}

- (void)exchangeChildAtIndex:(NSUInteger)fromIndex withChildAtIndex:(NSUInteger)toIndex
{
    [[self mutableOrderedSetValueForKey:@"children"] exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
}

- (void)importFileFromURL:(NSURL *)fileURL completionHandler:(void (^)(BOOL))completionHandler
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
        if (completionHandler)
            completionHandler(YES);
    }
    else
    {
        [fileManager createDirectoryAtURL:[self.fileURL URLByAppendingPathComponent:[fileURL lastPathComponent]] withIntermediateDirectories:YES attributes:nil error:NULL];
        ACGroup *childGroup = [self insertChildGroupWithName:[fileURL lastPathComponent] atIndex:NSNotFound];
        for (NSURL *fileInSubdirectoryURL in [fileManager contentsOfDirectoryAtURL:fileURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:NULL])
            [childGroup importFileFromURL:fileInSubdirectoryURL completionHandler:^(BOOL success) {
                if (!success)
                    ECASSERT(NO); // TODO: error handling
            }];
        if (completionHandler)
            completionHandler(YES);
    }
}

- (void)importFilesFromZIP:(NSURL *)ZIPFileURL completionHandler:(void (^)(BOOL))completionHandler
{
    NSURL *tempDirectory = [NSURL temporaryDirectory];
    ECArchive *archive = [[ECArchive alloc] initWithFileURL:ZIPFileURL];
    [archive extractToDirectory:tempDirectory completionHandler:^(BOOL success) {
        if (!success)
            ECASSERT(NO); // TODO: error handling
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:tempDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:NULL])
            [self importFileFromURL:fileURL completionHandler:^(BOOL success) {
                if (!success)
                    ECASSERT(NO); // TODO: error handling
                if (completionHandler)
                    completionHandler(YES);
            }];
    }];
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
