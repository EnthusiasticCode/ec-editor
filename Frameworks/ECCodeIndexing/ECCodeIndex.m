//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeIndex+Subclass.h"
#import "TMSyntax.h"
#import <ECFoundation/ECCache.h>

static NSMutableArray *_extensionClasses;

@interface ECCodeIndex ()
{
    NSMutableArray *_extensions;
    NSMutableDictionary *_fileBuffers;
    ECCache *_codeUnitCache;
}
- (id)_codeUnitCacheKeyForFileURL:(NSURL *)fileURL scope:(NSString *)scope;
@end

@implementation ECCodeIndex

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
    _fileBuffers = [NSMutableDictionary dictionary];
    _codeUnitCache = [[ECCache alloc] init];
    return self;
}

- (void)setUnsavedContent:(NSString *)content forFile:(NSURL *)fileURL
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return;
    ECASSERT(fileURL);
    if (content)
        [_fileBuffers setObject:content forKey:fileURL];
    else
        [_fileBuffers removeObjectForKey:fileURL];
}

- (ECCodeUnit *)codeUnitForFile:(NSURL *)fileURL scope:(NSString *)scope
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    if (!scope)
        scope = [[TMSyntax syntaxForFile:fileURL] scope];
    id cacheKey = [self _codeUnitCacheKeyForFileURL:fileURL scope:scope];
    ECCodeUnit *codeUnit = [_codeUnitCache objectForKey:cacheKey];
    if (!codeUnit)
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if (![fileManager fileExistsAtPath:[fileURL path]])
            return nil;
        float winningSupport = 0.0;
        ECCodeIndex *winningExtension = nil;
        for (ECCodeIndex *extension in _extensions)
        {
            float support = [extension supportForScope:scope];
            if (support <= winningSupport)
                continue;
            winningSupport = support;
            winningExtension = extension;
        }
        ECASSERT(winningSupport >= 0.0 && winningSupport < 1.0);
        if (winningSupport == 0.0)
            return nil;
        codeUnit = [winningExtension codeUnitWithIndex:self forFile:fileURL scope:scope];
        [_codeUnitCache setObject:codeUnit forKey:[self _codeUnitCacheKeyForFileURL:fileURL scope:scope]];
    }
    return codeUnit;
}

- (id)_codeUnitCacheKeyForFileURL:(NSURL *)fileURL scope:(NSString *)scope
{
    ECASSERT(fileURL && [scope length]);
    return [NSString stringWithFormat:@"%@:%@", scope, [fileURL absoluteString]];
}

@end

@implementation ECCodeIndex (Internal)

+ (void)registerExtension:(Class)extensionClass
{
    if (self != [ECCodeIndex class])
        return;
    ECASSERT([extensionClass isSubclassOfClass:self]);
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableArray alloc] init];
    [_extensionClasses addObject:extensionClass];
}

- (NSString *)contentsForFile:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    NSString *contents = [_fileBuffers objectForKey:fileURL];
    if (!contents)
    {
        NSError *error = nil;
        contents = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
        if (error)
            contents = nil;
        else
            [_fileBuffers setObject:contents forKey:fileURL];
    }
    return contents;
}

@end
