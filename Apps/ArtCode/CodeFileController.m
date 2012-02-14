//
//  CodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFileController.h"
#import "SingleTabController.h"
#import "CodeFileSearchBarController.h"
#import "QuickBrowsersContainerController.h"
#import "UIViewController+PresentingPopoverController.h"

#import <QuartzCore/QuartzCore.h>
#import "BezelAlert.h"
#import "TabController.h"
#import "TMTheme.h"
#import "UIColor+Contrast.h"
#import "UIColor+AppStyle.h"

#import "CodeFileKeyboardAccessoryView.h"
#import "CodeFileKeyboardAccessoryPopoverView.h"
#import "CodeFileCompletionsController.h"

#import "ShapePopoverBackgroundView.h"

#import "CodeFile.h"
#import "ArtCodeURL.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"


@interface CodeFileController () {
    UIActionSheet *_toolsActionSheet;
    CodeFileSearchBarController *_searchBarController;
    UIPopoverController *_quickBrowsersPopover;

    CGRect _keyboardFrame;
    CGRect _keyboardRotationFrame;
    
    /// Button inside keyboard accessory popover that look like the underneat button that presented the popover from the accessory.
    /// This button is supposed to have the same appearance of the underlying button and the same tag.
    UIButton *_keyboardAccessoryItemPopoverButton;
    
    /// Actions associated to items in the accessory view.
    NSArray *_keyboardAccessoryItemActions;
    
    /// The index of the accessory item action currently being performed.
    NSInteger _keyboardAccessoryItemCurrentActionIndex;
}

@property (nonatomic, strong) CodeView *codeView;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) CodeFile *codeFile;

@property (nonatomic, strong, readonly) CodeFileKeyboardAccessoryView *_keyboardAccessoryView;
@property (nonatomic, strong, readonly) CodeFileCompletionsController *_keyboardAccessoryItemCompletionsController;

/// Returns the content view used to display the content in the given editing state.
/// This method evaluate if using the codeView or the webView based on the current fileURL.
- (UIView *)_contentViewForEditingState:(BOOL)editingState;
- (UIView *)_contentView;

/// Indicates if the current content view is the web preview.
- (BOOL)_isWebPreview;
- (void)_loadWebPreviewContentAndTitle;

- (void)_layoutChildViews;

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer;
- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer;

- (void)_keyboardWillShow:(NSNotification *)notification;
- (void)_keyboardWillHide:(NSNotification *)notification;
- (void)_keyboardWillChangeFrame:(NSNotification *)notification;

- (void)_keyboardAccessoryItemSetupWithActions:(NSArray *)actions;
- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item;

@end

// from: http://developer.apple.com/library/mac/#documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_patterns/dq_patterns.html
#define PSIZE 14
static void drawStencilStar(void *info, CGContextRef myContext)
{
    int k;
    double r, theta;
    
    r = 0.8 * PSIZE / 2;
    theta = 2 * M_PI * (2.0 / 5.0); // 144 degrees
    
    CGContextTranslateCTM (myContext, PSIZE/2, PSIZE/2);
    
    CGContextMoveToPoint(myContext, 0, r);
    for (k = 1; k < 5; k++) {
        CGContextAddLineToPoint (myContext,
                                 r * sin(k * theta),
                                 r * cos(k * theta));
    }
    CGContextClosePath(myContext);
    CGContextFillPath(myContext);
}


@implementation CodeFileController

#pragma mark - Properties

@synthesize codeView = _codeView, webView = _webView, minimapView = _minimapView, minimapVisible = _minimapVisible, minimapWidth = _minimapWidth;
@synthesize fileURL = _fileURL, codeFile = _codeFile;
@synthesize _keyboardAccessoryItemCompletionsController;

