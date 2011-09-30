//
//  ECTabController.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 29/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTabController.h"

#define TABBAR_HEIGHT 44

static void *ECTabControllerChildViewControllerContext;

@implementation ECTabController {
    NSMutableArray *orderedChildViewControllers;
    UIView *contentView;
}

#pragma mark - Properties

@synthesize tabBar;
@synthesize selectedViewControllerIndex;

- (UIViewController *)selectedViewController
{
    if (selectedViewControllerIndex == NSNotFound)
        return nil;
    
    return [orderedChildViewControllers objectAtIndex:selectedViewControllerIndex];
}

- (void)setSelectedViewControllerIndex:(NSUInteger)index
{
    [self setSelectedViewControllerIndex:index animated:NO];
}

- (void)setSelectedViewControllerIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (selectedViewControllerIndex == index)
        return;
    
    UIViewController *toViewController = nil;
    if (index != NSNotFound)
    {
        ECASSERT(index < [orderedChildViewControllers count]);
        toViewController = [orderedChildViewControllers objectAtIndex:index];
    }
    
    [self transitionFromViewController:self.selectedViewController toViewController:toViewController duration:animated ? 0.20 : 0 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:^(BOOL finished) {
        selectedViewControllerIndex = index;
    }];
    
    [tabBar setSelectedTabControl:[tabBar.tabControls objectAtIndex:index] animated:animated];
}

#pragma mark - Controller initialization

static void init(ECTabController *self)
{
    self->selectedViewControllerIndex = NSNotFound;
    [self addObserver:self forKeyPath:@"childViewControllers" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:ECTabControllerChildViewControllerContext];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder]))
    {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"childViewControllers" context:ECTabControllerChildViewControllerContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ECTabControllerChildViewControllerContext)
    {
        if (orderedChildViewControllers == nil)
            orderedChildViewControllers = [NSMutableArray new];
        
        NSInteger kind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
        if (kind == NSKeyValueChangeInsertion)
        {
            NSIndexSet *changedValues = [change objectForKey:NSKeyValueChangeIndexesKey];
            NSArray *newChildViewController = [change objectForKey:NSKeyValueChangeNewKey];
            [newChildViewController enumerateObjectsAtIndexes:changedValues options:0 usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
                // Adding to ordered array of controllers
                [orderedChildViewControllers addObject:controller];
                
                // Add tab button
                [tabBar addTabWithTitle:controller.navigationItem.title animated:YES];
                
                // Set selection
                if (self.selectedViewControllerIndex == NSNotFound)
                    [self setSelectedViewControllerIndex:[orderedChildViewControllers count] - 1 animated:YES];
            }];
        }
        else if (kind == NSKeyValueChangeRemoval)
        {
            NSIndexSet *changedValues = [change objectForKey:NSKeyValueChangeIndexesKey];
            NSArray *oldChildViewController = [change objectForKey:NSKeyValueChangeOldKey];
            [oldChildViewController enumerateObjectsAtIndexes:changedValues options:0 usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
                NSUInteger controllerIndex = [orderedChildViewControllers indexOfObject:controller];
                [orderedChildViewControllers removeObject:controller];
                
                // Remove from tab bar
                [tabBar removeTabControl:[tabBar.tabControls objectAtIndex:controllerIndex] animated:YES];
                
                // Change selection if needed
                if (self.selectedViewControllerIndex == controllerIndex)
                {
                    if (controllerIndex > 0)
                        controllerIndex -= 1;
                    if (controllerIndex < [orderedChildViewControllers count])
                        [self setSelectedViewControllerIndex:controllerIndex animated:YES];
                    else
                        self.selectedViewControllerIndex = NSNotFound;
                }
            }];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)loadView
{
    [super loadView];
    
    CGRect bounds = self.view.bounds;
    
    // Creating tab bar
    tabBar = [[ECTabBar alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, TABBAR_HEIGHT)];
    tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    tabBar.delegate = self;
    [self.view addSubview:tabBar];
    
    // Creating the content view
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0, TABBAR_HEIGHT, bounds.size.width, bounds.size.height - TABBAR_HEIGHT)];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:contentView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    tabBar = nil;
    contentView = nil;
}

#pragma mark - Managing tabs

- (void)moveChildViewControllerAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    ECASSERT(fromIndex < [orderedChildViewControllers count]);
    ECASSERT(toIndex < [orderedChildViewControllers count]);
    
    id obj = [orderedChildViewControllers objectAtIndex:fromIndex];
    [orderedChildViewControllers removeObjectAtIndex:fromIndex];
    [orderedChildViewControllers insertObject:obj atIndex:toIndex];
    
    [tabBar moveTabControlAtIndex:fromIndex toIndex:toIndex animated:YES];
    // TODO animation
}

#pragma mark - Tab bar delegate methods

- (UIControl *)tabBar:(ECTabBar *)tabBar controlForTabWithTitle:(NSString *)title atIndex:(NSUInteger)tabIndex
{
    UIButton *control = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    [control setTitle:title forState:UIControlStateNormal];
    // TODO close button
    return control;
}

@end
