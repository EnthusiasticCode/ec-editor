//
//  CodeView.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeView.h"
#import <QuartzCore/QuartzCore.h>
#import "TextPosition.h"
#import "TextRange.h"
#import "NSTimer+BlockTimer.h"
#import "KeyboardAccessoryView.h"
#import "BezelAlert.h"

#define CARET_WIDTH 2
#define ACCESSORY_HEIGHT 45
#define KEYBOARD_DOCKED_MINIMUM_HEIGHT 264
#define TILE_HEIGHT 1024
#define KNOB_SIZE 30.0
#define MAX_RENDERER_STRING_LENGTH_PER_SEGMENT 1024

NSString * const CodeViewPlaceholderAttributeName = @"codeViewPlaceholder";

static const void *rendererContext;

#pragma mark - Interfaces

@class CodeViewContentView, TextSelectionView, TextMagnificationView, CodeViewUndoManager;

#pragma mark -

@interface CodeView () {
@private
  CodeViewContentView *_contentView;
  
  // Dictionaries that holds additional passes
  NSMutableDictionary *overlayPasses;
  NSMutableDictionary *underlayPasses;
  
  // Text management
  TextSelectionView *_selectionView;
  NSRange _markedRange;
  
  CodeViewUndoManager *_undoManager;
  
  // Support objects
  NSTimer *_touchScrollTimer;
  CGFloat _touchScrollSpeed;
  void(^_touchScrollTimerCallback)(BOOL isScrolling);
  
  CGRect _keyboardFrame;
  BOOL _keyboardWillShow;
  
  // Delegate and dataSource flags
  struct {
    unsigned dataSourceHasCodeCanEditTextInRange : 1;
    unsigned dataSourceHasCommitStringForTextInRange : 1;
    unsigned dataSourceHasViewControllerForCompletionAtTextInRange : 1;
    unsigned dataSourceHasAttributeAtIndexLongestEffectiveRange : 1;
    unsigned delegateHasReplaceInsertedTextSelectionAfterInsertion : 1;
    unsigned delegateHasSelectedLineNumber : 1;
    unsigned delegateHasShouldShowKeyboardAccessoryViewInViewWithFrame : 1;
    unsigned delegateHasDidShowKeyboardAccessoryViewInViewWithFrame : 1;
    unsigned delegateHasShouldHideKeyboardAccessoryView : 1;
    unsigned delegateHasDidHideKeyboardAccessoryView : 1;
    unsigned delegateHasSelectionWillChange : 1;
    unsigned delegateHasSelectionDidChange : 1;
  } _flags;
  
  // Recognizers
  UITapGestureRecognizer *_tapRecognizer;
  UITapGestureRecognizer *_tapTwoTouchesRecognizer;
  UITapGestureRecognizer *_doubleTapRecognizer;
  UILongPressGestureRecognizer *_longPressRecognizer;
  UILongPressGestureRecognizer *_longDoublePressRecognizer;
  id<UITextInputTokenizer> _tokenizer;
  
  @package
  NSMutableDictionary *setupPasses;
  NSMutableDictionary *cleanupPasses;
}

@property (nonatomic, strong) TextRenderer *renderer;
@property (nonatomic, readonly) BOOL ownsRenderer;

/// Set the renderer text inserts adjusting them for line numbers
- (void)_forwardTextInsetsToRenderer;

/// Method to be used before any text modification occurs.
- (void)_editDataSourceInRange:(NSRange)range withString:(NSString *)string selectionRange:(NSRange)selection;

/// Shourtcut that will automatically set the selection after the inserted text.
- (void)_editDataSourceInRange:(NSRange)range withString:(NSString *)string;

/// Support method to set the selection and notify the input delefate.
- (void)_setSelectedTextRange:(NSRange)newSelection notifyDelegate:(BOOL)shouldNotify;

/// Convinience method to set the selection to an index location.
- (void)_setSelectedIndex:(NSUInteger)index;

/// Helper method to set the selection starting from two points.
- (void)_setSelectedTextFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint;

/// Given a touch point on the top or bottom of the codeview, this method
/// scroll the content faster as the point approaches the receiver's bounds.
- (void)_autoScrollForTouchAtPoint:(CGPoint)point eventBlock:(void(^)(BOOL isScrolling))block;
- (void)_stopAutoScroll;

// Gestures handlers
- (void)_handleGestureTap:(UITapGestureRecognizer *)recognizer;
- (void)_handleGestureLongPress:(UILongPressGestureRecognizer *)recognizer;

// Handle keyboard display
- (void)_keyboardWillChangeFrame:(NSNotification *)notification;
- (void)_keyboardDidChangeFrame:(NSNotification *)notification;

@end

#pragma mark -

@interface CodeViewContentView : UIView

@property (nonatomic, weak) CodeView *parentCodeView;

@end

#pragma mark -

@interface TextMagnificationView : UIView {
@private
  CodeView *parent;
  UIImage *detailImage;
}

- (id)initWithFrame:(CGRect)frame codeView:(CodeView *)codeView;

- (void)detailTextAtPoint:(CGPoint)point 
            magnification:(CGFloat)magnification 
   additionalDrawingBlock:(void(^)(CGContextRef context, CGPoint textOffset))block;

@end

#pragma mark -

@interface TextSelectionKnobView : UIView

@property (nonatomic) UITextLayoutDirection knobDirection;
@property (nonatomic) CGFloat knobDiameter;

@property (nonatomic) CGRect caretRect;
@property (nonatomic, strong) UIColor *caretColor;

@end

#pragma mark -

@interface TextSelectionView : UIView {
@private
  CodeView *parent;
  RectSet *selectionRects;
  
  CABasicAnimation *blinkAnimation;
  NSTimer *blinkDelayTimer;
  
  TextSelectionKnobView *leftKnob, *rightKnob;
  UILongPressGestureRecognizer *leftKnobRecognizer, *rightKnobRecognizer;
}

- (id)initWithFrame:(CGRect)frame codeView:(CodeView *)codeView;

#pragma mark Managin the Selection

@property (nonatomic) NSRange selection;
- (void)setSelection:(NSRange)selection scrollToVisible:(BOOL)scrollToVisible;
@property (nonatomic, weak) TextRange *selectionRange;
@property (nonatomic, readonly) TextPosition *selectionPosition;
@property (nonatomic, readonly) RectSet *selectionRects;
@property (nonatomic, readonly, getter = isEmpty) BOOL empty;
- (void)update;

#pragma mark Selection Styles

@property (nonatomic, strong) UIColor *selectionColor;
@property (nonatomic, strong) UIColor *caretColor;
@property (nonatomic, getter = isBlinking) BOOL blink;

#pragma mark Magnification

@property (nonatomic, getter = isMagnifying) BOOL magnify;
@property (nonatomic, readonly, strong) UIPopoverController *magnificationPopover;
@property (nonatomic, readonly, strong) TextMagnificationView *magnificationView;

- (void)setMagnify:(BOOL)doMagnify fromRect:(CGRect)rect textPoint:(CGPoint)textPoint ratio:(CGFloat)ratio animated:(BOOL)animated;
- (void)setMagnify:(BOOL)doMagnify fromRect:(CGRect)rect ratio:(CGFloat)ratio animated:(BOOL)animated; // set tap point = middle of rect

- (void)handleKnobGesture:(UILongPressGestureRecognizer *)recognizer;

@end

#pragma mark -

@interface CodeViewUndoManager : NSUndoManager

@end

#pragma mark - Implementations

#pragma mark - CodeView

@implementation CodeView

#pragma mark - Properties

@dynamic dataSource, delegate;
@synthesize renderer = _renderer, editing;
@synthesize keyboardAccessoryView, magnificationPopoverControllerClass;

- (void)setDataSource:(id<CodeViewDataSource>)aDataSource
{
  [self.renderer setDataSource:aDataSource];
  
  _flags.dataSourceHasCodeCanEditTextInRange = [self.dataSource respondsToSelector:@selector(codeView:canEditTextInRange:)];
  _flags.dataSourceHasCommitStringForTextInRange = [self.dataSource respondsToSelector:@selector(codeView:commitString:forTextInRange:)];
  _flags.dataSourceHasViewControllerForCompletionAtTextInRange = [self.dataSource respondsToSelector:@selector(codeView:viewControllerForCompletionAtTextInRange:)];
  _flags.dataSourceHasAttributeAtIndexLongestEffectiveRange = [self.dataSource respondsToSelector:@selector(codeView:attribute:atIndex:longestEffectiveRange:)];
}

