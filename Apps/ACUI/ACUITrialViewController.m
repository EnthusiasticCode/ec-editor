//
//  ACUITrialViewController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 14/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACUITrialViewController.h"

@implementation ACUITrialViewController
@synthesize jumpBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
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
    
    UIColor *brightColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    UIColor *highlightColor = [UIColor colorWithWhite:0.70 alpha:1.0];
    UIColor *darkColor = [UIColor colorWithWhite:0.16 alpha:1.0];
    UIColor *shadowColor = [UIColor whiteColor];
    
    id jumpBarAppearance = [ECJumpBar appearance];
    
    [jumpBarAppearance setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14]];
    
    [jumpBarAppearance setTextColor:darkColor];
    [jumpBarAppearance setTextShadowColor:shadowColor];
    [jumpBarAppearance setTextShadowOffset:CGSizeMake(0, 1)];
    
    [jumpBarAppearance setButtonColor:brightColor];
    [jumpBarAppearance setButtonHighlightColor:highlightColor];
}

- (void)viewDidUnload
{
    [self setJumpBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Trial Methods

- (IBAction)showPopover:(id)sender 
{
    if (!popoverContentController)
    {
        popoverContentController = [[UIViewController alloc] init];
        popoverContentController.contentSizeForViewInPopover = CGSizeMake(200, 300);
        popoverContentController.view = [[UIView alloc] initWithFrame:(CGRect){200, 300}];
        popoverContentController.view.backgroundColor = [UIColor whiteColor];
    }
    
    if (!popoverController)
    {
        popoverController = [[ECPopoverController alloc] initWithContentViewController:popoverContentController];
        popoverController.popoverView.backgroundColor = [UIColor colorWithWhite:0.16 alpha:1.0];
        popoverController.popoverView.arrowMargin = popoverController.popoverView.arrowMargin + 1;
//        [[ECPopoverView appearance] setBackgroundColor:[UIColor redColor]];
//        [[ECPopoverView appearance] setArrowCornerRadius:3];
    }
    
    [popoverController presentPopoverFromRect:[sender frame] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (IBAction)pushToJumpBar:(id)sender {
    [jumpBar pushControlWithTitle:@"Project" animated:YES];
}

@end
