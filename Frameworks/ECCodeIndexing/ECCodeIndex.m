//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"

static NSMutableArray *_extensionClasses;
static NSURL *_bundleDirectory;

@interface ECCodeIndex ()
@property (nonatomic, strong, readonly) NSMutableDictionary *extensionsByExtensionClass;
- (ECCodeIndex *)extensionForClass:(Class)extensionClass;
@end

@implementation ECCodeIndex

@synthesize extensionsByExtensionClass = _extensionsByExtensionClass;

- (NSMutableDictionary *)extensionsByExtensionClass
{
    if (!_extensionsByExtensionClass)
        _extensionsByExtensionClass = [[NSMutableDictionary alloc] init];
    return _extensionsByExtensionClass;
}

+ (NSURL *)bundleDirectory
{
    if (self != [ECCodeIndex class])
        return [ECCodeIndex bundleDirectory];
    return _bundleDirectory;
}

+ (void)setBundleDirectory:(NSURL *)bundleDirectory
{
    if (self != [ECCodeIndex class])
        return [ECCodeIndex setBundleDirectory:bundleDirectory];
    _bundleDirectory = bundleDirectory;
}

+ (void)registerExtension:(Class)extensionClass
{
    if (self != [ECCodeIndex class])
        return;
    ECASSERT([extensionClass isSubclassOfClass:self]);
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableArray alloc] init];
    [_extensionClasses addObject:extensionClass];
}

+ (float)implementsProtocol:(Protocol *)protocol forFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    if (self != [ECCodeIndex class])
        return 0.0;
    float support = 0.0;
    for (Class extensionClass in _extensionClasses)
        support = MAX([extensionClass implementsProtocol:protocol forFile:fileURL language:language scope:scope], support);
    return support;
}

- (id)codeUnitImplementingProtocol:(Protocol *)protocol withFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    if (self != [ECCodeIndex class])
        return nil;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    __block id<ECCodeUnit>codeUnit = nil;
    [fileCoordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink | NSFileCoordinatorReadingWithoutChanges error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if (![fileManager fileExistsAtPath:[newURL path]])
            return;
        float winningSupport = 0.0;
        Class winningExtensionClass;
        for (Class extensionClass in _extensionClasses)
        {
            float support = [extensionClass implementsProtocol:protocol forFile:fileURL language:language scope:scope];
            if (support <= winningSupport)
                continue;
            winningSupport = support;
            winningExtensionClass = extensionClass;
        }
        if (winningSupport == 0.0)
            return;
        ECCodeIndex *extension = [self extensionForClass:winningExtensionClass];
        codeUnit = [extension codeUnitImplementingProtocol:protocol withFile:fileURL language:language scope:scope];
    }];
    return codeUnit;
}

- (ECCodeIndex *)extensionForClass:(Class)extensionClass
{
    NSString *className = NSStringFromClass(extensionClass);
    ECCodeIndex *extension = [self.extensionsByExtensionClass objectForKey:className];
    if (!extension)
    {
        extension = [[extensionClass alloc] init];
        [self.extensionsByExtensionClass setObject:extension forKey:className];
    }
    return extension;
}
@end
