//
//  NSString+Utilities.h
//  ArtCode
//
//  Created by Uri Baghin on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Utilities)

// If the string has a path extension it will add the number before it
- (NSString *)stringByAddingDuplicateNumber:(NSUInteger)number;

// Substitute / with ▸
- (NSString *)prettyPath;

@end
