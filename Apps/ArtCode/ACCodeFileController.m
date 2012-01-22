//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileController.h"
#import "ACSingleProjectBrowsersController.h"
#import "ACCodeFileSearchBarController.h"

#import <QuartzCore/QuartzCore.h>
#import <ECFoundation/NSTimer+block.h>
#import <ECFoundation/ECFileBuffer.h>
#import <ECUIKit/ECBezelAlert.h>
#import <ECUIKit/ECTabController.h>

#import "ACCodeFileKeyboardAccessoryView.h"
#import "ACCodeFileKeyboardAccessoryPopoverView.h"
#import "ACCodeFileCompletionsController.h"
#import "ACCodeFileAccessoryAction.h"
#import "ACCodeFileAccessoryItemsGridView.h"

#import "ACShapePopoverBackgroundView.h"

#import "ACCodeFile.h"
#import "ACTab.h"
#import "ACProject.h"


@interface ACCodeFileController () {
    UIActionSheet *_toolsActionSheet;
    ACCodeFileSearchBarController *_searchBarController;

    CGRect _keyboardFrame;
    CGRect _keyboardRotationFrame;
    
    NSTimer *_syntaxColoringTimer;
    
    /// Button inside keyboard accessory popover that look like the underneat button that presented the popover from the accessory.
    /// This button is supposed to have the same appearance of the underlying button and the same tag.
    UIButton *_keyboardAccessoryItemPopoverButton;
    
    /// Tag of the keyboard accessory button that is being customized via long press.
    NSUInteger _keyboardAccessoryItemCustomizingTag;
    
    /// Actions associated to items in the accessory view. Associations are made with tag (as array index) to ACCodeFileAccessoryAction.
    NSMutableArray *_keyboardAccessoryItemActions;
    
    NSOperationQueue *_consumerOperationQueue;
}

@property (nonatomic, strong) ECCodeView *codeView;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) ACCodeFile *codeFile;

@property (nonatomic, strong, readonly) ACCodeFileKeyboardAccessoryView *_keyboardAccessoryView;
@property (nonatomic, strong, readonly) ACCodeFileCompletionsController *_keyboardAccessoryItemCompletionsController;
@property (nonatomic, strong, readonly) UIViewController *_keyboardAccessoryItemCustomizeController;

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
- (void)_keyboardAccessoryItemLongPressHandler:(UILongPressGestureRecognizer *)recognizer;

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


@implementation ACCodeFileController

#pragma mark - Properties

@synthesize codeView = _codeView, webView = _webView, minimapView = _minimapView, minimapVisible = _minimapVisible, minimapWidth = _minimapWidth;
@synthesize fileURL = _fileURL, tab = _tab, codeFile = _codeFile;
@synthesize _keyboardAccessoryItemCompletionsController, _keyboardAccessoryItemCustomizeController;

