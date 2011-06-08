//
//  ECTextRange.m
//  edit
//
//  Created by Nicola Peduzzi on 02/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextRange.h"


@implementation ECTextRange

#pragma mark Properties

@synthesize start, end;

- (NSRange)range
{
    NSUInteger s = start.index;
    NSUInteger e = end.index;
    if (s > e) 
        return (NSRange){e, s - e};
    return (NSRange){s, e - s};
}

- (CFRange)CFRange
{
    return (CFRange){(CFIndex)start.index, (CFIndex)(end.index - start.index)};
}

- (id)initWithStart:(ECTextPosition*)aStart end:(ECTextPosition*)aEnd
{
//    assert([aStart isKindOfClass:[ECTextPosition class]]);
//    assert([aEnd isKindOfClass:[ECTextPosition class]]);
    if((self = [super init]))
    {
        start = aStart;
        end = aEnd;
    }
    return self;
}

- (id)initWithRange:(NSRange)characterRange
{
    ECTextPosition *st = [[ECTextPosition alloc] initWithIndex:characterRange.location];
    ECTextPosition *en;
    
    if (characterRange.length == 0)
    {
        en = st;
    }
    else 
    {
        en = [[ECTextPosition alloc] initWithIndex:(characterRange.location + characterRange.length)];
    }
    
    self = [self initWithStart:st end:en];
    
    
    return self;
}


- (ECTextRange*)rangeIncludingPosition:(ECTextPosition*)p
{
    if ([p compare:start] == NSOrderedAscending)
        return [[[self class] alloc] initWithStart:p end:end];
    if ([p compare:end] == NSOrderedDescending)
        return [[[self class] alloc] initWithStart:start end:p];
    
    return self;
}

- (BOOL)includesPosition:(ECTextPosition*)p
{
    if ([start compare:p] == NSOrderedDescending)
        return NO;
    if ([end compare:p] == NSOrderedAscending)
        return NO;
    return YES;
}

- (id)copyWithZone:(NSZone *)z
{
    return self;
}

- (BOOL)isEmpty
{
    return ( [start compare:end] == NSOrderedSame );
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[self class]])
        return NO;
    
    ECTextRange *otherRange = (ECTextRange *)other;
    
    return ([start compare:otherRange.start] == NSOrderedSame) && ([end compare:otherRange.end] == NSOrderedSame);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@..%@", [start description], [end description]];
}

#pragma mark -
#pragma mark Class methods

+ (id)textRangeWithRange:(NSRange)range
{
    return [[self alloc] initWithRange:range];
}

@end
