//
//  NSTimer+block.h
//  CodeView
//
//  Created by Nicola Peduzzi on 10/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (BlockTimer)

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti usingBlock:(void(^)(NSTimer *timer))block repeats:(BOOL)yesOrNo;
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti usingBlock:(void(^)(NSTimer *timer))block repeats:(BOOL)yesOrNo;

@end
