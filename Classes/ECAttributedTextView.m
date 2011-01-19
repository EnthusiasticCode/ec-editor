//
//  ECAttributedTextView.m
//  edit
//
//  Created by Uri Baghin on 1/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECAttributedTextView.h"


@implementation ECAttributedTextView


#pragma mark -
#pragma KVO

// Omnigroup didn't bother adding willChangeValueForKey: and didChangeValueForKey: in their beforeMutate and notifyAfterMutate static functions, so we added empty methods we can subclass and do it ourselves

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    BOOL automatic = NO;
    
    if ([theKey isEqualToString:@"attributedText"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

- (void)beforeMutate
{
    [self willChangeValueForKey:@"attributedText"];
}

- (void)notifyAfterMutate
{
    [self didChangeValueForKey:@"attributedText"];
}

@end
