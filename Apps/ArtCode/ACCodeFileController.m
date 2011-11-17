//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileDocument.h"
#import <ECFoundation/ECAttributedUTF8FileBuffer.h>
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
#import "ACCodeFileCompletionsController.h"
#import "ACCodeFileAccessoryAction.h"
#import "ACCodeFileAccessoryItemsGridView.h"


@interface ACCodeFileController () {
    UIActionSheet *_toolsActionSheet;
    ACCodeFileSearchBarController *_searchBarController;

    CGRect _keyboardFrame;
    CGRect _keyboardRotationFrame;
    
    NSTimer *_syntaxColoringTimer;
    
    /// Button inside keyboard accessory popover that look like the underneat button that presented the popover from the accessory.
    /// This button is supposed to have the same appearance of the underlying button and the same tag.
    UIButton *_keyboardAccessoryItemPopoverButton;
}

@property (nonatomic, strong) ACFileDocument *document;

@property (nonatomic, strong, readonly) ECPopoverController *_keyboardAccessoryItemPopover;
@property (nonatomic, strong, readonly) ACCodeFileCompletionsController *_completionsController;
@property (nonatomic, strong, readonly) UIViewController *_customizeAccessoryItemController;

@property (nonatomic, strong) ACSyntaxColorer *syntaxColorer;
@property (nonatomic, strong) NSDictionary *defaultTextAttributes;

- (void)_layoutChildViews;

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer;
- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer;

- (void)_keyboardWillShow:(NSNotification *)notification;
- (void)_keyboardWillHide:(NSNotification *)notification;
- (void)_keyboardWillChangeFrame:(NSNotification *)notification;

- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item;
- (void)_keyboardAccessoryItemLongPressHandler:(UILongPressGestureRecognizer *)recognizer;

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
        
        // Items long press action
        [items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
            if (itemIndex > 0 && itemIndex < 10)
            {
                UILongPressGestureRecognizer *itemLongPressrecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_keyboardAccessoryItemLongPressHandler:)];
                itemLongPressrecognizer.minimumPressDuration = 1;
                [item.customView addGestureRecognizer:itemLongPressrecognizer];
            }
        }];
        
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
    [_document closeWithCompletionHandler:nil];
    self.document = nil;
    self.syntaxColorer = nil;
    _fileURL = fileURL;
    
    if (fileURL)
    {
        self.loading = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ACFileDocument *document = [[ACFileDocument alloc] initWithFileURL:fileURL];
            [document openWithCompletionHandler:^(BOOL success) {
                ECASSERT(success);
                ACSyntaxColorer *colorer = [[ACSyntaxColorer alloc] initWithFileBuffer:[document fileBuffer]];
                colorer.defaultTextAttributes = self.defaultTextAttributes;
                colorer.theme = [TMTheme themeWithName:@"Mac Classic" bundle:nil];
                [colorer applySyntaxColoring];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.document = document;
                    self.syntaxColorer = colorer;
                    self.loading = NO;
                    [self.codeView updateAllText];
                });
            }];
        });
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

#pragma mark -

@synthesize _keyboardAccessoryItemPopover, _completionsController, _customizeAccessoryItemController;

