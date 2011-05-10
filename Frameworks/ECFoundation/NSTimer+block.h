//
//  NSTimer+block.h
//  CodeView
//
//  Created by Nicola Peduzzi on 10/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSTimer (NSTimer_block)

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti usingBlock:(void(^)(void))block repeats:(BOOL)yesOrNo;
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti usingBlock:(void(^)(void))block repeats:(BOOL)yesOrNo;

@end
