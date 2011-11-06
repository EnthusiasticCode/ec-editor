//
//  ECTexturedPopoverView_ViewController.m
//  ECTexturedPopoverView
//
//  Created by Nicola Peduzzi on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTexturedPopoverView_ViewController.h"
#import "ECTexturedPopoverView.h"

@implementation ECTexturedPopoverView_ViewController

@synthesize popoverView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.popoverView.image =[[UIImage imageNamed:@"accessoryView_popoverBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 40, 10)];
    [self.popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowMiddle"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionMiddle];
    [self.popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionFarRight];
    [self.popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowLeft"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionFarLeft];
    [self.popoverView setArrowSize:CGSizeMake(70, 44) forMetaPosition:ECPopoverViewArrowMetaPositionMiddle];
    self.popoverView.arrowInsets = UIEdgeInsetsMake(6, 6, 6, 6);
    self.popoverView.arrowDirection = UIPopoverArrowDirectionDown;
    self.popoverView.arrowPosition = 200;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)viewDidUnload {
    [self setPopoverView:nil];
    [super viewDidUnload];
}

- (IBAction)changePopoverArrowSide:(id)sender {
    UIPopoverArrowDirection direction = self.popoverView.arrowDirection << 1;
    if (direction > UIPopoverArrowDirectionRight)
        direction = UIPopoverArrowDirectionUp;
    self.popoverView.arrowDirection = direction;
}

- (IBAction)changePopoverArrowPosition:(id)sender {
    CGFloat relativeSize = (self.popoverView.arrowDirection & (UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown)) ? self.popoverView.bounds.size.width : self.popoverView.bounds.size.height;
    self.popoverView.arrowPosition = [(UISlider *)sender value] * relativeSize;
}

@end
