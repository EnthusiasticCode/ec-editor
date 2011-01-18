//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 15/01/11.
//  Copyright 2011 Enthusiastic Code. All rights reserved.
//

#import "ECCodeView.h"

@implementation ECCodeView


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
