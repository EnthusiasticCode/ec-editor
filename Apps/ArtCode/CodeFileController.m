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
#import "UIViewController+Utilities.h"
#import "TopBarTitleControl.h"

#import <QuartzCore/QuartzCore.h>
#import "NSNotificationCenter+RACSupport.h"
#import "BezelAlert.h"
#import "TMTheme.h"
#import "UIColor+Contrast.h"
#import "UIColor+AppStyle.h"
#import "NSTimer+BlockTimer.h"

#import "CodeFileKeyboardAccessoryView.h"
#import "CodeFileKeyboardAccessoryPopoverView.h"

#import "ImagePopoverBackgroundView.h"

#import "TMUnit.h"
#import "TMSyntaxNode.h"
#import "TMPreference.h"
#import "TMSymbol.h"
#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"


#import "NSIndexSet+PersistentDataStructure.h"
#import "RCIOFile+ArtCode.h"
#import <file/FileMagic.h>


@interface CodeFileController ()

/// View that wraps all the content and that will be adjusted to avoid keyboard overlaps
@property (nonatomic, weak) UIView *wrapperView;

@property (nonatomic, weak) CodeView *codeView;
@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, strong) UIView *hiddenView;

@property (nonatomic, weak) CodeFileMinimapView *minimapView;

@property (nonatomic, strong) NSIndexSet *bookmarks;

@property (nonatomic, strong, readonly) CodeFileKeyboardAccessoryView *_keyboardAccessoryView;

@property (nonatomic, strong) RACScheduler *codeScheduler;

@property (nonatomic, weak) TMSymbol *currentSymbol;

// Text indentation preference blocks
@property (nonatomic, copy) bool(^preferenceIncreaseIndentBlock)(NSString *);
@property (nonatomic, copy) bool(^preferenceDecreaseIndentBlock)(NSString *);

/// Returns the content view used to display the content in the given editing state.
/// This method evaluate if using the codeView or the webView based on the current fileURL.
- (UIView *)_contentViewForEditingState:(BOOL)editingState;
- (UIView *)_contentView;

- (void)_setCodeViewAttributesForTheme:(TMTheme *)theme;

/// Indicates if the current content view is the web preview.
- (BOOL)_isWebPreview;
- (void)_loadWebPreviewContentAndTitle;

- (void)_layoutChildViews;

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer;
- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer;

- (void)_keyboardAccessoryItemSetupWithQualifiedIdentifier:(NSString *)qualifiedIdentifier;
- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item;

- (void)_markPlaceholderWithName:(NSString *)name inAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range;

@end

// from: http://developer.apple.com/library/mac/#documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_patterns/dq_patterns.html
#define PSIZE 14
static void drawStencilStar(CGContextRef myContext)
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


@implementation CodeFileController {
  UIActionSheet *_editToolsActionSheet;
  UIActionSheet *_webToolsActionSheet;
  CodeFileSearchBarController *_searchBarController;
  UIPopoverController *_quickBrowsersPopover;
  
  // Colors used in the minimap delegate methods to color a line, they are resetted when changin theme
  UIColor *_minimapSymbolColor;
  UIColor *_minimapCommentColor;
  UIColor *_minimapPreprocessorColor;
  
  /// Button inside keyboard accessory popover that look like the underneat button that presented the popover from the accessory.
  /// This button is supposed to have the same appearance of the underlying button and the same tag.
  UIButton *_keyboardAccessoryItemPopoverButton;
  
  /// Actions associated to items in the accessory view.
  NSArray *_keyboardAccessoryItemActions;
  
  /// The index of the accessory item action currently being performed.
  NSInteger _keyboardAccessoryItemCurrentActionIndex;
}

#pragma mark - Properties

- (CGFloat)minimapWidth {
  if (_minimapWidth == 0) {
    _minimapWidth = 124;
  }
  return _minimapWidth;
}

- (void)setMinimapVisible:(BOOL)minimapVisible {
  [self setMinimapVisible:minimapVisible animated:NO];
}

- (void)setMinimapVisible:(BOOL)minimapVisible animated:(BOOL)animated {
  if (_minimapVisible == minimapVisible || [self _isWebPreview]) {
    return;
  }
  
  [self willChangeValueForKey:@"minimapVisible"];
  if (minimapVisible) {
		CodeFileMinimapView *minimapView = [[CodeFileMinimapView alloc] init];
    minimapView.delegate = self;
    minimapView.renderer = self.codeView.renderer;
    
    minimapView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    minimapView.contentInset = UIEdgeInsetsMake(10, 0, 10, 10);
    minimapView.alwaysBounceVertical = YES;
    
    minimapView.backgroundColor = self.codeView.lineNumbersBackgroundColor;
    minimapView.lineShadowColor = self.codeView.backgroundColor;
    minimapView.lineDecorationInset = 10;
    minimapView.lineDefaultColor = [UIColor blackColor];
		
    [self.wrapperView addSubview:minimapView];
		self.minimapView = minimapView;
  }
  if (animated) {
    [self _layoutChildViews];
    _minimapVisible = minimapVisible;
    [UIView animateWithDuration:0.25 animations:^{
      [self _layoutChildViews];
    } completion:^(BOOL finished) {
      if (!_minimapVisible)
        [self.minimapView removeFromSuperview];
    }];
  } else {
    _minimapVisible = minimapVisible;
    if (!_minimapVisible)
      [self.minimapView removeFromSuperview];
    [self _layoutChildViews];
  }
  [self didChangeValueForKey:@"minimapVisible"];
}

