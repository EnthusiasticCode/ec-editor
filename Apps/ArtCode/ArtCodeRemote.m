//
//  ArtCodeRemote.m
//  ArtCode
//
//  Created by Uri Baghin on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeRemote.h"

@implementation ArtCodeRemote

+ (NSSet *)keyPathsForValuesAffectingUrl {
  return [NSSet setWithObjects:@"scheme", @"user", @"host", @"port", nil];
}

- (NSURL *)url {
  NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://", self.scheme];
  if (self.user) {
    [urlString appendFormat:@"%@@", self.user];
  }
  [urlString appendString:self.host];
  if (self.port) {
    [urlString appendFormat:@":%u", self.portValue];
  }
  return [NSURL URLWithString:urlString];
}

@end
