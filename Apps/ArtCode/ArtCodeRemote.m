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
  return [NSSet setWithObject:@"urlString"];
}

- (NSURL *)url {
  return [NSURL URLWithString:self.urlString];
}

- (void)setUrl:(NSURL *)url {
  self.urlString = url.absoluteString;
}

@end