- (void)setDelegate:(id<CodeViewDelegate>)delegate
{
  [super setDelegate:delegate];
  
  _flags.delegateHasReplaceInsertedTextSelectionAfterInsertion = [delegate respondsToSelector:@selector(codeView:replaceInsertedText:selectionAfterInsertion:)];
  _flags.delegateHasSelectedLineNumber = [delegate respondsToSelector:@selector(codeView:selectedLineNumber:)];
  _flags.delegateHasShouldShowKeyboardAccessoryViewInViewWithFrame = [delegate respondsToSelector:@selector(codeView:shouldShowKeyboardAccessoryViewInView:withFrame:)];
  _flags.delegateHasDidShowKeyboardAccessoryViewInViewWithFrame = [delegate respondsToSelector:@selector(codeView:didShowKeyboardAccessoryViewInView:withFrame:)];
  _flags.delegateHasShouldHideKeyboardAccessoryView = [delegate respondsToSelector:@selector(codeViewShouldHideKeyboardAccessoryView:)];
  _flags.delegateHasDidHideKeyboardAccessoryView = [delegate respondsToSelector:@selector(codeViewDidHideKeyboardAccessoryView:)];
  _flags.delegateHasSelectionWillChange = [delegate respondsToSelector:@selector(selectionWillChangeForCodeView:)];
  _flags.delegateHasSelectionDidChange = [delegate respondsToSelector:@selector(selectionDidChangeForCodeView:)];
}

- (TextRenderer *)renderer
{
  if (_renderer == nil)
  {
    _renderer = [TextRenderer new];
    _renderer.delegate = self;
    _renderer.maximumStringLenghtPerSegment = MAX_RENDERER_STRING_LENGTH_PER_SEGMENT;
  }
  return _renderer;
}

- (BOOL)ownsRenderer
{
  return self.renderer.delegate == self;
}

- (void)setEditing:(BOOL)value
{
  if (value == editing)
    return;
  editing = value;
  if (value)
    [self becomeFirstResponder];
  else
    [self resignFirstResponder];
}

- (void)setFrame:(CGRect)frame
{
  if (CGRectEqualToRect(frame, self.frame))
    return;
  
  // Setup renderer wrap with keeping in to account insets and line display
  if (self.ownsRenderer)
    self.renderer.renderWidth = frame.size.width;
  
  CGFloat contentHeight = self.renderer.renderHeight * self.contentScaleFactor;
  if (contentHeight == 0)
    contentHeight = frame.size.height;
  self.contentSize = CGSizeMake(frame.size.width, contentHeight);
  
  [super setFrame:frame];
  
  [_selectionView update];
}

- (void)setContentSize:(CGSize)contentSize
{
  // When the scrollview content size changes, reflect the same change to the content view
  CGSize size = CGSizeMake(ceilf(contentSize.width), ceilf(contentSize.height));
  [_contentView setFrame:self.renderer.isRenderHeightFinal ?
   (CGRect){ CGPointZero, size } :
   CGRectMake(0, 0, size.width, size.height + TILE_HEIGHT)];
  [super setContentSize:size];
}

#pragma mark Properties - Line numbers

@synthesize textInsets, lineNumbersEnabled, lineNumbersWidth, lineNumbersFont, lineNumbersColor, lineNumbersBackgroundColor;

- (void)setLineNumbersEnabled:(BOOL)enabled
{
  if (lineNumbersEnabled == enabled)
    return;
  
  lineNumbersEnabled = enabled;
  
  static NSString *lineNumberPassKey = @"LineNumbersUnderlayPass";
  if (lineNumbersEnabled)
  {
    __weak CodeView *this = self;
    [self addPassLayerBlock:^(CGContextRef context, TextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
      CGContextSetFillColorWithColor(context, this->lineNumbersColor.CGColor);
      if (!line.isTruncation)
      {
        // Rendering line number
        // TODO get this more efficient. possibly by creating line numbers with preallocated characters.
        NSString *lineNumberString = [NSString stringWithFormat:@"%u", lineNumber + 1];
        CGSize lineNumberStringSize = [lineNumberString sizeWithFont:this->lineNumbersFont];
        
        CGContextSelectFont(context, this->lineNumbersFont.fontName.UTF8String, this->lineNumbersFont.pointSize, kCGEncodingMacRoman);
        CGContextSetTextDrawingMode(context, kCGTextFill);
        
        CGContextShowTextAtPoint(context, -lineBounds.origin.x + this->lineNumbersWidth - lineNumberStringSize.width - 2, line.descent + (lineBounds.size.height - lineNumberStringSize.height) / 2, lineNumberString.UTF8String, [lineNumberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
      }
      else
      {
        // Rendering dot
        CGContextFillEllipseInRect(context, CGRectMake(-lineBounds.origin.x + this->lineNumbersWidth - 3 - 4, (line.height - 3) / 2, 3, 3));
      }
    } underText:YES forKey:lineNumberPassKey];
  }
  else
  {
    [self removePassLayerForKey:lineNumberPassKey];
  }
  [self _forwardTextInsetsToRenderer];
}

- (void)setTextInsets:(UIEdgeInsets)insets
{
  if (UIEdgeInsetsEqualToEdgeInsets(insets, textInsets))
    return;
  
  textInsets = insets;
  [self _forwardTextInsetsToRenderer];
}

- (void)setLineNumbersWidth:(CGFloat)width
{
  if (width == lineNumbersWidth)
    return;
  
  lineNumbersWidth = width;
  [self _forwardTextInsetsToRenderer];
}

- (void)_forwardTextInsetsToRenderer
{
  UIEdgeInsets insets = self.textInsets;
  
  if (lineNumbersEnabled)
    insets.left += lineNumbersWidth;
  
  self.renderer.textInsets = insets;
}

#pragma mark Properties - Keyboard

- (void)setKeyboardAccessoryView:(KeyboardAccessoryView *)value
{
  if (value == keyboardAccessoryView)
    return;
  if (!keyboardAccessoryView && self.superview != nil)
  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
  }
  keyboardAccessoryView = value;
  if (!keyboardAccessoryView)
  {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
  }
}

- (void)setCaretColor:(UIColor *)caretColor
{
  _selectionView.caretColor = caretColor;
}

- (UIColor *)caretColor
{
  return _selectionView.caretColor;
}

- (void)setSelectionColor:(UIColor *)selectionColor
{
  _selectionView.selectionColor = selectionColor;
}

- (UIColor *)selectionColor
{
  return _selectionView.selectionColor;
}

- (NSRange)selectionRange
{
  return _selectionView.selection;
}

- (void)setSelectionRange:(NSRange)selectionRange
{
  _selectionView.selection = selectionRange;
}

- (RectSet *)selectionRects
{
  if (_selectionView.isHidden)
    return nil;
  if (_selectionView.selection.length == 0)
    return [RectSet rectSetWithRect:[self caretRectForPosition:_selectionView.selectionPosition]];
  return _selectionView.selectionRects;
}

- (Class)magnificationPopoverControllerClass
{
  if (!magnificationPopoverControllerClass)
    magnificationPopoverControllerClass = [UIPopoverController class];
  return magnificationPopoverControllerClass;
}

#pragma mark UIView Methods

static void init(CodeView *self)
{
  self.contentMode = UIViewContentModeRedraw;
  self.clearsContextBeforeDrawing = NO;
  self->_contentView = [CodeViewContentView new];
  self->_contentView.clearsContextBeforeDrawing = NO;
  self->_contentView.parentCodeView = self;
  self->_contentView.contentMode = UIViewContentModeRedraw;
  [self addSubview:self->_contentView];
  
  if (self.ownsRenderer)
    self.renderer.renderWidth = self.bounds.size.width;
  [self.renderer addObserver:self forKeyPath:@"renderHeight" options:NSKeyValueObservingOptionNew context:&rendererContext];
  
  // Setup keyboard and selection
  self->_selectionView = [[TextSelectionView alloc] initWithFrame:CGRectZero codeView:self];
  [self->_selectionView setOpaque:NO];
  [self->_selectionView setHidden:YES];
  [self addSubview:self->_selectionView];
  self->_keyboardFrame = CGRectNull;
  
  // Gesture recognizers
  self->_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureTap:)];
  [self addGestureRecognizer:self->_tapRecognizer];
  
  self->_tapTwoTouchesRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureTap:)];
  self->_tapTwoTouchesRecognizer.numberOfTouchesRequired = 2;
  [self addGestureRecognizer:self->_tapTwoTouchesRecognizer];
  
  self->_doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureTap:)];
  self->_doubleTapRecognizer.numberOfTapsRequired = 2;
  [self addGestureRecognizer:self->_doubleTapRecognizer];
  
  self->_longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureLongPress:)];
  [self addGestureRecognizer:self->_longPressRecognizer];
  
  self->_longDoublePressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureLongPress:)];
  self->_longDoublePressRecognizer.numberOfTouchesRequired = 2;
  [self addGestureRecognizer:self->_longDoublePressRecognizer];
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    init(self);
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
  self = [super initWithCoder:coder];
  if (self) {
    init(self);
  }
  return self;
}

- (id)initWithFrame:(CGRect)frame renderer:(TextRenderer *)aRenderer
{    
  if (!(self = [super initWithFrame:frame]))
    return nil;
  
  self.renderer = aRenderer;
  init(self);
  
  return self;
}

