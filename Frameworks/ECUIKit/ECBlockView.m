//
//  ECBlockView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 21/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECBlockView.h"

@implementation ECBlockView

@synthesize layoutSubviewsBlock;

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (layoutSubviewsBlock)
        layoutSubviewsBlock(self);
}

@end
