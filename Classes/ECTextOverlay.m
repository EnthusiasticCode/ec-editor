//
//  MyClass.m
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextOverlay.h"


@implementation ECTextOverlay

@synthesize rect, alternative;

- (id)initWithRect:(CGRect)aRect alternative:(BOOL)alt
{
    if ((self = [super init]))
    {
        rect = aRect;
        alternative = alt;
    }
    return self;
}

+ (id)textOverlayWithRect:(CGRect)aRect alternative:(BOOL)alt
{
    return [[[self alloc] initWithRect:aRect alternative:alt] autorelease];
}

@end