- (void)dealloc
{
  [self setKeyboardAccessoryView:nil];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  if (aSelector == @selector(dataSource))
    return self.renderer;
  return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context == &rendererContext)
  {
    CGSize boundsSize = self.bounds.size;
    CGFloat height = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
    if (height == 0)
      height = boundsSize.height;
    CGFloat width = boundsSize.width;
    self.contentSize = CGSizeMake(width, height * self.contentScaleFactor);
  }
  else 
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
  [super willMoveToSuperview:newSuperview];
  
  if (self.keyboardAccessoryView != nil)
  {
    if (newSuperview != nil)
    {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    }
    else
    {
      [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
      [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
    }
  }
}

- (void)setNeedsDisplay
{
  [super setNeedsDisplay];
  [_contentView setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
  [super drawRect:rect];
  
  if (self->lineNumbersEnabled)
  {
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Line number background
    [self->lineNumbersBackgroundColor setFill];
    CGContextFillRect(context, (CGRect){ rect.origin, CGSizeMake(self->lineNumbersWidth, rect.size.height) });
    [self->lineNumbersColor setStroke];
    CGContextSetLineWidth(context, 1);
    CGContextMoveToPoint(context, rect.origin.x + self->lineNumbersWidth + 0.5, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + self->lineNumbersWidth + 0.5, CGRectGetMaxY(rect));
    CGContextStrokePath(context);
  }
}

#pragma mark - Text Renderer Delegate

- (void)textRenderer:(TextRenderer *)sender didInvalidateRenderInRect:(CGRect)rect
{
  if (rect.size.height == 0)
    [_contentView setNeedsDisplay];
  else
    [_contentView setNeedsDisplayInRect:rect];
}

#pragma mark - Text Renderer Methods

- (void)updateAllText
{
  [self.renderer updateAllText];
  [self setNeedsLayout];
}

- (void)updateTextFromStringRange:(NSRange)originalRange toStringRange:(NSRange)newRange
{
  [self.renderer updateTextFromStringRange:originalRange toStringRange:newRange];
  [self setNeedsLayout];
}

#pragma mark - Text Decoration Methods

- (void)addPassLayerBlock:(TextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey
{
  [self addPassLayerBlock:block underText:isUnderlay forKey:passKey setupTileBlock:nil cleanupTileBlock:nil];
}

- (void)addPassLayerBlock:(TextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey setupTileBlock:(CodeViewTileSetupBlock)setupBlock cleanupTileBlock:(CodeViewTileSetupBlock)cleanupBlock
{
  if (isUnderlay)
  {
    if (!underlayPasses)
      underlayPasses = [NSMutableDictionary new];
    [underlayPasses setObject:[block copy] forKey:passKey];
    
    self.renderer.underlayRenderingPasses = [underlayPasses allValues];
  }
  else
  {
    if (!overlayPasses)
      overlayPasses = [NSMutableDictionary new];
    [overlayPasses setObject:[block copy] forKey:passKey];
    
    self.renderer.overlayRenderingPasses = [overlayPasses allValues];
  }
  
  if (setupBlock)
  {
    if (!setupPasses)
      setupPasses = [NSMutableDictionary new];
    [setupPasses setObject:[setupBlock copy] forKey:passKey];
  }
  
  if (cleanupBlock)
  {
    if (!cleanupPasses)
      cleanupPasses = [NSMutableDictionary new];
    [cleanupPasses setObject:[cleanupBlock copy] forKey:passKey];
  }
}

- (void)removePassLayerForKey:(NSString *)passKey
{
  [underlayPasses removeObjectForKey:passKey];
  [overlayPasses removeObjectForKey:passKey];
  [setupPasses removeObjectForKey:passKey];
  [cleanupPasses removeObjectForKey:passKey];
  
  self.renderer.underlayRenderingPasses = [underlayPasses allValues];
  self.renderer.overlayRenderingPasses = [overlayPasses allValues];
}

- (void)flashTextInRange:(NSRange)textRange
{
  RectSet *rects = [self.renderer rectsForStringRange:textRange limitToFirstLine:NO];
  
  // Scroll to center selected rect
  [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
    [self scrollRectToVisible:CGRectInset(rects.bounds, -100, -100) animated:NO];
  } completion:^(BOOL finished) {
    [rects enumerateRectsUsingBlock:^(CGRect rect, BOOL *stop) {
      [[CodeFlashView new] flashInRect:rect view:self withDuration:0.25];
    }];
  }];
}

#pragma mark - Text Access Methods

- (NSString *)text
{
  if (self.dataSource == nil)
    return nil;
  
  return [[self.dataSource textRenderer:self.renderer attributedStringInRange:NSMakeRange(0, [self.dataSource stringLengthForTextRenderer:self.renderer])] string];
}

- (NSRange)visibleTextRange
{
  __block NSRange result = NSMakeRange(NSUIntegerMax, 0);
  [self.renderer enumerateLinesIntersectingRect:self.bounds usingBlock:^(TextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineYOffset, NSRange stringRange, BOOL *stop) {
    if (result.location == NSUIntegerMax)
      result.location = stringRange.location;
    result.length += stringRange.length;
  }];
  return result;
}

#pragma mark - UIResponder methods

- (BOOL)canBecomeFirstResponder
{
  return editing && _flags.dataSourceHasCommitStringForTextInRange;
}

- (BOOL)becomeFirstResponder
{
  BOOL shouldBecomeFirstResponder = [super becomeFirstResponder];
  
  // Activate recognizers and keyboard accessory
  if (shouldBecomeFirstResponder)
  {
    //        _tapTwoTouchesRecognizer.enabled = YES;
    //        _doubleTapRecognizer.enabled = YES;
    //        _longPressRecognizer.enabled = YES;
    //        _longDoublePressRecognizer.enabled = YES;
    
    if (!_keyboardWillShow)
      [self setKeyboardAccessoryViewVisible:YES animated:YES];
  }
  
  [self setNeedsLayout];
  
  return shouldBecomeFirstResponder;   
}

- (BOOL)resignFirstResponder
{
  BOOL shouldResignFirstResponder = [super resignFirstResponder];
  
  if (![self isFirstResponder])
  {
    //        _tapTwoTouchesRecognizer.enabled = NO;
    //        _doubleTapRecognizer.enabled = NO;
    //        _longPressRecognizer.enabled = NO;
    //        _longDoublePressRecognizer.enabled = NO;
    
    // Remove keyboard accessory
    [self setKeyboardAccessoryViewVisible:NO animated:YES];
  }
  
  [self setNeedsLayout];
  
  // TODO call delegate's endediting
  
  return shouldResignFirstResponder;
}

#pragma mark - UIKeyInput protocol

- (BOOL)hasText
{
  return [self.dataSource stringLengthForTextRenderer:self.renderer] > 0;
}

- (void)insertText:(NSString *)string
{
  NSString *insertString = nil;
  NSRange selectionAfterInsertion = NSMakeRange(_selectionView.selection.location + [string length], 0);
  
  if (_flags.delegateHasReplaceInsertedTextSelectionAfterInsertion)
    insertString = [self.delegate codeView:self replaceInsertedText:string selectionAfterInsertion:&selectionAfterInsertion];
  
  if (insertString == nil)
  {
    insertString = string;
    if ([string length] == 1)
    {
      unichar ch = [string characterAtIndex:0];
      switch (ch) {
          //                case NSLeftArrowFunctionKey:
          //                    [self _moveInDirection:UITextLayoutDirectionLeft];
          //                    return;
          //                case NSRightArrowFunctionKey:
          //                    [self _moveInDirection:UITextLayoutDirectionRight];
          //                    return;
          //                case NSUpArrowFunctionKey:
          //                    [self _moveInDirection:UITextLayoutDirectionUp];
          //                    return;
          //                case NSDownArrowFunctionKey:
          //                    [self _moveInDirection:UITextLayoutDirectionDown];
          //                    return;
        case 0x20: // Space
        {
          break;
        }
          
        case L'{':
          insertString = [NSString stringWithFormat:@"{%@}", [self selectedText]];
          if ([insertString length] == 2)
            selectionAfterInsertion = NSMakeRange(_selectionView.selection.location + 1, 0);
          else
            selectionAfterInsertion = NSMakeRange(_selectionView.selection.location + [insertString length], 0);
          break;
      }
    }
  }
  
  [self _editDataSourceInRange:_selectionView.selection withString:insertString selectionRange:selectionAfterInsertion];
  
  // Interrupting undo grouping on user return
  if ([string hasSuffix:@"\n"] && self.undoManager.groupingLevel != 0)
    [self.undoManager endUndoGrouping];
}

- (void)deleteBackward
{
  NSRange deleteRange;
  if (_markedRange.location != NSNotFound)
  {
    deleteRange = _markedRange;
  }
  else if (_selectionView)
  {
    deleteRange = _selectionView.selection;
  }
  else
  {
    ASSERT(NO); // no selection to delete
  }
  
  [self unmarkText];
  
  // TODO as OUI get rangeOfComposedCharacterSequencesForRange: or rangeOfComposedCharacterSequenceAtIndex:
  if (deleteRange.length == 0)
  {
    if (deleteRange.location == 0)
      return;
    deleteRange = NSMakeRange(deleteRange.location - 1, 1);
  }
  
  [self _editDataSourceInRange:deleteRange withString:@""];
}

#pragma mark - UITextInputTraits protocol

@synthesize keyboardType = _keyboardType, returnKeyType = _returnKeyType;

- (UIKeyboardAppearance)keyboardAppearance
{
  return UIKeyboardAppearanceDefault;
}

- (UIReturnKeyType)returnKeyType
{
  return UIReturnKeyDefault;
}

- (BOOL)enablesReturnKeyAutomatically
{
  return NO;
}

- (BOOL)isSecureTextEntry
{
  return NO;
}

- (UITextAutocorrectionType)autocorrectionType
{
  return UITextAutocorrectionTypeNo;
}

#pragma mark - UITextInput protocol

@synthesize inputDelegate;
@synthesize tokenizer;

// TODO create a proper code tokenizer, should be retreived from the dataSource
- (id<UITextInputTokenizer>)tokenizer
{
  if (!_tokenizer)
    _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
  return _tokenizer;
}

- (UIView *)textInputView
{
  return self;
}

#pragma mark Replacing and Returning Text

- (NSString *)textInRange:(UITextRange *)range
{
  if(!range || ![range isKindOfClass:[TextRange class]])
    return nil;
  
  NSUInteger s = ((TextPosition *)range.start).index;
  NSUInteger e = ((TextPosition *)range.end).index;
  
  NSString *result;
  if (e <= s)
    result = @"";
  else
    result = [self.dataSource textRenderer:self.renderer attributedStringInRange:(NSRange){s, e - s}].string;
  
  return result;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)string
{
  // Adjust replacing range
  if(!range || ![range isKindOfClass:[TextRange class]])
    return;
  
  NSUInteger s = ((TextPosition *)range.start).index;
  NSUInteger e = ((TextPosition *)range.end).index;
  if (e < s)
    return;
  
  [self unmarkText];
  
  NSUInteger textLength = [self.dataSource stringLengthForTextRenderer:self.renderer];
  if (s > textLength)
    s = textLength;
  
  if (e > s)
  {
    NSRange c = (NSRange){s, e - s};
    if (c.location + c.length > textLength)
      c.length = textLength - c.location;
    [self _editDataSourceInRange:c withString:string];
  }
  else
  {
    [self _editDataSourceInRange:(NSRange){s, 0} withString:string];
  }
}

#pragma mark Working with Marked and Selected Text

- (NSString *)selectedText
{
  if (_selectionView.selection.length == 0)
    return @"";
  return [[self.dataSource textRenderer:self.renderer attributedStringInRange:_selectionView.selection] string];
}

- (UITextRange *)selectedTextRange
{
  return _selectionView.selectionRange;
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
  // TODO solidCaret
  
  [self unmarkText];
  
  [self _setSelectedTextRange:[(TextRange *)selectedTextRange range] notifyDelegate:YES];
}

@synthesize markedTextStyle;

- (UITextRange *)markedTextRange
{
  if (_markedRange.length == 0)
    return nil;
  
  return [[TextRange alloc] initWithRange:_markedRange];
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange
{
  NSRange replaceRange;
  //    NSUInteger textLength = [self textLength];
  
  if (_markedRange.length == 0)
  {
    replaceRange = _selectionView.selection;
    //        if (selection)
    //        {
    //            replaceRange = [selection range];
    //        }
    //        else
    //        {
    //            replaceRange.location = textLength;
    //            replaceRange.length = 0;
    //        }
  }
  else
  {
    replaceRange = _markedRange;
  }
  
  NSRange newSelectionRange;
  NSUInteger markedTextLength = [markedText length];
  [self _editDataSourceInRange:replaceRange withString:markedText];
  
  // Adjust selection
  if (selectedRange.location > markedTextLength 
      || selectedRange.location + selectedRange.length > markedTextLength)
  {
    newSelectionRange = (NSRange){replaceRange.location + markedTextLength, 0};
  }
  else
  {
    newSelectionRange = (NSRange){replaceRange.location + selectedRange.location, selectedRange.length};
  }
  
  [self willChangeValueForKey:@"markedTextRange"];
  [self _setSelectedTextRange:newSelectionRange notifyDelegate:NO];
  _markedRange = (NSRange){replaceRange.location, markedTextLength};
  [self didChangeValueForKey:@"markedTextRange"];
}

- (void)unmarkText
{
  if (_markedRange.length == 0)
  {
    _markedRange = NSMakeRange(NSNotFound, 0);
    return;
  }
  
  // TODO needsdisplay for markedText layer.
  [self willChangeValueForKey:@"markedTextRange"];
  _markedRange = NSMakeRange(NSNotFound, 0);
  [self didChangeValueForKey:@"markedTextRange"];
}

#pragma mark Computing Text Ranges and Text Positions

- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition 
                            toPosition:(UITextPosition *)toPosition
{
  return [[TextRange alloc] initWithStart:(TextPosition *)fromPosition end:(TextPosition *)toPosition];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position 
                                  offset:(NSInteger)offset
{
  return [self positionFromPosition:position inDirection:(UITextLayoutDirection)UITextStorageDirectionForward offset:offset];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position 
                             inDirection:(UITextLayoutDirection)direction 
                                  offset:(NSInteger)offset
{
  if (offset == 0)
    return position;
  
  NSUInteger pos = [(TextPosition *)position index];
  NSUInteger result;
  
  if (direction == UITextStorageDirectionForward || direction == UITextStorageDirectionBackward) 
  {
    if (direction == UITextStorageDirectionBackward)
      offset = -offset;
    
    if (offset < 0 && (NSUInteger)(-offset) >= pos)
      result = 0;
    else
      result = pos + offset;
  } 
  else
  {
    result = [self.renderer positionFromPosition:pos inLayoutDirection:direction offset:offset];
    if (result == NSUIntegerMax)
      return nil;
  }
  
  NSUInteger textLength = [self.dataSource stringLengthForTextRenderer:self.renderer];
  if (result > textLength)
    result = textLength;
  
  TextPosition *resultPosition = [[TextPosition alloc] initWithIndex:result];
  
  return resultPosition;
}

- (UITextPosition *)beginningOfDocument
{
  TextPosition *p = [[TextPosition alloc] initWithIndex:0];
  return p;
}

- (UITextPosition *)endOfDocument
{
  TextPosition *p = [[TextPosition alloc] initWithIndex:[self.dataSource stringLengthForTextRenderer:self.renderer]];
  return p;
}

#pragma mark Evaluating Text Positions

- (NSComparisonResult)comparePosition:(UITextPosition *)position 
                           toPosition:(UITextPosition *)other
{
  return [(TextPosition *)position compare:other];
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from 
                     toPosition:(UITextPosition *)toPosition
{
  NSUInteger si = ((TextPosition *)from).index;
  NSUInteger di = ((TextPosition *)toPosition).index;
  return (NSInteger)di - (NSInteger)si;
}

#pragma mark Determining Layout and Writing Direction

- (UITextPosition *)positionWithinRange:(UITextRange *)range 
                    farthestInDirection:(UITextLayoutDirection)direction
{
  // TODO
  abort();
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position 
                                       inDirection:(UITextLayoutDirection)direction
{
  // TODO
  abort();
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position 
                                              inDirection:(UITextStorageDirection)direction
{
  // TODO
  abort();
}

-(void)setBaseWritingDirection:(UITextWritingDirection)writingDirection 
                      forRange:(UITextRange *)range
{
  // TODO
  //    abort();
}

#pragma mark Geometry and Hit-Testing Methods

- (CGRect)firstRectForRange:(UITextRange *)range
{
  CGRect r = [self.renderer rectsForStringRange:[(TextRange *)range range] limitToFirstLine:YES].bounds;
  return r;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
  NSUInteger pos = ((TextPosition *)position).index;
// TODO NIK: this method is called on main thread, and calls the renderer which eventually starts rendering text, triggering all of the text rendering on main thread
  CGRect carretRect = [self.renderer rectsForStringRange:(NSRange){pos, 0} limitToFirstLine:YES].bounds;
  
  carretRect.origin.x -= 1.0;
  carretRect.size.width = 2.0;
  
  CGFloat scale = self.contentScaleFactor;
  if (scale != 1.0) 
  {
    carretRect.origin.x *= scale;
    carretRect.origin.y *= scale;
    carretRect.size.width *= scale;
    carretRect.size.height *= scale;
  }
  
  return carretRect;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
  return [self closestPositionToPoint:point withinRange:nil];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point 
                               withinRange:(UITextRange *)range
{
  CGFloat scale = self.contentScaleFactor;
  if (scale != 1.0)
  {
    point.x /= scale;
    point.y /= scale;
  }
  
  NSUInteger location = [self.renderer closestStringLocationToPoint:point withinStringRange:range ? [(TextRange *)range range] : (NSRange){0, 0}];
  return [[TextPosition alloc] initWithIndex:location];
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
  TextPosition *pos = (TextPosition *)[self closestPositionToPoint:point];
  
  NSRange r = [[self.dataSource textRenderer:self.renderer attributedStringInRange:(NSRange){ pos.index, 1 }].string rangeOfComposedCharacterSequenceAtIndex:0];
  
  if (r.location == NSNotFound)
    return nil;
  
  return [[TextRange alloc] initWithRange:r];
}

#pragma mark - Editing Actions

- (void)copy:(id)sender
{
  if (_selectionView.isEmpty)
    return;
  
  UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
  NSString *text = [self textInRange:_selectionView.selectionRange];
  generalPasteboard.string = text;
}

- (void)cut:(id)sender
{
  if (_selectionView.isEmpty)
    return;
  
  [self copy:sender];
  [self delete:sender];
}

- (void)delete:(id)sender
{
  if (_selectionView.isEmpty)
    return;
  
  [inputDelegate textWillChange:self];
  [inputDelegate selectionWillChange:self];
  [self replaceRange:_selectionView.selectionRange withText:@""];
  [inputDelegate textDidChange:self];
  [inputDelegate selectionDidChange:self];
}

- (void)paste:(id)sender
{
  // TODO smart paste logic
  
  NSString *text = [UIPasteboard generalPasteboard].string;
  if (!text)
    return;
  
  TextRange *selectedRange;
  if (!_selectionView.hidden)
    selectedRange = _selectionView.selectionRange;
  else
    selectedRange = [TextRange textRangeWithRange:NSMakeRange([self.dataSource stringLengthForTextRenderer:self.renderer], 0)];
  
  [inputDelegate textWillChange:self];
  [inputDelegate selectionWillChange:self];
  [self replaceRange:selectedRange withText:text];
  [inputDelegate textDidChange:self];
  [inputDelegate selectionDidChange:self];
}

- (void)select:(id)sender
{
  TextRange *selectionRange = _selectionView.selectionRange;
  UITextRange *forwardRange = [tokenizer rangeEnclosingPosition:selectionRange.start withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionForward];
  UITextRange *backRange = [tokenizer rangeEnclosingPosition:selectionRange.end withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionBackward];
  
  if (forwardRange && backRange)
  {
    TextRange *range = [[TextRange alloc] initWithStart:(TextPosition *)backRange.start end:(TextPosition *)forwardRange.end];
    [self setSelectedTextRange:range];
  }
  else if (forwardRange)
  {
    [self setSelectedTextRange:forwardRange];
  }
  else if (backRange)
  {
    [self setSelectedTextRange:backRange];
  }
  else
  {
    // Not empty selection is not altered
    if (![selectionRange.start isEqual:selectionRange.end])
      return;
    
    // TODO instead of left/rigth text direction see oui
    UITextPosition *beforeStart = [self positionFromPosition:selectionRange.start inDirection:UITextLayoutDirectionLeft offset:1];
    if (beforeStart && [selectionRange.start isEqual:beforeStart] == NO)
    {
      self.selectedTextRange = [self textRangeFromPosition:beforeStart toPosition:selectionRange.start];
      return;
    }
    
    UITextPosition *afterEnd = [self positionFromPosition:selectionRange.end inDirection:UITextLayoutDirectionRight offset:1];
    if (afterEnd && [selectionRange.end isEqual:afterEnd] == NO)
    {
      self.selectedTextRange = [self textRangeFromPosition:selectionRange.end toPosition:afterEnd];
      return;
    }
  }
}

- (void)selectAll:(id)sender
{
  // TODO
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  if (action == @selector(copy:))
  {
    return !_selectionView.isEmpty;
  }
  
  if (action == @selector(cut:) || action == @selector(delete:))
  {
    return !_selectionView.isEmpty && editing;
  }
  
  if (action == @selector(paste:))
  {
    if (!editing)
      return NO;
    UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
    return [generalPasteboard containsPasteboardTypes:UIPasteboardTypeListString];
  }
  
  if (action == @selector(select:))
  {
    return _selectionView.selection.length == 0;
  }
  
  if (action == @selector(selectAll:))
  {
    if (_selectionView.isHidden)
      return YES;
    
    UITextRange *selectionRange = _selectionView.selectionRange;
    if (![selectionRange.start isEqual:[self beginningOfDocument]] 
        || ![selectionRange.end isEqual:[self endOfDocument]])
      return YES;
  }
  
  return NO;
}

#pragma mark - Undo management

- (NSUndoManager *)undoManager
{
  if (!_undoManager)
  {
    _undoManager = [CodeViewUndoManager new];
    // TODO fill the manager with stored stacks?
  }
  return _undoManager;
}

#pragma mark - Private methods

- (void)_editDataSourceInRange:(NSRange)range withString:(NSString *)string selectionRange:(NSRange)selection
{
  ASSERT(string);
  
  if (!_flags.dataSourceHasCommitStringForTextInRange)
    return;
  
  if (_flags.dataSourceHasCodeCanEditTextInRange
      && ![self.dataSource codeView:self canEditTextInRange:range]) 
    return;
  
  [self unmarkText];
  
  NSUInteger stringLenght = [string length];
  // Register undo operation
  if (self.undoManager.groupingLevel == 0)
  {
    [self.undoManager beginUndoGrouping];
    [self.undoManager setActionName:@"Typing"];
  }
  [[self.undoManager prepareWithInvocationTarget:self] _editDataSourceInRange:NSMakeRange(range.location, stringLenght) withString:range.length ? [[self.dataSource textRenderer:self.renderer attributedStringInRange:range] string] : @"" selectionRange:range];
  
  // Commit string
  [inputDelegate textWillChange:self];
  [self.dataSource codeView:self commitString:string forTextInRange:range];
  
  // Update caret location
  [self _setSelectedTextRange:selection notifyDelegate:NO];
  
  // NOTE this delegate method has to be called after the changed selection or UIKeyboardImpl will crash in some cases
  [inputDelegate textDidChange:self];
}

- (void)_editDataSourceInRange:(NSRange)range withString:(NSString *)string
{
  [self _editDataSourceInRange:range withString:string selectionRange:NSMakeRange(range.location + [string length], 0)];
}

- (void)_setSelectedTextRange:(NSRange)newSelection notifyDelegate:(BOOL)shouldNotify
{
  if (shouldNotify && !_selectionView.isHidden && NSEqualRanges(_selectionView.selection, newSelection))
    return;
  
  // Close undo grouping if selection explicitly modified
  if (shouldNotify && self.undoManager.groupingLevel != 0)
    [self.undoManager endUndoGrouping];
  
  if (shouldNotify)
  {
    [inputDelegate selectionWillChange:self];
    if (_flags.delegateHasSelectionWillChange)
      [self.delegate selectionWillChangeForCodeView:self];
  }
  
  // Modify selection to account for placeholders
  if (_flags.dataSourceHasAttributeAtIndexLongestEffectiveRange && newSelection.location < [self.dataSource stringLengthForTextRenderer:self.renderer])
  {
    NSRange replaceSelection = newSelection;
    NSRange placeholderRangeAtLocation;
    id placeholderValue = [self.dataSource codeView:self attribute:CodeViewPlaceholderAttributeName atIndex:newSelection.location longestEffectiveRange:&placeholderRangeAtLocation];
    if (placeholderValue && placeholderRangeAtLocation.location != newSelection.location)
    {
      replaceSelection = NSUnionRange(placeholderRangeAtLocation, replaceSelection);
    }
    if (newSelection.length > 0)
    {
      NSRange placeholderRangeAtEnd;
      id placeholderValue = [self.dataSource codeView:self attribute:CodeViewPlaceholderAttributeName atIndex:NSMaxRange(newSelection) longestEffectiveRange:&placeholderRangeAtEnd];
      if (placeholderValue && !NSEqualRanges(placeholderRangeAtLocation, placeholderRangeAtEnd) && placeholderRangeAtEnd.location != NSMaxRange(newSelection))
      {
        replaceSelection = NSUnionRange(placeholderRangeAtEnd, replaceSelection);
      }
    }
    newSelection = replaceSelection;
  }
  
  // Will automatically resize and position the selection view
  _selectionView.selection = newSelection;
  
  if (shouldNotify)
  {
    [inputDelegate selectionDidChange:self];
    if (_flags.delegateHasSelectionDidChange)
      [self.delegate selectionDidChangeForCodeView:self];
  }
}

- (void)_setSelectedIndex:(NSUInteger)index
{
  [self _setSelectedTextRange:(NSRange){index, 0} notifyDelegate:NO];
}

- (void)_setSelectedTextFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
  UITextPosition *startPosition = [self closestPositionToPoint:fromPoint];
  UITextPosition *endPosition;
  if (CGPointEqualToPoint(toPoint, fromPoint))
    endPosition = startPosition;
  else
    endPosition = [self closestPositionToPoint:toPoint];
  
  TextRange *range = [[TextRange alloc] initWithStart:(TextPosition *)startPosition end:(TextPosition *)endPosition];
  
  [self setSelectedTextRange:range];
}

- (void)_autoScrollForTouchAtPoint:(CGPoint)point eventBlock:(void(^)(BOOL isScrolling))block
{
  CGRect frame = self.frame;
  
  // Stop old scrolling 
  if (_touchScrollTimerCallback)
    _touchScrollTimerCallback(NO);
  [self _stopAutoScroll];
  
  // Get scrolling speed and direction
  CGFloat scrollingOffset = 0;
  if (point.y < 10) 
  {
    scrollingOffset = point.y - 10;
  }
  else if (point.y > frame.size.height - 10)
  {
    scrollingOffset = point.y - (frame.size.height - 10);
  }
  
  // Schedule new scrolling timer if needed
  if (scrollingOffset != 0) 
  {
    _touchScrollTimerCallback = [block copy];
    _touchScrollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 usingBlock:^(NSTimer *timer) {
      CGFloat contentOffset = (scrollingOffset > 0 ? 1.0 : -1.0) * _touchScrollSpeed + self.contentOffset.y + (scrollingOffset > 0 ? self.bounds.size.height : 0);
      
      // Invalidate timer if reaging content limits
      if (contentOffset < 0 || contentOffset > self.contentSize.height) 
      {
        [_touchScrollTimer invalidate];
        _touchScrollTimer = nil;
        _touchScrollSpeed = 1;
        if (_touchScrollTimerCallback)
          _touchScrollTimerCallback(NO);
      }
      else
      {
        [self scrollRectToVisible:CGRectMake(0, contentOffset, 1, 0.01) animated:NO];
        if (_touchScrollSpeed < 10.0)
          _touchScrollSpeed += 0.1;
        if (_touchScrollTimerCallback)
          _touchScrollTimerCallback(YES);
      }
    } repeats:YES];
  }
}

- (void)_stopAutoScroll
{
  if (_touchScrollTimer) 
  {
    [_touchScrollTimer invalidate];
    _touchScrollTimer = nil;
  }
  _touchScrollSpeed = 1;
  _touchScrollTimerCallback = nil;
}

#pragma mark - Gesture Recognizers and Interaction

- (void)_handleGestureTap:(UITapGestureRecognizer *)recognizer
{
  // Tap with two fingers to show context menu
  if (recognizer.numberOfTouchesRequired == 2)
  {
    UIMenuController *sharedMenuController = [UIMenuController sharedMenuController];
    
    // Adding custom menu
    UIMenuItem *completionMenuItem = [[UIMenuItem alloc] initWithTitle:@"Completion" action:@selector(complete:)];
    sharedMenuController.menuItems = [NSArray arrayWithObject:completionMenuItem];
    
    // Show context menu
    [sharedMenuController setTargetRect:_selectionView.frame inView:self];
    [sharedMenuController setMenuVisible:YES animated:YES];
    return;
  }
  
  // Double tap to select word
  if (recognizer.numberOfTapsRequired == 2)
  {
    CGPoint tapPoint = [recognizer locationInView:self];
    UITextPosition *tapPosition = [self closestPositionToPoint:tapPoint];
    TextRange *sel = (TextRange *)[self.tokenizer rangeEnclosingPosition:tapPosition withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionForward];
    if (sel == nil)
    {
      UITextPosition *tapStart = [self.tokenizer positionFromPosition:tapPosition toBoundary:UITextGranularityWord inDirection:UITextStorageDirectionBackward];
      UITextPosition *tapEnd = [self.tokenizer positionFromPosition:tapPosition toBoundary:UITextGranularityWord inDirection:UITextStorageDirectionForward];
      sel = [[TextRange alloc] initWithStart:(TextPosition *)tapStart end:(TextPosition *)tapEnd];
    }
    [self setSelectedTextRange:sel];
    return;
  }
  
  // Become first responder if in editing mode
  if (self.isEditing && !self.isFirstResponder)
    [self becomeFirstResponder];
  
  [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
  
  CGPoint tapPoint = [recognizer locationInView:self];
  if (_flags.delegateHasSelectedLineNumber && tapPoint.x <= self.lineNumbersWidth)
  {
    __block NSUInteger tappedLineNumber = 0;
    [self.renderer enumerateLinesIntersectingRect:(CGRect){ tapPoint, CGSizeMake(1, 1) } usingBlock:^(TextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineYOffset, NSRange stringRange, BOOL *stop) {
      tappedLineNumber = lineNumber + 1;
      *stop = YES;
    }];
    [self.delegate codeView:self selectedLineNumber:tappedLineNumber];
    return;
  }
  [self _setSelectedTextFromPoint:tapPoint toPoint:tapPoint];
}

- (void)_handleGestureLongPress:(UILongPressGestureRecognizer *)recognizer
{
  BOOL multiTouch = NO;
  CGPoint tapPoint = [recognizer locationOfTouch:0 inView:self];
  CGPoint secondTapPoint = tapPoint;
  if ([recognizer numberOfTouches] > 1) 
  {
    secondTapPoint = [recognizer locationOfTouch:1 inView:self];
    multiTouch = YES;
  }
  
  BOOL animatePopover = NO;
  
  switch (recognizer.state)
  {
    case UIGestureRecognizerStateEnded:
      [self _setSelectedTextFromPoint:tapPoint toPoint:secondTapPoint];
    case UIGestureRecognizerStateCancelled:
      _selectionView.magnify = NO;
      [self _stopAutoScroll];
      break;
      
    case UIGestureRecognizerStateBegan:
      animatePopover = YES;
      
    default:
    {
      if (CGPointEqualToPoint(tapPoint, CGPointZero)) 
      {
        _selectionView.magnify = NO;
        [self _setSelectedTextFromPoint:tapPoint toPoint:secondTapPoint];
        return;
      }
      
      // Set selection
      if (multiTouch) 
      {
        [self _setSelectedTextFromPoint:tapPoint toPoint:secondTapPoint];
      }
      else
      {
        [_selectionView setSelection:NSMakeRange([self.renderer closestStringLocationToPoint:tapPoint withinStringRange:(NSRange){0, 0}], 0) scrollToVisible:NO];
        CGRect selectionFrame = _selectionView.frame;
        [_selectionView setMagnify:YES fromRect:CGRectMake(tapPoint.x - 1, selectionFrame.origin.y, 2, selectionFrame.size.height) textPoint:CGPointMake(CGRectGetMidX(selectionFrame), CGRectGetMidY(selectionFrame)) ratio:2 animated:animatePopover];
      }
      
      // Scrolling
      tapPoint.y -= self.contentOffset.y;
      [self _autoScrollForTouchAtPoint:tapPoint eventBlock:^(BOOL isScrolling) {
        if ([recognizer numberOfTouches] == 1)
        {
          CGPoint point = [recognizer locationOfTouch:0 inView:self];
          [_selectionView setSelection:NSMakeRange([self.renderer closestStringLocationToPoint:point withinStringRange:(NSRange){0, 0}], 0) scrollToVisible:NO];
          if (isScrolling)
            _selectionView.magnify = NO;
          else
            [_selectionView setMagnify:YES fromRect:CGRectMake(tapPoint.x, self.contentOffset.y + tapPoint.y, 2, 2) textPoint:point ratio:2 animated:animatePopover];
        }
      }];
    }
  }
}

#pragma mark - Keyboard Accessory Methods

- (void)_keyboardWillChangeFrame:(NSNotification *)notification
{
  _keyboardFrame = CGRectNull;
  [self setKeyboardAccessoryViewVisible:NO animated:NO];
  _keyboardWillShow = YES;
}

- (void)_keyboardDidChangeFrame:(NSNotification *)notification
{
  _keyboardWillShow = NO;
  _keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  if (self.isFirstResponder)
    [self setKeyboardAccessoryViewVisible:YES animated:YES];
}

- (void)setKeyboardAccessoryViewVisible:(BOOL)visible animated:(BOOL)animated
{
  if (_keyboardWillShow || !self.keyboardAccessoryView || (self.keyboardAccessoryView.superview != nil) == visible)
    return;
  
  if (visible && self.isFirstResponder)
  {
    // Setup accessory view
    CGRect targetFrame = CGRectIsNull(_keyboardFrame) ? CGRectMake(0, CGRectGetMaxY(self.bounds), [self convertRect:[[UIScreen mainScreen] bounds] fromView:nil].size.width, KEYBOARD_DOCKED_MINIMUM_HEIGHT) : [self convertRect:_keyboardFrame fromView:nil];
    CGFloat keyboardHeight = targetFrame.size.height;
    targetFrame.size.height = ACCESSORY_HEIGHT;
    targetFrame.origin.y -= ACCESSORY_HEIGHT;
    self.keyboardAccessoryView.split = (keyboardHeight < KEYBOARD_DOCKED_MINIMUM_HEIGHT);
    self.keyboardAccessoryView.flipped = NO;
    
    // Ask delegate if accessory view should be shown
    __autoreleasing UIView *targetView = self;
    if (_flags.delegateHasShouldShowKeyboardAccessoryViewInViewWithFrame && ![self.delegate codeView:self shouldShowKeyboardAccessoryViewInView:&targetView withFrame:&targetFrame])
      return;
    
    // Reposition if flipped
    if (self.keyboardAccessoryView.isSplit && self.keyboardAccessoryView.isFlipped)
    {
      targetFrame.origin.y += keyboardHeight + ACCESSORY_HEIGHT;
    }
    
    // Add accessory to target view
    self.keyboardAccessoryView.frame = targetFrame;
    [targetView addSubview:self.keyboardAccessoryView];
    [self.keyboardAccessoryView setNeedsLayout];
    self.keyboardAccessoryView.alpha = 0;
    [UIView animateWithDuration:(animated ? 0.25 : 0) delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      self.keyboardAccessoryView.alpha = 1;
    } completion:^(BOOL finished) {
      if (_flags.delegateHasDidShowKeyboardAccessoryViewInViewWithFrame)
      {
        [self.delegate codeView:self didShowKeyboardAccessoryViewInView:targetView withFrame:targetFrame];
      }
    }];
  }
  else if (!_flags.delegateHasShouldHideKeyboardAccessoryView || [self.delegate codeViewShouldHideKeyboardAccessoryView:self])
  {
    [UIView animateWithDuration:(animated ? 0.25 : 0) delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
      keyboardAccessoryView.alpha = 0;
    } completion:^(BOOL finished) {
      [keyboardAccessoryView removeFromSuperview];
      keyboardAccessoryView.alpha = 1;
      if (_flags.delegateHasDidHideKeyboardAccessoryView)
      {
        [self.delegate codeViewDidHideKeyboardAccessoryView:self];
      }
    }];
  }
}

@end

#pragma mark - CodeViewConentView

@implementation CodeViewContentView

@synthesize parentCodeView;

+ (Class)layerClass
{
  return [CATiledLayer class];
}

- (void)drawRect:(CGRect)rect
{
  ASSERT(parentCodeView != nil);
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  [parentCodeView.backgroundColor setFill];
  CGContextFillRect(context, rect);
  
  // Setup tile passes
  [parentCodeView->setupPasses enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    ((CodeViewTileSetupBlock)obj)(context, rect);
  }];
  
  // Line number background
  if (parentCodeView.isLineNumbersEnabled)
  {
    [parentCodeView.lineNumbersBackgroundColor setFill];
    CGContextFillRect(context, (CGRect){ rect.origin, CGSizeMake(parentCodeView.lineNumbersWidth, rect.size.height) });
    [parentCodeView.lineNumbersColor setStroke];
    CGContextSetLineWidth(context, 1);
    CGContextMoveToPoint(context, rect.origin.x + parentCodeView.lineNumbersWidth + 0.5, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + parentCodeView.lineNumbersWidth + 0.5, CGRectGetMaxY(rect));
    CGContextStrokePath(context);
  }
  
  // Drawing text
  if (rect.origin.y > 0)
    CGContextTranslateCTM(context, 0, rect.origin.y);
  [parentCodeView.renderer drawTextWithinRect:rect inContext:context];
  
  // Cleanup tile passes
  [parentCodeView->cleanupPasses enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    ((CodeViewTileSetupBlock)obj)(context, rect);
  }];
}

- (void)setFrame:(CGRect)frame
{
  ASSERT(CGRectEqualToRect(frame, CGRectIntegral(frame)) && "If frame is not integral, the rendering is blurry.");
  
  if (CGRectEqualToRect(frame, self.frame))
    return;
  
  if (frame.size.width != self.frame.size.width)
    [(CATiledLayer *)self.layer setTileSize:CGSizeMake(frame.size.width, TILE_HEIGHT)];
  
  [super setFrame:frame];
}

@end

#pragma mark - TextMagnificationView

@implementation TextMagnificationView

- (id)initWithFrame:(CGRect)frame codeView:(CodeView *)codeView
{
  if ((self = [super initWithFrame:frame])) 
  {
    parent = codeView;
  }
  return self;
}


- (void)drawRect:(CGRect)rect
{
  [self.backgroundColor setFill];
  CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
  
  @synchronized(detailImage)
  {
    [detailImage drawInRect:rect];
  }
}

- (void)detailTextAtPoint:(CGPoint)point magnification:(CGFloat)magnification additionalDrawingBlock:(void(^)(CGContextRef, CGPoint))block
{
  // Generate required text rect
  CGRect textRect = (CGRect){ point, self.bounds.size };
  textRect.size.width /= magnification;
  textRect.size.height /= magnification;
  textRect.origin.x -= (textRect.size.width / 2);
  textRect.origin.y -= (textRect.size.height / 2);
  
  // Check to be contained in text bounds
  if (textRect.origin.x < -10)
    textRect.origin.x = -10;
  else if (CGRectGetMaxX(textRect) > parent.renderer.renderWidth + 10)
    textRect.origin.x = parent.renderer.renderWidth - textRect.size.width + 10;
  // Render magnified image
  __weak TextMagnificationView *this = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    UIGraphicsBeginImageContext(this.bounds.size);
    // Prepare magnified context
    CGContextRef imageContext = UIGraphicsGetCurrentContext();        
    CGContextScaleCTM(imageContext, magnification, magnification);
    CGContextTranslateCTM(imageContext, -textRect.origin.x, 0);
    // Render text
    CGContextSaveGState(imageContext);
    [this->parent.renderer drawTextWithinRect:textRect inContext:imageContext];
    CGContextRestoreGState(imageContext);
    // Render additional drawings
    if (block)
      block(imageContext, textRect.origin);
    // Get result image
    @synchronized(this->detailImage)
    {
      this->detailImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    // Request rerendering
    [NSOperationQueue.mainQueue addOperationWithBlock:^(void) {
      [this setNeedsDisplay];
    }];
  });
}

@end

#pragma mark - TextSelectionKnobView

@implementation TextSelectionKnobView

@synthesize knobDirection, knobDiameter;
@synthesize caretRect, caretColor;

- (void)setCaretRect:(CGRect)rect
{
  caretRect = rect;
  
  // Set frame considering knob direction
  // The given rect has origin where the selection start/end
  rect.size.width = KNOB_SIZE;
  rect.origin.x -= KNOB_SIZE / 2;
  rect.size.height = KNOB_SIZE;
  rect.origin.y -= (KNOB_SIZE - caretRect.size.height) / 2;
  self.frame = rect;
}

- (id)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) 
  {
    knobDiameter = 10;
    self.backgroundColor = [UIColor clearColor];
  }
  return self;
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  [caretColor setFill];
  
  // Draw caret
  CGRect bounds = self.bounds;
  CGRect caret = caretRect;
  caret.origin.x = CGRectGetMidX(bounds) - CARET_WIDTH / 2;
  caret.origin.y = CGRectGetMidY(bounds) - caretRect.size.height / 2;
  CGContextFillRect(context, caret);
  
  // Draw knob
  CGContextAddArc(context, CGRectGetMidX(caret), knobDirection == UITextLayoutDirectionRight ? CGRectGetMaxY(caret) : caret.origin.y, knobDiameter / 2, -M_PI, M_PI, 0);
  CGContextFillPath(context);
}

@end

#pragma mark - TextSelectionView

@implementation TextSelectionView

#pragma mark Properties

@synthesize selection, selectionRects;
@synthesize selectionColor, caretColor, blink;
@synthesize magnificationPopover, magnificationView;

- (void)setSelection:(NSRange)range scrollToVisible:(BOOL)scrollToVisible
{
  [parent willChangeValueForKey:@"selectionRange"];
  
  selection = range;
  [self update];
  
  if (scrollToVisible)
    [parent scrollRectToVisible:self.frame animated:self.isHidden];
  
  [parent didChangeValueForKey:@"selectionRange"];
}

- (void)setSelection:(NSRange)range
{
  [self setSelection:range scrollToVisible:YES];
}

- (TextRange *)selectionRange
{
  return [[TextRange alloc] initWithRange:selection];
}

- (void)setSelectionRange:(TextRange *)selectionRange
{
  self.selection = [selectionRange range];
}

- (TextPosition *)selectionPosition
{
  return [[TextPosition alloc] initWithIndex:selection.location];
}

- (BOOL)isEmpty
{
  return selection.length == 0;
}

#pragma mark Selection updating

- (void)update
{
  // Stop blinking
  if (blinkDelayTimer)
  {
    [blinkDelayTimer invalidate];
    blinkDelayTimer = nil;
  }
  self.blink = NO;
  
  // Set new selection behaviour
  if (selection.length == 0) 
  {
    self.frame = [parent caretRectForPosition:self.selectionPosition];
    self.hidden = ![parent isFirstResponder];
    
    [leftKnob removeFromSuperview];
    leftKnobRecognizer.enabled = NO;
    [rightKnob removeFromSuperview];
    rightKnobRecognizer.enabled = NO;
    
    if (self.isHidden)
      return;
    
    // Start blinking after the selection change has stopped
    blinkDelayTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 usingBlock:^(NSTimer *timer) {
      self.blink = YES;
      blinkDelayTimer = nil;
    } repeats:NO];
  }
  else
  {
    selectionRects = [parent.renderer rectsForStringRange:selection limitToFirstLine:NO];
    self.frame = selectionRects.bounds;
    self.hidden = NO;
    
    // Left knob
    if (!leftKnob) 
    {
      leftKnob = [TextSelectionKnobView new];
      leftKnob.caretColor = caretColor;
      leftKnob.knobDirection = UITextLayoutDirectionLeft;
    }
    CGRect knobRect = [selectionRects topLeftRect];
    knobRect.size.width = CARET_WIDTH;
    leftKnob.caretRect = knobRect;
    [parent addSubview:leftKnob];
    if (!leftKnobRecognizer) 
    {
      leftKnobRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleKnobGesture:)];
      leftKnobRecognizer.minimumPressDuration = 0;
      [leftKnob addGestureRecognizer:leftKnobRecognizer];
    }
    leftKnobRecognizer.enabled = YES;
    
    // Right knob
    if (!rightKnob) 
    {
      rightKnob = [TextSelectionKnobView new];
      rightKnob.caretColor = caretColor;
      rightKnob.knobDirection = UITextLayoutDirectionRight;
    }
    knobRect = [selectionRects bottomRightRect];
    knobRect.origin.x = CGRectGetMaxX(knobRect);
    knobRect.size.width = CARET_WIDTH;
    rightKnob.caretRect = knobRect;
    [parent addSubview:rightKnob];
    if (!rightKnobRecognizer) 
    {
      rightKnobRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleKnobGesture:)];
      rightKnobRecognizer.minimumPressDuration = 0;
      [rightKnob addGestureRecognizer:rightKnobRecognizer];
    }
    rightKnobRecognizer.enabled = YES;
  }
  
  [self setNeedsDisplay];
}

