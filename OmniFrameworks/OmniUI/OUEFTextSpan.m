// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OUEFTextSpan.h"

#import <CoreText/CoreText.h>
#import <OmniQuartz/OQColor.h>
#import <OmniAppKit/OAFontDescriptor.h>
#import <OmniAppKit/OAParagraphStyle.h>
#import <OmniAppKit/OATextAttributes.h>
#import <OmniUI/OUIEditableFrame.h>
#import <OmniBase/rcsid.h>

#import "OUEFTextPosition.h"


RCS_ID("$Id$");


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
