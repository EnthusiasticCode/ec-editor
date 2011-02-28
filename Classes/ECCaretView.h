//
//  ECCaretView.h
//  edit
//
//  Created by Nicola Peduzzi on 26/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef CGPathRef (^PathForRectBlock)(CGRect);

@interface ECCaretView : UIView {
@private
    CGPathRef _caretShape;
}

@property (nonatomic, getter = isBlinking) BOOL blink;
@property (nonatomic) NSUInteger pulsePerSecond;

// Gets or set the color of the carret.
@property (nonatomic, retain) UIColor *caretColor;

// Specify or retrieve a block that can be used to create a 
// path used to draw the caret shape.
@property (nonatomic, copy) PathForRectBlock caretShapeBlock;

// Retrieve the current shape of the caret.
@property (nonatomic, readonly) CGPathRef caretShape;

// Draw the solid caret in the specified context
- (void)drawInContext:(CGContextRef)context;
@end