+ (BOOL)automaticallyNotifiesObserversOfMinimapVisible {
  return NO;
}

- (RACScheduler *)codeScheduler {
  if (!_codeScheduler) {
		_codeScheduler = [RACScheduler scheduler];
  }
  return _codeScheduler;
}

#pragma mark - Single tab controller informal protocol

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar {
  return YES;
}

- (void)singleTabController:(SingleTabController *)singleTabController titleControlAction:(id)sender {
  QuickBrowsersContainerController *quickBrowserContainerController = [QuickBrowsersContainerController defaultQuickBrowsersContainerControllerForContentController:self];
  
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:quickBrowserContainerController];
  [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
  
  _quickBrowsersPopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
  _quickBrowsersPopover.popoverBackgroundViewClass = [ImagePopoverBackgroundView class];
  
  quickBrowserContainerController.presentingPopoverController = _quickBrowsersPopover;
  quickBrowserContainerController.openingButton = sender;
  
  [_quickBrowsersPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	
	[self.codeView resignFirstResponder];
}

- (BOOL)singleTabController:(SingleTabController *)singleTabController setupDefaultToolbarTitleControl:(TopBarTitleControl *)titleControl {
  if (self.currentSymbol) {
    NSString *path = self.artCodeTab.currentLocation.path;
    if (self.currentSymbol.icon) {
      [titleControl setTitleFragments:@[[path stringByDeletingLastPathComponent], [path lastPathComponent], self.currentSymbol.icon, self.currentSymbol.title] selectedIndexes:[NSIndexSet indexSetWithIndex:1]];
    } else {
      [titleControl setTitleFragments:@[[path stringByDeletingLastPathComponent], [path lastPathComponent], self.currentSymbol.title] selectedIndexes:[NSIndexSet indexSetWithIndex:1]];
    }
    return YES;
  }
  return NO;
}

#pragma mark - Toolbar Items Actions

- (void)toolButtonAction:(id)sender {
  UIActionSheet *actionSheet = nil;
  if (self._isWebPreview) {
    if (!_webToolsActionSheet) {
      _webToolsActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Reload", nil];
    }
    actionSheet = _webToolsActionSheet;
  } else {
    if (!_editToolsActionSheet) {
      _editToolsActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Find and replace", @"Minimap", nil];
    }
    actionSheet = _editToolsActionSheet;
  }
  
  [actionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (actionSheet == _editToolsActionSheet) {
    switch (buttonIndex) {
      case 0: // toggle find/replace
      {
        if (!_searchBarController) {
          _searchBarController = [[UIStoryboard storyboardWithName:@"SearchBar" bundle:nil] instantiateInitialViewController];
        }
				_searchBarController.targetCodeFileController = self;
        if (self.singleTabController.toolbarViewController != _searchBarController) {
          [self.singleTabController setToolbarViewController:_searchBarController animated:YES];
          [_searchBarController.findTextField becomeFirstResponder];
        } else {
          [self.singleTabController setToolbarViewController:nil animated:YES];
        }
        break;
      }
        
      case 1: // toggle minimap
      {
        [self setMinimapVisible:!self.minimapVisible animated:YES];
        if (self.minimapVisible) {
          self.minimapView.selectionRectangle = self.codeView.bounds;
        }
        break;
      }
        
      default:
        break;
    }
  } else if (actionSheet == _webToolsActionSheet) {
    switch (buttonIndex) {
      case 0: // Reload
        [self.webView reload];
        break;
        
      default:
        break;
    }
  }
}

#pragma mark - View lifecycle

- (id)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  
  @weakify(self);
  
  // Keep main view background color equal to code view background
  RAC(self.view.backgroundColor) = RACAble(self.codeView.backgroundColor);
  
  // When the currentLocation's url changes, bind the text file and the bookmarks
  [[[[RACAble(self.artCodeTab.currentLocation) map:^(ArtCodeLocation *location) {
    return [RCIOFile itemWithURL:location.url];
  }] switchToLatest] catchTo:RACSignal.empty] toProperty:@keypath(self.textFile) onObject:self];
	
  __block RACDisposable *bookmarksDisposable = nil;
  [RACAble(self.textFile) subscribeNext:^(RCIOFile *textFile) {
    @strongify(self);
    if (!self) { return; }
    [bookmarksDisposable dispose];
    bookmarksDisposable = [RACBind(self, bookmarks) bindTo:textFile.bookmarksSubject.binding];
  }];
  
  // When the text file or the code view change, bind their texts together
	__block RACDisposable *fileContentDisposable = nil;
  [[RACSignal combineLatest:@[RACAble(self.codeView), RACAble(self.textFile)]] subscribeNext:^(RACTuple *tuple) {
    CodeView *codeView = tuple.first;
    RCIOFile *textFile = tuple.second;
    [fileContentDisposable dispose];
    if (!codeView || !textFile) return;
		fileContentDisposable = [RACBind(codeView, text) bindTo:textFile.contentSubject.binding];
  }];

  // When the text file changes, moves or selects another syntax, reload the code unit
  [[[[[[[RACSignal combineLatest:@[[RACAble(self.textFile.urlSignal) switchToLatest], [RACAble(self.textFile.explicitSyntaxIdentifierSubject) switchToLatest], RACAble(self.textFile)]] deliverOn:self.codeScheduler] map:^RACSignal *(RACTuple *tuple) {
    NSURL *fileURL = tuple.first;
    NSString *explicitSyntaxIdentifier = tuple.second;
    RCIOFile *textFile = tuple.third;
    ASSERT_NOT_MAIN_QUEUE();
    @strongify(self);
    if (!self || !fileURL) {
      return nil;
    }
    // Selecting the syntax to use
    if (explicitSyntaxIdentifier) {
      return [RACSignal return:[RACTuple tupleWithObjectsFromArray:@[fileURL, [TMSyntaxNode syntaxWithScopeIdentifier:explicitSyntaxIdentifier]]]];
    }
    return [[textFile.contentSubject take:1] map:^RACTuple *(NSString *x) {
      TMSyntaxNode *syntax = [TMSyntaxNode syntaxForFirstLine:[x substringWithRange:[x lineRangeForRange:NSMakeRange(0, 0)]]];
      if (!syntax) {
        syntax = [TMSyntaxNode syntaxForFileName:fileURL.lastPathComponent];
      }
      if (!syntax) {
        syntax = [TMSyntaxNode defaultSyntax];
      }
      ASSERT(syntax);
      return [RACTuple tupleWithObjectsFromArray:@[fileURL, syntax]];
    }];
  }] switchToLatest] map:^TMUnit *(RACTuple *xs) {
    return [[TMUnit alloc] initWithFileURL:xs.first syntax:xs.second index:nil];
  }] deliverOn:RACScheduler.mainThreadScheduler] toProperty:@keypath(self.codeUnit) onObject:self];
  
  // subscribe to the tokens for syntax coloring
  [[[[[RACAble(self.codeUnit.tokens) switchToLatest] subscribeOn:self.codeScheduler] flatten] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(TMToken *token) {
    ASSERT_MAIN_QUEUE();
    @strongify(self);
    if (!self) {
      return;
    }
    // Check for range sanity since the text could have changed during the delivery
    if (NSMaxRange(token.range) <= self.codeView.text.length) {
      [self.codeView setAttributes:[[TMTheme currentTheme] attributesForQualifiedIdentifier:token.qualifiedIdentifier] range:token.range];
    }
  }];
  
  // subscribe to the text file's content to reparse
  [[[RACSignal combineLatest:@[[RACAble(self.textFile.contentSubject) switchToLatest], RACAble(self.codeUnit), RACAble(self.codeView)]] deliverOn:self.codeScheduler] subscribeNext:^(RACTuple *tuple) {
    ASSERT_NOT_MAIN_QUEUE();
    NSString *changedContent = tuple.first;
    TMUnit *codeUnit = tuple.second;
    [codeUnit reparseWithUnsavedContent:changedContent];
  }];
  
  // Update title with current symbol and keyboard accessory based on current scope
  [[[RACSignal combineLatest:@[RACAble(self.codeView.selectionRange), [RACAble(self.textFile.contentSubject) switchToLatest]]] throttle:0.3] subscribeNext:^(RACTuple *tuple) {
    @strongify(self);
    if (!self) {
      return;
    }
    NSRange selectionRange = [tuple.first rangeValue];
    
    // Select current scope
    TMSymbol *currentSymbol = nil;
    for (TMSymbol *symbol in self.codeUnit.symbolList) {
      if (symbol.range.location > selectionRange.location)
        break;
      currentSymbol = symbol;
    }
    if (currentSymbol != self.currentSymbol) {
      self.currentSymbol = currentSymbol;
      [self.singleTabController updateDefaultToolbarTitle];
    }
    
    // Update the keyboard accessory view and other preferences
    NSString *qualifiedIdentifier = [self.codeUnit qualifiedScopeIdentifierAtOffset:selectionRange.location];
    [self _keyboardAccessoryItemSetupWithQualifiedIdentifier:qualifiedIdentifier];
    self.codeView.pairingStringDictionary = [TMPreference preferenceValueForKey:TMPreferenceSmartTypingPairsKey qualifiedIdentifier:qualifiedIdentifier];
    
    // Updating indentation blocks used by autoIndentationBlock property of CodeView
    self.preferenceIncreaseIndentBlock = [TMPreference preferenceValueForKey:TMPreferenceIncreaseIndentKey
                                                           qualifiedIdentifier:qualifiedIdentifier];
    self.preferenceDecreaseIndentBlock = [TMPreference preferenceValueForKey:TMPreferenceDecreaseIndentKey
                                                           qualifiedIdentifier:qualifiedIdentifier];
  }];
  
  // load the web preview if needed
  [[RACSignal combineLatest:@[RACAble(self.textFile), RACAble(self.webView)]] subscribeNext:^(id x) {
    @strongify(self);
    [self _loadWebPreviewContentAndTitle];
  }];
  
  // Handle keyboard display changes
	[[RACSignal combineLatest:@[ [RACSignal merge:@[ [NSNotificationCenter.defaultCenter rac_addObserverForName:UIKeyboardDidShowNotification object:nil], [NSNotificationCenter.defaultCenter rac_addObserverForName:UIKeyboardWillHideNotification object:nil] ]], RACAble(self.codeView.keyboardAccessoryViewVisible) ] reduce:^(NSNotification *keyboardNotification, NSNumber *accessoryViewVisible) {
		@strongify(self);
		if (keyboardNotification.name == UIKeyboardWillHideNotification) {
			return @(self.view.bounds.size.height);
		} else {
			CGRect keyboardFrame = [self.view convertRect:[keyboardNotification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
			if (accessoryViewVisible.boolValue) {
				return @(keyboardFrame.origin.y - 45);
			} else {
				return @(keyboardFrame.origin.y);
			}
		}
	}] subscribeNext:^(NSNumber *frameHeight) {
		@strongify(self);
		CGRect frame = self.view.bounds;
		frame.size.height = frameHeight.floatValue;
		self.wrapperView.frame = frame;
	}];
  
  return self;
}

- (void)didReceiveMemoryWarning {
	self.hiddenView = nil;
	[super didReceiveMemoryWarning];
}

- (void)loadView {
  [super loadView];
  
	UIView *wrapperView = [[UIView alloc] initWithFrame:self.view.bounds];
  wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:wrapperView];
	self.wrapperView = wrapperView;
  
  self.editButtonItem.title = @"";
  self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];

}

- (void)viewDidLoad {
  [self.wrapperView addSubview:[self _contentView]];
  
  self.toolbarItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"topBarItem_Tools"] style:UIBarButtonItemStylePlain target:self action:@selector(toolButtonAction:)]];  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self _layoutChildViews];
  if ([self _isWebPreview]) {
    [self _loadWebPreviewContentAndTitle];
  }
}

