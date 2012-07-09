//
//  NSString+UUID.m
//  ArtCode
//
//  Created by Uri Baghin on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+UUID.h"


@implementation NSString (UUID)

- (id)initWithGeneratedUUID {
  CFUUIDRef uuid = CFUUIDCreate(NULL);
  NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  CFRelease(uuid);
  return uuidString;
}

@end