- (CodeView *)codeView
{
    if (!_codeView)
    {
        __weak CodeFileController *this = self;
        
        _codeView = [CodeView new];
        _codeView.dataSource = self.codeFile;
        _codeView.delegate = self;
        _codeView.magnificationPopoverControllerClass = [ShapePopoverController class];
        
        _codeView.backgroundColor = [UIColor whiteColor];
        _codeView.caretColor = [UIColor blackColor];
        _codeView.selectionColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];

        _codeView.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        _codeView.contentInset = UIEdgeInsetsMake(10, 0, 10, 0);
        
        _codeView.lineNumbersEnabled = YES;
        _codeView.lineNumbersWidth = 30;
        _codeView.lineNumbersFont = [UIFont systemFontOfSize:10];
        _codeView.lineNumbersColor = [UIColor colorWithWhite:0.62 alpha:1];
        _codeView.lineNumbersBackgroundColor = [UIColor colorWithWhite:0.91 alpha:1];
        
        _codeView.alwaysBounceVertical = YES;
        _codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UISwipeGestureRecognizer *undoRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureUndo:)];
        undoRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        undoRecognizer.numberOfTouchesRequired = 2;
        [_codeView addGestureRecognizer:undoRecognizer];
        
        UISwipeGestureRecognizer *redoRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureRedo:)];
        redoRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        undoRecognizer.numberOfTouchesRequired = 2;
        [_codeView addGestureRecognizer:redoRecognizer];
        
        // Bookmark markers
        [_codeView addPassLayerBlock:^(CGContextRef context, TextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
            if (!line.isTruncation && [[this.artCodeTab.currentProject bookmarksForFile:this.artCodeTab.currentURL atLine:(lineNumber + 1)] count] > 0)
            {
                CGContextSetFillColorWithColor(context, this->_codeView.lineNumbersColor.CGColor);
                CGContextTranslateCTM(context, -lineBounds.origin.x, line.descent / 2.0 + 1);
                drawStencilStar(NULL, context);
            }
        } underText:NO forKey:@"bookmarkMarkers"];
        
        // Accessory view
        CodeFileKeyboardAccessoryView *accessoryView = [CodeFileKeyboardAccessoryView new];
        accessoryView.itemBackgroundImage = [[UIImage imageNamed:@"accessoryView_itemBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 12, 0, 12)];
        
        [accessoryView setItemDefaultWidth:59 + 4 forAccessoryPosition:KeyboardAccessoryPositionPortrait];
        [accessoryView setItemDefaultWidth:81 + 4 forAccessoryPosition:KeyboardAccessoryPositionLandscape];
        [accessoryView setItemDefaultWidth:36 + 4 forAccessoryPosition:KeyboardAccessoryPositionFloating]; // 44
        
        [accessoryView setContentInsets:UIEdgeInsetsMake(3, 0, 2, 0) forAccessoryPosition:KeyboardAccessoryPositionPortrait];
        [accessoryView setItemInsets:UIEdgeInsetsMake(0, 3, 0, 3) forAccessoryPosition:KeyboardAccessoryPositionPortrait];
        
        [accessoryView setContentInsets:UIEdgeInsetsMake(3, 4, 2, 3) forAccessoryPosition:KeyboardAccessoryPositionLandscape];
        [accessoryView setItemInsets:UIEdgeInsetsMake(0, 0, 0, 8) forAccessoryPosition:KeyboardAccessoryPositionLandscape];
        
        [accessoryView setContentInsets:UIEdgeInsetsMake(3, 10, 2, 7) forAccessoryPosition:KeyboardAccessoryPositionFloating];
        [accessoryView setItemInsets:UIEdgeInsetsMake(0, 0, 0, 3) forAccessoryPosition:KeyboardAccessoryPositionFloating];
        
        self.codeView.keyboardAccessoryView = accessoryView;
        
        // Accessory view popover setup
        accessoryView.itemPopoverView.contentSize = CGSizeMake(300, 300);
        accessoryView.itemPopoverView.contentInsets = UIEdgeInsetsMake(12, 12, 12, 12);
        accessoryView.itemPopoverView.backgroundView.image = [[UIImage imageNamed:@"accessoryView_popoverBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 50, 10)];
        [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowMiddle"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionMiddle];
        [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionFarRight];
        [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowLeft"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionFarLeft];
        accessoryView.itemPopoverView.arrowInsets = UIEdgeInsetsMake(12, 12, 12, 12);
        // Prepare handlers to show and hide controllers in keyboard accessory item popover
        accessoryView.willPresentPopoverForItemBlock = ^(CodeFileKeyboardAccessoryView *sender, NSUInteger itemIndex, CGRect popoverContentRect, NSTimeInterval animationDuration) {
            UIView *presentedView = nil;
            UIView *presentingView = sender.superview;
            presentedView = this._keyboardAccessoryItemCompletionsController.view;
            CGRect popoverContentFrame = CGRectIntegral([presentingView convertRect:sender.itemPopoverView.contentView.frame fromView:sender.itemPopoverView]);
            presentedView.frame = popoverContentFrame;
            [presentingView addSubview:presentedView];
            presentedView.alpha = 0;
            [UIView animateWithDuration:animationDuration animations:^{
                presentedView.alpha = 1;
            }];
        };
        accessoryView.willDismissPopoverForItemBlock = ^(CodeFileKeyboardAccessoryView *sender, NSTimeInterval animationDuration) {
            [UIView animateWithDuration:animationDuration animations:^{
                if (this._keyboardAccessoryItemCompletionsController.isViewLoaded)
                    this._keyboardAccessoryItemCompletionsController.view.alpha = 0;              
            } completion:^(BOOL finished) {
                if (this._keyboardAccessoryItemCompletionsController.isViewLoaded)
                    [this._keyboardAccessoryItemCompletionsController.view removeFromSuperview];
            }];
        };
        
        UIView *accessoryPopoverContentView = [UIView new];
        accessoryPopoverContentView.backgroundColor = [UIColor whiteColor];
        accessoryView.itemPopoverView.contentView = accessoryPopoverContentView;
        
        // Items actions
        #warning TODO set actions on code view selection changed
        _keyboardAccessoryItemActions = [TMKeyboardAction keyboardActionsConfigurationForScopeIdentifiersStack:[NSArray arrayWithObject:@"source.objc"]];
        
        // Items setup
        [self _keyboardAccessoryItemSetupWithActions:_keyboardAccessoryItemActions];
    }
    return _codeView;
}

- (UIWebView *)webView
{
    if (!_webView)
    {
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self _loadWebPreviewContentAndTitle];
    }
    return _webView;
}

- (CodeFileMinimapView *)minimapView
{
    if (!_minimapView)
    {
        _minimapView = [CodeFileMinimapView new];
        _minimapView.delegate = self;
        _minimapView.renderer = self.codeView.renderer;
        
        _minimapView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        _minimapView.contentInset = UIEdgeInsetsMake(10, 0, 10, 10);
        _minimapView.alwaysBounceVertical = YES;
        
        _minimapView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"minimap_Background"]];
        _minimapView.backgroundView.contentMode = UIViewContentModeTopLeft;
        _minimapView.lineDecorationInset = 10;
        _minimapView.lineShadowColor = [UIColor colorWithWhite:0 alpha:0.75];
        _minimapView.lineDefaultColor = [UIColor colorWithWhite:0.7 alpha:1];
    }
    return _minimapView;
}

- (void)setFileURL:(NSURL *)fileURL
{
    if (fileURL == _fileURL)
        return;
    
    self.loading = YES;
    [self willChangeValueForKey:@"fileURL"];
    
    _fileURL = fileURL;
    if (fileURL)
        [CodeFile codeFileWithFileURL:fileURL completionHandler:^(CodeFile *codeFile) {
            self.codeFile = codeFile;

            // Update CodeView environment settings
            if (self.codeFile)
            {
                UIColor *color = nil;
                color = [self.codeFile.theme.environmentAttributes objectForKey:TMThemeBackgroundColorEnvironmentAttributeKey];
                self.codeView.backgroundColor = color ? color : [UIColor whiteColor];
                self.codeView.lineNumbersColor = color ? [color colorByIncreasingContrast:.38] : [UIColor colorWithWhite:0.62 alpha:1];
                self.codeView.lineNumbersBackgroundColor = color ? [color colorByIncreasingContrast:.09] : [UIColor colorWithWhite:0.91 alpha:1];
                color = [self.codeFile.theme.environmentAttributes objectForKey:TMThemeCaretColorEnvironmentAttributeKey];
                self.codeView.caretColor = color ? color : [UIColor blackColor];
                color = [self.codeFile.theme.environmentAttributes objectForKey:TMThemeSelectionColorEnvironmentAttributeKey];
                self.codeView.selectionColor = color ? color : [[UIColor blueColor] colorWithAlphaComponent:0.3];
            }
            self.loading = NO;
        }];
    else
        self.codeFile = nil;
        
    [self didChangeValueForKey:@"fileURL"];
}

- (void)setCodeFile:(CodeFile *)codeFile
{
    if (codeFile == _codeFile)
        return;
    
    [self willChangeValueForKey:@"codeFile"];
    
    [_codeFile removePresenter:self];
    _codeFile = codeFile;
    _codeView.dataSource = _codeFile;
    [_codeView updateAllText];
    [_codeFile addPresenter:self];
    
    [self _loadWebPreviewContentAndTitle];
    
    [self didChangeValueForKey:@"codeFile"];
}

- (CGFloat)minimapWidth
{
    if (_minimapWidth == 0)
        _minimapWidth = 124;
    return _minimapWidth;
}

- (void)setMinimapVisible:(BOOL)minimapVisible
{
    [self setMinimapVisible:minimapVisible animated:NO];
}

- (void)setMinimapVisible:(BOOL)minimapVisible animated:(BOOL)animated
{
    if (_minimapVisible == minimapVisible || [self _isWebPreview])
        return;
    
    [self willChangeValueForKey:@"minimapVisible"];
    if (minimapVisible)
        [self.view addSubview:self.minimapView];
    if (animated)
    {
        [self _layoutChildViews];
        _minimapVisible = minimapVisible;
        [UIView animateWithDuration:0.25 animations:^{
            [self _layoutChildViews];
        } completion:^(BOOL finished) {
            if (!_minimapVisible)
                [_minimapView removeFromSuperview];
        }];
    }
    else
    {
        _minimapVisible = minimapVisible;
        if (!_minimapVisible)
            [_minimapView removeFromSuperview];
        [self _layoutChildViews];
    }
    [self didChangeValueForKey:@"minimapVisible"];
}

#pragma mark - Single tab controller informal protocol

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar
{
    return YES;
}

- (void)singleTabController:(SingleTabController *)singleTabController titleControlAction:(id)sender
{
    QuickBrowsersContainerController *quickBrowserContainerController = [QuickBrowsersContainerController defaultQuickBrowsersContainerControllerForContentController:self];
    if (!_quickBrowsersPopover)
    {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:quickBrowserContainerController];
        [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        
        _quickBrowsersPopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        _quickBrowsersPopover.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
    }
    quickBrowserContainerController.presentingPopoverController = _quickBrowsersPopover;
    quickBrowserContainerController.openingButton = sender;
    
    [_quickBrowsersPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - Toolbar Items Actions

- (void)toolButtonAction:(id)sender
{
    if (!_toolsActionSheet)
        _toolsActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select action" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Toggle find and replace", @"Toggle minimap", @"Show/hide tabs", nil];
    
    [_toolsActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {    
        case 0: // toggle find/replace 
        {
            if (!_searchBarController)
            {
                _searchBarController = [[UIStoryboard storyboardWithName:@"SearchBar" bundle:nil] instantiateInitialViewController];
                _searchBarController.targetCodeFileController = self;
            }
            if (self.singleTabController.toolbarViewController != _searchBarController)
            {
                [self.singleTabController setToolbarViewController:_searchBarController animated:YES];
                [_searchBarController.findTextField becomeFirstResponder];
            }
            else
            {
                [self.singleTabController setToolbarViewController:nil animated:YES];
            }
            break;
        }
        
        case 1: // toggle minimap
        {
            [self setMinimapVisible:!self.minimapVisible animated:YES];
            if (self.minimapVisible)
                self.minimapView.selectionRectangle = self.codeView.bounds;
            break;
        }
            
        case 2: // toggle tabs
        {
            [self.tabCollectionController setTabBarVisible:!self.tabCollectionController.isTabBarVisible animated:YES];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    self.editButtonItem.title = @"";
    self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
    
    [self.view addSubview:[self _contentView]];
}

- (void)viewDidLoad
{
    self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"topBarItem_Tools"] style:UIBarButtonItemStylePlain target:self action:@selector(toolButtonAction:)]];
    
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    _keyboardFrame = CGRectNull;
    _keyboardRotationFrame = CGRectNull;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _minimapView = nil;
    _codeView = nil;
    
    _toolsActionSheet = nil;
    _searchBarController = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _layoutChildViews];
}

#pragma mark - Controller Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [_quickBrowsersPopover dismissPopoverAnimated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (self.minimapVisible)
        self.minimapView.selectionRectangle = self.codeView.bounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if (!_minimapVisible)
        _minimapView = nil;
    
    if ([self _isWebPreview])
        self.codeView = nil;
    else
        self.webView = nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    UIView *oldContentView = [self _contentView];
    
    [self willChangeValueForKey:@"editing"];
    
    [super setEditing:editing animated:animated];
    self.editButtonItem.title = @"";
    
    UIView *currentContentView = [self _contentView];
    if ([currentContentView isKindOfClass:[CodeView class]])
        [(CodeView *)currentContentView setEditing:editing];
    
    if (oldContentView != currentContentView)
    {
        [self _loadWebPreviewContentAndTitle];
        
        [UIView transitionFromView:oldContentView toView:currentContentView duration:animated ? 0.2 : 0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
            [self _layoutChildViews];
            [self didChangeValueForKey:@"editing"];
        }];
    }
    else
    {
        [self didChangeValueForKey:@"editing"];
    }
}

