//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileDocument.h"
#import <ECFoundation/ECFileBuffer.h>
#import "ACSyntaxColorer.h"
#import "ACCodeFileController.h"
#import <ECFoundation/NSTimer+block.h>
#import <QuartzCore/QuartzCore.h>

#import <ECCodeIndexing/TMTheme.h>

#import <ECUIKit/ECTabController.h>

#import "ACSingleTabController.h"
#import "ACCodeFileSearchBarController.h"

#import "ACCodeFileKeyboardAccessoryView.h"
#import <ECUIKit/ECPopoverController.h>
#import <ECUIKit/ECTexturedPopoverView.h>


@interface ACCodeFileController () {
    UIActionSheet *_toolsActionSheet;
    ACCodeFileSearchBarController *_searchBarController;

    CGRect _keyboardFrame;
    ECPopoverController *_popoverAccessoryItem;
}

@property (nonatomic, strong) ACFileDocument *document;
@property (nonatomic, strong, readonly) ACSyntaxColorer *syntaxColorer;
@property (nonatomic, strong) NSDictionary *defaultTextAttributes;

- (void)_layoutChildViews;

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer;
- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer;

- (void)_keyboardWillShow:(NSNotification *)notification;
- (void)_keyboardWillHide:(NSNotification *)notification;

- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item;

@end


@implementation ACCodeFileController

#pragma mark - Properties

@synthesize fileURL = _fileURL, tab = _tab, document = _document;
@synthesize codeView = _codeView, minimapView = _minimapView, minimapVisible = _minimapVisible, minimapWidth = _minimapWidth;
@synthesize defaultTextAttributes = _defaultTextAttributes, syntaxColorer = _syntaxColorer;

- (ECCodeView *)codeView
{
    if (!_codeView)
    {
        _codeView = [ECCodeView new];
        _codeView.dataSource = self;
        _codeView.delegate = self;
        
        _codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
        
        // Items
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:11];
        ACCodeFileKeyboardAccessoryItem *item;
        
        for (NSInteger i = 0; i < 11; ++i)
        {
            // TODO add long press menu
            item = [[ACCodeFileKeyboardAccessoryItem alloc] initWithTitle:[NSString stringWithFormat:@"%d", i] style:UIBarButtonItemStylePlain target:self action:@selector(_keyboardAccessoryItemAction:)];
            item.tag = i;
            [items addObject:item];
            
            if (i == 0)
                [item setWidth:44 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionFloating];
            
            if (i % 2)
                [item setWidth:60 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionPortrait];
            
            if (i == 10)
            {
                [item setWidth:63 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionPortrait];
                [item setWidth:82 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionLandscape];
                [item setWidth:44 + 4 forAccessoryPosition:ECKeyboardAccessoryPositionFloating];
            }
        }
        accessoryView.items = items;
        _codeView.keyboardAccessoryView = accessoryView;
    }
    return _codeView;
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
    {
        ACFileDocument *document = [[ACFileDocument alloc] initWithFileURL:fileURL];
        [document openWithCompletionHandler:nil];
        self.document = document;
    }
    
    [self didChangeValueForKey:@"fileURL"];
}

- (NSDictionary *)defaultTextAttributes
{
    if (!_defaultTextAttributes)
    {
        CTFontRef defaultFont = CTFontCreateWithName((__bridge CFStringRef)@"Inconsolata-dz", 16, NULL);
        _defaultTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)defaultFont, kCTFontAttributeName,
                                  [NSNumber numberWithInt:0], kCTLigatureAttributeName, nil];
        CFRelease(defaultFont);
    }
    return _defaultTextAttributes;
}

- (ACSyntaxColorer *)syntaxColorer
{
    if (!_syntaxColorer)
    {
        _syntaxColorer = [[ACSyntaxColorer alloc] initWithFileBuffer:[self.document fileBuffer]];
        _syntaxColorer.defaultTextAttributes = self.defaultTextAttributes;
        _syntaxColorer.theme = [TMTheme themeWithName:@"Mac Classic" bundle:nil];
    }
    return _syntaxColorer;
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
    if (_minimapVisible == minimapVisible)
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
                _searchBarController = [[ACCodeFileSearchBarController alloc] initWithNibName:@"ACCodeFileSearchBarController" bundle:nil];
                _searchBarController.targetCodeFileController = self;
            }
            if (self.singleTabController.toolbarViewController != _searchBarController)
                [self.singleTabController setToolbarViewController:_searchBarController animated:YES];
            else
                [self.singleTabController setToolbarViewController:nil animated:YES];
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
    
    [self.view addSubview:self.codeView];
}

