//
//  RACTableViewDataSource.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "RACTableViewDataSource.h"

@implementation RACTableViewDataSource

- (instancetype)initWithSubscribable:(id<RACSubscribable>)subscribable {
  self = [super init];
  if (!self) {
    return nil;
  }
  [self rac_deriveProperty:RAC_KEYPATH_SELF(items) from:subscribable];
  return self;
}

@end
