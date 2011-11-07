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

@implementation TMCodeIndex

+ (void)load
{
    [ECCodeIndex registerExtension:self];
}

- (float)supportForScope:(NSString *)scope
{
    ECASSERT(scope);
    if (![TMSyntax syntaxWithScope:scope])
        return 0.0;
    return 0.3;
}

- (ECCodeUnit *)codeUnitWithIndex:(ECCodeIndex *)index forFile:(NSURL *)fileURL scope:(NSString *)scope
{
    ECASSERT(index && fileURL && scope);
    return [[TMCodeUnit alloc] initWithIndex:index file:fileURL scope:scope];
}

@end
