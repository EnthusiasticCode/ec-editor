// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OUEFTextSpan.h"

#import "OUIEditableFrame.h"

#import "OUEFTextPosition.h"





@implementation OUEFTextSpan

- initWithRange:(NSRange)characterRange generation:(NSUInteger)g editor:(OUIEditableFrame *)ed; // D.I.
{
    if ((self = [super initWithRange:characterRange generation:g]) != nil) {
        frame = [ed retain];
    }
    return self;
}

- (void)dealloc
{
    [frame release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[self class]])
        return NO;
    
    OUEFTextSpan *o = (OUEFTextSpan *)other;
    
    return ( frame == o->frame ) && ( [super isEqual:o] );
}

- (NSUInteger)hash;
{
    return [super hash] ^ ( ( (uintptr_t)frame ) >> 4 );
}


@end
