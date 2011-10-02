//
//  ECCustomizableScrollView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 02/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCustomizableScrollView.h"

@implementation ECCustomizableScrollView

@synthesize layoutSubviewsBlock;

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (layoutSubviewsBlock)
        layoutSubviewsBlock(self);
}

@end
