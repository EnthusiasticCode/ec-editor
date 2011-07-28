//
//  ACNavigationController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ECPopoverController.h"
#import "AppStyle.h"
#import "ACURL.h"
#import "ACNavigationController.h"

#import "ACJumpBarTextField.h"
#import "ACPopoverHistoryToolController.h"
#import "ACFileTableController.h"

#import "ECTabBar.h"
#import "ECSwipeGestureRecognizer.h"
#import "ACTabController.h"

#import "ECInstantGestureRecognizer.h"
#import "ACToolPanelController.h"
#import "ACToolController.h"

#import "ECBezelAlert.h"

@implementation ACNavigationController {
@private
    ECPopoverController *popoverController;
    
    // Jump Bar
    UILongPressGestureRecognizer *jumpBarElementLongPressRecognizer;
    ACPopoverHistoryToolController *popoverHistoryToolController;
    ACFileTableController *popoverBrowseFileToolController;
    
    // Tool panel recognizers
    UISwipeGestureRecognizer *toolPanelLeftGestureRecognizer, *toolPanelRightGestureRecognizer;
    ECInstantGestureRecognizer *toolPanelDismissGestureRecognizer;
    
    // Bezel current page
    UIPageControl *tabPageControl;
    UIViewController *tabPageControlController;
}

#pragma mark - Properties

@synthesize jumpBar, buttonEdit, buttonTools;
@synthesize toolPanelController, toolPanelEnabled, toolPanelOnRight;
@synthesize tabNavigationController;

- (void)setToolPanelEnabled:(BOOL)enabled
{
    if (enabled == toolPanelEnabled)
        return;
    
    toolPanelEnabled = enabled;
    
    toolPanelLeftGestureRecognizer.enabled = enabled;
    toolPanelRightGestureRecognizer.enabled = enabled;
    
    if (!toolPanelEnabled)
        [self hideToolPanelAnimated:NO];
}

#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)loadView
{
    [super loadView];
    
    // TODO create internal views if not connected in IB
    
    popoverController = [ECPopoverController new];
    popoverController.popoverView.layer.shadowOpacity = 0.5;
    popoverController.popoverView.layer.shadowRadius = 4;
    popoverController.popoverView.shadowOffsetForArrowDirectionUpToAutoOrient = CGSizeMake(0, 3);
    
    // Setup present APIs to use this controller as reference.
    self.definesPresentationContext = YES;
    
    // Tools button
    [buttonTools setImage:[UIImage styleAddImageWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    buttonTools.adjustsImageWhenHighlighted = NO;
    
    ////////////////////////////////////////////////////////////////////////////
    // Jump Bar
    jumpBar.delegate = self;
    jumpBar.minimumTextElementWidth = 0.4;
    jumpBar.textElement = [ACJumpBarTextField new];
    jumpBar.textElement.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    jumpBar.textElement.placeholder = @"Filter";
    jumpBar.textElement.autocorrectionType = UITextAutocorrectionTypeNo;
    jumpBar.textElement.spellCheckingType = UITextSpellCheckingTypeNo;
    jumpBar.textElement.autocapitalizationType = UITextAutocapitalizationTypeNone;
    jumpBar.textElement.returnKeyType = UIReturnKeySearch;
    jumpBar.backgroundView = [[UIImageView alloc] initWithImage:[UIImage styleBackgroundImageWithColor:[UIColor styleAlternateBackgroundColor] borderColor:[UIColor styleForegroundColor]]];
    // TODO make this a button?
    jumpBar.textElement.rightView = [[UIImageView alloc] initWithImage:[UIImage styleSearchIconWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]]];
    jumpBar.textElement.rightViewMode = UITextFieldViewModeAlways;
    // Jump bar back button
    UIButton *backButton = [UIButton new];
    UIImage *normalBackButtonBackgrounImage = [UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsZero arrowSize:CGSizeZero roundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft];
    [backButton setBackgroundImage:normalBackButtonBackgrounImage forState:UIControlStateNormal];
    [backButton setBackgroundImage:normalBackButtonBackgrounImage forState:UIControlStateDisabled];
    [backButton setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleHighlightColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsZero arrowSize:CGSizeZero roundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft] forState:UIControlStateHighlighted];
    [backButton setImage:[UIImage styleDisclosureArrowImageWithOrientation:UIImageOrientationLeft color:[UIColor styleForegroundColor]] forState:UIControlStateNormal];
    backButton.frame = CGRectMake(0, 0, 40, 30);
    [backButton addTarget:self action:@selector(jumpBarBackAction:) forControlEvents:UIControlEventTouchUpInside];
    [backButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(jumpBarBackLongAction:)]];
    jumpBar.backElement = backButton;
    //
    jumpBar.textElement.leftView = [[UIImageView alloc] initWithImage:[UIImage styleSymbolImageWithColor:[UIColor styleSymbolColorBlue] letter:@"M"]];
    jumpBar.textElement.leftViewMode = UITextFieldViewModeUnlessEditing;
    
    ////////////////////////////////////////////////////////////////////////////
    // Tool panel gesture recognizer
    toolPanelLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleToolPanelGesture:)];
    toolPanelLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    toolPanelRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleToolPanelGesture:)];
    toolPanelRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:toolPanelLeftGestureRecognizer];
    [self.view addGestureRecognizer:toolPanelRightGestureRecognizer];
    toolPanelLeftGestureRecognizer.enabled = toolPanelEnabled;
    toolPanelRightGestureRecognizer.enabled = toolPanelEnabled;
    
    ////////////////////////////////////////////////////////////////////////////
    // Tab controller
    if (!tabNavigationController)
        tabNavigationController = [ACTabNavigationController new];
    tabNavigationController.delegate = self;
    [self addChildViewController:tabNavigationController];
    [self.view addSubview:tabNavigationController.view];
    CGRect tabControllerFrame = self.view.bounds;
    tabControllerFrame.origin.y = 45;
    tabControllerFrame.size.height -= 45;
    tabNavigationController.view.frame = tabControllerFrame;
    tabNavigationController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tabNavigationController.contentScrollView.frame = (CGRect){ CGPointZero, tabControllerFrame.size };
}

