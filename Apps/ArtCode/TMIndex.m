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
#import "WeakDictionary.h"
#import "CodeFile.h"

static NSMutableDictionary *_extensionClasses;

@interface TMIndex ()
{
    NSMutableDictionary *_extensions;
    WeakDictionary *_codeUnits;
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
    _codeUnits = [[WeakDictionary alloc] init];
    return self;
}

- (TMUnit *)codeUnitForCodeFile:(CodeFile *)codeFile rootScopeIdentifier:(NSString *)rootScopeIdentifier
{
    id cacheKey = [self _codeUnitCacheKeyForFileURL:[codeFile fileURL] scope:rootScopeIdentifier];
    TMUnit *codeUnit = [_codeUnits objectForKey:cacheKey];
    if (!codeUnit)
    {
        codeUnit = [[TMUnit alloc] initWithIndex:self codeFile:codeFile rootScopeIdentifier:rootScopeIdentifier];
        [_codeUnits setObject:codeUnit forKey:[self _codeUnitCacheKeyForFileURL:[codeFile fileURL] scope:rootScopeIdentifier]];
    }
    return codeUnit;
}

- (id)extensionForKey:(id)key
{
    return [_extensions objectForKey:key];
}

- (id)_codeUnitCacheKeyForFileURL:(NSURL *)fileURL scope:(NSString *)scope
{
    return [NSString stringWithFormat:@"%@:%@", scope, [fileURL absoluteString]];
}

@end
