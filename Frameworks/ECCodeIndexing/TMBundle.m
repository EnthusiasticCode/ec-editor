//
//  TMBundle.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMBundle+Internal.h"
#import "TMSyntax+Internal.h"

static NSString * const _bundleExtension = @"tmbundle";
static NSString * const _syntaxDirectory = @"Syntaxes";

static NSURL *_bundleDirectory;

@implementation TMBundle

#pragma mark - Properties

+ (NSURL *)bundleDirectory
{
    return _bundleDirectory;
}

+ (void)setBundleDirectory:(NSURL *)bundleDirectory
{
    _bundleDirectory = bundleDirectory;
}

+ (void)loadAllBundles
{
    [TMSyntax loadAllSyntaxes];
}

+ (NSArray *)syntaxFileURLs
{
    NSMutableArray *syntaxFileURLs = [NSMutableArray array];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (NSURL *bundleURL in [fileManager contentsOfDirectoryAtURL:[self bundleDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
    {
        if (![[bundleURL pathExtension] isEqualToString:_bundleExtension])
            continue;
        for (NSURL *syntaxURL in [fileManager contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:_syntaxDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
            [syntaxFileURLs addObject:syntaxURL];
    }
    return syntaxFileURLs;
}

@end
