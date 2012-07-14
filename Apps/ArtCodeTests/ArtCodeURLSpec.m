//
//  ArtCodeLocation.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/03/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTests.h"
#import "ArtCodeLocation.h"

SPEC_BEGIN(ArtCodeLocationSpec)

describe(@"The ArtCodeLocation class", ^{
  
  it(@"should create a valid project list URL", ^{
    NSURL *url = [ArtCodeLocation ArtCodeLocationWithProject:nil item:nil path:ArtCodeLocationProjectListPath];
    [[[url absoluteString] should] equal:@"artcode://projects"];
  });
  
});

SPEC_END