- (ECCodeView *)codeView
{
    if (!_codeView)
    {
        __weak ACCodeFileController *this = self;
        
        _codeView = [ECCodeView new];
        _codeView.dataSource = self.codeFile;
        _codeView.delegate = self;
        _codeView.magnificationPopoverControllerClass = [ACShapePopoverController class];
        
        _codeView.backgroundColor = [UIColor whiteColor];
        _codeView.caretColor = [UIColor blackColor]; // TODO use TMTheme cursor color
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
        [_codeView addPassLayerBlock:^(CGContextRef context, ECTextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
            if (!line.isTruncation && [[this.singleProjectBrowsersController.tab.currentProject bookmarksForFile:this.singleProjectBrowsersController.tab.currentURL atLine:(lineNumber + 1)] count] > 0)
            {
                CGContextSetFillColorWithColor(context, this->_codeView.lineNumbersColor.CGColor);
                CGContextTranslateCTM(context, -lineBounds.origin.x, line.descent / 2.0 + 1);
                drawStencilStar(NULL, context);
            }
        } underText:NO forKey:@"bookmarkMarkers"];
        
        // Accessory view
        ACCodeFileKeyboardAccessoryView *accessoryView = [ACCodeFileKeyboardAccessoryView new];
        accessoryView.itemBackgroundImage = [[UIImage imageNamed:@"accessoryView_itemBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 12, 0, 12)];
        
        [accessoryView setItemDefaultWidth:59 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionPortrait];
        [accessoryView setItemDefaultWidth:81 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionLandscape];
        [accessoryView setItemDefaultWidth:36 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionFloating]; // 44
        
        [accessoryView setContentInsets:UIEdgeInsetsMake(3, 0, 2, 0) forAccessoryPosition:ECKeyboardAccessoryPositionPortrait];
        [accessoryView setItemInsets:UIEdgeInsetsMake(0, 3, 0, 3) forAccessoryPosition:ECKeyboardAccessoryPositionPortrait];
        
        [accessoryView setContentInsets:UIEdgeInsetsMake(3, 4, 2, 3) forAccessoryPosition:ECKeyboardAccessoryPositionLandscape];
        [accessoryView setItemInsets:UIEdgeInsetsMake(0, 0, 0, 8) forAccessoryPosition:ECKeyboardAccessoryPositionLandscape];
        
        [accessoryView setContentInsets:UIEdgeInsetsMake(3, 10, 2, 7) forAccessoryPosition:ECKeyboardAccessoryPositionFloating];
        [accessoryView setItemInsets:UIEdgeInsetsMake(0, 0, 0, 3) forAccessoryPosition:ECKeyboardAccessoryPositionFloating];
        
        self.codeView.keyboardAccessoryView = accessoryView;
        
        // Accessory view popover setup
        accessoryView.itemPopoverView.contentSize = CGSizeMake(300, 300);
        accessoryView.itemPopoverView.contentInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        accessoryView.itemPopoverView.backgroundView.image = [[UIImage imageNamed:@"accessoryView_popoverBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 50, 10)];
        [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowMiddle"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionMiddle];
        [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionFarRight];
        [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowLeft"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionFarLeft];
        accessoryView.itemPopoverView.arrowInsets = UIEdgeInsetsMake(12, 12, 12, 12);
        // Prepare handlers to show and hide controllers in keyboard accessory item popover
        accessoryView.willPresentPopoverForItemBlock = ^(ACCodeFileKeyboardAccessoryView *sender, NSUInteger itemIndex, CGRect popoverContentRect, NSTimeInterval animationDuration) {
            UIView *presentedView = nil;
            UIView *presentingView = sender.superview;
            if (itemIndex == 10)
                presentedView = this._keyboardAccessoryItemCompletionsController.view;
            else if (itemIndex > 0)
                presentedView = this._keyboardAccessoryItemCustomizeController.view;
            CGRect popoverContentFrame = CGRectIntegral([presentingView convertRect:sender.itemPopoverView.contentView.frame fromView:sender.itemPopoverView]);
            presentedView.frame = popoverContentFrame;
            [presentingView addSubview:presentedView];
            presentedView.alpha = 0;
            [UIView animateWithDuration:animationDuration animations:^{
                presentedView.alpha = 1;
            }];
        };
        accessoryView.willDismissPopoverForItemBlock = ^(ACCodeFileKeyboardAccessoryView *sender, NSTimeInterval animationDuration) {
            [UIView animateWithDuration:animationDuration animations:^{
                if (this._keyboardAccessoryItemCompletionsController.isViewLoaded)
                    this._keyboardAccessoryItemCompletionsController.view.alpha = 0;
                if (this._keyboardAccessoryItemCustomizeController.isViewLoaded)
                    this._keyboardAccessoryItemCustomizeController.view.alpha = 0;                
            } completion:^(BOOL finished) {
                if (this._keyboardAccessoryItemCompletionsController.isViewLoaded)
                    [this._keyboardAccessoryItemCompletionsController.view removeFromSuperview];
                if (this._keyboardAccessoryItemCustomizeController.isViewLoaded)
                    [this._keyboardAccessoryItemCustomizeController.view removeFromSuperview];
            }];
        };
        
        UIView *accessoryPopoverContentView = [UIView new];
        accessoryPopoverContentView.backgroundColor = [UIColor whiteColor];
        accessoryView.itemPopoverView.contentView = accessoryPopoverContentView;
        
        //        _keyboardAccessoryItemPopoverButton = [UIButton new];
        //        [_keyboardAccessoryItemPopoverButton setBackgroundImage:[[UIImage imageNamed:@"accessoryView_itemBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 12, 0, 12)] forState:UIControlStateNormal];
        //        [_keyboardAccessoryPopoverView addSubview:_keyboardAccessoryItemPopoverButton];
        
        // Items actions
        #warning TODO load from plist and change for current language
        _keyboardAccessoryItemActions = [NSMutableArray arrayWithCapacity:9];
        // TODO method to set items based on language
        for (int i = 0; i < 9; ++i) {
            [_keyboardAccessoryItemActions addObject:[ACCodeFileAccessoryAction accessoryActionWithName:@"commaReturn"]];
        }
        
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

- (ACCodeFileMinimapView *)minimapView
{
    if (!_minimapView)
    {
        _minimapView = [ACCodeFileMinimapView new];
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
    
    [self willChangeValueForKey:@"fileURL"];
    
    _fileURL = fileURL;
    if (fileURL)
        self.codeFile = [[ACCodeFile alloc] initWithFileURL:fileURL];
    else
        self.codeFile = nil;
    
    [self didChangeValueForKey:@"fileURL"];
}

- (void)setCodeFile:(ACCodeFile *)codeFile
{
    if (codeFile == _codeFile)
        return;
    
    [self willChangeValueForKey:@"codeFile"];
    
    [_codeFile.fileBuffer removeConsumer:self];
    _codeFile = codeFile;
    if (!_consumerOperationQueue)
    {
        _consumerOperationQueue = [[NSOperationQueue alloc] init];
        _consumerOperationQueue.maxConcurrentOperationCount = 1;
    }
    else
        [_consumerOperationQueue cancelAllOperations];
    [_codeFile.fileBuffer addConsumer:self];
    
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

#pragma mark - Toolbar Items Actions

- (BOOL)singleTabController:(ACSingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(ACTopBarToolbar *)toolbar
{
    return YES;
}

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

#pragma mark - Controller Editing Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    UIView *oldContentView = [self _contentView];
    
    [self willChangeValueForKey:@"editing"];
    
    [super setEditing:editing animated:animated];
    self.editButtonItem.title = @"";
    
    UIView *currentContentView = [self _contentView];
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

- (BOOL)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView 
           shouldRenderLine:(ECTextRendererLine *)line 
                     number:(NSUInteger)lineNumber 
                  withColor:(UIColor *__autoreleasing *)lineColor 
                 decoration:(ACCodeFileMinimapLineDecoration *)decoration 
            decorationColor:(UIColor *__autoreleasing *)decorationColor
{
    if (line.width < line.height)
        return NO;
    
    if (lineNumber < 8)
        *lineColor = [UIColor greenColor];
    
    if (lineNumber == 15)
    {
        *decoration = ACCodeFileMinimapLineDecorationDisc;
        *decorationColor = [UIColor whiteColor];
    }
    
    if (lineNumber == 154)
    {
        *decoration = ACCodeFileMinimapLineDecorationSquare;
        *decorationColor = [UIColor whiteColor];
    }
    
    return YES;
}

- (BOOL)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView shouldChangeSelectionRectangle:(CGRect)newSelection
{
    [self.codeView scrollRectToVisible:newSelection animated:YES];
    return NO;
}

#pragma mark - ECFileBufferConsumer

- (NSOperationQueue *)consumerOperationQueue
{
    ECASSERT(_consumerOperationQueue);
    return _consumerOperationQueue;
}

- (void)fileBuffer:(ECFileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.codeView updateTextFromStringRange:range toStringRange:NSMakeRange(range.location, [string length])];
    }];
}

#pragma mark - Code View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_minimapVisible && scrollView == _codeView)
    {
        _minimapView.selectionRectangle = _codeView.bounds;
    }
}

- (void)codeView:(ECCodeView *)codeView selectedLineNumber:(NSUInteger)lineNumber
{
    NSArray *bookmarks = [self.tab.currentProject bookmarksForFile:self.tab.currentURL atLine:lineNumber];
    if ([bookmarks count] == 0)
    {
        [self.tab.currentProject addBookmarkWithFileURL:self.tab.currentURL line:lineNumber note:nil];
    }
    else
    {
        for (ACProjectBookmark *bookmark in bookmarks)
        {
            [self.tab.currentProject removeBookmark:bookmark];
        }
    }
    [self.codeView setNeedsDisplay];
}

- (BOOL)codeView:(ECCodeView *)codeView shouldShowKeyboardAccessoryViewInView:(UIView *__autoreleasing *)view withFrame:(CGRect *)frame
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

- (void)codeView:(ECCodeView *)codeView didShowKeyboardAccessoryViewInView:(UIView *)view withFrame:(CGRect)accessoryFrame
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
            ECRectSet *selectionRects = self.codeView.selectionRects;
            if (selectionRects == nil)
                return;
            [self.codeView scrollRectToVisible:CGRectInset(selectionRects.bounds, 0, -50) animated:YES];
        }];
    }
}

- (BOOL)codeViewShouldHideKeyboardAccessoryView:(ECCodeView *)codeView
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
        [self.webView loadHTMLString:[self.codeFile.fileBuffer string] baseURL:self.fileURL];
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

- (ACCodeFileKeyboardAccessoryView *)_keyboardAccessoryView
{
    return (ACCodeFileKeyboardAccessoryView *)self.codeView.keyboardAccessoryView;
}

- (ACCodeFileCompletionsController *)_keyboardAccessoryItemCompletionsController
{
    if (!_keyboardAccessoryItemCompletionsController)
    {
        _keyboardAccessoryItemCompletionsController = [[ACCodeFileCompletionsController alloc] initWithStyle:UITableViewStylePlain];
        _keyboardAccessoryItemCompletionsController.targetCodeFileController = self;
        _keyboardAccessoryItemCompletionsController.targetKeyboardAccessoryView = self._keyboardAccessoryView;
        _keyboardAccessoryItemCompletionsController.contentSizeForViewInPopover = CGSizeMake(300, 300);
    }
    return _keyboardAccessoryItemCompletionsController;
}

/// Controller shown on long press on non-fixed keyboard accessory items
- (UIViewController *)_keyboardAccessoryItemCustomizeController
{
    if (!_keyboardAccessoryItemCustomizeController)
    {
        ACCodeFileAccessoryItemsGridView *gridView = [ACCodeFileAccessoryItemsGridView new];
        gridView.itemSize = CGSizeMake(50, 30);
        gridView.itemInsents = UIEdgeInsetsMake(5, 5, 5, 5);
        gridView.didSelectActionItemBlock = ^(ACCodeFileAccessoryItemsGridView *view, ACCodeFileAccessoryAction *action) {
            ECASSERT(_keyboardAccessoryItemCustomizingTag > 0 && _keyboardAccessoryItemCustomizingTag < 10);
            [self._keyboardAccessoryView dismissPopoverForItemAnimated:YES];
            // Setup changed keyboard accessory item
            [_keyboardAccessoryItemActions removeObjectAtIndex:_keyboardAccessoryItemCustomizingTag - 1];
            [_keyboardAccessoryItemActions insertObject:action atIndex:_keyboardAccessoryItemCustomizingTag - 1];
            [self _keyboardAccessoryItemSetupWithActions:_keyboardAccessoryItemActions];
        };
        
        _keyboardAccessoryItemCustomizeController = [[UIViewController alloc] init];
        _keyboardAccessoryItemCustomizeController.view = gridView;
        _keyboardAccessoryItemCustomizeController.contentSizeForViewInPopover = CGSizeMake(300, 200);
    }
    return _keyboardAccessoryItemCustomizeController;
}

- (void)_keyboardAccessoryItemSetupWithActions:(NSArray *)actions
{
    ECASSERT([actions count] == 9);
    
    ACCodeFileKeyboardAccessoryView *accessoryView = (ACCodeFileKeyboardAccessoryView *)self.codeView.keyboardAccessoryView;
    
    // Items
    if (accessoryView.items == nil)
    {
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:11];
        ACCodeFileKeyboardAccessoryItem *item = nil;
        ACCodeFileAccessoryAction *action = nil;
        
        for (NSInteger i = 0; i < 11; ++i)
        {
            item = [[ACCodeFileKeyboardAccessoryItem alloc] initWithTitle:[NSString stringWithFormat:@"%d", i] style:UIBarButtonItemStylePlain target:self action:@selector(_keyboardAccessoryItemAction:)];
            
            if (i == 0)
            {
                item.title = @"tab";
                [item setWidth:44 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionFloating];
            }
            else if (i == 10)
            {
                item.title = @"compl";
                [item setWidth:63 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionPortrait];
                [item setWidth:82 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionLandscape];
                [item setWidth:44 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionFloating];
            }
            else 
            {
                action = [actions objectAtIndex:i - 1];
                item.title = action.title;
                item.image = [UIImage imageNamed:action.imageName];
                if (i % 2)
                    [item setWidth:60 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionPortrait];
            }
            
            item.tag = i;
            [items addObject:item];
        }
        
        accessoryView.items = items;

        // Items long press action
        [items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
            if (itemIndex < 1 || itemIndex > 9)
                return;
            
            UILongPressGestureRecognizer *itemLongPressrecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_keyboardAccessoryItemLongPressHandler:)];
            itemLongPressrecognizer.minimumPressDuration = 1;
            [item.customView addGestureRecognizer:itemLongPressrecognizer];
        }];
    }
    else
    {
        NSArray *items = accessoryView.items;
        [items enumerateObjectsUsingBlock:^(ACCodeFileKeyboardAccessoryItem *item, NSUInteger itemIndex, BOOL *stop) {
            if (itemIndex < 1 || itemIndex > 9)
                return;
            
            ACCodeFileAccessoryAction *action = [actions objectAtIndex:itemIndex - 1];
            item.title = action.title;
            item.image = [UIImage imageNamed:action.imageName];
        }];
        accessoryView.items = items;
    }
}

- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item
{
    if (item.tag == 0)
    {
    }
    else if (item.tag == 10)
    {
        // Prepare completion controller
        self._keyboardAccessoryItemCompletionsController.offsetInDocumentForCompletions = self.codeView.selectionRange.location;
        if (![self._keyboardAccessoryItemCompletionsController hasCompletions])
        {
            [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:@"No completions" image:nil displayImmediatly:YES];
            return;
        }
        
        [self._keyboardAccessoryView presentPopoverForItemAtIndex:item.tag permittedArrowDirection:(self.codeView.keyboardAccessoryView.isFlipped ? UIPopoverArrowDirectionUp : UIPopoverArrowDirectionDown) animated:YES];
    }
    else
    {
        ECASSERT([_keyboardAccessoryItemActions count] == 9);
        ECASSERT([[_keyboardAccessoryItemActions objectAtIndex:item.tag - 1] actionBlock] != nil);
        
        [[_keyboardAccessoryItemActions objectAtIndex:item.tag - 1] actionBlock](self.codeView);
    }
}

- (void)_keyboardAccessoryItemLongPressHandler:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        UIView *itemView = recognizer.view;
        
        // Setup customizing view
        _keyboardAccessoryItemCustomizingTag = itemView.tag;
        [(ACCodeFileAccessoryItemsGridView *)self._keyboardAccessoryItemCustomizeController.view setAccessoryActions:[ACCodeFileAccessoryAction accessoryActionsForLanguageWithIdentifier:nil]];
        
        // Show popover
        [self._keyboardAccessoryView presentPopoverForItemAtIndex:itemView.tag permittedArrowDirection:(self.codeView.keyboardAccessoryView.isFlipped ? UIPopoverArrowDirectionUp : UIPopoverArrowDirectionDown) animated:YES];
    }
}

@end
