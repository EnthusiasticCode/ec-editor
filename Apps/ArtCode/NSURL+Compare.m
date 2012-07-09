//
//  NSURL+Compare.m
//  ArtCode
//
//  Created by Uri Baghin on 1/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSURL+Compare.h"

@implementation NSURL (Compare)

- (NSComparisonResult)compare:(NSURL *)other
{
  return [[self path] compare:[other path]];
}

@end
