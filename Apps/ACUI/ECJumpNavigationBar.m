//
//  ECJumpNavigationBar.m
//  ACUI
//
//  Created by Nicola Peduzzi on 10/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECJumpNavigationBar.h"

@implementation ECJumpNavigationBar

@synthesize jumpBar;

static void init(ECJumpNavigationBar *self)
{
    // Create jumpbar to use
    if (self->jumpBar == nil)
    {
        CGRect jumpBarFrame = self.bounds;
        jumpBarFrame.origin = CGPointMake(67, 7);
        jumpBarFrame.size.width -= 67 * 2;
        jumpBarFrame.size.height = 28;
        self->jumpBar = [[ECJumpBar alloc] initWithFrame:jumpBarFrame];
        self->jumpBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    [self addSubview:self->jumpBar];
}

- (id)initWithCoder:(NSCoder *)coder 
{
    if ((self = [super initWithCoder:coder])) 
    {
        init(self);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        init(self);
    }
    return self;
}

- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated
{
    UINavigationItem *previousItem = [self.items lastObject];
    
    [super pushNavigationItem:item animated:NO];
    
    NSString *commonPath = [item.title commonPrefixWithString:previousItem.title options:NSCaseInsensitiveSearch];
    
    NSArray *commonComponents = [commonPath componentsSeparatedByString:@"/"];
    NSArray *itemComponents = [item.title componentsSeparatedByString:@"/"];
    
    NSUInteger commonComponentsCount = [commonComponents count];
    if (commonComponents)
        [jumpBar popControlsDownThruIndex:commonComponentsCount animated:animated];
    
    NSUInteger itemComponentsCount = [itemComponents count];
    for (NSUInteger i = commonComponentsCount; i < itemComponentsCount; ++i)
    {
        [jumpBar pushControlWithTitle:[itemComponents objectAtIndex:i] animated:animated];
    }
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    [super setItems:items animated:animated];
}

- (void)setItems:(NSArray *)items
{
    [super setItems:items];
}

@end