#pragma mark - Controller Methods

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [_quickBrowsersPopover dismissPopoverAnimated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  if (self.minimapVisible) {
    self.minimapView.selectionRectangle = self.codeView.bounds;
  }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
  UIView *oldContentView = [self _contentView];
  
  [self willChangeValueForKey:@"editing"];
  
  [super setEditing:editing animated:animated];
  self.editButtonItem.title = @"";
  
  UIView *currentContentView = [self _contentView];
  if ([currentContentView isKindOfClass:[CodeView class]]) {
    [(CodeView *)currentContentView setEditing:editing];
  }
	
	self.hiddenView = oldContentView;
  
  if (editing) {
    // Set keyboard for main scope
    [self _keyboardAccessoryItemSetupWithQualifiedIdentifier:nil];
  }
  
  if (oldContentView != currentContentView) {
    [self _loadWebPreviewContentAndTitle];
    
    [UIView transitionFromView:oldContentView toView:currentContentView duration:animated ? 0.2 : 0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
      [self _layoutChildViews];
      [self didChangeValueForKey:@"editing"];
    }];
  } else {
    [self didChangeValueForKey:@"editing"];
  }
}

+ (BOOL)automaticallyNotifiesObserversOfEditing {
  return NO;
}

#pragma mark - Minimap Delegate Methods

