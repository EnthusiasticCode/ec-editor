//
//  TMBundle.m
//  CodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMBundle.h"
#import "TMSyntax.h"

static NSString * const _bundleExtension = @"tmbundle";

static NSURL *_bundleDirectory;
static NSArray *_bundleURLs;

@interface TMBundle ()
{
    NSURL *_bundleURL;
}
@end

@implementation TMBundle

#pragma mark - Properties

+ (NSURL *)bundleDirectory
{
    if (!_bundleDirectory)
        _bundleDirectory = [[NSBundle mainBundle] bundleURL];
    return _bundleDirectory;
}

+ (void)setBundleDirectory:(NSURL *)bundleDirectory
{
    _bundleDirectory = bundleDirectory;
}

+ (NSArray *)bundleURLs
{
    if (!_bundleURLs)
    {
        NSMutableArray *bundleURLs = [NSMutableArray array];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *bundleURL in [fileManager contentsOfDirectoryAtURL:[self bundleDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
        {
            if (![[bundleURL pathExtension] isEqualToString:_bundleExtension])
                continue;
            [bundleURLs addObject:bundleURL];
        }
        _bundleURLs = [bundleURLs copy];
    }
    return _bundleURLs;
}

@end
