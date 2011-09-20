//
//  ECUIKitTests.m
//  ECUIKitTests
//
//  Created by Uri Baghin on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Kiwi.h"
#import <ECUIKit/ECRectSet.h>

SPEC_BEGIN(ECUIKitTests)

describe(@"An ECRectSet", ^{
    context(@"newly created", ^{
        __block ECRectSet *rectSet;
        beforeEach(^{
            rectSet = [[ECRectSet alloc] init];
        });
        afterEach(^{
            [rectSet release];
        });
        it(@"should have no rects", ^{
            [[theValue([rectSet count]) should] beZero];
        });
    });
});

SPEC_END