- (ECPopoverController *)_keyboardAccessoryItemPopover
{
    if (!_keyboardAccessoryItemPopover)
    {
        _keyboardAccessoryItemPopover = [[ECTexturedPopoverController alloc] init];
        ECTexturedPopoverView *popoverView = (ECTexturedPopoverView *)_keyboardAccessoryItemPopover.popoverView;
        popoverView.contentInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        popoverView.backgroundView.image = [[UIImage imageNamed:@"accessoryView_popoverBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 50, 10)];
        [popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowMiddle"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionMiddle];
        [popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionFarRight];
        [popoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowLeft"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:ECPopoverViewArrowMetaPositionFarLeft];
        [popoverView setArrowSize:CGSizeMake(70, 54) forMetaPosition:ECPopoverViewArrowMetaPositionMiddle];
        popoverView.positioningInsets = UIEdgeInsetsMake(59, 58, 58, 58);
        popoverView.arrowInsets = UIEdgeInsetsMake(12, 12, 12, 12);
        popoverView.contentInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        
        _keyboardAccessoryItemPopoverButton = [UIButton new];
        [_keyboardAccessoryItemPopoverButton setBackgroundImage:[[UIImage imageNamed:@"accessoryView_itemBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 12, 0, 12)] forState:UIControlStateNormal];
        [popoverView addSubview:_keyboardAccessoryItemPopoverButton];
    }
    return _keyboardAccessoryItemPopover;
}

- (ACCodeFileCompletionsController *)_completionsController
{
    if (!_completionsController)
    {
        _completionsController = [[ACCodeFileCompletionsController alloc] initWithStyle:UITableViewStylePlain];
        _completionsController.targetCodeFileController = self;
        _completionsController.contentSizeForViewInPopover = CGSizeMake(300, 300);
    }
    return _completionsController;
}

- (UIViewController *)_customizeAccessoryItemController
{
    if (!_customizeAccessoryItemController)
    {
        ACCodeFileAccessoryItemsGridView *gridView = [ACCodeFileAccessoryItemsGridView new];
        gridView.itemSize = CGSizeMake(50, 30);
        gridView.itemInsents = UIEdgeInsetsMake(5, 5, 5, 5);
        
        _customizeAccessoryItemController = [[UIViewController alloc] init];
        _customizeAccessoryItemController.view = gridView;
        _customizeAccessoryItemController.contentSizeForViewInPopover = CGSizeMake(300, 200);
    }
    return _customizeAccessoryItemController;
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
    [[self.document fileBuffer] replaceCharactersInRange:range withAttributedString:[commitString length] ? [[NSAttributedString alloc] initWithString:commitString attributes:self.defaultTextAttributes] : nil];
    NSRange newRange = NSMakeRange(range.location, [commitString length]);
    [_syntaxColoringTimer invalidate];
    _syntaxColoringTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 usingBlock:^(NSTimer *timer) {
        [self.syntaxColorer applySyntaxColoring];
        [self.codeView updateAllText];
    } repeats:NO];
    [self.codeView updateTextFromStringRange:range toStringRange:newRange];
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
    
    [_keyboardAccessoryItemPopover dismissPopoverAnimated:YES];
}

- (void)_keyboardWillHide:(NSNotification *)notification
{
    [self _keyboardWillShow:notification];
}

#pragma mark -

- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item
{
    // TODO use item tag to see what action to perform

    if (item.tag == 10)
    {
        // Prepare completion controller
        self._completionsController.targetPopoverController = self._keyboardAccessoryItemPopover;
        self._completionsController.offsetInDocumentForCompletions = self.codeView.selectionRange.location;
        
        // Prepare popover
        self._keyboardAccessoryItemPopover.contentViewController = self._completionsController;
        switch (self.codeView.keyboardAccessoryView.currentAccessoryPosition) {
            case ECKeyboardAccessoryPositionFloating:
                self._keyboardAccessoryItemPopover.allowedBoundsInsets = UIEdgeInsetsMake(0, 3, 0, 3);
                break;
                
            case ECKeyboardAccessoryPositionPortrait:
                self._keyboardAccessoryItemPopover.allowedBoundsInsets = UIEdgeInsetsMake(0, -4, 0, -4);
                break;
                
            default:
                self._keyboardAccessoryItemPopover.allowedBoundsInsets = UIEdgeInsetsMake(0, -3, 0, -3);
                break;
        }
        
        [(ECTexturedPopoverView *)self._keyboardAccessoryItemPopover.popoverView setArrowSize:CGSizeMake(item.customView.bounds.size.width + 14, 54) forMetaPosition:ECPopoverViewArrowMetaPositionMiddle];
        [self._keyboardAccessoryItemPopover presentPopoverFromRect:[item.customView.superview convertRect:item.customView.frame toView:self.view.window.rootViewController.view] inView:self.view.window.rootViewController.view permittedArrowDirections:self.codeView.keyboardAccessoryView.isFlipped ? UIPopoverArrowDirectionUp : UIPopoverArrowDirectionDown animated:YES];
        
        // Layout substitutive button in popover view
        _keyboardAccessoryItemPopoverButton.frame = [item.customView.superview convertRect:item.customView.frame toView:self._keyboardAccessoryItemPopover.popoverView];
        _keyboardAccessoryItemPopoverButton.tag = item.tag;
    }
}

- (void)_keyboardAccessoryItemLongPressHandler:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        UIView *itemView = recognizer.view;
        // 
        [(ACCodeFileAccessoryItemsGridView *)self._customizeAccessoryItemController.view setAccessoryActions:[ACCodeFileAccessoryAction accessoryActionsForLanguageWithIdentifier:nil]];
        
        // Show popover
        self._keyboardAccessoryItemPopover.contentViewController = self._customizeAccessoryItemController;
        self._keyboardAccessoryItemPopover.allowedBoundsInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        [(ECTexturedPopoverView *)self._keyboardAccessoryItemPopover.popoverView setArrowSize:CGSizeMake(itemView.bounds.size.width + 14, 54) forMetaPosition:ECPopoverViewArrowMetaPositionMiddle];
        [self._keyboardAccessoryItemPopover presentPopoverFromRect:[itemView.superview convertRect:itemView.frame toView:self.view.window.rootViewController.view] inView:self.view.window.rootViewController.view permittedArrowDirections:self.codeView.keyboardAccessoryView.isFlipped ? UIPopoverArrowDirectionUp : UIPopoverArrowDirectionDown animated:YES];
        
        // Layout substitutive button in popover view
        _keyboardAccessoryItemPopoverButton.frame = [itemView.superview convertRect:itemView.frame toView:self._keyboardAccessoryItemPopover.popoverView];
        _keyboardAccessoryItemPopoverButton.tag = itemView.tag;
    }
}

@end