#pragma mark - Minimap Delegate Methods

- (BOOL)codeFileMinimapView:(CodeFileMinimapView *)minimapView 
           shouldRenderLine:(TextRendererLine *)line 
                     number:(NSUInteger)lineNumber 
                      range:(NSRange)range
                  withColor:(UIColor *__autoreleasing *)lineColor 
                 decoration:(CodeFileMinimapLineDecoration *)decoration 
            decorationColor:(UIColor *__autoreleasing *)decorationColor
{
    if (!line.isTruncation && [[self.artCodeTab.currentProject bookmarksForFile:self.artCodeTab.currentURL atLine:(lineNumber + 1)] count] > 0)
    {
        *decoration = CodeFileMinimapLineDecorationDisc;
        *decorationColor = [UIColor whiteColor];
    }
    
    if (*decoration == 0 && line.width < line.height)
        return NO;
    
    switch ([self.codeFile kindOfTextInRange:range]) {
        case CodeFileCommentTextKind:
            *lineColor = [UIColor styleMinimapCommentColor];
            break;
            
        case CodeFilePreprocessorTextKind:
            *lineColor = [UIColor styleMinimapPreprocessorColor];
            break;
            
        case CodeFileSymbolTextKind:
            *lineColor = [UIColor styleMinimapSymbolColor];
            break;
            
        default:
            break;
    }
    
    return YES;
}

