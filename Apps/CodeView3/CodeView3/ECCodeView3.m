//
//  ECCodeView3.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView3.h"
#import "ECTextRange.h"
#import "ECTextPosition.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "ECCoreText.h"

@interface ECCodeView3 () {
    NSMutableAttributedString *text;
    
    // Text input support ivars
    ECTextRange *selection;
    NSRange markedRange;
    
    // Core text support ivars
    BOOL framesetterInvalid;
    CTFramesetterRef framesetter;
    NSMutableArray *frames;
}

/// Method to be used before any text modification occurs.
- (void)beforeTextChange;
- (void)afterTextChangeInRange:(UITextRange *)range;

/// Support method to set the selection and notify the input delefate.
- (void)setSelectedTextRange:(ECTextRange *)newSelection notifyDelegate:(BOOL)shouldNotify;

/// Convinience method to set the selection to an index location.
- (void)setSelectedIndex:(NSUInteger)index;

/// Helper method to set the selection starting from two points.
- (void)setSelectedTextFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint;

@end

@implementation ECCodeView3

#pragma mark -
#pragma mark Properties

@synthesize delegate;
@synthesize textInsets;

- (void)setDelegate:(id<ECCodeViewDelegate>)aDelegate
{
    delegate = aDelegate;
    // TODO compute if delegate responds to selectors.
}

#pragma mark -
#pragma mark UIView Methods

static void init(ECCodeView3 *self)
{
    self->frames = [NSMutableArray new];
}

- (void)dealloc
{
    // TODO release frames
    [frames release];
    if (framesetter)
        CFRelease(framesetter);
    [selection release];
    [text release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        init(self);
    }
    return self;
}

+ (Class)layerClass
{
    return [CATiledLayer class];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    
}

@end
