//
//  ECFoundationTests.m
//  ECFoundationTests
//
//  Created by Uri Baghin on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Kiwi.h"
#import <ECFoundation/NSTimer+block.h>
#import <ECFoundation/ECPatriciaTrie.h>

SPEC_BEGIN(ECFoundationTests);

describe(@"An NSTimer", ^{
    context(@"created with a block", ^{
        it(@"should not be nil", ^{
            [[[NSTimer timerWithTimeInterval:0.1 usingBlock:nil repeats:NO] should] beNonNil];
        });
        it(@"should call the block", ^{
            id mockTarget = [NSObject mock];
            [NSTimer scheduledTimerWithTimeInterval:1.0 usingBlock:^(NSTimer *timer) {
                [mockTarget performSelector:@selector(timer)];
            } repeats:NO];
            [[mockTarget shouldEventuallyBeforeTimingOutAfter(3.0)] receive:@selector(timer)];
        });
    });
});

describe(@"An ECPatriciaTrie", ^{
    context(@"newly created", ^{
        __block ECPatriciaTrie *trie;
        beforeEach(^{
            trie = [[ECPatriciaTrie alloc] init];
        });
        afterEach(^{
            trie = nil;
        });
        it(@"should be empty", ^{
            [[theValue([trie count]) should] beZero];
        });
    });
});

SPEC_END;