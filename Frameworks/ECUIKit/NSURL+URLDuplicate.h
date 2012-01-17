//
//  NSURL+URLDuplicate.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 17/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (URLDuplicate)

/// Create a new URL that has the given number before the URL extension in brackets.
/// /url/to/file.ext become /url/to/file (number).ext
- (NSURL *)URLByAddingDuplicateNumber:(NSUInteger)number;

@end
