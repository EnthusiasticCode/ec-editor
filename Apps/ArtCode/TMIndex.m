//
//  CodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TMIndex+Internal.h"
#import "TMUnit+Internal.h"
#import "TMSyntaxNode.h"
#import "Cache.h"
#import "FileBuffer.h"

static NSMutableDictionary *_extensionClasses;

@interface TMIndex ()
{
    NSMutableDictionary *_extensions;
    Cache *_codeUnitCache;
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
    _codeUnitCache = [[Cache alloc] init];
    return self;
}

- (TMUnit *)codeUnitForFileBuffer:(FileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier
{
    if (!rootScopeIdentifier)
        rootScopeIdentifier = [[[TMSyntaxNode syntaxForFileBuffer:fileBuffer] attributes] objectForKey:TMSyntaxScopeIdentifierKey];
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