#pragma mark Blinking

- (void)setBlink:(BOOL)doBlink
{
  if (blink == doBlink)
    return;
  
  blink = doBlink;
  
  if (!blinkAnimation) 
  {
    blinkAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    blinkAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    blinkAnimation.toValue = [NSNumber numberWithFloat:0.0];
    blinkAnimation.repeatCount = CGFLOAT_MAX;
    blinkAnimation.autoreverses = YES;
    blinkAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    blinkAnimation.duration = 0.6;
  }
  
  if (blink) 
  {
    [self.layer addAnimation:blinkAnimation forKey:@"blink"];
  }
  else
  {
    [self.layer removeAnimationForKey:@"blink"];
    self.layer.opacity = 1.0;
  }
}

- (void)setHidden:(BOOL)hidden
{
  if (hidden)
    [self setBlink:NO];
  [super setHidden:hidden];
}

#pragma mark Magnification

@synthesize magnify;

- (void)setMagnify:(BOOL)doMagnify
{
  if (magnify == doMagnify)
    return;
  
  [self setMagnify:doMagnify fromRect:self.frame ratio:2 animated:YES];
}

- (void)setMagnify:(BOOL)doMagnify fromRect:(CGRect)rect ratio:(CGFloat)ratio animated:(BOOL)animated
{
  [self setMagnify:doMagnify fromRect:rect textPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect)) ratio:ratio animated:animated];
}

