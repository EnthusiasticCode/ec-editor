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
#import <ECFoundation/ECAttributedUTF8FileBuffer.h>

static NSMutableArray *_extensionClasses;

@interface ECCodeIndex ()
{
    NSMutableArray *_extensions;
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
    _codeUnitCache = [[ECCache alloc] init];
    return self;
}

- (ECCodeUnit *)codeUnitForFileBuffer:(ECFileBuffer *)fileBuffer scope:(NSString *)scope
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    if (!scope)
        scope = [[TMSyntax syntaxForFileBuffer:fileBuffer] scope];
    id cacheKey = [self _codeUnitCacheKeyForFileURL:[fileBuffer fileURL] scope:scope];
    ECCodeUnit *codeUnit = [_codeUnitCache objectForKey:cacheKey];
    if (!codeUnit)
    {
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
        codeUnit = [winningExtension codeUnitWithIndex:self forFileBuffer:fileBuffer scope:scope];
        [_codeUnitCache setObject:codeUnit forKey:[self _codeUnitCacheKeyForFileURL:[fileBuffer fileURL] scope:scope]];
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

@end
