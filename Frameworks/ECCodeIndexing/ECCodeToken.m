//
//  ECCodeToken.m
//  edit
//
//  Created by Uri Baghin on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeToken.h"
#import <ECFoundation/ECHashing.h>

@interface ECCodeToken ()
{
    NSUInteger _hash;
}
- (NSUInteger)computeHash;
@end

@implementation ECCodeToken

@synthesize kind = _kind;
@synthesize spelling = _spelling;
@synthesize file = _file;
@synthesize offset = _offset;
@synthesize extent = _extent;
@synthesize cursor = cursor_;

- (void)dealloc
{
    [_spelling release];
    [_file release];
    [cursor_ release];
    [super dealloc];
}

- (id)initWithKind:(ECCodeTokenKind)kind spelling:(NSString *)spelling file:(NSString *)file offset:(NSUInteger )offset extent:(NSRange)extent cursor:(ECCodeCursor *)cursor
{
    self = [super init];
    if (self)
    {
        _kind = kind;
        _spelling = [spelling copy];
        _file = [file copy];
        _offset = offset;
        _extent = extent;
        cursor_ = [cursor retain];
        _hash = [self computeHash];
    }
    return self;
}

+ (id)tokenWithKind:(ECCodeTokenKind)kind spelling:(NSString *)spelling file:(NSString *)file offset:(NSUInteger )offset extent:(NSRange)extent cursor:(ECCodeCursor *)cursor
{
    id token = [self alloc];
    token = [token initWithKind:kind spelling:spelling file:file offset:offset extent:extent cursor:cursor];
    return [token autorelease];
}

- (NSString *)description
{
    return self.spelling;
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
    const NSUInteger propertyCount = 6;
    NSUInteger propertyHashes[6] = { _kind, [_spelling hash], [_file hash], _offset, _extent.location, _extent.length };
    return ECHashNSUIntegers(propertyHashes, propertyCount);
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECCodeToken *otherToken = other;
    if (!otherToken.offset == _offset)
        return NO;
    NSRange otherTokenExtent = otherToken.extent;
    if (!otherTokenExtent.location == _extent.location)
        return NO;
    if (!otherTokenExtent.length == _extent.length)
        return NO;
    if (!otherToken.kind == _kind)
        return NO;
    if (_spelling || otherToken.spelling)
        if (![otherToken.spelling isEqual:_spelling])
            return NO;
    if (_file || otherToken.file)
        if (![otherToken.file isEqual:_file])
            return NO;
    return YES;
}

@end
