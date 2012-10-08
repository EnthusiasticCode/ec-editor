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

#import "ArtCodeProject.h"

#import "NSIndexSet+PersistentDataStructure.h"
#import "FileSystemItem+TextFile.h"
#import <file/FileMagic.h>
#import "RACPropertySyncSubject.h"


@interface CodeFileController ()

@property (nonatomic, strong) CodeView *codeView;
@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, strong) NSIndexSet *bookmarks;

@property (nonatomic, strong, readonly) CodeFileKeyboardAccessoryView *_keyboardAccessoryView;

@property (nonatomic, strong) RACScheduler *codeScheduler;

@property (nonatomic, weak) TMSymbol *currentSymbol;

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

- (void)_keyboardWillShow:(NSNotification *)notification;
- (void)_keyboardWillHide:(NSNotification *)notification;
- (void)_keyboardWillChangeFrame:(NSNotification *)notification;

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
  
  // Keyboard manahement
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

#pragma mark - Properties

@synthesize codeView = _codeView, webView = _webView, minimapView = _minimapView, minimapVisible = _minimapVisible, minimapWidth = _minimapWidth;
@synthesize codeUnit = _codeUnit, codeScheduler = _codeScheduler, currentSymbol = _currentSymbol;

- (UIWebView *)webView {
  if (!_webView && self.isViewLoaded) {
    _webView = [[UIWebView alloc] init];
    _webView.delegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  }
  return _webView;
}

- (CodeFileMinimapView *)minimapView {
  if (!_minimapView) {
    _minimapView = [CodeFileMinimapView new];
    _minimapView.delegate = self;
    _minimapView.renderer = self.codeView.renderer;
    
    _minimapView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    _minimapView.contentInset = UIEdgeInsetsMake(10, 0, 10, 10);
    _minimapView.alwaysBounceVertical = YES;
    
    _minimapView.backgroundColor = self.codeView.lineNumbersBackgroundColor;
    _minimapView.lineShadowColor = self.codeView.backgroundColor;
    _minimapView.lineDecorationInset = 10;
    _minimapView.lineDefaultColor = [UIColor blackColor];
  }
  return _minimapView;
}

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
    [self.view addSubview:self.minimapView];
  }
  if (animated) {
    [self _layoutChildViews];
    _minimapVisible = minimapVisible;
    [UIView animateWithDuration:0.25 animations:^{
      [self _layoutChildViews];
    } completion:^(BOOL finished) {
      if (!_minimapVisible)
        [_minimapView removeFromSuperview];
    }];
  } else {
    _minimapVisible = minimapVisible;
    if (!_minimapVisible)
      [_minimapView removeFromSuperview];
    [self _layoutChildViews];
  }
  [self didChangeValueForKey:@"minimapVisible"];
}

+ (BOOL)automaticallyNotifiesObserversOfMinimapVisible {
  return NO;
}

- (TMUnit *)codeUnit {
  ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
  return _codeUnit;
}

- (void)setCodeUnit:(TMUnit *)codeUnit {
  ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
  if (codeUnit == _codeUnit) {
    return;
  }
  _codeUnit = codeUnit;
}

