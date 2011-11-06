//
//  TMCodeIndex.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex+Subclass.h"
#import "TMCodeIndex.h"
#import "TMCodeUnit.h"
#import "TMSyntax.h"
#import <ECFoundation/ECCache.h>

@interface TMCodeIndex ()
{
    ECCache *_codeUnitCache;
}
- (id)_codeUnitCacheKeyForFileURL:(NSURL *)fileURL syntax:(TMSyntax *)syntax;
@end

@implementation TMCodeIndex

+ (void)load
{
    [ECCodeIndex registerExtension:self];
}

- (float)supportForFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    ECASSERT(fileURL);
    if (![TMSyntax syntaxForFile:fileURL language:language scope:scope])
        return 0.0;
    return 0.3;
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _codeUnitCache = [[ECCache alloc] init];
    return self;
}

- (ECCodeUnit *)codeUnitForFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    ECASSERT(fileURL);
    TMSyntax *syntax = [TMSyntax syntaxForFile:fileURL language:language scope:scope];
    id cacheKey = [self _codeUnitCacheKeyForFileURL:fileURL syntax:syntax];
    TMCodeUnit *codeUnit = [_codeUnitCache objectForKey:cacheKey];
    if (!codeUnit)
    {
        codeUnit = [[TMCodeUnit alloc] initWithIndex:self fileURL:fileURL syntax:syntax];
        [_codeUnitCache setObject:codeUnit forKey:cacheKey];
    }
    return codeUnit;
}

- (id)_codeUnitCacheKeyForFileURL:(NSURL *)fileURL syntax:(TMSyntax *)syntax
{
    return [NSString stringWithFormat:@"%@:%@", [syntax name], [fileURL absoluteString]];
}

@end
