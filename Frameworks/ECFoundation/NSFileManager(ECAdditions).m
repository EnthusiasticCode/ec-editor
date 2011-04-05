//
//  NSFileManager-ECExtensions.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager(ECAdditions).h"

static BOOL isPackage(NSString *path)
{
    if ([[path pathExtension] isEqualToString:@"xcodeproj"])
        return YES;
    if ([[path pathExtension] isEqualToString:@"xcworkspace"])
        return YES;
    if ([[path pathExtension] isEqualToString:@"xcdatamodeld"])
        return YES;
    return NO;
}

static BOOL arrayIncludesExtensionOfPath(NSArray *extensions, NSString *path)
{
    NSString *pathExtension = [path pathExtension];
    for (NSString *extension in extensions)
        if ([extension isEqualToString:pathExtension])
            return YES;
    return NO;
}

@implementation NSFileManager (ECAdditions)

- (BOOL)fileExistsAndIsDirectoryAtPath:(NSString *)path
{
    BOOL isDirectory;
    BOOL exists = [self fileExistsAtPath:path isDirectory:&isDirectory];
    return (exists && isDirectory);
}

- (BOOL)fileExistsAndIsNotDirectoryAtPath:(NSString *)path
{
    BOOL isDirectory;
    BOOL exists = [self fileExistsAtPath:path isDirectory:&isDirectory];
    return (exists && !isDirectory);
}


- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withExtensions:(NSArray *)extensions options:(NSDirectoryEnumerationOptions)options skipFiles:(BOOL)skipFiles skipDirectories:(BOOL)skipDirectories error:(NSError **)error
{
    if (skipFiles && skipDirectories)
        return nil;
    NSArray *paths = [self contentsOfDirectoryAtPath:path error:error];
    if (!paths)
        return nil;
    NSMutableArray *contents = [NSMutableArray array];
    NSString *oldWorkingDirectory = [self currentDirectoryPath];
    [self changeCurrentDirectoryPath:path];
    for (NSString *content in paths)
    {
        if ((options & NSDirectoryEnumerationSkipsHiddenFiles) && [content characterAtIndex:0] == '.')
            continue;
        if (skipFiles || skipDirectories)
        {
            if (skipFiles && (isPackage(content) || [self fileExistsAndIsNotDirectoryAtPath:content]))
                continue;
            if (skipDirectories && [self fileExistsAndIsDirectoryAtPath:content] && !isPackage(content))
                continue;
        }
        if (extensions)
        {
            if (!arrayIncludesExtensionOfPath(extensions, content))
                continue;
        }
        [contents addObject:content];
    }
    [self changeCurrentDirectoryPath:oldWorkingDirectory];
    return contents;
}

- (NSArray *)subpathsOfDirectoryAtPath:(NSString *)path withExtensions:(NSArray *)extensions options:(NSDirectoryEnumerationOptions)options skipFiles:(BOOL)skipFiles skipDirectories:(BOOL)skipDirectories error:(NSError **)error
{
    if (skipFiles && skipDirectories)
        return nil;
    NSArray *paths = [self contentsOfDirectoryAtPath:path withExtensions:extensions options:options skipFiles:skipFiles skipDirectories:NO error:error];
    if (!paths)
        return nil;
    NSMutableArray *subpaths = [NSMutableArray arrayWithArray:paths];
    NSString *oldWorkingDirectory = [self currentDirectoryPath];
    [self changeCurrentDirectoryPath:path];
    for (NSString *subPath in paths)
    {
        if ((options & NSDirectoryEnumerationSkipsPackageDescendants) && isPackage(subPath))
            continue;
        for (NSString *subPathFromRecursing in [self subpathsOfDirectoryAtPath:subPath withExtensions:extensions options:options skipFiles:skipFiles skipDirectories:NO error:error])
            [subpaths addObject:[subPath stringByAppendingPathComponent:subPathFromRecursing]];
    }
    if (skipDirectories)
    {
        NSMutableIndexSet *directories = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < [subpaths count]; i++)
            if ([self fileExistsAndIsDirectoryAtPath:[subpaths objectAtIndex:i]])
                [directories addIndex:i];
        [subpaths removeObjectsAtIndexes:directories];
    }
    [self changeCurrentDirectoryPath:oldWorkingDirectory];
    return subpaths;
}

@end
