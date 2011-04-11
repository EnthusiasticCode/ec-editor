//
//  ECStackFilterBarController.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECStackFilterBarController.h"
#import <QuartzCore/QuartzCore.h>


@implementation ECStackFilterBarController

@synthesize backgroundView;
@synthesize filterTextField;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        
//    }
//    return self;
//}

- (void)dealloc
{
    [buttonStack release];
    [backgroundView release];
    [filterTextField release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CALayer *backgroundViewLayer = backgroundView.layer;
    backgroundViewLayer.borderColor = [UIColor colorWithHue:0 saturation:0 brightness:0.01 alpha:1].CGColor;
    backgroundViewLayer.borderWidth = 1;
    backgroundViewLayer.cornerRadius = 3;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return NO;
}

#pragma mark Stack managment

- (void)pushStateButtonWithDescription:(NSString *)description
{
    if (!buttonStack)
        buttonStack = [[NSMutableArray alloc] initWithCapacity:10];
    
    ECButton *button = [ECButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:description forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    button.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [button setTitleShadowColor:[UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:0.3] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0.23 alpha:1] forState:UIControlStateNormal];
    
    // Calculate new button frame
    CGSize size = [button sizeThatFits:CGSizeZero];
    size.height = self.view.bounds.size.height;
    size.width += 40.0;
    CGPoint position = self.view.bounds.origin;
    if ([buttonStack count]) 
    {
        CGRect lastFrame = [[buttonStack lastObject] frame];
        position.x = lastFrame.origin.x + lastFrame.size.width - 15;
    }
    
    // Create new button frame
    button.frame = (CGRect) { position, size };
    
    // Adjust text field frame
    position.x += size.width + 5;
    size.width = self.view.bounds.size.width - position.x - 5;
    filterTextField.frame = (CGRect) { position, size };
    
    // Insert in view
    if ([buttonStack count]) 
    {
        [self.view insertSubview:button belowSubview:(ECButton *)[buttonStack lastObject]];
    }
    else
    {
        [self.view insertSubview:button aboveSubview:filterTextField];
    }
    
    // Adding to stack
    [buttonStack addObject:button];
    
    // Adding arrow
    button.arrowSizes = UIEdgeInsetsMake(0, 0, 0, 10);
}

- (void)popStateButton
{
    
}

@end
