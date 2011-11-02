//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeIndexSubclass.h"

static NSMutableArray *_extensionClasses;
static NSURL *_bundleDirectory;

@interface ECCodeIndex ()
{
    NSMutableArray *_extensions;
}
@end

@implementation ECCodeIndex

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

- (id)init
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return [super init];
    self = [super init];
    if (!self)
        return nil;
    _extensions = [NSMutableArray arrayWithCapacity:[_extensionClasses count]];
    for (Class extensionClass in _extensionClasses)
        [_extensions addObject:[[extensionClass alloc] init]];
    return self;
}

- (id)codeUnitImplementingProtocol:(Protocol *)protocol withFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:[fileURL path]])
        return nil;
    float winningSupport = 0.0;
    ECCodeIndex *winningExtension = nil;
    for (ECCodeIndex *extension in _extensions)
    {
        float support = [extension implementsProtocol:protocol forFile:fileURL language:language scope:scope];
        if (support <= winningSupport)
            continue;
        winningSupport = support;
        winningExtension = extension;
    }
    ECASSERT(winningSupport >= 0.0 && winningSupport < 1.0);
    if (winningSupport == 0.0)
        return nil;
    return [winningExtension codeUnitImplementingProtocol:protocol withFile:fileURL language:language scope:scope];;
}

@end

@implementation ECCodeIndex (Subclass)

+ (void)registerExtension:(Class)extensionClass
{
    if (self != [ECCodeIndex class])
        return;
    ECASSERT([extensionClass isSubclassOfClass:self]);
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableArray alloc] init];
    [_extensionClasses addObject:extensionClass];
}

- (float)implementsProtocol:(Protocol *)protocol forFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    return 0.0;
}

@end
