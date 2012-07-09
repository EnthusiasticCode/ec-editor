//
//  NSFileManager+Utilities.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 09/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+Utilities.h"
#import "NSURL+Utilities.h"

@implementation NSFileManager (Utilities)

- (NSURL *)_validDuplicateForURL:(NSURL *)url {
  NSUInteger i = 0;
  NSURL *result = url;
  while ([self fileExistsAtPath:result.path]) {
    result = [url URLByAddingDuplicateNumber:++i];
  }
  return result;
}

- (NSURL *)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL avoidReplace:(BOOL)shouldAvoidReplace error:(NSError *__autoreleasing *)error {
  if (shouldAvoidReplace) {
    dstURL = [self _validDuplicateForURL:dstURL];
  }
  return [self moveItemAtURL:srcURL toURL:dstURL error:error] ? dstURL : nil;
}

- (NSURL *)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL avoidReplace:(BOOL)shouldAvoidReplace error:(NSError *__autoreleasing *)error {
  if (shouldAvoidReplace) {
    dstURL = [self _validDuplicateForURL:dstURL];
  }
  return [self copyItemAtURL:srcURL toURL:dstURL error:error] ? dstURL : nil;
}

@end
