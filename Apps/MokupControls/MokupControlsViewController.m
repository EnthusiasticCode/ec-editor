//
//  MokupControlsViewController.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MokupControlsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ECMockupLayer.h"

@implementation MokupControlsViewController
@synthesize aButton;
@synthesize jumpBar;

- (void)dealloc
{
    [aButton release];
    [jumpBar release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    aButton.arrowSizes = UIEdgeInsetsMake(0, 10, 0, 0);
    
    jumpBar.delegate = self;
}

- (void)viewDidUnload
{
    [self setAButton:nil];
    [self setJumpBar:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (IBAction)pushToJumpBar:(id)sender {
    [jumpBar pushControlWithTitle:[NSString stringWithFormat:@"%dProject", jumpBar.stackSize]];
}

#pragma mark Jump Bar Delegation

- (void)jumpBarButtonAction:(id)sender
{
    [jumpBar popControlsDownThruIndex:[sender tag]];
}

- (void)jumpBar:(ECJumpBar *)jumpBar didPushControl:(UIControl *)control atStackIndex:(NSUInteger)index
{
    [control addTarget:self action:@selector(jumpBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)jumpBar:(ECJumpBar *)jumpBar didCollapseToControl:(UIControl *)control collapsedRange:(NSRange)collapsedRange
{

}
@end
