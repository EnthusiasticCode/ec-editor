//
//  NSURL+URLDuplicate.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 17/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSURL+URLDuplicate.h"

@implementation NSURL (URLDuplicate)

- (NSURL *)URLByAddingDuplicateNumber:(NSUInteger)number
{
    return [[self URLByDeletingLastPathComponent] URLByAppendingPathComponent:[[[self lastPathComponent] stringByDeletingPathExtension] stringByAppendingFormat:@" (%u).%@", number, [self pathExtension]]];
}

@end
