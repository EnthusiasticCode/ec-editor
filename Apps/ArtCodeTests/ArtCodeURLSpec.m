//
//  ArtCodeURL.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/03/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi.h>
#import "ArtCodeURL.h"

SPEC_BEGIN(ArtCodeURLSpec)

describe(@"The ArtCodeURL class", ^{
  
  it(@"should create a valid project list URL", ^{
    NSURL *url = [ArtCodeURL artCodeURLWithProject:nil item:nil path:artCodeURLProjectListPath];
    [[[url absoluteString] should] equal:@"artcode://projects"];
  });
  
});

SPEC_END


