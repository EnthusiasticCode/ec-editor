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
static NSString * const _syntaxDirectory = @"Syntaxes";

static NSURL *_bundleDirectory;
static NSArray *_allBundles;

@interface TMBundle ()
{
    NSURL *_bundleURL;
    NSArray *_syntaxes;
}
- (id)_initWithBundleURL:(NSURL *)bundleURL;
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

+ (NSArray *)allBundles
{
    if (!_allBundles)
    {
        NSMutableArray *allBundles = [NSMutableArray array];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *bundleURL in [fileManager contentsOfDirectoryAtURL:[self bundleDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
        {
            if (![[bundleURL pathExtension] isEqualToString:_bundleExtension])
                continue;
            [allBundles addObject:[[self alloc] _initWithBundleURL:bundleURL]];
        }
        _allBundles = [allBundles copy];
    }
    return _allBundles;
}

- (id)_initWithBundleURL:(NSURL *)bundleURL
{
    ECASSERT(bundleURL);
    self = [super init];
    if (!self)
        return nil;
    _bundleURL = bundleURL;
    return self;
}

- (NSString *)name
{
    return [[_bundleURL lastPathComponent] stringByDeletingPathExtension];
}

- (NSArray *)syntaxes
{
    if (!_syntaxes)
    {
        NSMutableArray *syntaxes = [NSMutableArray array];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *syntaxURL in [fileManager contentsOfDirectoryAtURL:[_bundleURL URLByAppendingPathComponent:_syntaxDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
        {
            TMSyntax *syntax = [[TMSyntax alloc] initWithFileURL:syntaxURL];
            if (!syntax)
                continue;
            [syntax endContentAccess];
            [syntaxes addObject:syntax];
        }
        _syntaxes = [syntaxes copy];
    }
    return _syntaxes;
}

@end