- (BOOL)codeFileMinimapView:(CodeFileMinimapView *)minimapView shouldChangeSelectionRectangle:(CGRect)newSelection
{
    [self.codeView scrollRectToVisible:newSelection animated:YES];
    return NO;
}

#pragma mark - CodeFilePresenter

- (void)codeFile:(CodeFile *)codeFile didReplaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    [self.codeView updateTextFromStringRange:range toStringRange:NSMakeRange(range.location, [string length])];
}

- (void)codeFile:(CodeFile *)codeFile didAddAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    [self.codeView updateTextFromStringRange:range toStringRange:range];
}

#pragma mark - Code View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_minimapVisible && scrollView == _codeView)
    {
        _minimapView.selectionRectangle = _codeView.bounds;
    }
}

- (void)codeView:(CodeView *)codeView selectedLineNumber:(NSUInteger)lineNumber
{
    NSArray *bookmarks = [self.artCodeTab.currentProject bookmarksForFile:self.artCodeTab.currentURL atLine:lineNumber];
    if ([bookmarks count] == 0)
    {
        [self.artCodeTab.currentProject addBookmarkWithFileURL:self.artCodeTab.currentURL line:lineNumber note:nil];
    }
    else
    {
        for (ProjectBookmark *bookmark in bookmarks)
        {
            [self.artCodeTab.currentProject removeBookmark:bookmark];
        }
    }
    [self.codeView setNeedsDisplay];
    if (_minimapVisible)
        [_minimapView setNeedsDisplay];
}