- (RACScheduler *)codeScheduler {
  if (!_codeScheduler) {
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 1;
    operationQueue.name = @"CodeFileController code queue";
    _codeScheduler = [RACScheduler schedulerWithOperationQueue:operationQueue];
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
}

- (BOOL)singleTabController:(SingleTabController *)singleTabController setupDefaultToolbarTitleControl:(TopBarTitleControl *)titleControl {
  if (self.currentSymbol) {
    NSString *path = [self.artCodeTab.currentLocation path];
    if (self.currentSymbol.icon) {
      [titleControl setTitleFragments:[NSArray arrayWithObjects:[path stringByDeletingLastPathComponent], [path lastPathComponent], self.currentSymbol.icon, self.currentSymbol.title, nil] selectedIndexes:[NSIndexSet indexSetWithIndex:1]];
    } else {
      [titleControl setTitleFragments:[NSArray arrayWithObjects:[path stringByDeletingLastPathComponent], [path lastPathComponent], self.currentSymbol.title, nil] selectedIndexes:[NSIndexSet indexSetWithIndex:1]];
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
          _searchBarController.targetCodeFileController = self;
        }
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

  // When the currentLocation's url changes, bind the text file and the bookmarks
  [RACAble(self.artCodeTab.currentLocation.url) subscribeNext:^(NSURL *url) {
    [[FileSystemItem readItemAtURL:url] subscribeNext:^(FileSystemItem *textFile) {
      @strongify(self);
      if (!self) {
        return;
      }
      self.textFile = textFile;
      [textFile.bookmarks syncProperty:RAC_KEYPATH_SELF(bookmarks) ofObject:self];
    }];
  }];
  
  // When the text file or the code view change, bind their texts together
  [[RACSubscribable combineLatest:@[RACAble(self.codeView), RACAble(self.textFile)]] subscribeNext:^(RACTuple *tuple) {
    CodeView *codeView = tuple.first;
    FileSystemItem *textFile = tuple.second;
    if (!codeView || !textFile) {
      return;
    }
    [textFile.stringContent syncProperty:RAC_KEYPATH(codeView, text) ofObject:codeView];
  }];
  
  // When the text file changes, reload the code unit
  [RACAble(self.textFile) subscribeNext:^(FileSystemItem *textFile) {
    if (!textFile) {
      // No file, remove the code unit
      @strongify(self);
      self.codeUnit = nil;
      return;
    }
    [[textFile itemURL] subscribeNext:^(NSURL *fileURL) {
      if (!fileURL) {
        // File was deleted, remove the code unit
        @strongify(self);
        self.codeUnit = nil;
        return;
      }
      [[textFile explicitSyntaxIdentifier] subscribeNext:^(NSString *explicitSyntaxIdentifier) {
        [[[textFile stringContent] take:1] subscribeNext:^(NSString *content) {
          @strongify(self);
          if (!self) {
            return;
          }
          // Selecting the syntax to use
          TMSyntaxNode *syntax = nil;
          if (explicitSyntaxIdentifier) {
            syntax = [TMSyntaxNode syntaxWithScopeIdentifier:explicitSyntaxIdentifier];
          }
          if (!syntax) {
            syntax = [TMSyntaxNode syntaxForFirstLine:[content substringWithRange:[content lineRangeForRange:NSMakeRange(0, 0)]]];
          }
          if (!syntax) {
            syntax = [TMSyntaxNode syntaxForFileName:fileURL.lastPathComponent];
          }
          if (!syntax) {
            syntax = [TMSyntaxNode defaultSyntax];
          }
          ASSERT(syntax);
          
          // Create the code unit
          [self.codeScheduler schedule:^{
            ASSERT_NOT_MAIN_QUEUE();
            TMUnit *codeUnit = [[TMUnit alloc] initWithFileURL:fileURL syntax:syntax index:nil];
            
            [[RACScheduler mainQueueScheduler] schedule:^{
              ASSERT_MAIN_QUEUE();
              @strongify(self);
              if (!self) {
                return;
              }
              self.codeUnit = codeUnit;
              
              // subscribe to the tokens for syntax coloring
              [[[[codeUnit.tokens subscribeOn:self.codeScheduler] merge] deliverOn:[RACScheduler mainQueueScheduler]] subscribeNext:^(TMToken *token) {
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
              [[textFile.stringContent deliverOn:self.codeScheduler] subscribeNext:^(NSString *changedContent) {
                [codeUnit reparseWithUnsavedContent:changedContent];
              }];
            }];
          }];
        }];
      }];
    }];
  }];
  
  // Update title with current symbol and keyboard accessory based on current scope
  [[RACAble(self.codeView.selectionRange) throttle:0.3] subscribeNext:^(NSValue *selectionValue) {
    @strongify(self);
    if (!self) {
      return;
    }
    NSRange selectionRange = [selectionValue rangeValue];
    
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
  }];
  
  return self;
}

- (void)loadView {
  [super loadView];
  
  self.editButtonItem.title = @"";
  self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
  
  // Load the codeview
  __weak CodeFileController *this = self;
  
  CodeView *codeView = [CodeView new];
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
  
  codeView.keyboardAccessoryView = accessoryView;
  
  // Accessory view popover setup
  accessoryView.itemPopoverView.contentSize = CGSizeMake(300, 300);
  accessoryView.itemPopoverView.contentInsets = UIEdgeInsetsMake(12, 12, 12, 12);
  accessoryView.itemPopoverView.backgroundView.image = [[UIImage imageNamed:@"accessoryView_popoverBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 50, 10)];
  [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowMiddle"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionMiddle];
  [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowRight"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionFarRight];
  [accessoryView.itemPopoverView setArrowImage:[[UIImage imageNamed:@"accessoryView_popoverArrowLeft"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forDirection:UIPopoverArrowDirectionDown metaPosition:PopoverViewArrowMetaPositionFarLeft];
  accessoryView.itemPopoverView.arrowInsets = UIEdgeInsetsMake(12, 12, 12, 12);
  
  UIView *accessoryPopoverContentView = [UIView new];
  accessoryPopoverContentView.backgroundColor = [UIColor whiteColor];
  accessoryView.itemPopoverView.contentView = accessoryPopoverContentView;
  
  codeView.defaultTextAttributes = [[TMTheme currentTheme] commonAttributes];

  self.codeView = codeView;
  [self _setCodeViewAttributesForTheme:nil];
}

- (void)viewDidLoad {
  [self.view addSubview:[self _contentView]];
  
  self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"topBarItem_Tools"] style:UIBarButtonItemStylePlain target:self action:@selector(toolButtonAction:)]];
  
  // Keyboard notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
  _keyboardFrame = CGRectNull;
  _keyboardRotationFrame = CGRectNull;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  _minimapView = nil;
  self.codeView = nil;
  
  _editToolsActionSheet = nil;
  _searchBarController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self _layoutChildViews];
  if ([self _isWebPreview]) {
    [self _loadWebPreviewContentAndTitle];
  }
}

#pragma mark - Controller Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

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

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  
  if (!_minimapVisible) {
    _minimapView = nil;
  }
  
  if ([self _isWebPreview]) {
    self.codeView = nil;
  } else {
    self.webView = nil;
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
        _minimapSymbolColor = [UIColor colorWithCGColor:(__bridge CGColorRef)[[[TMTheme currentTheme] attributesForQualifiedIdentifier:symbol.qualifiedIdentifier] objectForKey:(__bridge id)kCTForegroundColorAttributeName]];
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
        _minimapPreprocessorColor = [UIColor colorWithCGColor:(__bridge CGColorRef)[[[TMTheme currentTheme] attributesForQualifiedIdentifier:qualifiedIdentifier] objectForKey:(__bridge id)kCTForegroundColorAttributeName]];
      }
      color = _minimapPreprocessorColor;
      *stop = YES;
      return;
    }
    
    if ([qualifiedIdentifier rangeOfString:@"comment"].location != NSNotFound) {
      if (!_minimapCommentColor) {
        _minimapCommentColor = [UIColor colorWithCGColor:(__bridge CGColorRef)[[[TMTheme currentTheme] attributesForQualifiedIdentifier:qualifiedIdentifier] objectForKey:(__bridge id)kCTForegroundColorAttributeName]];
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
  if ([self.bookmarks containsIndex:lineNumber]) {
    self.bookmarks = [self.bookmarks indexSetByRemovingIndex:lineNumber];
  } else {
    self.bookmarks = [self.bookmarks indexSetByAddingIndex:lineNumber];
  }
  [codeView setNeedsDisplay];
  [_minimapView setNeedsDisplay];
}

- (BOOL)codeView:(CodeView *)codeView shouldShowKeyboardAccessoryViewInView:(UIView *__autoreleasing *)view withFrame:(CGRect *)frame {
  ASSERT(view && frame);
  
  if ([_keyboardAccessoryItemActions count] != 11)
    return NO;
  
  /// Set keyboard position specific accessory popover properties
  if (codeView.keyboardAccessoryView.isSplit) {
    self._keyboardAccessoryView.itemPopoverView.positioningInsets = UIEdgeInsetsMake(4, 3, 4, 3);
    [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(62, 54) forMetaPosition:PopoverViewArrowMetaPositionFarLeft];
    [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(56, 54) forMetaPosition:PopoverViewArrowMetaPositionMiddle];
    [self._keyboardAccessoryView.itemPopoverView setArrowSize:CGSizeMake(62, 54) forMetaPosition:PopoverViewArrowMetaPositionFarRight];
  } else if (_keyboardFrame.size.width > 768) {
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
  
  if ((*frame).origin.y - (*view).bounds.origin.y < (*view).bounds.size.height / 4)
    codeView.keyboardAccessoryView.flipped = YES;
  
  UIView *targetView = self.view.window.rootViewController.view;
  *frame = [targetView convertRect:*frame fromView:*view];
  *view = targetView;
  
  return YES;
}

- (void)codeView:(CodeView *)codeView didShowKeyboardAccessoryViewInView:(UIView *)view withFrame:(CGRect)accessoryFrame {
  if (!codeView.keyboardAccessoryView.isSplit) {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
      CGRect frame = self.view.frame;
      if (!CGRectIsNull(_keyboardFrame)) {
        frame.size.height = _keyboardFrame.origin.y - codeView.keyboardAccessoryView.frame.size.height;
      } else if (!CGRectIsNull(_keyboardRotationFrame)) {
        frame.size.height = _keyboardRotationFrame.origin.y - codeView.keyboardAccessoryView.frame.size.height;
      } else {
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

- (BOOL)codeViewShouldHideKeyboardAccessoryView:(CodeView *)codeView {
  [self._keyboardAccessoryView dismissPopoverForItemAnimated:YES];
  
  if (!codeView.keyboardAccessoryView.isSplit) {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
      CGRect frame = self.view.frame;
      if (!CGRectIsNull(_keyboardFrame)) {
        frame.size.height = _keyboardFrame.origin.y;
      } else if (!CGRectIsNull(_keyboardRotationFrame)) {
        frame.size.height = _keyboardRotationFrame.origin.y;
      } else {
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
  FileMagic *magic = [FileMagic.alloc initWithFileURL:fileURL];
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
    return self.webView;
  } else {
    return self.codeView;
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
    [[self.textFile save] subscribeCompleted:^{
      [self.textFile.itemURL subscribeNext:^(NSURL *itemURL) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:itemURL]];
        self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
      }];
    }];
  } else {
    self.title = nil;
  }
}

- (void)_layoutChildViews {
  CGRect frame = (CGRect){ CGPointZero, self.view.frame.size };
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

- (void)_keyboardWillChangeFrame:(NSNotification *)notification {
  _keyboardRotationFrame = [self.view convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
}

- (void)_keyboardWillShow:(NSNotification *)notification {
  _keyboardFrame = [self.view convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
  _keyboardRotationFrame = CGRectNull;
  [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0 options:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 | UIViewAnimationOptionBeginFromCurrentState animations:^{
    CGRect frame = self.view.frame;
    frame.size.height = _keyboardFrame.origin.y;
    self.view.frame = frame;
  } completion:nil];
  
  [self._keyboardAccessoryView dismissPopoverForItemAnimated:YES];
}

- (void)_keyboardWillHide:(NSNotification *)notification {
  [self _keyboardWillShow:notification];
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
      
      action = [_keyboardAccessoryItemActions objectAtIndex:i];
      item.title = action.title;
      item.image = [action image];
      item.tag = i;
      [items addObject:item];
    }
    
    accessoryView.items = items;
  } else {
    NSArray *items = accessoryView.items;
    [items enumerateObjectsUsingBlock:^(CodeFileKeyboardAccessoryItem *item, NSUInteger itemIndex, BOOL *stop) {
      TMKeyboardAction *action = [_keyboardAccessoryItemActions objectAtIndex:itemIndex];
      item.title = action.title;
      item.image = [action image];
    }];
    accessoryView.items = items;
  }
  [self.codeView setKeyboardAccessoryViewVisible:([_keyboardAccessoryItemActions count] == 11) animated:YES];
}

- (void)_keyboardAccessoryItemAction:(UIBarButtonItem *)item {
  _keyboardAccessoryItemCurrentActionIndex = item.tag;
  [[_keyboardAccessoryItemActions objectAtIndex:item.tag] executeActionOnTarget:self];
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
  [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:placeHolderBodyBlock, TextRendererRunUnderlayBlockAttributeName, [UIColor blackColor].CGColor, kCTForegroundColorAttributeName, nil] range:NSMakeRange(range.location + 2, range.length - 4)];
  
  // Opening and Closing style
  
  //
  CGFontRef font = (__bridge CGFontRef)[TMTheme.defaultTheme.commonAttributes objectForKey:(__bridge id)kCTFontAttributeName];
  ASSERT(font);
  CTRunDelegateRef delegateRef = CTRunDelegateCreate(&placeholderEndingsRunCallbacks, font);
  
  [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderLeftBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(range.location, 2)];
  [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderRightBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(NSMaxRange(range) - 2, 2)];
  
  CFRelease(delegateRef);
  
  // Placeholder behaviour
  [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:name, CodeViewPlaceholderAttributeName, nil] range:range];
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
  color = [theme.environmentAttributes objectForKey:TMThemeBackgroundColorEnvironmentAttributeKey];
  self.codeView.backgroundColor = color ? color : [UIColor whiteColor];
  self.codeView.lineNumbersColor = color ? [color colorByIncreasingContrast:.38] : [UIColor colorWithWhite:0.62 alpha:1];
  self.codeView.lineNumbersBackgroundColor = color ? [color colorByIncreasingContrast:.09] : [UIColor colorWithWhite:0.91 alpha:1];
  color = [theme.environmentAttributes objectForKey:TMThemeCaretColorEnvironmentAttributeKey];
  self.codeView.caretColor = color ? color : [UIColor blackColor];
  color = [theme.environmentAttributes objectForKey:TMThemeSelectionColorEnvironmentAttributeKey];
  self.codeView.selectionColor = color ? color : [[UIColor blueColor] colorWithAlphaComponent:0.3];
  
  _minimapView.backgroundColor = self.codeView.lineNumbersBackgroundColor;
  _minimapView.lineShadowColor = self.codeView.backgroundColor;
  
  _minimapSymbolColor = _minimapCommentColor = _minimapPreprocessorColor = nil;
}

@end
