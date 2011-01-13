// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OUEFTextRange.h"

#import <OmniBase/rcsid.h>

#import "OUEFTextPosition.h"

RCS_ID("$Id$");

@implementation OUEFTextRange : UITextRange

- initWithStart:(OUEFTextPosition *)st end:(OUEFTextPosition *)en
{
    [super init];
    start = [st retain];
    end = [en retain];
    assert([st isKindOfClass:[OUEFTextPosition class]]);
    assert([en isKindOfClass:[OUEFTextPosition class]]);
    return self;
}

- initWithRange:(NSRange)characterRange generation:(NSUInteger)g
{
    OUEFTextPosition *st = [[OUEFTextPosition alloc] initWithIndex:characterRange.location];
    OUEFTextPosition *en;
    
    st.generation = g;
    
    if (characterRange.length == 0)
        en = [st retain];
    else {
        en = [[OUEFTextPosition alloc] initWithIndex:(characterRange.location + characterRange.length)];
        en.generation = g;
    }
    
    self = [self initWithStart:st end:en];
    
    [st release];
    [en release];
    
    return self;
}

- copyWithZone:(NSZone *)z
{
    if (NSShouldRetainWithZone(self, z)) {
        return [self retain];
    } else {
        OUEFTextPosition *st = [start copyWithZone:z];
        OUEFTextPosition *en = [end copyWithZone:z];
        
        OUEFTextRange *r = [[OUEFTextRange allocWithZone:z] initWithStart:st end:en];
        
        [st release];
        [en release];
        
        return r;
    }
}

- (void)dealloc
{
    [start release];
    [end release];
    [super dealloc];
}

@synthesize start, end;

- (BOOL)isEmpty
{
    return ( [start compare:end] == NSOrderedSame );
}

- (NSRange)range
{
    NSRange r;
    r.location = start.index;
    r.length = end.index - start.index;
    return r;
}

- (OUEFTextRange *)rangeIncludingPosition:(OUEFTextPosition *)p;
{
    if ([p compare:start] == NSOrderedAscending)
        return [[[[self class] alloc] initWithStart:p end:end] autorelease];
    if ([p compare:end] == NSOrderedDescending)
        return [[[[self class] alloc] initWithStart:start end:p] autorelease];
    
    return self;
}

- (BOOL)includesPosition:(OUEFTextPosition *)p;
{
    if ([start compare:p] == NSOrderedDescending)
        return NO;
    if ([end compare:p] == NSOrderedAscending)
        return NO;
    return YES;
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[self class]])
        return NO;
    
    OUEFTextRange *otherRange = (OUEFTextRange *)other;
    
    return ([start compare:otherRange.start] == NSOrderedSame) && ([end compare:otherRange.end] == NSOrderedSame);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@..%@", [start description], [end description]];
}

@end