- (void)setMagnify:(BOOL)doMagnify fromRect:(CGRect)rect textPoint:(CGPoint)textPoint ratio:(CGFloat)ratio animated:(BOOL)animated
{
  magnify = doMagnify;
  
  if (!doMagnify) 
  {
    self.blink = selection.length == 0;
    [self.magnificationPopover dismissPopoverAnimated:animated];
  }
  else
  {
    // Stop blinking
    if (blinkDelayTimer)
    {
      [blinkDelayTimer invalidate];
      blinkDelayTimer = nil;
    }
    self.blink = NO;
    
    // Magnify at the center of given rect
    [self.magnificationView detailTextAtPoint:textPoint magnification:ratio additionalDrawingBlock:^(CGContextRef context, CGPoint textOffset) {
      if (selection.length == 0) 
      {
        // Draw caret
        CGRect detailCaretRect = self.frame;
        detailCaretRect.origin.y -= textOffset.y;
        [caretColor setFill];
        CGContextFillRect(context, detailCaretRect);
      }
      else
      {
        // Draw selection
        [selectionColor setFill];
        CGContextTranslateCTM(context, 0, -textOffset.y);
        [selectionRects addRectsToContext:context];
        CGContextFillPath(context);
      }
    }];
    
    // Show popover
    [self.magnificationPopover presentPopoverFromRect:rect inView:parent permittedArrowDirections:UIPopoverArrowDirectionDown | UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight animated:animated];
  }
}