- (BOOL)codeFileMinimapView:(CodeFileMinimapView *)minimapView
           shouldRenderLine:(TextRendererLine *)line
                     number:(NSUInteger)lineNumber
                      range:(NSRange)range
                  withColor:(UIColor *__autoreleasing *)lineColor
                 decoration:(CodeFileMinimapLineDecoration *)decoration
            decorationColor:(UIColor *__autoreleasing *)decorationColor {
  // Set bookmark decoration
  if (!line.isTruncation && [self.bookmarks containsIndex:lineNumber + 1]) {
    *decoration = CodeFileMinimapLineDecorationDisc;
    *decorationColor = [UIColor whiteColor];
  }
  
  // Don't draw if line is too small
  if (*decoration == 0 && line.width <= line.height)
    return NO;
  
  // Color symbols
  for (TMSymbol *symbol in self.codeUnit.symbolList) {
    if (NSLocationInRange(symbol.range.location, range)) {
      if (!_minimapSymbolColor) {
        _minimapSymbolColor = [UIColor colorWithCGColor:(__bridge CGColorRef)[[TMTheme currentTheme] attributesForQualifiedIdentifier:symbol.qualifiedIdentifier][(__bridge id)kCTForegroundColorAttributeName]];
      }
      *lineColor = _minimapSymbolColor;
      return YES;
    }
  }
  
  // Color comments and preprocessor
  __block UIColor *color = *lineColor;
  [self.codeUnit enumerateQualifiedScopeIdentifiersInRange:range withBlock:^(NSString *qualifiedIdentifier, NSRange scopeRange, BOOL *stop) {
    if (scopeRange.length < 2)
      return;
    
    if ([qualifiedIdentifier rangeOfString:@"preprocessor"].location != NSNotFound) {
      if (!_minimapPreprocessorColor) {
        _minimapPreprocessorColor = [UIColor colorWithCGColor:(__bridge CGColorRef)[[TMTheme currentTheme] attributesForQualifiedIdentifier:qualifiedIdentifier][(__bridge id)kCTForegroundColorAttributeName]];
      }
      color = _minimapPreprocessorColor;
      *stop = YES;
      return;
    }
    
    if ([qualifiedIdentifier rangeOfString:@"comment"].location != NSNotFound) {
      if (!_minimapCommentColor) {
        _minimapCommentColor = [UIColor colorWithCGColor:(__bridge CGColorRef)[[TMTheme currentTheme] attributesForQualifiedIdentifier:qualifiedIdentifier][(__bridge id)kCTForegroundColorAttributeName]];
      }
      color = _minimapCommentColor;
      *stop = YES;
      return;
    }
  }];
  *lineColor = color;
  
  return YES;
}

