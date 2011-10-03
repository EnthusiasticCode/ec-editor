//
//  ACNavigationController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <ECUIKit/ECPopoverController.h>
#import "AppStyle.h"
#import "ACNavigationController.h"

#import "ACJumpBarTextField.h"
#import "ACPopoverHistoryToolController.h"
#import "ACProjectTableController.h"
#import "ACFileTableController.h"
#import "ACCodeFileController.h"

#import "ACTab.h"
#import "ACApplication.h"

static void *contentViewControllerEditingObservingContext;
static void *tabCurrentURLObservingContext;

@interface ACNavigationController ()
{
    ECPopoverController *popoverController;
    
    // Jump Bar
    UILongPressGestureRecognizer *jumpBarElementLongPressRecognizer;
    ACPopoverHistoryToolController *popoverHistoryToolController;
    ACFileTableController *popoverBrowseFileToolController;
}
@property (nonatomic, strong) UIViewController *contentViewController;
@end

@implementation ACNavigationController

#pragma mark - Properties

@synthesize topBarView, jumpBar, buttonEdit, buttonTools;
@synthesize tab = _tab;
@synthesize contentViewController = _contentViewController;
@synthesize contentView = _contentView;

+ (NSSet *)keyPathsForValuesAffectingEditing
{
    return [NSSet setWithObject:@"contentViewController.editing"];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self.contentViewController setEditing:editing animated:animated];
}

