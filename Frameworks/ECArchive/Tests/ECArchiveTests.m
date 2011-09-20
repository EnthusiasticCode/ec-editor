//
//  ECArchiveTests.m
//  ECArchiveTests
//
//  Created by Uri Baghin on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Kiwi.h"

#import <ECArchive/ECArchive.h>

SPEC_BEGIN(ECArchiveSpec)

describe(@"An ECArchive", ^{
    it(@"should not be nil", ^{
        ECArchive* archive = [[ECArchive alloc] init];
        [[archive should] beNonNil];
        [archive release];
    });
});

SPEC_END