- (BOOL)codeFileMinimapView:(CodeFileMinimapView *)minimapView shouldChangeSelectionRectangle:(CGRect)newSelection {
  [self.codeView scrollRectToVisible:newSelection animated:YES];
  return NO;
}

#pragma mark - Code View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (_minimapVisible && scrollView == self.codeView) {
    _minimapView.selectionRectangle = self.codeView.bounds;
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (_minimapVisible && scrollView == self.codeView) {
    [_minimapView scrollToSelection];
  }
}

- (void)codeView:(CodeView *)codeView selectedLineNumber:(NSUInteger)lineNumber {
	if (self.bookmarks == nil) self.bookmarks = [NSIndexSet indexSet];
  if ([self.bookmarks containsIndex:lineNumber]) {
    self.bookmarks = [self.bookmarks indexSetByRemovingIndex:lineNumber];
  } else {
    self.bookmarks = [self.bookmarks indexSetByAddingIndex:lineNumber];
  }
  [codeView setNeedsDisplay];
  [_minimapView setNeedsDisplay];
}

- (BOOL)codeView:(CodeView *)codeView shouldShowKeyboardAccessoryViewOnNotification:(NSNotification *)note inView:(UIView *__autoreleasing *)view withFrame:(CGRect *)frame {
	*view = self.view;
	*frame = [self.view convertRect:[note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
	
	// Set keyboard position specific accessory popover properties
	if (self.codeView.keyboardAccessoryView.isSplit) {
		self._keyboardAccessoryView.itemPopoverView.positioningInsets = UIEdgeInsetsMake(4, 3, 4, 3);
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(62, 54) forMetaPosition:PopoverViewArrowMetaPositionFarLeft];
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(56, 54) forMetaPosition:PopoverViewArrowMetaPositionMiddle];
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(62, 54) forMetaPosition:PopoverViewArrowMetaPositionFarRight];
	} else if ((*frame).size.width > 768) {
		self._keyboardAccessoryView.itemPopoverView.positioningInsets = UIEdgeInsetsMake(4, -3, 4, -3);
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(100, 54) forMetaPosition:PopoverViewArrowMetaPositionFarLeft];
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(99, 54) forMetaPosition:PopoverViewArrowMetaPositionMiddle];
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(100, 54) forMetaPosition:PopoverViewArrowMetaPositionFarRight];
	} else {
		self._keyboardAccessoryView.itemPopoverView.positioningInsets = UIEdgeInsetsMake(4, -3, 4, -3);
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(79, 54) forMetaPosition:PopoverViewArrowMetaPositionFarLeft];
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(77, 54) forMetaPosition:PopoverViewArrowMetaPositionMiddle];
		[self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(79, 54) forMetaPosition:PopoverViewArrowMetaPositionFarRight];
	}
	return YES;
}

#pragma mark - Webview delegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
  self.loading = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  self.loading = NO;
  if ([self _isWebPreview]) {
    self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
  }
}