- (BOOL)codeView:(CodeView *)codeView shouldShowKeyboardAccessoryViewInView:(UIView *__autoreleasing *)view withFrame:(CGRect *)frame
{
    ECASSERT(view && frame);
    
    /// Set keyboard position specific accessory popover properties
    if (codeView.keyboardAccessoryView.isSplit)
    {
        self._keyboardAccessoryView.itemPopoverView.positioningInsets = UIEdgeInsetsMake(4, 3, 4, 3);
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(62, 54) forMetaPosition:PopoverViewArrowMetaPositionFarLeft];
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(56, 54) forMetaPosition:PopoverViewArrowMetaPositionMiddle];
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(62, 54) forMetaPosition:PopoverViewArrowMetaPositionFarRight];
    }
    else if (_keyboardFrame.size.width > 768)
    {
        self._keyboardAccessoryView.itemPopoverView.positioningInsets = UIEdgeInsetsMake(4, -3, 4, -3);
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(100, 54) forMetaPosition:PopoverViewArrowMetaPositionFarLeft];
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(99, 54) forMetaPosition:PopoverViewArrowMetaPositionMiddle];
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(100, 54) forMetaPosition:PopoverViewArrowMetaPositionFarRight];
    }
    else
    {
        self._keyboardAccessoryView.itemPopoverView.positioningInsets = UIEdgeInsetsMake(4, -3, 4, -3);
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(79, 54) forMetaPosition:PopoverViewArrowMetaPositionFarLeft];
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(77, 54) forMetaPosition:PopoverViewArrowMetaPositionMiddle];
        [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(79, 54) forMetaPosition:PopoverViewArrowMetaPositionFarRight];
    }
    
    if ((*frame).origin.y - (*view).bounds.origin.y < (*view).bounds.size.height / 4)
        codeView.keyboardAccessoryView.flipped = YES;
    
    UIView *targetView = self.view.window.rootViewController.view;
    *frame = [targetView convertRect:*frame fromView:*view];
    *view = targetView;
    
    return YES;
}

