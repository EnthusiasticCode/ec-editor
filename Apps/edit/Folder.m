//
//  Folder.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <ECFoundation/NSFileManager(ECAdditions).h>
#import "Folder.h"
#import "File.h"
#import "Folder.h"
#import "Group.h"
#import "Project.h"

@implementation Folder
@dynamic collapsed;
@dynamic groups;
@dynamic project;
@dynamic files;
@dynamic subfolders;
@dynamic parent;

- (void)addGroupsObject:(Group *)value
{
    [self addObject:value forOrderedKey:@"groups"];
}

- (void)removeGroupsObject:(Group *)value
{
    [self removeObject:value forOrderedKey:@"groups"];
}

- (void)addGroups:(NSSet *)value
{
    [self addObjects:value forOrderedKey:@"groups"];
}

- (void)removeGroups:(NSSet *)value
{
    [self removeObjects:value forOrderedKey:@"groups"];
}

- (NSMutableArray *)orderedGroups
{
    return [self mutableArrayValueForOrderedKey:@"groups"];
}

- (void)scanForNewFiles
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
    NSArray *filePaths = [fileManager contentsOfDirectoryAtPath:self.path withExtensions:nil options:options skipFiles:NO skipDirectories:YES error:NULL];
    NSMutableDictionary *fileDictionary = [NSMutableDictionary dictionary];
    for (File *file in self.files)
        [fileDictionary setObject:file forKey:file.name];
    NSMutableArray *newFiles = [NSMutableArray array];
    for (NSString *filePath in filePaths)
        if (![fileDictionary objectForKey:filePath])
        {
            File *file = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:[self managedObjectContext]];
            file.folder = self;
            file.name = filePath;
            file.path = [self.path stringByAppendingPathComponent:filePath];
            file.project = self.project;
            [newFiles addObject:file];
        }
    if ([newFiles count])
    {
        Group *newGroup = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:[self managedObjectContext]];
        newGroup.area = self;
        [newGroup addItems:[NSSet setWithArray:newFiles]];
    }
    NSArray *subfolderPaths = [fileManager contentsOfDirectoryAtPath:self.path withExtensions:nil options:options skipFiles:YES skipDirectories:NO error:NULL];
    NSMutableDictionary *subfolderDictionary = [NSMutableDictionary dictionary];
    for (Folder *folder in self.subfolders)
        [subfolderDictionary setObject:folder forKey:folder.name];
    for (NSString *subfolderPath in subfolderPaths)
        if (![subfolderDictionary objectForKey:subfolderPath])
        {
            Folder *folder = [NSEntityDescription insertNewObjectForEntityForName:@"Folder" inManagedObjectContext:[self managedObjectContext]];
            folder.parent = self;
            folder.name = subfolderPath;
            folder.path = [self.path stringByAppendingPathComponent:subfolderPath];
            folder.project = self.project;
        }
    for (Folder *folder in self.subfolders)
        [folder scanForNewFiles];
    [fileManager release];
}

@end
