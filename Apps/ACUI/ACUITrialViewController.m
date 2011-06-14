//
//  ACUITrialViewController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 14/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACUITrialViewController.h"

@implementation ACUITrialViewController
@synthesize popoverContentController;

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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [self setPopoverContentController:nil];
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
    popoverContentController.contentSizeForViewInPopover = CGSizeMake(200, 300);
    
    if (!popoverController)
        popoverController = [[ECPopoverController alloc] initWithContentViewController:popoverContentController];
    
    [popoverController presentPopoverFromRect:[sender frame] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
}

@end
