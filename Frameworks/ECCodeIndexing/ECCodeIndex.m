//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeIndex+Internal.h"
#import "TMSyntax.h"
#import <ECFoundation/ECCache.h>
#import <ECFoundation/ECFileBuffer.h>

static NSMutableDictionary *_extensionClasses;

@interface ECCodeIndex ()
{
    NSMutableDictionary *_extensions;
    ECCache *_codeUnitCache;
}
- (id)_codeUnitCacheKeyForFileURL:(NSURL *)fileURL scope:(NSString *)scope;
@end

@implementation ECCodeIndex

+ (void)registerExtension:(Class)extensionClass forKey:(id)key
{
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableDictionary alloc] init];
    [_extensionClasses setObject:extensionClass forKey:key];
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _extensions = [NSMutableDictionary dictionaryWithCapacity:[_extensionClasses count]];
    [_extensionClasses enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id extension = [[obj alloc] init];
        if (!extension)
            return;
        [_extensions setObject:extension forKey:key];
    }];
    _codeUnitCache = [[ECCache alloc] init];
    return self;
}

- (ECCodeUnit *)codeUnitForFileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier
{
    if (!rootScopeIdentifier)
        rootScopeIdentifier = [[TMSyntax syntaxForFileBuffer:fileBuffer] scopeIdentifier];
    id cacheKey = [self _codeUnitCacheKeyForFileURL:[fileBuffer fileURL] scope:rootScopeIdentifier];
    ECCodeUnit *codeUnit = [_codeUnitCache objectForKey:cacheKey];
    if (!codeUnit)
    {
        codeUnit = [[ECCodeUnit alloc] initWithIndex:self fileBuffer:fileBuffer rootScopeIdentifier:rootScopeIdentifier];
        [_codeUnitCache setObject:codeUnit forKey:[self _codeUnitCacheKeyForFileURL:[fileBuffer fileURL] scope:rootScopeIdentifier]];
    }
    return codeUnit;
}

- (id)extensionForKey:(id)key
{
    return [_extensions objectForKey:key];
}

- (id)_codeUnitCacheKeyForFileURL:(NSURL *)fileURL scope:(NSString *)scope
{
    ECASSERT(fileURL && [scope length]);
    return [NSString stringWithFormat:@"%@:%@", scope, [fileURL absoluteString]];
}

@end