- (UIPopoverController *)magnificationPopover
{
  if (!magnificationPopover) 
  {
    UIViewController *magnificationViewController = [[UIViewController alloc] init];
    magnificationViewController.view = self.magnificationView;
    magnificationViewController.contentSizeForViewInPopover = CGSizeMake(200, 40);
    
    magnificationPopover = [[parent.magnificationPopoverControllerClass alloc] initWithContentViewController:magnificationViewController];
  }
  return magnificationPopover;
}

- (TextMagnificationView *)magnificationView
{
  if (!magnificationView)
  {
    magnificationView = [[TextMagnificationView alloc] initWithFrame:CGRectMake(0, 0, 200, 40) codeView:parent];
    magnificationView.backgroundColor = parent.backgroundColor;
    // TODO make this more efficient
    magnificationView.layer.cornerRadius = 3;
    magnificationView.layer.masksToBounds = YES;
  }
  return magnificationView;
}

- (void)handleKnobGesture:(UILongPressGestureRecognizer *)recognizer
{
  // TODO it may be needed to change thumbs hit test, see ouieditableframe 1842
  
  CGPoint tapPoint = [recognizer locationInView:parent];
  
  // Retrieving position
  NSUInteger pos = [parent.renderer closestStringLocationToPoint:tapPoint withinStringRange:NSMakeRange(0, 0)];
  
  // Changing selection
  if (recognizer.view == rightKnob) 
  {   
    if (pos > selection.location) 
    {
      [self setSelection:NSMakeRange(selection.location, pos - selection.location) scrollToVisible:NO];
    }
  }
  else // leftKnob
  {
    if (pos < NSMaxRange(selection)) 
    {
      [self setSelection:NSMakeRange(pos, NSMaxRange(selection) - pos) scrollToVisible:NO];
    }
  }
  
  // Magnification
  BOOL animatePopover = NO;
  switch (recognizer.state)
  {
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled:
      self.magnify = NO;
      [parent _stopAutoScroll];
      break;
      
    case UIGestureRecognizerStateBegan:
      animatePopover = YES;
      
    default:
    {
      CGRect knobRect = recognizer.view.frame;
      [self setMagnify:YES fromRect:knobRect ratio:2 animated:animatePopover];
      
      // Scrolling
      tapPoint.y -= parent.contentOffset.y;
      [parent _autoScrollForTouchAtPoint:tapPoint eventBlock:^(BOOL isScrolling) {
        if (isScrolling)
          self.magnify = NO;
        else
          [self setMagnify:YES fromRect:recognizer.view.frame ratio:2 animated:YES];
      }];
    }
  }
}

