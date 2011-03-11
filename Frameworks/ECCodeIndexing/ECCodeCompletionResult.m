//
//  ECCodeCompletionResult.m
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCompletionResult.h"
#import <ECFoundation/ECHashing.h>

@interface ECCodeCompletionResult ()
- (NSUInteger)computeHash;
@end

@implementation ECCodeCompletionResult

@synthesize cursorKind = _cursorKind;
@synthesize completionString = _completionString;

- (void)dealloc
{
    [_completionString release];
    [super dealloc];
}

- (id)initWithCursorKind:(int)cursorKind completionString:(ECCodeCompletionString *)completionString
{
    self = [super init];
    if (self)
    {
        _cursorKind = cursorKind;
        _completionString = [completionString copy];
        _hash = [self computeHash];
    }
    return self;
}

- (id)initWithCompletionString:(ECCodeCompletionString *)completionString
{
    return [self initWithCursorKind:0 completionString:completionString];
}

+ (id)resultWithCursorKind:(int)cursorKind completionString:(ECCodeCompletionString *)completionString
{
    id result = [self alloc];
    result = [result initWithCursorKind:cursorKind completionString:completionString];
    return [result autorelease];
}

+ (id)resultWithCompletionString:(ECCodeCompletionString *)completionString
{
    return [self resultWithCursorKind:0 completionString:completionString];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (NSUInteger)hash
{
    return _hash;
}

- (NSUInteger)computeHash
{
    const NSUInteger propertyCount = 2;
    NSUInteger propertyHashes[2] = { _cursorKind, [_completionString hash] };
    return ECHashNSUIntegers(propertyHashes, propertyCount);
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECCodeCompletionResult *otherResult = other;
    if (!otherResult.cursorKind == _cursorKind)
        return NO;
    if (_completionString || otherResult.completionString)
        if (![otherResult.completionString isEqual:_completionString])
            return NO;
    return YES;
}

@end
