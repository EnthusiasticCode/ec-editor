//
//  TMToken.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMToken.h"
#import "TMScope.h"

@interface TMToken ()
{
    NSString *_containingString;
    NSRange _range;
    TMScope *_scope;
}
@end

@implementation TMToken

- (id)initWithContainingString:(NSString *)containingString range:(NSRange)range scope:(TMScope *)scope
{
    self = [super init];
    if (!self)
        return nil;
    _containingString = containingString;
    _range = range;
    _scope = scope;
    return self;
}

#pragma mark ECCodeToken

- (NSRange)range
{
    return _range;
}

- (NSString *)spelling
{
    return [_containingString substringWithRange:_range];
}

- (CXTokenKind)kind
{
    if ([_scope.identifier hasPrefix:@"comment"])
        return CXToken_Comment;
    else if ([_scope.identifier hasPrefix:@"keyword"])
        return CXToken_Keyword;
    else if ([_scope.identifier hasPrefix:@"string"])
        return CXToken_Literal;
    else if ([_scope.identifier hasPrefix:@"punctuation"])
        return CXToken_Punctuation;
    else
        return CXToken_Identifier;
}

- (NSString *)scopeIdentifier
{
    return _scope.identifier;
}

- (NSArray *)scopeIdentifiersStack
{
    return [_scope identifiersStack];
}

- (id<ECCodeCursor>)cursor
{
    return nil;
}

@end
