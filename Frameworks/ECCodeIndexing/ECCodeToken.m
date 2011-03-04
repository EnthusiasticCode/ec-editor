//
//  ECCodeToken.m
//  edit
//
//  Created by Uri Baghin on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeToken.h"
#import <ECAdditions/ECHashing.h>

@interface ECCodeToken ()
- (NSUInteger)computeHash;
@end

@implementation ECCodeToken

@synthesize kind = _kind;
@synthesize spelling = _spelling;
@synthesize fileURL = _fileURL;
@synthesize offset = _offset;
@synthesize extent = _extent;

- (void)dealloc
{
    [_spelling release];
    [_fileURL release];
    [super dealloc];
}

- (id)initWithKind:(ECCodeTokenKind)kind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger )offset extent:(NSRange)extent
{
    self = [super init];
    if (self)
    {
        _kind = kind;
        _spelling = [spelling copy];
        _fileURL = [fileURL copy];
        _offset = offset;
        _extent = extent;
        _hash = [self computeHash];
    }
    return self;
}

+ (id)tokenWithKind:(ECCodeTokenKind)kind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger )offset extent:(NSRange)extent
{
    id token = [self alloc];
    token = [token initWithKind:kind spelling:spelling fileURL:fileURL offset:offset extent:extent];
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
    NSUInteger propertyHashes[6] = { _kind, [_spelling hash], [_fileURL hash], _offset, _extent.location, _extent.length };
    return ECHashNSUIntegers(propertyHashes, propertyCount);
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECCodeToken *otherToken = other;
    if (!otherToken.kind == _kind)
        return NO;
    if (![otherToken.spelling isEqual:_spelling])
        return NO;
    if (![otherToken.fileURL isEqual:_fileURL])
        return NO;
    if (!otherToken.offset == _offset)
        return NO;
    NSRange otherTokenExtent = otherToken.extent;
    if (!otherTokenExtent.location == _extent.location)
        return NO;
    if (!otherTokenExtent.length == _extent.length)
        return NO;
    return YES;
}

@end
