//
//  NSString+Utilities.m
//  ArtCode
//
//  Created by Uri Baghin on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)

- (NSString *)stringByAddingDuplicateNumber:(NSUInteger)number {
  NSString *string = self;
  NSString *pathExtension = string.pathExtension;
  if (pathExtension) {
    string = string.stringByDeletingPathExtension;
  }
  string = [string stringByAppendingFormat:@" (%u)", number];
  if (pathExtension) {
    string = [string stringByAppendingPathExtension:pathExtension];
  }
  return string;
}

- (NSString *)prettyPath {
  return [self stringByReplacingOccurrencesOfString:@"/" withString:@" ▸ "];
}

@end