- (void)viewDidUnload
{
    popoverController = nil;
    [self setJumpBar:nil];
    toolPanelLeftGestureRecognizer = nil;
    toolPanelRightGestureRecognizer = nil;
    [self setTabNavigationController:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Bar Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    buttonEdit.selected = editing;
    [tabNavigationController setEditing:editing animated:animated];
}

- (IBAction)toggleTools:(id)sender
{
//    if (!popoverController)
//        popoverController = [ECPopoverController new];
}

- (IBAction)toggleEditing:(id)sender
{
    BOOL editing = !tabNavigationController.isEditing;
    [self setEditing:editing animated:YES];
}

#pragma mark - JumpBar Methods

- (void)jumpBarBackAction:(id)sender
{
    [tabNavigationController.currentTabController moveBackInHistory];
}

- (void)jumpBarBackLongAction:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // Create and initialize popover tool history controller
        if (popoverHistoryToolController == nil)
        {
            popoverHistoryToolController = [[ACPopoverHistoryToolController alloc] initWithStyle:UITableViewStyleGrouped];
            popoverHistoryToolController.contentSizeForViewInPopover = CGSizeMake(300, 200);
        }
        [popoverHistoryToolController setHistoryURLs:tabNavigationController.currentTabController.historyURLs 
                                    hisoryPointIndex:tabNavigationController.currentTabController.currentURLIndex];
        
        // Present popover
        popoverController.contentViewController = popoverHistoryToolController;
        popoverController.automaticDismiss = YES;
        [popoverController presentPopoverFromRect:jumpBar.backElement.frame inView:jumpBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

- (void)jumpBarElementAction:(id)sender
{
    if (popoverBrowseFileToolController == nil)
    {
        popoverBrowseFileToolController = [ACFileTableController new];
        // TODO size that fits
        popoverBrowseFileToolController.contentSizeForViewInPopover = CGSizeMake(268, 220);
        // TODO more performant, maybe move inside popover
        popoverBrowseFileToolController.view.layer.cornerRadius = 3;
        popoverBrowseFileToolController.view.layer.masksToBounds = YES;
    }
    
    // Setup file browser
    [popoverBrowseFileToolController openURL:[NSURL ACURLWithPath:[jumpBar jumpPathUpThroughElement:sender]]];
    // TODO!!! the select row of the controller should not change the parent acnavigationcotnroller pushURL...
    
    popoverController.contentViewController = popoverBrowseFileToolController;
    popoverController.automaticDismiss = YES;
    [popoverController presentPopoverFromRect:[sender frame] inView:jumpBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
//    [jumpBar popThroughJumpElement:sender animated:YES];
}

- (void)jumpBarElementLongAction:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
//        recognizer.view
    }
}

#pragma mark -

- (UIView *)jumpBar:(ECJumpBar *)bar elementForJumpPathComponent:(NSString *)pathComponent index:(NSUInteger)componentIndex
{
    static NSString *elementIdentifier = @"jumpBarElement";
    
    // TODO special case for componentIndex == NSNotFound as collapse element?
    UIButton *button = (UIButton *)[bar dequeueReusableJumpElementWithIdentifier:elementIdentifier];
    if (button == nil)
    {
        button = [UIButton new];
        button.reuseIdentifier = elementIdentifier;
        [button addTarget:self action:@selector(jumpBarElementAction:) forControlEvents:UIControlEventTouchUpInside];
        // TODO move label settings in appearance when possble
        button.titleLabel.font = [UIFont styleFontWithSize:14];
        button.titleLabel.shadowOffset = CGSizeMake(0, 1);
        
        if (jumpBarElementLongPressRecognizer == nil)
            jumpBarElementLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(jumpBarElementLongAction:)];
        [button addGestureRecognizer:jumpBarElementLongPressRecognizer];
    }
    
    [button setTitle:pathComponent forState:UIControlStateNormal];
    
    return button;
}

