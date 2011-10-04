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
static CGFloat _topBarHeight = 44.0;
static CGFloat _buttonSpacing = 7.0;
static CGFloat _buttonWidth = 75.0;


@interface ACNavigationController ()
{
    ECPopoverController *popoverController;
    
    // Jump Bar
    UILongPressGestureRecognizer *jumpBarElementLongPressRecognizer;
    ACPopoverHistoryToolController *popoverHistoryToolController;
    ACFileTableController *popoverBrowseFileToolController;
}
@property (nonatomic, strong) UIViewController *contentViewController;
- (void)loadContentView;

#pragma mark Navigation Tools

@property (nonatomic, strong) IBOutlet UIView *topBarView;
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;
@property (nonatomic, strong) IBOutlet UIButton *buttonTools;
@property (nonatomic, strong) IBOutlet UIButton *buttonEdit;

#pragma mark Head Bar Methods

- (IBAction)editButtonAction:(id)sender;

@end

@implementation ACNavigationController

#pragma mark - Properties

@synthesize topBarView = _topBarView, jumpBar = _jumpBar, buttonEdit = _buttonEdit, buttonTools = _buttonTools;
@synthesize tab = _tab;
@synthesize contentViewController = _contentViewController, contentView = _contentView;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self.contentViewController setEditing:editing animated:animated];
}

+ (NSSet *)keyPathsForValuesAffectingEditing
{
    return [NSSet setWithObject:@"contentViewController.editing"];
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
    [self.jumpBar.textElement resignFirstResponder];
    self.jumpBar.textElement.delegate = nil;
    [self willChangeValueForKey:@"contentViewController"];
    if (_contentViewController)
    {
        [_contentViewController removeObserver:self forKeyPath:@"editing" context:&contentViewControllerEditingObservingContext];
        [_contentViewController willMoveToParentViewController:nil];
        if (self.isViewLoaded && self.view.window)
            [_contentViewController viewWillDisappear:NO];
        [_contentViewController.view removeFromSuperview];
        [self.buttonTools removeFromSuperview];
        self.buttonTools = nil;
        if (self.isViewLoaded && self.view.window)
            [_contentViewController viewDidDisappear:NO];
        [_contentViewController removeFromParentViewController];
        [_contentViewController didMoveToParentViewController:nil];
    }
    
    _contentViewController = contentViewController;
    
    if (_contentViewController)
    {
        [_contentViewController willMoveToParentViewController:self];
        [self addChildViewController:_contentViewController];
        [_contentViewController didMoveToParentViewController:self];
        if (self.isViewLoaded)
        {
            if (self.view.window)
                [_contentViewController viewWillAppear:NO];
            [self loadContentView];
            if (self.view.window)
                [_contentViewController viewDidAppear:NO];
        }
        [_contentViewController addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&contentViewControllerEditingObservingContext];
    }
    
    [self didChangeValueForKey:@"contentViewController"];
}

- (UIView *)contentView
{
    if (!self.isViewLoaded)
        return nil;
    if (!_contentView)
    {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 44.0, self.view.bounds.size.width, self.view.bounds.size.height - 44.0)];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _contentView.backgroundColor = [UIColor styleBackgroundColor];
    }
    return _contentView;
}

- (UIView *)topBarView
{
    if (!self.isViewLoaded)
        return nil;
    if (!_topBarView)
    {
        _topBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, _topBarHeight)];
        _topBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _topBarView.backgroundColor = [UIColor styleBackgroundColor];
    }
    return _topBarView;
}