- (void)setTab:(ACTab *)tab
{
    if (tab == _tab)
        return;
    [self willChangeValueForKey:@"tab"];
    [_tab removeObserver:self forKeyPath:@"currentURL" context:&tabCurrentURLObservingContext];
    _tab = tab;
    [_tab addObserver:self forKeyPath:@"currentURL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&tabCurrentURLObservingContext];
    [self didChangeValueForKey:@"tab"];
}

- (void)setContentViewController:(UIViewController<ACNavigationTarget> *)contentViewController
{
    if (contentViewController == _contentViewController)
        return;
    [self willChangeValueForKey:@"contentViewController"];
    [_contentViewController removeObserver:self forKeyPath:@"editing" context:&contentViewControllerEditingObservingContext];

    UIViewController *oldViewController = _contentViewController;
    
    [oldViewController willMoveToParentViewController:nil];
    [contentViewController willMoveToParentViewController:self];
    [oldViewController viewWillDisappear:NO];
    if (self.isViewLoaded && self.view.window)
        [contentViewController viewWillAppear:NO];
    
    [oldViewController.view removeFromSuperview];
    [oldViewController removeFromParentViewController];
    if (contentViewController)
    {
        [self addChildViewController:contentViewController];
        [self.contentView addSubview:contentViewController.view];
        contentViewController.view.frame = self.contentView.bounds;
        contentViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    [oldViewController viewDidDisappear:NO];
    [oldViewController didMoveToParentViewController:nil];
    [contentViewController didMoveToParentViewController:self];
    [contentViewController viewDidAppear:NO];
    
    _contentViewController = contentViewController;
    [_contentViewController addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&contentViewControllerEditingObservingContext];

    // Layou top bar with tool button
    UIButton *newToolButton = nil;
    if ([_contentViewController respondsToSelector:@selector(toolButton)])
        newToolButton = [_contentViewController toolButton];
    if (newToolButton != buttonTools)
    {
        CGRect bounds = topBarView.bounds;
        CGRect newToolButtonFrame = CGRectMake(7, 7, 75, 30);
        newToolButton.frame = newToolButtonFrame;
        if (buttonTools == nil)
        {
            // Animate jump bar and than fade in new button
            [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
                jumpBar.frame = CGRectMake(CGRectGetMaxX(newToolButtonFrame) + 7, 7, bounds.size.width - (7 + 75 + 7) * 2, 30);
            } completion:^(BOOL finished) {
                buttonTools = newToolButton;
                [topBarView addSubview:buttonTools];
                buttonTools.alpha = 0;
                [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
                    buttonTools.alpha = 1;
                }];
            }];
        }
        else if (newToolButton == nil)
        {
            // Fade out current button and resize jump bar
            [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
                buttonTools.alpha = 0;
            } completion:^(BOOL finished) {
                [buttonTools removeFromSuperview];
                buttonTools = nil;
                [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
                    jumpBar.frame = CGRectMake(7, 7, bounds.size.width - (7 + 75 + 7 + 7), 30);
                }];
            }];
        }
        else
        {
            [UIView transitionFromView:buttonTools toView:newToolButton duration:STYLE_ANIMATION_DURATION options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
                buttonTools = newToolButton;
            }];
        }
    }
    // Setup jump bar filter field
    [jumpBar.textElement resignFirstResponder];
    [(UIButton *)jumpBar.textElement.rightView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [(UIButton *)jumpBar.textElement.rightView addTarget:self action:@selector(jumpBarTextElementRightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    jumpBar.textElement.delegate = [_contentViewController respondsToSelector:@selector(delegateForFilterField:)] ? [_contentViewController delegateForFilterField:jumpBar.textElement] : nil; 

    [self didChangeValueForKey:@"contentViewController"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &contentViewControllerEditingObservingContext)
    {
        self.buttonEdit.selected = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
    }
    else if (context == &tabCurrentURLObservingContext)
    {
        NSURL *currentURL = self.tab.currentURL;
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        __block BOOL currentURLIsEqualToProjectsDirectory = NO;
        __block BOOL currentURLExists = NO;
        __block BOOL currentURLIsDirectory = NO;
        [fileCoordinator coordinateReadingItemAtURL:currentURL options:NSFileCoordinatorReadingResolvesSymbolicLink | NSFileCoordinatorReadingWithoutChanges error:NULL byAccessor:^(NSURL *newURL) {
            currentURLIsEqualToProjectsDirectory = [newURL isEqual:[self.tab.application projectsDirectory]];
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            currentURLExists = [fileManager fileExistsAtPath:[newURL path] isDirectory:&currentURLIsDirectory];
        }];
        if (currentURLIsEqualToProjectsDirectory)
        {
            if (![self.contentViewController isKindOfClass:[ACProjectTableController class]])
                self.contentViewController = [[ACProjectTableController alloc] init];
            ACProjectTableController *projectTableController = (ACProjectTableController *)self.contentViewController;
            projectTableController.projectsDirectory = currentURL;
            projectTableController.tab = self.tab;
        }
        else if (currentURLExists)
        {
            if (currentURLIsDirectory)
            {
                if (![self.contentViewController isKindOfClass:[ACFileTableController class]])
                    self.contentViewController = [[ACFileTableController alloc] init];
                ACFileTableController *fileTableController = (ACFileTableController *)self.contentViewController;
                fileTableController.directory = currentURL;
                fileTableController.tab = self.tab;
            }
            else
            {
                if (![self.contentViewController isKindOfClass:[ACCodeFileController class]])
                    self.contentViewController = [[ACCodeFileController alloc] init];
                ACCodeFileController *codeFileController = (ACCodeFileController *)self.contentViewController;
                codeFileController.fileURL = currentURL;
                codeFileController.tab = self.tab;
            }
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - General methods

- (void)dealloc
{
    [self.contentViewController removeObserver:self forKeyPath:@"editing" context:&contentViewControllerEditingObservingContext];
    [self.tab removeObserver:self forKeyPath:@"currentURL" context:&tabCurrentURLObservingContext];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO create internal views if not connected in IB
    
    popoverController = [ECPopoverController new];
    
    // Setup present APIs to use this controller as reference.
    self.definesPresentationContext = YES;
    
    ////////////////////////////////////////////////////////////////////////////
    // Jump Bar
    jumpBar.delegate = self;
    jumpBar.minimumTextElementWidth = 0.4;
    if (self.contentViewController.toolButton)
        jumpBar.frame = CGRectMake(CGRectGetMaxX(self.contentViewController.toolButton.frame) + 7, 7, topBarView.bounds.size.width - (7 + 75 + 7) * 2, 30);
    // Text Element
    jumpBar.textElement = [ACJumpBarTextField new];
    jumpBar.textElement.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    jumpBar.textElement.placeholder = @"Filter";
    jumpBar.textElement.autocorrectionType = UITextAutocorrectionTypeNo;
    jumpBar.textElement.spellCheckingType = UITextSpellCheckingTypeNo;
    jumpBar.textElement.autocapitalizationType = UITextAutocapitalizationTypeNone;
    jumpBar.textElement.returnKeyType = UIReturnKeySearch;
    jumpBar.backgroundView = [[UIImageView alloc] initWithImage:[UIImage styleBackgroundImageWithColor:[UIColor styleAlternateBackgroundColor] borderColor:[UIColor styleForegroundColor]]];
    // Right button to search/remove search
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 16, 17)];
    [rightButton setImage:[UIImage styleSearchIconWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    [rightButton setImage:[UIImage styleCloseImageWithColor:[UIColor styleForegroundColor] outlineColor:nil shadowColor:[UIColor whiteColor]] forState:UIControlStateSelected];
    [rightButton setBackgroundImage:nil forState:UIControlStateNormal];
    [rightButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    [rightButton setBackgroundImage:nil forState:UIControlStateSelected];
    rightButton.adjustsImageWhenHighlighted = NO;
    jumpBar.textElement.rightView = rightButton;
    jumpBar.textElement.rightViewMode = UITextFieldViewModeAlways;
    jumpBar.textElement.clearButtonMode = UITextFieldViewModeAlways;
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
    //    jumpBar.textElement.leftView = [[UIImageView alloc] initWithImage:[UIImage styleSymbolImageWithColor:[UIColor styleSymbolColorBlue] letter:@"M"]];
    //    jumpBar.textElement.leftViewMode = UITextFieldViewModeUnlessEditing;
    if (self.contentViewController)
    {
        self.contentViewController.view.frame = self.contentView.bounds;
        self.contentViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (self.view.window)
            [self.contentViewController viewWillAppear:NO];
        [self.contentView addSubview:self.contentViewController.view];
        if (self.view.window)
            [self.contentViewController viewDidAppear:NO];
    }
}

- (void)viewDidUnload
{
    popoverController = nil;
    [self setJumpBar:nil];
    [self setTopBarView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Bar Methods

- (IBAction)editButtonAction:(id)sender
{
    [self.contentViewController setEditing:!self.contentViewController.editing animated:YES];
}

#pragma mark - JumpBar Methods

- (void)jumpBarBackAction:(id)sender
{
    [self.tab moveBackInHistory];
}

- (void)jumpBarBackLongAction:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // Create and initialize popover tool history controller
        if (popoverHistoryToolController == nil)
        {
            popoverHistoryToolController = [[ACPopoverHistoryToolController alloc] initWithStyle:UITableViewStylePlain];
        }
        popoverHistoryToolController.contentSizeForViewInPopover = CGSizeMake(300, MIN(439, [self.tab.historyItems count] * 44 - 1));
        popoverHistoryToolController.tab = self.tab;
        
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
        popoverBrowseFileToolController.contentSizeForViewInPopover = CGSizeMake(268, 219);
    }
    
    // Setup file browser
#warning update following line to new architecture
    //    [popoverBrowseFileToolController openURL:[NSURL ACURLWithPath:[jumpBar jumpPathUpThroughElement:sender]]];
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

// By default, when selected, the text element right button will remove the content of the field.
- (void)jumpBarTextElementRightButtonAction:(UIButton *)sender
{
    if (sender.isSelected)
    {
        id<UITextFieldDelegate> del = jumpBar.textElement.delegate;
        if (del && [del respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)])
        {
            if (![del textField:jumpBar.textElement shouldChangeCharactersInRange:NSMakeRange(0, [jumpBar.textElement.text length]) replacementString:@""])
                return;
        }
        jumpBar.textElement.text = @"";
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
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 10);
        
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

@end
