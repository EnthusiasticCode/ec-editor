//
//  NSTimer+block.m
//  CodeView
//
//  Created by Nicola Peduzzi on 10/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSTimer+BlockTimer.h"


@implementation NSTimer (BlockTimer)

+ (void)executeTimerUserInfoAsBlock:(NSTimer *)timer
{
  void (^block)(NSTimer *) = [timer userInfo];
  if (block)
    block(timer);
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti usingBlock:(void(^)(NSTimer *timer))block repeats:(BOOL)yesOrNo
{
  return [NSTimer timerWithTimeInterval:ti target:NSTimer.class selector:@selector(executeTimerUserInfoAsBlock:) userInfo:[block copy] repeats:yesOrNo];
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti usingBlock:(void(^)(NSTimer *timer))block repeats:(BOOL)yesOrNo
{
  return [NSTimer scheduledTimerWithTimeInterval:ti target:NSTimer.class selector:@selector(executeTimerUserInfoAsBlock:) userInfo:[block copy] repeats:yesOrNo];
}

@end
