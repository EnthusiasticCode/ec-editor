//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TMIndex+Internal.h"
#import "TMUnit+Internal.h"
#import "TMSyntax.h"
#import "ECCache.h"
#import "ECFileBuffer.h"

static NSMutableDictionary *_extensionClasses;

@interface TMIndex ()
{
    NSMutableDictionary *_extensions;
    ECCache *_codeUnitCache;
}
- (id)_codeUnitCacheKeyForFileURL:(NSURL *)fileURL scope:(NSString *)scope;
@end

@implementation TMIndex

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

- (TMUnit *)codeUnitForFileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier
{
    if (!rootScopeIdentifier)
        rootScopeIdentifier = [[TMSyntax syntaxForFileBuffer:fileBuffer] scopeIdentifier];
    id cacheKey = [self _codeUnitCacheKeyForFileURL:[fileBuffer fileURL] scope:rootScopeIdentifier];
    TMUnit *codeUnit = [_codeUnitCache objectForKey:cacheKey];
    if (!codeUnit)
    {
        codeUnit = [[TMUnit alloc] initWithIndex:self fileBuffer:fileBuffer rootScopeIdentifier:rootScopeIdentifier];
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