- (void)viewDidLoad
{
    self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithTitle:@"tools" style:UIBarButtonItemStylePlain target:self action:@selector(toolButtonAction:)]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    _keyboardFrame = CGRectMake(0 ,CGRectGetMaxY(self.view.frame), self.view.frame.size.width, 0);
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
    if (self.minimapVisible)
        self.minimapView.selectionRectangle = self.codeView.bounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if (!_minimapVisible)
        _minimapView = nil;
}

#pragma mark - Minimap Delegate Methods

- (BOOL)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView shouldRenderLine:(ECTextRendererLine *)line number:(NSUInteger)lineNumber withColor:(UIColor *__autoreleasing *)lineColor deocration:(ACCodeFileMinimapLineDecoration *)decoration decorationColor:(UIColor *__autoreleasing *)decorationColor
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

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(ECTextRenderer *)sender
{
    return [[self.document fileBuffer] length];
}

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    return [[self.document fileBuffer] attributedStringInRange:stringRange];
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    [[self.document fileBuffer] replaceCharactersInRange:range withString:commitString];
}

#pragma mark - Code View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_minimapVisible && scrollView == _codeView)
    {
        _minimapView.selectionRectangle = _codeView.bounds;
    }
}

- (BOOL)codeView:(ECCodeView *)codeView shouldShowKeyboardAccessoryViewInView:(UIView *__autoreleasing *)view withFrame:(CGRect *)frame
{
    ECASSERT(view && frame);
    
    if ((*frame).origin.y < 200)
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
            frame.size.height = _keyboardFrame.origin.y - codeView.keyboardAccessoryView.frame.size.height;
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
    if (!codeView.keyboardAccessoryView.isSplit)
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
            CGRect frame = self.view.frame;
            frame.size.height = _keyboardFrame.origin.y;
            self.view.frame = frame;
        } completion:nil];
    }
    return YES;
}

#pragma mark - Private Methods

- (void)_layoutChildViews
{
    CGRect frame = (CGRect){ CGPointZero, self.view.frame.size };
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

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer
{
    [_codeView.undoManager undo];
}

- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer
{
    [_codeView.undoManager redo];
}

- (void)_keyboardWillShow:(NSNotification *)notification
{
    _keyboardFrame = [self.view convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    
    [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0 options:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 | UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect frame = self.view.frame;
        frame.size.height = _keyboardFrame.origin.y;
        self.view.frame = frame;
    } completion:nil];
    
    [_popoverAccessoryItem dismissPopoverAnimated:YES];
}

- (void)_keyboardWillHide:(NSNotification *)notification
{
    [self _keyboardWillShow:notification];
}

- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item
{
    // TODO use item tag to see what action to perform
    if (!_popoverAccessoryItem)
    {
        UIViewController *tempViewController = [UIViewController new];
        tempViewController.contentSizeForViewInPopover = CGSizeMake(300, 300);
        tempViewController.view.backgroundColor = [UIColor whiteColor];
        
        _popoverAccessoryItem = [[ECTexturedPopoverController alloc] initWithContentViewController:tempViewController];
        ECTexturedPopoverView *popoverView = (ECTexturedPopoverView *)_popoverAccessoryItem.popoverView;
        popoverView.contentInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        popoverView.backgroundView.image = [[UIImage imageNamed:@"accessoryView_popoverBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        [popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowMiddle"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionMiddle];
        [popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionFarRight];
        [popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowLeft"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionFarLeft];
        [popoverView setArrowSize:CGSizeMake(70, 54) forMetaPosition:ECPopoverViewArrowMetaPositionMiddle];
        popoverView.positioningInsets = UIEdgeInsetsMake(59, 58, 58, 58);
        popoverView.arrowInsets = UIEdgeInsetsMake(12, 12, 12, 12);
        popoverView.contentInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    
    switch (self.codeView.keyboardAccessoryView.currentAccessoryPosition) {
        case ECKeyboardAccessoryPositionFloating:
            _popoverAccessoryItem.allowedBoundsInsets = UIEdgeInsetsMake(0, 3, 0, 3);
            break;
            
        case ECKeyboardAccessoryPositionPortrait:
            _popoverAccessoryItem.allowedBoundsInsets = UIEdgeInsetsMake(0, -4, 0, -4);
            break;
            
        default:
            _popoverAccessoryItem.allowedBoundsInsets = UIEdgeInsetsMake(0, -3, 0, -3);
            break;
    }
    
    [(ECTexturedPopoverView *)_popoverAccessoryItem.popoverView setArrowSize:CGSizeMake(item.customView.bounds.size.width + 14, 54) forMetaPosition:ECPopoverViewArrowMetaPositionMiddle];
    [_popoverAccessoryItem presentPopoverFromBarButtonItem:item permittedArrowDirections:self.codeView.keyboardAccessoryView.isFlipped ? UIPopoverArrowDirectionUp : UIPopoverArrowDirectionDown animated:YES];
    [item.customView.superview bringSubviewToFront:item.customView];
}

@end