#pragma mark UIView Methods

- (id)initWithFrame:(CGRect)frame codeView:(CodeView *)codeView
{
  if ((self = [super initWithFrame:frame])) 
  {
    parent = codeView;
  }
  return self;
}


- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  if (selection.length > 0) 
  {
    [selectionColor setFill];
    
    CGPoint rectsOrigin = selectionRects.bounds.origin;
    CGContextTranslateCTM(context, -rectsOrigin.x, -rectsOrigin.y);
    
    [selectionRects addRectsToContext:context];
    CGContextFillPath(context);
  }
  else
  {
    [caretColor setFill];
    CGContextFillRect(context, rect);
  }
}

@end

#pragma mark - CodeFlashView

@implementation CodeFlashView {
  UIImageView *_backgroundImageView;
}

@synthesize cornerRadius;

- (UIImage *)backgroundImage
{
  return _backgroundImageView.image;
}

- (void)setBackgroundImage:(UIImage *)value
{
  if (value == _backgroundImageView.image)
    return;
  if (!_backgroundImageView)
  {
    _backgroundImageView = [UIImageView new];
    _backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backgroundImageView.frame = self.bounds;
    [self addSubview:_backgroundImageView];
  }
  _backgroundImageView.image = value;
}

- (void)flashInRect:(CGRect)rect view:(UIView *)view withDuration:(NSTimeInterval)duration
{
  [self setNeedsDisplay];
  
  [view addSubview:self];
  self.contentMode = UIViewContentModeScaleToFill;
  self.frame = CGRectIntegral(rect);
  self.alpha = 0;
  self.transform = CGAffineTransformIdentity;
  [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:^{
    self.alpha = 1;
    self.transform = CGAffineTransformMakeScale(1.7, 1.7);
  } completion:^(BOOL finished) {
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
      self.alpha = 0;
      self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
      [self removeFromSuperview];
    }];
  }];
}

@end

#pragma mark - CodeViewUndoManager

@implementation CodeViewUndoManager

- (void)beginUndoGrouping
{
  if (self.groupingLevel != 0)
    [self endUndoGrouping];
  [super beginUndoGrouping];
}

- (void)undo
{
  if (self.groupingLevel != 0)
    [self endUndoGrouping];
  
  if ([[self undoActionName] length] > 0)
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormat:@"Undo %@", [self undoActionName]] image:nil displayImmediatly:YES];
  
  [super undo];
}

- (void)redo
{
  if ([[self redoActionName] length] > 0)
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormat:@"Redo %@", [self redoActionName]] image:nil displayImmediatly:YES];
  
  [super redo];
}

@end
