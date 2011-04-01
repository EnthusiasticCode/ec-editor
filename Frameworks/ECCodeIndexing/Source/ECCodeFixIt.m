//
//  ECCodeFixIt.m
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeFixIt.h"
#import <ECFoundation/ECHashing.h>

@interface ECCodeFixIt ()
- (NSUInteger)computeHash;
@end

@implementation ECCodeFixIt

@synthesize string = _string;
@synthesize file = _file;
@synthesize replacementRange = _replacementRange;

- (void)dealloc
{
    [_string release];
    [_file release];
    [super dealloc];
}

- (id)initWithString:(NSString *)string file:(NSString *)file replacementRange:(NSRange)replacementRange
{
    self = [super init];
    if (self)
    {
        _string = [string copy];
        _file = [file copy];
        _replacementRange = replacementRange;
        _hash = [self computeHash];
    }
    return self;
}

+ (id)fixItWithString:(NSString *)string file:(NSString *)file replacementRange:(NSRange)replacementRange
{
    id fixIt = [self alloc];
    fixIt = [fixIt initWithString:string file:file replacementRange:replacementRange];
    return [fixIt autorelease];
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
    const NSUInteger propertyCount = 4;
    NSUInteger propertyHashes[4] = { [_string hash], [_file hash], _replacementRange.location, _replacementRange.length };
    return ECHashNSUIntegers(propertyHashes, propertyCount);
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECCodeFixIt *otherFixIt = other;
    NSRange otherFixItReplacementRange = otherFixIt.replacementRange;
    if (!otherFixItReplacementRange.location == _replacementRange.location)
        return NO;
    if (!otherFixItReplacementRange.length == _replacementRange.length)
        return NO;
    if (_string || otherFixIt.string)
        if (![otherFixIt.string isEqual:_string])
            return NO;
    if (_file || otherFixIt.file)
        if (![otherFixIt.file isEqual:_file])
            return NO;
    return YES;
}

@end