- (ECJumpBar *)jumpBar
{
    if (!self.isViewLoaded)
        return nil;
    if (!self.topBarView)
        return nil;
    if (!_jumpBar)
    {
        _jumpBar = [[ECJumpBar alloc] initWithFrame:CGRectMake(self.buttonTools ? _buttonWidth + _buttonSpacing : 0.0, _buttonSpacing, self.topBarView.bounds.size.width - _buttonSpacing * 2 - (self.buttonTools ?_buttonWidth + _buttonSpacing : 0.0) - (self.buttonEdit ? _buttonWidth + _buttonSpacing : 0.0), self.topBarView.bounds.size.height - _buttonSpacing * 2)];
        _jumpBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _jumpBar.delegate = self;
        [(UIButton *)_jumpBar.textElement.rightView addTarget:self action:@selector(jumpBarTextElementRightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _jumpBar.minimumTextElementWidth = 0.4;
        // Text Element
        _jumpBar.textElement = [ACJumpBarTextField new];
        _jumpBar.textElement.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _jumpBar.textElement.placeholder = @"Filter";
        _jumpBar.textElement.autocorrectionType = UITextAutocorrectionTypeNo;
        _jumpBar.textElement.spellCheckingType = UITextSpellCheckingTypeNo;
        _jumpBar.textElement.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _jumpBar.textElement.returnKeyType = UIReturnKeySearch;
        _jumpBar.backgroundView = [[UIImageView alloc] initWithImage:[UIImage styleBackgroundImageWithColor:[UIColor styleAlternateBackgroundColor] borderColor:[UIColor styleForegroundColor]]];
        // Right button to search/remove search
        UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 16, 17)];
        [rightButton setImage:[UIImage styleSearchIconWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        [rightButton setImage:[UIImage styleCloseImageWithColor:[UIColor styleForegroundColor] outlineColor:nil shadowColor:[UIColor whiteColor]] forState:UIControlStateSelected];
        [rightButton setBackgroundImage:nil forState:UIControlStateNormal];
        [rightButton setBackgroundImage:nil forState:UIControlStateHighlighted];
        [rightButton setBackgroundImage:nil forState:UIControlStateSelected];
        rightButton.adjustsImageWhenHighlighted = NO;
        _jumpBar.textElement.rightView = rightButton;
        _jumpBar.textElement.rightViewMode = UITextFieldViewModeAlways;
        _jumpBar.textElement.clearButtonMode = UITextFieldViewModeAlways;
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
        _jumpBar.backElement = backButton;
    }
    return _jumpBar;
}

- (UIButton *)buttonTools
{
    if (!self.isViewLoaded)
        return nil;
    if (!self.topBarView)
        return nil;
    if (!self.contentViewController || ![self.contentViewController respondsToSelector:@selector(toolButton)])
        return nil;
    if (!_buttonTools)
    {
        _buttonTools = [self.contentViewController toolButton];
        _buttonTools.frame = CGRectMake(_buttonSpacing, _buttonSpacing, _buttonWidth, self.topBarView.bounds.size.height - _buttonSpacing * 2);
    }
    return _buttonTools;
}

- (UIButton *)buttonEdit
{
    if (!self.isViewLoaded)
        return nil;
    if (!self.topBarView)
        return nil;
    if (!self.contentViewController)
        return nil;
    if (!_buttonEdit)
    {
        _buttonEdit = [[UIButton alloc] initWithFrame:CGRectMake(self.topBarView.bounds.size.width - _buttonSpacing - _buttonWidth, _buttonSpacing, _buttonWidth, self.topBarView.bounds.size.height - _buttonSpacing * 2)];
        _buttonEdit.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_buttonEdit setImage:[UIImage styleAddImageWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        [_buttonEdit setTitle:@"Edit" forState:UIControlStateNormal];
        [_buttonEdit setTitleColor:[UIColor styleForegroundColor] forState:UIControlStateNormal];
        [_buttonEdit setTitleShadowColor:[UIColor styleForegroundShadowColor] forState:UIControlStateNormal];
        [_buttonEdit setTitle:@"Done" forState:UIControlStateSelected];
        [_buttonEdit setTitleColor:[UIColor styleThemeColorOne] forState:UIControlStateSelected];
        _buttonEdit.adjustsImageWhenHighlighted = NO;
    }
    return _buttonEdit;
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

#pragma mark - Content management

- (void)loadContentView
{
    if (self.view.window)
        [self.contentViewController viewWillAppear:NO];
    [self.contentView addSubview:self.contentViewController.view];
    self.contentViewController.view.frame = self.contentView.bounds;
    self.contentViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (self.buttonTools)
        [self.topBarView addSubview:self.buttonTools];
    if (self.view.window)
        [self.contentViewController viewDidAppear:NO];

    // Layou top bar with tool button
//    UIButton *newToolButton = nil;
//    if ([_contentViewController respondsToSelector:@selector(toolButton)])
//        newToolButton = [_contentViewController toolButton];
//    if (newToolButton != buttonTools)
//    {
//        if (buttonTools == nil)
//        {
//            // Animate jump bar and than fade in new button
//            [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
//                jumpBar.frame = CGRectMake(CGRectGetMaxX(newToolButtonFrame) + 7, 7, bounds.size.width - (7 + 75 + 7) * 2, 30);
//            } completion:^(BOOL finished) {
//                buttonTools = newToolButton;
//                [topBarView addSubview:buttonTools];
//                buttonTools.alpha = 0;
//                [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
//                    buttonTools.alpha = 1;
//                }];
//            }];
//        }
//        else if (newToolButton == nil)
//        {
//            // Fade out current button and resize jump bar
//            [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
//                buttonTools.alpha = 0;
//            } completion:^(BOOL finished) {
//                [buttonTools removeFromSuperview];
//                buttonTools = nil;
//                [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
//                    jumpBar.frame = CGRectMake(7, 7, bounds.size.width - (7 + 75 + 7 + 7), 30);
//                }];
//            }];
//        }
//        else
//        {
//            [UIView transitionFromView:buttonTools toView:newToolButton duration:STYLE_ANIMATION_DURATION options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
//                buttonTools = newToolButton;
//            }];
//        }
//    }
    // Setup jump bar filter field
    self.jumpBar.textElement.delegate = [_contentViewController respondsToSelector:@selector(delegateForFilterField:)] ? [_contentViewController delegateForFilterField:self.jumpBar.textElement] : nil;
    [self.jumpBar setJumpPath:[self.tab.application pathRelativeToProjectsDirectory:self.tab.currentURL] animated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    popoverController = [ECPopoverController new];
    
    if (self.topBarView)
        [self.view addSubview:self.topBarView];
    if (self.jumpBar)
        [self.topBarView addSubview:self.jumpBar];
    if (self.buttonEdit)
        [self.topBarView addSubview:self.buttonEdit];
    if (self.contentView)
        [self.view addSubview:self.contentView];
    if (self.contentViewController)
        [self loadContentView];
}

- (void)viewDidUnload
{
    popoverController = nil;
    self.jumpBar = nil;
    self.buttonTools = nil;
    self.buttonEdit = nil;
    self.topBarView = nil;
    self.contentView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if (self.isViewLoaded)
        return;
    self.topBarView = nil;
    self.jumpBar = nil;
    self.buttonTools = nil;
    self.buttonEdit = nil;
    self.contentView = nil;
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
        [popoverController presentPopoverFromRect:self.jumpBar.backElement.frame inView:self.jumpBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
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
    [popoverController presentPopoverFromRect:[sender frame] inView:self.jumpBar permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
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
        id<UITextFieldDelegate> del = self.jumpBar.textElement.delegate;
        if (del && [del respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)])
        {
            if (![del textField:self.jumpBar.textElement shouldChangeCharactersInRange:NSMakeRange(0, [self.jumpBar.textElement.text length]) replacementString:@""])
                return;
        }
        self.jumpBar.textElement.text = @"";
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