- (void)codeView:(CodeView *)codeView didShowKeyboardAccessoryViewInView:(UIView *)view withFrame:(CGRect)accessoryFrame
{
    if (!codeView.keyboardAccessoryView.isSplit)
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
            CGRect frame = self.view.frame;
            if (!CGRectIsNull(_keyboardFrame))
            {
                frame.size.height = _keyboardFrame.origin.y - codeView.keyboardAccessoryView.frame.size.height;
            }
            else if (!CGRectIsNull(_keyboardRotationFrame))
            {
                frame.size.height = _keyboardRotationFrame.origin.y - codeView.keyboardAccessoryView.frame.size.height;
            }
            else
            {
                frame.size.height = frame.size.height - codeView.keyboardAccessoryView.frame.size.height;
            }
            self.view.frame = frame;
        } completion:^(BOOL finished) {
            // Scroll to selection
            RectSet *selectionRects = self.codeView.selectionRects;
            if (selectionRects == nil)
                return;
            [self.codeView scrollRectToVisible:CGRectInset(selectionRects.bounds, 0, -50) animated:YES];
        }];
    }
}

- (BOOL)codeViewShouldHideKeyboardAccessoryView:(CodeView *)codeView
{
    [self._keyboardAccessoryView dismissPopoverForItemAnimated:YES];
    
    if (!codeView.keyboardAccessoryView.isSplit)
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
            CGRect frame = self.view.frame;
            if (!CGRectIsNull(_keyboardFrame))
            {
                frame.size.height = _keyboardFrame.origin.y;
            }
            else if (!CGRectIsNull(_keyboardRotationFrame))
            {
                frame.size.height = _keyboardRotationFrame.origin.y;
            }
            else
            {
                frame.size.height = frame.size.height + codeView.keyboardAccessoryView.frame.size.height;
            }
            _keyboardFrame = CGRectNull;
            _keyboardRotationFrame = CGRectNull;
            self.view.frame = frame;
        } completion:nil];
    }
    return YES;
}

