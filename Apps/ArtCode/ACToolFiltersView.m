//
//  ACToolFiltersView.m
//  ACUI
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ACToolFiltersView.h"
#import "AppStyle.h"

@implementation ACToolFiltersView

@synthesize customDrawRect;

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (customDrawRect)
        customDrawRect(self, rect);
}

@end