- (NSString *)jumpBar:(ECJumpBar *)jumpBar pathComponentForJumpElement:(UIView *)jumpElement index:(NSUInteger)elementIndex
{
    return [(UIButton *)jumpElement currentTitle];
}

#pragma mark - Navigation Methods

- (void)pushURL:(NSURL *)url
{
    [tabNavigationController.currentTabController pushURL:url];
}

#pragma mark - Tab Navigation Controller Delegate Method

- (BOOL)tabNavigationController:(ACTabNavigationController *)controller willRemoveTabController:(ACTabController *)tabController
{
    if (controller.tabCount == 1)
    {
        [[ECBezelAlert sharedAlert] addAlertMessageWithText:@"Can not stay without tabs!" image:nil displayImmediatly:YES];
        return NO;
    }
    return YES;
}

- (void)tabNavigationController:(ACTabNavigationController *)controller didChangeCurrentTabController:(ACTabController *)tabController fromTabController:(ACTabController *)previousTabController
{
    // Bezel alert with page indicator
    if (tabController != previousTabController && controller.tabCount > 1)
    {
        if (tabPageControlController == nil)
        {
            tabPageControl = [UIPageControl new];
            tabPageControlController = [UIViewController new];
            tabPageControlController.view = tabPageControl;
        }        
        tabPageControl.numberOfPages = controller.tabCount;
        tabPageControl.currentPage = tabController.position;
        CGRect tabPageControlFrame = (CGRect){ CGPointZero, [tabPageControl sizeForNumberOfPages:controller.tabCount] };
        tabPageControl.frame = tabPageControlFrame;
        tabPageControlController.contentSizeForViewInPopover = CGSizeMake(tabPageControlFrame.size.width, 10);
        [[ECBezelAlert sharedAlert] addAlertMessageWithViewController:tabPageControlController displayImmediatly:YES];
    }
    
    // TODO enable tabs and stuff
    controller.tabBarEnabled = YES;
    
    // Setup jump bar
    [jumpBar setJumpPath:tabController.currentURL.path animated:YES];
    [(UIButton *)jumpBar.backElement setEnabled:[tabController.historyURLs count] > 1];
}

#pragma mark - Tool Panel Management Methods

