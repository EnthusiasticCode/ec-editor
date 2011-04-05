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

- (void)dealloc
{
    [aButton release];
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
    
    UIColor *darkColor = [UIColor colorWithHue:0 saturation:0 brightness:0.01 alpha:1];
    UIColor *shadowColor = [UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:0.3];
    CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"Helvetica-Bold");
    
    CALayer *testLayer = [CALayer layer];
    testLayer.frame = CGRectMake(50, 50, 100, 100);
    testLayer.masksToBounds = YES;
    testLayer.opaque = NO;
    testLayer.cornerRadius = 3;
    testLayer.borderWidth = 1;
    testLayer.borderColor = darkColor.CGColor;
    
    CATextLayer *testText = [CATextLayer layer];
    testText.frame = CGRectMake(50, 90, 100, 100);
    testText.alignmentMode = kCAAlignmentCenter;
    testText.string = @"Button";
    testText.foregroundColor = darkColor.CGColor;
    testText.font = font;
    testText.fontSize = 16;
    testText.shadowColor = shadowColor.CGColor;
    testText.shadowOffset = CGSizeMake(0, 1);
    testText.shadowOpacity = 1;
    testText.shadowRadius = 0;
    
    [self.view.layer addSublayer:testLayer];
    [self.view.layer addSublayer:testText];
    
    ECMockupLayer *mLayer = [ECMockupLayer layer];
    mLayer.rightArrowSize = 10;
    mLayer.cornerRadius = 3;
    mLayer.borderColor = darkColor.CGColor;
    mLayer.frame = CGRectMake(100, 8, 79, 29);
    mLayer.borderWidth = 1;
    [self.view.layer addSublayer:mLayer];
    [mLayer setNeedsDisplay];
    
    aButton.arrowSizes = UIEdgeInsetsMake(0, 10, 0, 0);
}

- (void)viewDidUnload
{
    [self setAButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (IBAction)doSomething:(id)sender {
    [sender setSelected:![sender isSelected]];
}

- (IBAction)changeArrows:(id)sender {
    if (UIEdgeInsetsEqualToEdgeInsets([sender arrowSizes], UIEdgeInsetsZero)) {
        [sender setArrowSizes:UIEdgeInsetsMake(0, 10, 0, 10)];
    }
    else {
            [sender setArrowSizes:UIEdgeInsetsZero];
    }
}
@end
