//
//  NSMutableArray+Shuffling.h
//  edit
//
//  Created by Uri Baghin on 4/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Shuffling)
- (void)moveObjectAtIndex:(NSUInteger)idx1 toIndex:(NSUInteger)idx2;
@end
