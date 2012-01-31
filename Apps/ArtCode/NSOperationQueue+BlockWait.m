//
//  NSOperationQueue+ECAdditions.m
//  ECFoundation
//
//  Created by Uri Baghin on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSOperationQueue+BlockWait.h"

@implementation NSOperationQueue (BlockWait)

- (void)addOperationWithBlockWaitUntilFinished:(void (^)(void))block
{
    [self addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:block]] waitUntilFinished:YES];
}

@end
