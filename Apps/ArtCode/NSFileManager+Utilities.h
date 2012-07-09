//
//  NSFileManager+Utilities.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 09/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Utilities)

/// Move and copy a file avoiding replace by modifiying the the destination URL with a number.
/// Returns the actual destination URL on success or nil.
- (NSURL *)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL avoidReplace:(BOOL)shouldAvoidReplace error:(NSError *__autoreleasing *)error;
- (NSURL *)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL avoidReplace:(BOOL)shouldAvoidReplace error:(NSError *__autoreleasing *)error;

@end
