//
//  ECCodeCompletionResult.m
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCompletionResult.h"
#import <ECFoundation/ECHashing.h>
#import "ECCodeIndexing+PrivateInitializers.h"

@interface ECCodeCompletionResult ()
{
    NSUInteger _hash;
}
- (NSUInteger)computeHash;
@end

@implementation ECCodeCompletionResult

@synthesize cursorKind = _cursorKind;
@synthesize completionString = _completionString;


- (id)initWithCursorKind:(ECCodeCursorKind)cursorKind completionString:(ECCodeCompletionString *)completionString
{
    self = [super init];
    if (self)
    {
        _cursorKind = cursorKind;
        _completionString = completionString;
        _hash = [self computeHash];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
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