#pragma mark - Displayable Content

+ (BOOL)canDisplayFileInCodeView:(NSURL *)fileURL {
  FileMagic *magic = [[FileMagic alloc] initWithFileURL:fileURL];
  if ([magic.mimeType isEqualToString:@"application/x-empty"] || [magic.mimeType isEqualToString:@"inode/x-empty"]) {
    return YES;
  }
  return [magic.mimeType hasPrefix:@"text"];
}

+ (BOOL)canDisplayFileInWebView:(NSURL *)fileURL {
  NSString *extension = fileURL.pathExtension.lowercaseString;
  return [extension isEqualToString:@"html"] || [extension isEqualToString:@"htm"];
}

#pragma mark - Private Methods

- (UIView *)_contentViewForEditingState:(BOOL)editingState {
  if (!editingState && [self.class canDisplayFileInWebView:self.artCodeTab.currentLocation.url]) {
		UIWebView *webView = self.webView;
    if (webView) return webView;
		
		if ([self.hiddenView isKindOfClass:[UIWebView class]]) return self.hiddenView;
		
		webView = [[UIWebView alloc] init];
		webView.delegate = self;
		webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.webView = webView;
		return webView;
  } else {
		CodeView *codeView = self.codeView;
		if (codeView) return codeView;
		
		if ([self.hiddenView isKindOfClass:[CodeView class]]) return self.hiddenView;
		
		// Load the codeview
		__weak CodeFileController *this = self;
		
		codeView = [[CodeView alloc] init];
		codeView.delegate = self;
		codeView.magnificationPopoverBackgroundViewClass = [ImagePopoverBackgroundView class];
		
		codeView.textInsets = UIEdgeInsetsMake(0, 10, 0, 10);
		codeView.contentInset = UIEdgeInsetsMake(10, 0, 10, 0);
		
		codeView.lineNumbersEnabled = YES;
		codeView.lineNumbersWidth = 30;
		codeView.lineNumbersFont = [UIFont systemFontOfSize:10];
		
		codeView.alwaysBounceVertical = YES;
		codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		UISwipeGestureRecognizer *undoRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureUndo:)];
		undoRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
		undoRecognizer.numberOfTouchesRequired = 2;
		[codeView addGestureRecognizer:undoRecognizer];
		UISwipeGestureRecognizer *redoRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureRedo:)];
		redoRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
		undoRecognizer.numberOfTouchesRequired = 2;
		[codeView addGestureRecognizer:redoRecognizer];
		
		// Bookmark markers
		[codeView addPassLayerBlock:^(CGContextRef context, TextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
			if (!line.isTruncation && [this.bookmarks containsIndex:lineNumber +1]) {
				CGContextSetFillColorWithColor(context, this.codeView.lineNumbersColor.CGColor);
				CGContextTranslateCTM(context, -lineBounds.origin.x, line.descent / 2.0 + 1);
				drawStencilStar(context);
			}
		} underText:NO forKey:@"bookmarkMarkers"];
		
		// Autoindentation block
		@weakify(self);
		codeView.autoIndentationBlock = ^CodeViewAutoIndentResult(NSString *line) {
			@strongify(self);
			if (self.preferenceIncreaseIndentBlock) {
				// Apply increase indetantion
				if (self.preferenceIncreaseIndentBlock(line)) {
					return CodeViewAutoIndentIncrease;
				} else {
					// Apply decrease indentation
					if (self.preferenceDecreaseIndentBlock) {
						if (self.preferenceDecreaseIndentBlock(line)) {
							return CodeViewAutoIndentDecrease;
						}
						// TODO: else single line indent
					}
				}
			}
			return CodeViewAutoIndentKeep;
		};
		
		// Accessory view
		CodeFileKeyboardAccessoryView *accessoryView = [[CodeFileKeyboardAccessoryView alloc] init];
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
		
		codeView.keyboardAccessoryView = accessoryView;
		
		// Accessory view popover setup
		accessoryView.itemPopoverView.contentSize = CGSizeMake(300, 300);
		accessoryView.itemPopoverView.contentInsets = UIEdgeInsetsMake(12, 12, 12, 12);
		accessoryView.itemPopoverView.backgroundView.image = [[UIImage imageNamed:@"accessoryView_popoverBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 50, 10)];
		[accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowMiddle"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionMiddle];
		[accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionFarRight];
		[accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowLeft"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionFarLeft];
		accessoryView.itemPopoverView.arrowInsets = UIEdgeInsetsMake(12, 12, 12, 12);
		
		UIView *accessoryPopoverContentView = [[UIView alloc] init];
		accessoryPopoverContentView.backgroundColor = [UIColor whiteColor];
		accessoryView.itemPopoverView.contentView = accessoryPopoverContentView;
		
		codeView.defaultTextAttributes = [[TMTheme currentTheme] commonAttributes];
		
		self.codeView = codeView;
		[self _setCodeViewAttributesForTheme:nil];
		
		return codeView;
  }
}

- (UIView *)_contentView {
  return [self _contentViewForEditingState:self.isEditing];
}

- (BOOL)_isWebPreview {
  return [self _contentViewForEditingState:self.isEditing] == _webView;
}

- (void)_loadWebPreviewContentAndTitle {
  if ([self _isWebPreview] && self.textFile) {
    @weakify(self);
		[self.textFile.save subscribeNext:^(RCIOItem *item) {
      @strongify(self);
      [self.webView loadRequest:[NSURLRequest requestWithURL:item.url]];
      self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
		}];
  } else {
    self.title = nil;
  }
}

- (void)_layoutChildViews {
  CGRect frame = (CGRect){ CGPointZero, self.wrapperView.frame.size };
  if ([self _isWebPreview]) {
    self.webView.frame = frame;
  } else {
    if (self.minimapVisible) {
      self.codeView.frame = CGRectMake(0, 0, frame.size.width - self.minimapWidth, frame.size.height);
      self.minimapView.frame = CGRectMake(frame.size.width - self.minimapWidth, 0, self.minimapWidth, frame.size.height);
    } else {
      self.codeView.frame = frame;
      _minimapView.frame = CGRectMake(frame.size.width, 0, self.minimapWidth, frame.size.height);
    }
  }
}

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer {
  [self.codeView.undoManager undo];
}

- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer {
  [self.codeView.undoManager redo];
}

#pragma mark - Keyboard Accessory Item Methods

- (CodeFileKeyboardAccessoryView *)_keyboardAccessoryView {
  return (CodeFileKeyboardAccessoryView *)self.codeView.keyboardAccessoryView;
}

- (void)_keyboardAccessoryItemSetupWithQualifiedIdentifier:(NSString *)qualifiedIdentifier {
  NSArray *configuration = [TMKeyboardAction keyboardActionsConfigurationForQualifiedIdentifier:qualifiedIdentifier];
  ASSERT(configuration);
  
  if (_keyboardAccessoryItemActions == configuration) {
    return;
  }
  
  _keyboardAccessoryItemActions = configuration;
  ASSERT([_keyboardAccessoryItemActions count] == 11);
  
  CodeFileKeyboardAccessoryView *accessoryView = (CodeFileKeyboardAccessoryView *)self.codeView.keyboardAccessoryView;
  
  // Items
  if (accessoryView.items == nil) {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:11];
    CodeFileKeyboardAccessoryItem *item = nil;
    TMKeyboardAction *action = nil;
    
    for (NSInteger i = 0; i < 11; ++i) {
      item = [[CodeFileKeyboardAccessoryItem alloc] initWithTitle:[NSString stringWithFormat:@"%d", i] style:UIBarButtonItemStylePlain target:self action:@selector(_keyboardAccessoryItemAction:)];
      
      if (i == 0) {
        [item setWidth:44 + 4 forAccessoryPosition:KeyboardAccessoryPositionFloating];
      } else if (i == 10) {
        [item setWidth:63 + 4 forAccessoryPosition:KeyboardAccessoryPositionPortrait];
        [item setWidth:82 + 4 forAccessoryPosition:KeyboardAccessoryPositionLandscape];
        [item setWidth:44 + 4 forAccessoryPosition:KeyboardAccessoryPositionFloating];
      } else {
        if (i % 2)
          [item setWidth:60 + 4 forAccessoryPosition:KeyboardAccessoryPositionPortrait];
      }
      
      action = _keyboardAccessoryItemActions[i];
      item.title = action.title;
      item.image = [action image];
      item.tag = i;
      [items addObject:item];
    }
    
    accessoryView.items = items;
  } else {
    NSArray *items = accessoryView.items;
    [items enumerateObjectsUsingBlock:^(CodeFileKeyboardAccessoryItem *item, NSUInteger itemIndex, BOOL *stop) {
      TMKeyboardAction *action = _keyboardAccessoryItemActions[itemIndex];
      item.title = action.title;
      item.image = [action image];
    }];
    accessoryView.items = items;
  }
}

- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item {
  _keyboardAccessoryItemCurrentActionIndex = item.tag;
  [_keyboardAccessoryItemActions[item.tag] executeActionOnTarget:self];
}

static CGFloat placeholderEndingsWidthCallback(void *refcon) {
  if (refcon) {
    CGFloat height = CTFontGetXHeight(refcon);
    return height / 2.0;
  }
  return 4.5;
}

static CTRunDelegateCallbacks placeholderEndingsRunCallbacks = {
  kCTRunDelegateVersion1,
  NULL,
  NULL,
  NULL,
  &placeholderEndingsWidthCallback
};

- (void)_markPlaceholderWithName:(NSString *)name inAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range {
  ASSERT(range.length > 4);
  
  static CGColorRef placeholderFillColor = NULL;
  if (!placeholderFillColor) {
    placeholderFillColor = CGColorRetain([UIColor colorWithRed:234.0/255.0 green:240.0/255.0 blue:250.0/255.0 alpha:1].CGColor);
  }
  
  static CGColorRef placeholderStrokeColor = NULL;
  if (!placeholderStrokeColor) {
    placeholderStrokeColor = CGColorRetain([UIColor colorWithRed:197.0/255.0 green:216.0/255.0 blue:243.0/255.0 alpha:1].CGColor);
  }
  
  static TextRendererRunBlock placeHolderBodyBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
    rect.origin.y += 1;
    rect.size.height -= baselineOffset;
    CGContextSetFillColorWithColor(context, placeholderFillColor);
    CGContextAddRect(context, rect);
    CGContextFillPath(context);
    //
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), rect.origin.y);
    CGContextMoveToPoint(context, rect.origin.x, CGRectGetMaxY(rect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
    CGContextStrokePath(context);
  };
  
  static TextRendererRunBlock placeholderLeftBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
    rect.origin.y += 1;
    rect.size.height -= baselineOffset;
    CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    //
    CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
    CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
    CGContextClosePath(context);
    CGContextSetFillColorWithColor(context, placeholderFillColor);
    CGContextFillPath(context);
    //
    CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
    CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
    CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
    CGContextStrokePath(context);
  };
  
  static TextRendererRunBlock placeholderRightBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
    rect.origin.y += 1;
    rect.size.height -= baselineOffset;
    CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    //
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
    CGContextClosePath(context);
    CGContextSetFillColorWithColor(context, placeholderFillColor);
    CGContextFillPath(context);
    //
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
    CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
    CGContextStrokePath(context);
  };
  
  // placeholder body style
  [attributedString addAttributes:@{TextRendererRunUnderlayBlockAttributeName: placeHolderBodyBlock, (id)kCTForegroundColorAttributeName: (id)([UIColor blackColor].CGColor)} range:NSMakeRange(range.location + 2, range.length - 4)];
  
  // Opening and Closing style
  
  //
  CGFontRef font = (__bridge CGFontRef)(TMTheme.defaultTheme.commonAttributes)[(__bridge id)kCTFontAttributeName];
  ASSERT(font);
  CTRunDelegateRef delegateRef = CTRunDelegateCreate(&placeholderEndingsRunCallbacks, font);
  
  [attributedString addAttributes:@{(id)kCTRunDelegateAttributeName: (__bridge id)delegateRef, TextRendererRunDrawBlockAttributeName: placeholderLeftBlock} range:NSMakeRange(range.location, 2)];
  [attributedString addAttributes:@{(id)kCTRunDelegateAttributeName: (__bridge id)delegateRef, TextRendererRunDrawBlockAttributeName: placeholderRightBlock} range:NSMakeRange(NSMaxRange(range) - 2, 2)];
  
  CFRelease(delegateRef);
  
  // Placeholder behaviour
  [attributedString addAttributes:@{CodeViewPlaceholderAttributeName: name} range:range];
}

