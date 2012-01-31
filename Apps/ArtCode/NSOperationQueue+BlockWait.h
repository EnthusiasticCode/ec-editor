//
//  NSOperationQueue+ECAdditions.h
//  ECFoundation
//
//  Created by Uri Baghin on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOperationQueue (BlockWait)

- (void)addOperationWithBlockWaitUntilFinished:(void (^)(void))block;

@end