- (void)showToolPanelAnimated:(BOOL)animated
{
    UIView *toolPanelView = toolPanelController.view;
    if (!toolPanelController || toolPanelView.superview != nil)
        return;
    
    if (!toolPanelDismissGestureRecognizer)
    {
        toolPanelDismissGestureRecognizer = [[ECInstantGestureRecognizer alloc] initWithTarget:self action:@selector(handleToolPanelGesture:)];
        [toolPanelRightGestureRecognizer requireGestureRecognizerToFail:toolPanelLeftGestureRecognizer];
        [toolPanelRightGestureRecognizer requireGestureRecognizerToFail:toolPanelRightGestureRecognizer];
    }
    
    toolPanelView.autoresizingMask = UIViewAutoresizingFlexibleHeight | (toolPanelOnRight ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin);
    
    CALayer *toolPanelLayer = toolPanelView.layer;
    CGRect bounds = self.view.bounds;
    CGFloat panelSize = 322 + toolPanelLayer.borderWidth;
    CGRect panelFrame = (CGRect){
        (toolPanelOnRight 
         ? (CGPoint){ bounds.size.width - panelSize + toolPanelLayer.borderWidth, 0 } 
         : CGPointMake(toolPanelLayer.borderWidth, 0)),
        CGSizeMake(panelSize, bounds.size.height)
    };
    
    [self.view addSubview:toolPanelView];
    
    // TODO add instant gesture recognizer to dismiss
    if (animated)
    {
        toolPanelLayer.shadowOpacity = 0;
        toolPanelLayer.shouldRasterize = YES; // TODO check for performance 
        CGRect panelPreAnimationFrame = panelFrame;
        panelPreAnimationFrame.origin.x += toolPanelOnRight ? panelFrame.size.width : -panelFrame.size.width;
        toolPanelView.frame = panelPreAnimationFrame;
        [UIView animateWithDuration:0.10 delay:0 options:UIViewAnimationCurveEaseInOut animations:^(void) {
            toolPanelView.frame = panelFrame;
        } completion:^(BOOL finished) {
            toolPanelLayer.shouldRasterize = NO;
            //
            toolPanelLayer.shadowOffset = toolPanelOnRight ? CGSizeMake(-5, 0) : CGSizeMake(5, 0);
            toolPanelLayer.shadowOpacity = 0.3;
            //
            [self.view addGestureRecognizer:toolPanelDismissGestureRecognizer];
        }];
    }
    else
    {
        toolPanelView.frame = panelFrame;
        toolPanelLayer.shadowOffset = toolPanelOnRight ? CGSizeMake(-5, 0) : CGSizeMake(5, 0);
        toolPanelLayer.shadowOpacity = 0.3;
        [self.view addGestureRecognizer:toolPanelDismissGestureRecognizer];
    }
}

- (void)hideToolPanelAnimated:(BOOL)animated
{
    UIView *toolPanelView = toolPanelController.view;
    if (!toolPanelController || toolPanelView.superview == nil)
        return;
    
    [self.view removeGestureRecognizer:toolPanelDismissGestureRecognizer];
    
    CALayer *toolPanelLayer = toolPanelView.layer;
    toolPanelLayer.shadowOpacity = 0;
    
    if (animated)
    {
        // TODO check for performance 
        toolPanelLayer.shouldRasterize = YES;
        CGRect panelFrame = toolPanelView.frame;
        panelFrame.origin.x += toolPanelOnRight ? panelFrame.size.width : -panelFrame.size.width;
        [UIView animateWithDuration:0.10 delay:0 options:UIViewAnimationCurveEaseInOut animations:^(void) {
            toolPanelView.frame = panelFrame;
        } completion:^(BOOL finished) {
            toolPanelLayer.shouldRasterize = NO;
            [toolPanelView removeFromSuperview];
        }];
    }
    else
    {
        [toolPanelView removeFromSuperview];
    }
}

#pragma mark -

- (void)handleToolPanelGesture:(UIGestureRecognizer *)recognizer
{
    if (recognizer == toolPanelLeftGestureRecognizer)
    {
        if (toolPanelOnRight)
            [self showToolPanelAnimated:YES];
        else
            [self hideToolPanelAnimated:YES];
    }
    else if (recognizer == toolPanelRightGestureRecognizer)
    {
        if (!toolPanelOnRight)
            [self showToolPanelAnimated:YES];
        else
            [self hideToolPanelAnimated:YES];
    }
    else if (recognizer == toolPanelDismissGestureRecognizer)
    {
        CGPoint location = [recognizer locationInView:toolPanelController.view];
        if ([toolPanelController.view pointInside:location withEvent:nil])
            return;
        [self hideToolPanelAnimated:YES];
        [recognizer.view removeGestureRecognizer:recognizer];
    }
}

#pragma mark -

- (IBAction)tests:(id)sender {
    static NSUInteger count = 0;
    NSString *title = [NSString stringWithFormat:@"Path %u", count++];
//    [jumpBar pushJumpElementWithPathComponent:title animated:YES];
    [[ECBezelAlert sharedAlert] addAlertMessageWithText:title image:nil displayImmediatly:NO];
}


@end

@implementation UIViewController (ACNavigationController)

- (ACNavigationController *)ACNavigationController
{
    UIViewController *ancestor = self.parentViewController;
    while (ancestor && ![ancestor isKindOfClass:[ACNavigationController class]])
        ancestor = [ancestor parentViewController];
    return (ACNavigationController *)ancestor;
}

@end