- (void)selectionDidChangeForCodeView:(CodeView *)codeView
{
    // TODO change title and keyboard accessories
}

#pragma mark - Webview delegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.loading = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.loading = NO;
    if ([self _isWebPreview])
        self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

#pragma mark - Public Methods

- (void)showCompletionPopoverForCurrentSelectionAtKeyboardAccessoryItemIndex:(NSUInteger)accessoryItemIndex
{
    ECASSERT(self._keyboardAccessoryView.superview);
    
    self._keyboardAccessoryItemCompletionsController.offsetInDocumentForCompletions = self.codeView.selectionRange.location;
    if (![self._keyboardAccessoryItemCompletionsController hasCompletions])
    {
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"No completions" image:[UIImage imageNamed:@"bezelAlert_nothingIcon"] displayImmediatly:YES];
        return;
    }
    
    [self._keyboardAccessoryView presentPopoverForItemAtIndex:accessoryItemIndex permittedArrowDirection:(self.codeView.keyboardAccessoryView.isFlipped ? UIPopoverArrowDirectionUp : UIPopoverArrowDirectionDown) animated:YES];
}

#pragma mark - Private Methods

- (UIView *)_contentViewForEditingState:(BOOL)editingState
{
    // TODO better check for file type
    if (editingState || ![[self.fileURL pathExtension] isEqualToString:@"html"])
    {
        return self.codeView;
    }
    else
    {
        return self.webView;
    }
}

- (UIView *)_contentView
{
    return [self _contentViewForEditingState:self.isEditing];
}

- (BOOL)_isWebPreview
{
    return [self _contentViewForEditingState:self.isEditing] == _webView;
}