#pragma mark Keyboard Actions Target Methods

- (BOOL)keyboardAction:(TMKeyboardAction *)keyboardAction canPerformSelector:(SEL)selector {
  if ([self forwardingTargetForSelector:selector] != nil) {
    return YES;
  }
  ASSERT(NO && "An action called a not supported selector");
  return NO;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
  if (aSelector == @selector(insertText:) || aSelector == @selector(deleteBackward)) {
    return self.codeView;
  }
  if (aSelector == @selector(undo) || aSelector == @selector(redo)) {
    return self.codeView.undoManager;
  }
  return nil;
}

- (void)_setCodeViewAttributesForTheme:(TMTheme *)theme {
  UIColor *color = nil;
  color = (theme.environmentAttributes)[TMThemeBackgroundColorEnvironmentAttributeKey];
  self.codeView.backgroundColor = color ? color : [UIColor whiteColor];
  self.codeView.lineNumbersColor = color ? [color colorByIncreasingContrast:.38] : [UIColor colorWithWhite:0.62 alpha:1];
  self.codeView.lineNumbersBackgroundColor = color ? [color colorByIncreasingContrast:.09] : [UIColor colorWithWhite:0.91 alpha:1];
  color = (theme.environmentAttributes)[TMThemeCaretColorEnvironmentAttributeKey];
  self.codeView.caretColor = color ? color : [UIColor blackColor];
  color = (theme.environmentAttributes)[TMThemeSelectionColorEnvironmentAttributeKey];
  self.codeView.selectionColor = color ? color : [[UIColor blueColor] colorWithAlphaComponent:0.3];
  
  _minimapView.backgroundColor = self.codeView.lineNumbersBackgroundColor;
  _minimapView.lineShadowColor = self.codeView.backgroundColor;
  
  _minimapSymbolColor = _minimapCommentColor = _minimapPreprocessorColor = nil;
}

@end
