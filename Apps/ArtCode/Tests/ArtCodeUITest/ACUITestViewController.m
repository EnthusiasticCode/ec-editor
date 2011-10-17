//
//  ACUITestViewController.m
//  ArtCodeUITest
//
//  Created by Nicola Peduzzi on 16/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACUITestViewController.h"
#import "ACUITestToolBar.h"

@interface ACUITestViewController ()


@end

@implementation ACUITestViewController

@synthesize barView = _barView, contentViewController = _contentViewController;

- (void)setContentViewController:(UIViewController *)contentViewController
{
    [self setContentViewController:contentViewController animated:NO];
}

- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated
{
    if (contentViewController == _contentViewController)
        return;
    
    [self willChangeValueForKey:@"contentViewController"];
    
    if (self.isViewLoaded)
    {
        CGRect barBounds = self.barView.bounds;
        CGRect contentFrame = self.view.bounds;
        contentFrame.origin.y += barBounds.size.height;
        contentFrame.size.height -= barBounds.size.height;
        
        contentViewController.view.frame = contentFrame;
        if (_contentViewController != nil && animated)
        {
            [UIView transitionFromView:_contentViewController.view toView:contentViewController.view duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
                [_contentViewController.view removeFromSuperview];
            }];
        }
        else
        {
            [self.view addSubview:contentViewController.view];
            [_contentViewController.view removeFromSuperview];
        }
        
        [self.barView.titleItem setTitle:_contentViewController.navigationItem.title forState:UIControlStateNormal];
    }
    
    [self.childViewControllers makeObjectsPerformSelector:@selector(removeFromParentViewController)];
    [self addChildViewController:contentViewController];
    _contentViewController = contentViewController;
    
    [self didChangeValueForKey:@"contentViewController"];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    CGRect barBounds = self.barView.bounds;
    CGRect contentFrame = self.view.bounds;
    contentFrame.origin.y += barBounds.size.height;
    contentFrame.size.height -= barBounds.size.height;
    
    self.contentViewController.view.frame = contentFrame;
    [self.view addSubview:self.contentViewController.view];
    
    [self.barView.titleItem setTitle:self.contentViewController.navigationItem.title forState:UIControlStateNormal];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


@end