- (void)_loadWebPreviewContentAndTitle
{
    if ([self _isWebPreview] && self.codeFile)
    {
        [self.webView loadHTMLString:[self.codeFile string] baseURL:self.fileURL];
        self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    else
    {
        self.title = nil;
    }
}

- (void)_layoutChildViews
{
    CGRect frame = (CGRect){ CGPointZero, self.view.frame.size };
    if ([self _isWebPreview])
    {
        self.webView.frame = frame;
    }
    else
    {
        if (self.minimapVisible)
        {
            self.codeView.frame = CGRectMake(0, 0, frame.size.width - self.minimapWidth, frame.size.height);
            self.minimapView.frame = CGRectMake(frame.size.width - self.minimapWidth, 0, self.minimapWidth, frame.size.height);
        }
        else
        {
            self.codeView.frame = frame;
            _minimapView.frame = CGRectMake(frame.size.width, 0, self.minimapWidth, frame.size.height);
        }
    }
}

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer
{
    [_codeView.undoManager undo];
}

- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer
{
    [_codeView.undoManager redo];
}

- (void)_keyboardWillChangeFrame:(NSNotification *)notification
{
    _keyboardRotationFrame = [self.view convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
}

- (void)_keyboardWillShow:(NSNotification *)notification
{
    _keyboardFrame = [self.view convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    _keyboardRotationFrame = CGRectNull;
    [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0 options:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 | UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect frame = self.view.frame;
        frame.size.height = _keyboardFrame.origin.y;
        self.view.frame = frame;
    } completion:nil];
    
    [self._keyboardAccessoryView dismissPopoverForItemAnimated:YES];
}

- (void)_keyboardWillHide:(NSNotification *)notification
{
    [self _keyboardWillShow:notification];
}

#pragma mark - Keyboard Accessory Item Methods

- (CodeFileKeyboardAccessoryView *)_keyboardAccessoryView
{
    return (CodeFileKeyboardAccessoryView *)self.codeView.keyboardAccessoryView;
}

- (CodeFileCompletionsController *)_keyboardAccessoryItemCompletionsController
{
    if (!_keyboardAccessoryItemCompletionsController)
    {
        _keyboardAccessoryItemCompletionsController = [[CodeFileCompletionsController alloc] initWithStyle:UITableViewStylePlain];
        _keyboardAccessoryItemCompletionsController.targetCodeFileController = self;
        _keyboardAccessoryItemCompletionsController.targetKeyboardAccessoryView = self._keyboardAccessoryView;
        _keyboardAccessoryItemCompletionsController.contentSizeForViewInPopover = CGSizeMake(300, 300);
    }
    return _keyboardAccessoryItemCompletionsController;
}

- (void)_keyboardAccessoryItemSetupWithActions:(NSArray *)actions
{
    ECASSERT([actions count] == 11);
    
    CodeFileKeyboardAccessoryView *accessoryView = (CodeFileKeyboardAccessoryView *)self.codeView.keyboardAccessoryView;
    
    // Items
    if (accessoryView.items == nil)
    {
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:11];
        CodeFileKeyboardAccessoryItem *item = nil;
        TMKeyboardAction *action = nil;
        
        for (NSInteger i = 0; i < 11; ++i)
        {
            item = [[CodeFileKeyboardAccessoryItem alloc] initWithTitle:[NSString stringWithFormat:@"%d", i] style:UIBarButtonItemStylePlain target:self action:@selector(_keyboardAccessoryItemAction:)];
            
            if (i == 0)
            {
                [item setWidth:44 + 4 forAccessoryPosition:KeyboardAccessoryPositionFloating];
            }
            else if (i == 10)
            {
                [item setWidth:63 + 4 forAccessoryPosition:KeyboardAccessoryPositionPortrait];
                [item setWidth:82 + 4 forAccessoryPosition:KeyboardAccessoryPositionLandscape];
                [item setWidth:44 + 4 forAccessoryPosition:KeyboardAccessoryPositionFloating];
            }
            else 
            {
                if (i % 2)
                    [item setWidth:60 + 4 forAccessoryPosition:KeyboardAccessoryPositionPortrait];
            }
            
            action = [actions objectAtIndex:i];
            item.title = action.title;
            item.image = [action image];            
            item.tag = i;
            [items addObject:item];
        }
        
        accessoryView.items = items;
    }
    else
    {
        NSArray *items = accessoryView.items;
        [items enumerateObjectsUsingBlock:^(CodeFileKeyboardAccessoryItem *item, NSUInteger itemIndex, BOOL *stop) {
            TMKeyboardAction *action = [actions objectAtIndex:itemIndex];
            item.title = action.title;
            item.image = [action image];
        }];
        accessoryView.items = items;
    }
}

- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item
{
    _keyboardAccessoryItemCurrentActionIndex = item.tag;
    [[_keyboardAccessoryItemActions objectAtIndex:item.tag] executeActionOnTarget:self];
}

#pragma mark Keyboard Actions Target Methods

- (BOOL)keyboardAction:(TMKeyboardAction *)keyboardAction canPerformSelector:(SEL)selector
{
    if ([self forwardingTargetForSelector:selector] != nil)
        return YES;
    if (selector == @selector(showCompletionsAtCursor))
        return YES;
    ECASSERT(NO && "An action called a not supported selector");
    return NO;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (aSelector == @selector(insertText:) || aSelector == @selector(deleteBackward))
        return self.codeView;
    if (aSelector == @selector(undo) || aSelector == @selector(redo))
        return self.codeView.undoManager;
    return nil;
}

- (void)showCompletionsAtCursor
{
    [self showCompletionPopoverForCurrentSelectionAtKeyboardAccessoryItemIndex:_keyboardAccessoryItemCurrentActionIndex];
}

@end
